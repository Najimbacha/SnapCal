import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../core/resilience/app_failure.dart';
import '../core/resilience/resilient_provider_mixin.dart';
import '../core/resilience/retry_policy.dart';
import '../core/resilience/safe_async.dart';
import '../core/state/async_ui_state.dart';
import '../core/resilience/timeout_policy.dart';
import '../l10n/generated/app_localizations.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier, ResilientProviderMixin {
  static const String _googleServerClientId =
      '183409999145-2p9nqjrr8d07ulal61nupsefkh7pt9on.apps.googleusercontent.com';
  static Future<void>? _googleInitFuture;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final StreamSubscription<User?> _authSubscription;

  User? _user;
  AuthStatus _status = AuthStatus.initial;
  AsyncUiState _uiState = const AsyncUiState.idle();
  String? _errorMessage;

  AuthProvider() {
    _authSubscription = _auth.userChanges().listen(_onAuthStateChanged);
  }

  // Getters
  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  AsyncUiState get uiState => _uiState;
  bool get isBusy => _uiState.isBusy || _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAnonymous => _user?.isAnonymous ?? true;

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
      if (identical(_googleInitFuture, initFuture)) {
        _googleInitFuture = null;
      }
      rethrow;
    }
  }

  void _syncStatusFromUser() {
    _status =
        _user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    _uiState = const AsyncUiState.success();
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    _syncStatusFromUser();
    notifyListeners();
  }

  void _setAuthFailure(Object error) {
    final failure = error is AppFailure ? error : AppFailure.fromError(error);
    _errorMessage = failure.message;
    _status = AuthStatus.error;
    _uiState = stateFromFailure(failure);
  }

  Future<void> _runAuthOperation({
    required String label,
    required String operationKey,
    required Future<void> Function() operation,
    bool blocking = true,
  }) async {
    if (isBusy || !canStartOperation(operationKey)) return;
    _errorMessage = null;
    _status = AuthStatus.loading;
    _uiState =
        blocking || _user == null
            ? const AsyncUiState.loading()
            : const AsyncUiState.refreshing();
    notifyListeners();

    try {
      final result = await SafeAsync.run<void>(
        label: label,
        operation: operation,
        timeout: TimeoutPolicy.auth,
        retryPolicy: RetryPolicy.auth,
        isActive: () => isProviderActive,
      );
      if (!isProviderActive) return;
      if (result.isFailure) {
        _setAuthFailure(result.failure!);
        return;
      }
      _user = _auth.currentUser;
      _syncStatusFromUser();
    } finally {
      finishOperation(operationKey);
      if (isProviderActive) notifyListeners();
    }
  }

  /// Sign in anonymously (Lazy Auth)
  Future<void> signInAnonymously() async {
    await _runAuthOperation(
      label: 'Anonymous sign-in',
      operationKey: 'auth:anonymous',
      operation: () => _auth.signInAnonymously().then((_) {}),
    );
  }

  /// Sign in with Google and link if anonymous
  Future<void> signInWithGoogle() async {
    if (isBusy) return;
    _errorMessage = null; // Clear previous errors
    _status = AuthStatus.loading;
    _uiState =
        _user == null
            ? const AsyncUiState.loading()
            : const AsyncUiState.refreshing();
    notifyListeners();

    try {
      debugPrint('🔑 AuthProvider: Starting Google Auth...');
      await _ensureGoogleInitialized().timeout(
        TimeoutPolicy.auth,
        onTimeout:
            () =>
                throw TimeoutException(
                  'Google sign-in is taking too long. Please try again.',
                ),
      );
      debugPrint('🔑 AuthProvider: GoogleSignIn initialized');

      if (!_googleSignIn.supportsAuthenticate()) {
        throw FirebaseAuthException(
          code: 'google-auth-unavailable',
          message: 'Google Sign-In is not available on this platform.',
        );
      }

      final googleUser = await _googleSignIn.authenticate().timeout(
        TimeoutPolicy.socialAuth,
        onTimeout:
            () =>
                throw TimeoutException(
                  'Google sign-in timed out. Please try again.',
                ),
      );

      debugPrint(
        '🔑 AuthProvider: Google Auth success, getting authentication data...',
      );
      final GoogleSignInAuthentication authData = googleUser.authentication;

      debugPrint('🔑 AuthProvider: Creating Firebase credential...');
      if (authData.idToken == null || authData.idToken!.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message:
              'Google did not return a valid sign-in token. Please try again.',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: authData.idToken,
      );

      if (isAnonymous) {
        debugPrint('🔑 AuthProvider: Linking anonymous account...');
        try {
          await _user!
              .linkWithCredential(credential)
              .timeout(TimeoutPolicy.auth);
          debugPrint('🔑 AuthProvider: Linking success');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            debugPrint(
              '🔑 AuthProvider: Credential in use, signing in directly...',
            );
            await _auth
                .signInWithCredential(credential)
                .timeout(TimeoutPolicy.auth);
          } else {
            debugPrint(
              '❌ AuthProvider: Linking error: ${e.code} - ${e.message}',
            );
            rethrow;
          }
        }
      } else {
        debugPrint('🔑 AuthProvider: Signing in with credential...');
        await _auth
            .signInWithCredential(credential)
            .timeout(TimeoutPolicy.auth);
      }
      debugPrint('✅ AuthProvider: Google Sign-In Complete');
      _user = _auth.currentUser;
      _syncStatusFromUser();
      notifyListeners();
    } on GoogleSignInException catch (e) {
      debugPrint('❌ AuthProvider: Google Sign-In Error: $e');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _syncStatusFromUser();
      } else {
        final description = e.description;
        _errorMessage =
            description == null || description.isEmpty
                ? _l10n.auth_google_sign_in_failed_code(e.code.name)
                : description;
        _status = AuthStatus.error;
        _uiState = AsyncUiState.error(_errorMessage);
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthProvider: Firebase Google Auth Error: $e');
      _errorMessage =
          e.message ?? _l10n.auth_firebase_google_sign_in_failed(e.code);
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AuthProvider: Google Sign-In Error: $e');
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    }
  }

  /// Sign in with Facebook and link if anonymous
  Future<void> signInWithFacebook() async {
    _errorMessage = null; // Clear previous errors
    if (isBusy) return;
    _status = AuthStatus.loading;
    _uiState =
        _user == null
            ? const AsyncUiState.loading()
            : const AsyncUiState.refreshing();
    notifyListeners();

    try {
      final LoginResult result = await FacebookAuth.instance.login().timeout(
        TimeoutPolicy.socialAuth,
      );

      if (result.status == LoginStatus.success) {
        final AuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );

        if (isAnonymous) {
          try {
            await _user!
                .linkWithCredential(credential)
                .timeout(TimeoutPolicy.auth);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use') {
              // Account exists, switch to it
              await _auth
                  .signInWithCredential(credential)
                  .timeout(TimeoutPolicy.auth);
            } else {
              rethrow;
            }
          }
        } else {
          await _auth
              .signInWithCredential(credential)
              .timeout(TimeoutPolicy.auth);
        }
      } else {
        _errorMessage = result.message;
        _status = AuthStatus.error;
        _uiState = AsyncUiState.error(_errorMessage);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<void> registerWithEmail(String email, String password) async {
    _errorMessage = null; // Clear previous errors
    if (isBusy) return;
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    try {
      if (isAnonymous) {
        try {
          // Try to link first
          final credential = EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          await _user!
              .linkWithCredential(credential)
              .timeout(TimeoutPolicy.auth);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Account exists, so sign in (switch users)
            await _auth
                .signInWithEmailAndPassword(email: email, password: password)
                .timeout(TimeoutPolicy.auth);
          } else {
            rethrow;
          }
        }
      } else {
        await _auth
            .createUserWithEmailAndPassword(email: email, password: password)
            .timeout(TimeoutPolicy.auth);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    await _runAuthOperation(
      label: 'Email sign-in',
      operationKey: 'auth:emailSignIn',
      operation:
          () => _auth
              .signInWithEmailAndPassword(email: email, password: password)
              .then((_) {}),
    );
  }

  /// Verify phone number (Step 1 of Phone Auth)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    bool isMock = false, // Add isMock for WhatsApp simulation
  }) async {
    _errorMessage = null;
    if (isBusy) return;
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    if (isMock) {
      // Simulation for WhatsApp/Development
      await Future.delayed(const Duration(seconds: 2));
      _status = AuthStatus.unauthenticated;
      _uiState = const AsyncUiState.success();
      onCodeSent("mock_verification_id"); // Simulate success
      notifyListeners();
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (isAnonymous) {
            await _user!
                .linkWithCredential(credential)
                .timeout(TimeoutPolicy.auth);
          } else {
            await _auth
                .signInWithCredential(credential)
                .timeout(TimeoutPolicy.auth);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = e.message;
          _status = AuthStatus.error;
          _uiState = AsyncUiState.error(_errorMessage);
          onVerificationFailed(e.message ?? 'Verification failed');
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _status = AuthStatus.unauthenticated;
          _uiState = const AsyncUiState.success();
          onCodeSent(verificationId);
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    }
  }

  /// Sign in with OTP (Step 2 of Phone Auth)
  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    _errorMessage = null;
    if (isBusy) return;
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    if (verificationId == "mock_verification_id") {
      // Mock validation: Allow logic if code is 123456
      if (smsCode == "123456") {
        await Future.delayed(const Duration(seconds: 1));
        _status = AuthStatus.authenticated;
        _uiState = const AsyncUiState.success();
        notifyListeners();
      } else {
        _errorMessage = "Invalid mock code. Try 123456";
        _status = AuthStatus.error;
        _uiState = AsyncUiState.error(_errorMessage);
        notifyListeners();
        throw Exception(_errorMessage);
      }
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      if (isAnonymous) {
        await _user!.linkWithCredential(credential).timeout(TimeoutPolicy.auth);
      } else {
        await _auth
            .signInWithCredential(credential)
            .timeout(TimeoutPolicy.auth);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _runAuthOperation(
      label: 'Sign out',
      operationKey: 'auth:signOut',
      blocking: false,
      operation: () async {
        unawaited(
          SafeAsync.fireAndReport(
            label: 'Google sign-out',
            operation: () => _googleSignIn.signOut().then((_) {}),
            timeout: TimeoutPolicy.auth,
          ),
        );
        unawaited(
          SafeAsync.fireAndReport(
            label: 'Facebook sign-out',
            operation: () => FacebookAuth.instance.logOut(),
            timeout: TimeoutPolicy.auth,
          ),
        );
        await _auth.signOut();
      },
    );
  }

  /// Delete Account (requires recent login)
  Future<void> deleteAccount() async {
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    try {
      if (_user != null) {
        // If it's a social account, we might need to re-auth
        // But for now we try to delete directly.
        await _user!.delete().timeout(TimeoutPolicy.auth);
        _status = AuthStatus.unauthenticated;
        _uiState = const AsyncUiState.success();
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      if (e.code == 'requires-recent-login') {
        _errorMessage =
            "Please sign out and sign in again to verify your identity before deleting.";
      }
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _runAuthOperation(
      label: 'Password reset email',
      operationKey: 'auth:passwordReset',
      operation: () => _auth.sendPasswordResetEmail(email: email),
    );
  }

  /// Update display name
  Future<void> updateDisplayName(String name) async {
    await _runAuthOperation(
      label: 'Update display name',
      operationKey: 'auth:updateDisplayName',
      blocking: false,
      operation: () async {
        final user = _user;
        if (user == null) return;
        await user.updateDisplayName(name);
        await user.reload();
      },
    );
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _syncStatusFromUser();
    }
    notifyListeners();
  }

  AppLocalizations get _l10n {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode =
        AppLocalizations.supportedLocales.any(
              (supported) => supported.languageCode == locale.languageCode,
            )
            ? locale.languageCode
            : 'en';
    return lookupAppLocalizations(Locale(languageCode));
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
