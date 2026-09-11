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
import '../data/services/sync_queue_service.dart';
import 'assistant_provider.dart';
import 'cloud_sync_provider.dart';
import 'meal_provider.dart';
import 'metrics_provider.dart';
import 'planner_provider.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';
import 'template_provider.dart';
import 'water_provider.dart';

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
    Future<void> Function() signIn,
  ) async {
    String? previousUidToken;
    try {
      previousUidToken = await anonymousUser.getIdToken();
    } catch (e) {
      debugPrint('Anonymous token fetch failed before link: $e');
    }

    await signIn();

    // Quota keys are UID-scoped, so a switch would otherwise hand the user a
    // fresh set of free scans. Carry the anonymous counters across.
    final newUid = FirebaseAuth.instance.currentUser?.uid;
    if (newUid != null) {
      await ScanGateService().migrateScopeTo(newUid);
    }

    // What they logged as a guest is on this phone only, under the identity
    // just left behind. Carry it into the account, or it is never backed up.
    unawaited(ref.read(cloudSyncProvider.notifier).uploadAllLocal());

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
            await _switchAwayFromAnonymous(
              anonymousUser!,
              () => FirebaseAuth.instance.signInWithCredential(credential),
            );
          } else {
            rethrow;
          }
        }
      } else if (_isDifferentAccount(email: googleUser.email)) {
        await _signInReplacingAccount(
          () => FirebaseAuth.instance.signInWithCredential(credential),
        );
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
            await _switchAwayFromAnonymous(
              anonymousUser!,
              () => FirebaseAuth.instance.signInWithCredential(credential),
            );
          } else {
            rethrow;
          }
        }
      } else if (_isDifferentAccount(providerId: 'facebook.com')) {
        await _signInReplacingAccount(
          () => FirebaseAuth.instance.signInWithCredential(credential),
        );
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
            // guards as social sign-in.
            await _switchAwayFromAnonymous(
              anonymousUser!,
              () => FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
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
    state = await AsyncValue.guard(() async {
      Future<void> signIn() => FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // This used to sign in directly. From a guest session that moved to the
      // account's UID with none of the guards the social sign-ins have: the
      // guest's meals stayed on the phone and never reached the account.
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.isAnonymous) {
        await _switchAwayFromAnonymous(current, signIn);
      } else if (_isDifferentAccount(email: email)) {
        await _signInReplacingAccount(signIn);
      } else {
        await signIn();
      }
    });
  }

  /// Whether signing in would move a signed-in user to a different account.
  /// Compares email where both sides have one; otherwise whether the current
  /// account already uses [providerId].
  bool _isDifferentAccount({String? email, String? providerId}) {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.isAnonymous) return false;
    final currentEmail = current.email;
    if (email != null && currentEmail != null) {
      return email.trim().toLowerCase() != currentEmail.toLowerCase();
    }
    if (providerId != null) {
      return !current.providerData.any((p) => p.providerId == providerId);
    }
    return true;
  }

  /// Signing in as someone else while signed in skips [signOut], and with it
  /// the wipe of this phone: the previous account's meals stayed here and were
  /// uploaded into the new account when edited. Send what is still queued for
  /// the current account, clear the phone, then sign in; the new account's
  /// data arrives with its first sync.
  Future<void> _signInReplacingAccount(Future<void> Function() signIn) async {
    await _flushQueueBeforeLeaving();
    try {
      await SessionCleanupService().clearLocalUserData().timeout(
        const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Session cleanup warning: $e');
    }
    try {
      await signIn();
    } finally {
      // On failure the current account is still signed in with an emptied
      // phone; its sync brings the data back.
      //
      // Settings come first. Until they arrive the emptied phone reads as a
      // user who never finished onboarding, and the router sends that user to
      // onboarding -- where answering again would overwrite the account's
      // real settings.
      await _pullSettingsNow();
      _resetUserState();
      unawaited(ref.read(cloudSyncProvider.notifier).syncNow());
    }
  }

  Future<void> _pullSettingsNow() async {
    try {
      final repo = await ref.read(settingsRepositoryProvider.future);
      await repo
          .syncFromFirestore(force: true)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Settings pull after account switch skipped: $e');
    }
  }

  /// Anything still queued belongs to the account being left, and the wipe
  /// that follows clears the queue with everything else.
  Future<void> _flushQueueBeforeLeaving() async {
    try {
      await SyncQueueService().flushDue().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Queue flush before leaving the account skipped: $e');
    }
  }

  /// Providers rebuild from the boxes the cleanup just emptied; without this
  /// they keep serving the previous account's data from memory, and a stale
  /// settings object saved later would write it into the new account.
  void _resetUserState() {
    ref.invalidate(settingsProvider);
    ref.invalidate(todaysMealsProvider);
    ref.invalidate(mealLogProvider);
    ref.invalidate(waterProvider);
    ref.invalidate(bodyMetricsProvider);
    ref.invalidate(templatesProvider);
    ref.invalidate(assistantProvider);
    ref.invalidate(plannerProvider);
    ref.invalidate(plannerNotifierProvider);
  }

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Wipe every user-scoped store BEFORE the Firebase sign-out so no other
      // account on this device can ever see the previous user's health data
      // (BUG-002). Provider invalidation alone is not enough — providers
      // rebuild from the same encrypted Hive boxes.
      await _flushQueueBeforeLeaving();
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

  /// Deletes the account on the server -- every record, photo and scan, then
  /// the login -- and only then clears this phone.
  ///
  /// This deleted the Firebase login from the phone and nothing else: the
  /// data stayed in the cloud. Firebase also refuses that call unless the
  /// user signed in within the last few minutes, so it usually failed -- and
  /// failed quietly, caught into state while the caller went home as if the
  /// account were gone. It now throws, and the caller says so.
  Future<void> deleteAccount() async {
    if (state.isLoading) {
      throw StateError('Another account action is still running.');
    }
    state = const AsyncLoading();
    try {
      // Anything still queued goes up first, so the server deletes it too
      // rather than it arriving after the account is gone.
      try {
        await _flushQueueBeforeLeaving();
      } catch (e) {
        debugPrint('Pre-deletion flush skipped: $e');
      }
      await ApiClient.dio
          .delete<void>('${ConfigService().backendProxyUrl}/api/account')
          .timeout(const Duration(seconds: 90));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
    // The account is gone; nothing of theirs may remain on disk. Clears
    // every box, deletes the box files and removes the encryption key.
    try {
      await SessionCleanupService()
          .clearLocalUserData(wipeSecurityKeys: true)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Post-deletion cleanup warning: $e');
    }
    unawaited(_googleSignIn.signOut());
    unawaited(FacebookAuth.instance.logOut());
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign-out after deletion: $e');
    }
    state = const AsyncData(null);
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
