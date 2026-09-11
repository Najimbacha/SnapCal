import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:snapcal/core/auth/auth_errors.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));

  FirebaseAuthException fb(String code) => FirebaseAuthException(code: code);

  test('each Firebase failure gets a message a person can act on', () {
    expect(authProblemOf(fb('wrong-password')), AuthProblem.wrongCredentials);
    expect(
      authProblemOf(fb('invalid-credential')),
      AuthProblem.wrongCredentials,
    );
    expect(authProblemOf(fb('user-not-found')), AuthProblem.wrongCredentials);
    expect(authProblemOf(fb('email-already-in-use')), AuthProblem.emailInUse);
    expect(authProblemOf(fb('weak-password')), AuthProblem.weakPassword);
    expect(authProblemOf(fb('invalid-email')), AuthProblem.invalidEmail);
    expect(authProblemOf(fb('too-many-requests')), AuthProblem.tooManyRequests);
    expect(authProblemOf(fb('network-request-failed')), AuthProblem.network);
    expect(
      authProblemOf(fb('account-exists-with-different-credential')),
      AuthProblem.otherProvider,
    );
    expect(authProblemOf(TimeoutException('slow')), AuthProblem.network);
    expect(authProblemOf(Exception('odd')), AuthProblem.unknown);
  });

  test('backing out of a sign-in shows nothing', () {
    expect(authErrorMessage(en, const AuthCancelled()), isNull);
    expect(
      authErrorMessage(
        en,
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ),
      isNull,
    );
  });

  test('messages are in the user\'s language', () {
    expect(
      authErrorMessage(en, fb('wrong-password')),
      en.auth_err_wrong_credentials,
    );
    expect(
      authErrorMessage(fr, fb('wrong-password')),
      fr.auth_err_wrong_credentials,
    );
    expect(fr.auth_err_wrong_credentials, isNot(en.auth_err_wrong_credentials));
  });

  test('a short existing password may sign in; a new one must be 8+', () {
    expect(validatePassword(en, 'abc123', isSignUp: false), isNull);
    expect(
      validatePassword(en, 'abc123', isSignUp: true),
      en.auth_password_too_short,
    );
    expect(validatePassword(en, 'abcd1234', isSignUp: true), isNull);
    expect(
      validatePassword(en, '', isSignUp: false),
      en.auth_password_required,
    );
  });

  test('the email is checked before it is sent', () {
    expect(validateEmail(en, ''), en.auth_email_required);
    expect(validateEmail(en, 'name@'), en.auth_err_invalid_email);
    expect(
      validateEmail(en, 'name example@mail.com'),
      en.auth_err_invalid_email,
    );
    expect(validateEmail(en, ' name@example.com '), isNull);
  });
}
