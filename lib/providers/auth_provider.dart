import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../core/state/async_ui_state.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  static const String _googleServerClientId =
      '183409999145-2p9nqjrr8d07ulal61nupsefkh7pt9on.apps.googleusercontent.com';
  static Future<void>? _googleInitFuture;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? _user;
  AuthStatus _status = AuthStatus.initial;
  AsyncUiState _uiState = const AsyncUiState.idle();
  String? _errorMessage;

  AuthProvider() {
    _auth.userChanges().listen(_onAuthStateChanged);
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

  /// Sign in anonymously (Lazy Auth)
  Future<void> signInAnonymously() async {
    if (isBusy) return;
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    try {
      await _auth.signInAnonymously().timeout(
        const Duration(seconds: 10),
        onTimeout:
            () =>
                throw TimeoutException(
                  'Sign-in timed out. Please check your connection.',
                ),
      );
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    }
  }

  /// Sign in with Google and link if anonymous
  Future<void> signInWithGoogle() async {
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
        const Duration(seconds: 8),
        onTimeout:
            () =>
                throw TimeoutException(
                  'Google sign-in is taking too long. Please try again.',
                ),
      );
      debugPrint('🔑 AuthProvider: GoogleSignIn initialized');

      if (!_googleSignIn.supportsAuthenticate()) {
        throw FirebaseAuthException(
          code: 'google-sign-in-unavailable',
          message: 'Google sign-in is not available on this device.',
        );
      }

      // In v7.2.0+, use authenticate() instead of signIn()
      final googleUser = await _googleSignIn.authenticate().timeout(
        const Duration(seconds: 30),
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
        // accessToken is no longer directly available in v7.x authentication object
        // but idToken is sufficient for Firebase Google Sign-In.
      );

      if (isAnonymous) {
        debugPrint('🔑 AuthProvider: Linking anonymous account...');
        try {
          await _user?.linkWithCredential(credential);
          debugPrint('🔑 AuthProvider: Linking success');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            debugPrint(
              '🔑 AuthProvider: Credential in use, signing in directly...',
            );
            await _auth.signInWithCredential(credential);
          } else {
            debugPrint(
              '❌ AuthProvider: Linking error: ${e.code} - ${e.message}',
            );
            rethrow;
          }
        }
      } else {
        debugPrint('🔑 AuthProvider: Signing in with credential...');
        await _auth.signInWithCredential(credential);
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
                ? 'Google Sign-In failed (${e.code}). Please try again.'
                : description;
        _status = AuthStatus.error;
        _uiState = AsyncUiState.error(_errorMessage);
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthProvider: Firebase Google Auth Error: $e');
      _errorMessage =
          e.message ??
          'Firebase could not complete Google Sign-In (${e.code}).';
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
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );

        if (isAnonymous) {
          try {
            await _user?.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use') {
              // Account exists, switch to it
              await _auth.signInWithCredential(credential);
            } else {
              rethrow;
            }
          }
        } else {
          await _auth.signInWithCredential(credential);
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
          await _user?.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Account exists, so sign in (switch users)
            await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
        }
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
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
    _errorMessage = null; // Clear previous errors
    if (isBusy) return;
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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
            await _user?.linkWithCredential(credential);
          } else {
            await _auth.signInWithCredential(credential);
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
        await _user?.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
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
    try {
      // Run social sign-outs in background to avoid blocking the UI
      _googleSignIn.signOut().catchError((_) => null);
      FacebookAuth.instance.logOut().catchError((_) => null);

      // Sign out from Firebase
      await _auth.signOut();

      // Status will be updated via _onAuthStateChanged listener
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    }
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
        await _user!.delete();
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
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _status = AuthStatus.unauthenticated; // Or stay in initial/error
      _uiState = const AsyncUiState.success();
      notifyListeners();
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

  /// Update display name
  Future<void> updateDisplayName(String name) async {
    _status = AuthStatus.loading;
    _uiState = const AsyncUiState.loading();
    notifyListeners();

    try {
      if (_user != null) {
        await _user!.updateDisplayName(name);
        await _user!.reload();
        _user = _auth.currentUser;
        _status = AuthStatus.authenticated;
        _uiState = const AsyncUiState.success();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _uiState = AsyncUiState.error(_errorMessage);
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _syncStatusFromUser();
    }
    notifyListeners();
  }
}
