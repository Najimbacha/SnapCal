import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Getters
  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  /// Sign in anonymously (Lazy Auth)
  Future<void> signInAnonymously() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _auth.signInAnonymously();
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  /// Sign in with Google and link if anonymous
  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (isAnonymous) {
        try {
          // Link anonymous account to Google
          await _user?.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Account exists, just sign in (switch to that account)
            await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  /// Sign in with Facebook and link if anonymous
  Future<void> signInWithFacebook() async {
    _status = AuthStatus.loading;
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
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<void> registerWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
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
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
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
    _status = AuthStatus.loading;
    notifyListeners();

    if (isMock) {
      // Simulation for WhatsApp/Development
      await Future.delayed(const Duration(seconds: 2));
      _status = AuthStatus.authenticated;
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
          onVerificationFailed(e.message ?? 'Verification failed');
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _status = AuthStatus.authenticated;
          onCodeSent(verificationId);
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  /// Sign in with OTP (Step 2 of Phone Auth)
  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    _status = AuthStatus.loading;
    notifyListeners();

    if (verificationId == "mock_verification_id") {
      // Mock validation: Allow logic if code is 123456
      if (smsCode == "123456") {
        await Future.delayed(const Duration(seconds: 1));
        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        _errorMessage = "Invalid mock code. Try 123456";
        _status = AuthStatus.error;
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
      notifyListeners();
      throw e;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      throw e;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _status = AuthStatus.unauthenticated; // Or stay in initial/error
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
