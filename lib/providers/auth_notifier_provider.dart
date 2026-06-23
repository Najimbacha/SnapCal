import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/resilience/timeout_policy.dart';
import '../l10n/generated/app_localizations.dart';

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

  AppLocalizations get _l10n {
    final locale = PlatformDispatcher.instance.locale;
    final lang = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    ) ? locale.languageCode : 'en';
    return lookupAppLocalizations(Locale(lang));
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

      final googleUser = await _googleSignIn
          .authenticate()
          .timeout(TimeoutPolicy.socialAuth);
      final authData = googleUser.authentication;

      if (authData.idToken == null || authData.idToken!.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google did not return a valid sign-in token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: authData.idToken);
      final user = FirebaseAuth.instance.currentUser;

      if (user?.isAnonymous == true) {
        try {
          await user!.linkWithCredential(credential).timeout(TimeoutPolicy.auth);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            await FirebaseAuth.instance.signInWithCredential(credential);
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
      final result = await FacebookAuth.instance
          .login()
          .timeout(TimeoutPolicy.socialAuth);

      if (result.status != LoginStatus.success) {
        throw Exception(result.message ?? 'Facebook sign-in failed');
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      final user = FirebaseAuth.instance.currentUser;

      if (user?.isAnonymous == true) {
        try {
          await user!.linkWithCredential(credential).timeout(TimeoutPolicy.auth);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            await FirebaseAuth.instance.signInWithCredential(credential);
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
      final user = FirebaseAuth.instance.currentUser;
      if (user?.isAnonymous == true) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        try {
          await user!.linkWithCredential(credential).timeout(TimeoutPolicy.auth);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
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
    state = await AsyncValue.guard(() =>
      FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .then((_) {}),
    );
  }

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
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
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email),
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
