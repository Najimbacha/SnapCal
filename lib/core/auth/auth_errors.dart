import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../l10n/generated/app_localizations.dart';

/// What went wrong with a sign-in, in terms a person can act on.
///
/// The three sign-in screens each kept their own English copy of this, and
/// none of them ever ran: the sign-in methods swallowed every error.
enum AuthProblem {
  cancelled,
  network,
  wrongCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  otherProvider,
  disabled,
  unavailable,
  unknown,
}

/// Thrown when the user backs out of a sign-in themselves. Not an error, so
/// nothing is shown for it.
class AuthCancelled implements Exception {
  const AuthCancelled();

  @override
  String toString() => 'AuthCancelled';
}

AuthProblem authProblemOf(Object error) {
  if (error is AuthCancelled) return AuthProblem.cancelled;
  if (error is GoogleSignInException) {
    return error.code == GoogleSignInExceptionCode.canceled
        ? AuthProblem.cancelled
        : AuthProblem.unknown;
  }
  if (error is TimeoutException || error is SocketException) {
    return AuthProblem.network;
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'network-request-failed':
        return AuthProblem.network;
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AuthProblem.wrongCredentials;
      case 'email-already-in-use':
        return AuthProblem.emailInUse;
      case 'weak-password':
        return AuthProblem.weakPassword;
      case 'invalid-email':
      case 'missing-email':
        return AuthProblem.invalidEmail;
      case 'too-many-requests':
        return AuthProblem.tooManyRequests;
      case 'account-exists-with-different-credential':
        return AuthProblem.otherProvider;
      case 'user-disabled':
        return AuthProblem.disabled;
      case 'google-auth-unavailable':
      case 'operation-not-allowed':
        return AuthProblem.unavailable;
    }
  }
  return AuthProblem.unknown;
}

/// The message to show for [error], or null when there is nothing to say --
/// a sign-in the user cancelled is not a failure.
String? authErrorMessage(AppLocalizations l10n, Object error) {
  return switch (authProblemOf(error)) {
    AuthProblem.cancelled => null,
    AuthProblem.network => l10n.auth_err_network,
    AuthProblem.wrongCredentials => l10n.auth_err_wrong_credentials,
    AuthProblem.emailInUse => l10n.auth_err_email_in_use,
    AuthProblem.weakPassword => l10n.auth_err_weak_password,
    AuthProblem.invalidEmail => l10n.auth_err_invalid_email,
    AuthProblem.tooManyRequests => l10n.auth_err_too_many,
    AuthProblem.otherProvider => l10n.auth_err_other_provider,
    AuthProblem.disabled => l10n.auth_err_disabled,
    AuthProblem.unavailable => l10n.auth_err_unavailable,
    AuthProblem.unknown => l10n.auth_err_unknown,
  };
}

/// Something@something.tld with no spaces: enough to catch a typo before
/// asking the server, which is the real judge.
bool looksLikeEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

String? validateEmail(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.auth_email_required;
  if (!looksLikeEmail(email)) return l10n.auth_err_invalid_email;
  return null;
}

/// Eight characters is the bar for a new password. Signing in asks only for
/// the password the account already has: Firebase accepts six, and a six- or
/// seven-character password was refused here before it reached the server.
String? validatePassword(
  AppLocalizations l10n,
  String? value, {
  required bool isSignUp,
}) {
  if (value == null || value.isEmpty) return l10n.auth_password_required;
  if (isSignUp && value.length < 8) return l10n.auth_password_too_short;
  return null;
}
