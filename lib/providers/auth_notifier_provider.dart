import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/network/api_client.dart';
import '../core/resilience/timeout_policy.dart';
import '../core/services/config_service.dart';
import '../core/services/session_cleanup_service.dart';
import '../data/services/scan_gate_service.dart';
import '../data/services/subscription_service.dart';

part 'auth_notifier_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  static const String _googleServerClientId =
      '183409999145-2p9nqjrr8d07ulal61nupsefkh7pt9on.apps.googleusercontent.com';
  static Future<void>? _googleInitFuture;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  FutureOr<void> build() {}

  Future<void> _ensureGoogleInitialized() async {
    final existingInit = _googleInitFuture;
    if (existingInit != null) return existingInit;
    final initFuture = GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitFuture = initFuture;
    try {
      await initFuture;
    } catch (_) {
      if (identical(_googleInitFuture, initFuture)) _googleInitFuture = null;
      rethrow;
    }
  }

  /// Signs into [credential] while guarding against stranding a purchase
  /// (BUG-007). When the current anonymous account cannot be upgraded because
  /// the credential already belongs to another Firebase account, the fallback
  /// `signInWithCredential` switches to a *different UID* — and any Pro
  /// entitlement recorded by the RevenueCat webhook for the anonymous UID is
  /// left behind with no self-service recovery.
  ///
  /// Before switching we snapshot the anonymous identity; after switching we
  /// ask the backend whether the abandoned UID holds an active subscription.
  /// If it does we record both UIDs in Crashlytics so support can transfer it,
  /// and re-verify the new session's entitlement.
  Future<void> _switchAwayFromAnonymous(
    User anonymousUser,
    AuthCredential credential,
  ) async {
    String? previousUidToken;
    try {
      previousUidToken = await anonymousUser.getIdToken();
    } catch (e) {
      debugPrint('Anonymous token fetch failed before link: $e');
    }

    await FirebaseAuth.instance.signInWithCredential(credential);

    // Quota keys are UID-scoped, so a switch would otherwise hand the user a
    // fresh set of free scans. Carry the anonymous counters across.
    final newUid = FirebaseAuth.instance.currentUser?.uid;
    if (newUid != null) {
      await ScanGateService().migrateScopeTo(newUid);
    }

    unawaited(
      _reportStrandedEntitlementIfNeeded(anonymousUser.uid, previousUidToken),
    );
  }

  Future<void> _reportStrandedEntitlementIfNeeded(
    String previousUid,
    String? previousUidToken,
  ) async {
    try {
      if (previousUidToken == null) return;
      final response = await ApiClient.dio
          .get<Map<String, dynamic>>(
            '${ConfigService().backendProxyUrl}/api/premium-status',
            options: Options(
              headers: {'Authorization': 'Bearer $previousUidToken'},
            ),
          )
          .timeout(TimeoutPolicy.revenueCat);
      final wasActive = response.data?['isActive'] == true;
      if (!wasActive) return;

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseCrashlytics.instance.recordError(
        StateError('Premium entitlement stranded on orphaned UID'),
        StackTrace.current,
        information: [
          'abandonedUid=$previousUid',
          'currentUid=${currentUid ?? "unknown"}',
          'action=transfer-via-revenuecat-or-admin-grant',
        ],
      );
      // The RevenueCat app-user-id follows the new Firebase UID via the auth
      // listener; a restore/transfer will now attach the purchase correctly.
      unawaited(SubscriptionService().verifyCurrentEntitlement());
    } catch (e) {
      debugPrint('Stranded-entitlement check skipped: $e');
    }
  }

  Future<void> signInAnonymously() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => FirebaseAuth.instance.signInAnonymously().then((_) {}),
    );
  }

  Future<void> signInWithGoogle() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _ensureGoogleInitialized().timeout(TimeoutPolicy.auth);

      if (!_googleSignIn.supportsAuthenticate()) {
        throw FirebaseAuthException(
          code: 'google-auth-unavailable',
          message: 'Google Sign-In is not available on this platform.',
        );
      }

      final googleUser = await _googleSignIn.authenticate().timeout(
        TimeoutPolicy.socialAuth,
      );
      final authData = googleUser.authentication;

      if (authData.idToken == null || authData.idToken!.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google did not return a valid sign-in token.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: authData.idToken,
      );
      final anonymousUser = FirebaseAuth.instance.currentUser;
      final isAnonymous = anonymousUser?.isAnonymous == true;

      if (isAnonymous) {
        try {
          await anonymousUser!
              .linkWithCredential(credential)
              .timeout(TimeoutPolicy.auth);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            await _switchAwayFromAnonymous(anonymousUser!, credential);
          } else {
            rethrow;
          }
        }
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    });
  }

  Future<void> signInWithFacebook() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await FacebookAuth.instance.login().timeout(
        TimeoutPolicy.socialAuth,
      );

      if (result.status != LoginStatus.success) {
        throw Exception(result.message ?? 'Facebook sign-in failed');
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      final anonymousUser = FirebaseAuth.instance.currentUser;
      final isAnonymous = anonymousUser?.isAnonymous == true;

      if (isAnonymous) {
        try {
          await anonymousUser!
              .linkWithCredential(credential)
              .timeout(TimeoutPolicy.auth);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            await _switchAwayFromAnonymous(anonymousUser!, credential);
          } else {
            rethrow;
          }
        }
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    });
  }

  Future<void> registerWithEmail(String email, String password) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final anonymousUser = FirebaseAuth.instance.currentUser;
      if (anonymousUser?.isAnonymous == true) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        try {
          await anonymousUser!
              .linkWithCredential(credential)
              .timeout(TimeoutPolicy.auth);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Signing into an existing account switches UID; run the same
            // stranded-entitlement guard as social sign-in.
            final previousUidToken = await anonymousUser!.getIdToken();
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            unawaited(
              _reportStrandedEntitlementIfNeeded(
                anonymousUser.uid,
                previousUidToken,
              ),
            );
          } else {
            rethrow;
          }
        }
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .then((_) {}),
    );
  }

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Wipe every user-scoped store BEFORE the Firebase sign-out so no other
      // account on this device can ever see the previous user's health data
      // (BUG-002). Provider invalidation alone is not enough — providers
      // rebuild from the same encrypted Hive boxes.
      try {
        await SessionCleanupService().clearLocalUserData().timeout(
          const Duration(seconds: 15),
        );
      } catch (e) {
        debugPrint('Session cleanup warning: $e');
      }
      unawaited(_googleSignIn.signOut());
      unawaited(FacebookAuth.instance.logOut());
      await FirebaseAuth.instance.signOut();
    });
  }

  Future<void> deleteAccount() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) await user.delete().timeout(TimeoutPolicy.auth);
      // The Firebase user is gone; nothing of theirs may remain on disk.
      // Clears every box, deletes the box files and removes the encryption
      // key from secure storage.
      try {
        await SessionCleanupService()
            .clearLocalUserData(wipeSecurityKeys: true)
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('Post-deletion cleanup warning: $e');
      }
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => FirebaseAuth.instance.sendPasswordResetEmail(email: email),
    );
  }

  Future<void> updateDisplayName(String name) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.updateDisplayName(name);
      await user.reload();
    });
  }
}
