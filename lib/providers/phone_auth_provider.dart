import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_auth_provider.g.dart';

@Riverpod(keepAlive: true)
class VerificationId extends _$VerificationId {
  @override
  String? build() => null;
}

@Riverpod(keepAlive: true)
class PhoneAuth extends _$PhoneAuth {
  @override
  FutureOr<void> build() {}

  Future<void> verifyPhone(String number) async {
    state = const AsyncLoading();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      verificationCompleted: (cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
        state = const AsyncData(null);
      },
      verificationFailed: (e) => state = AsyncError(e, StackTrace.current),
      codeSent: (verificationId, _) {
        ref.read(verificationIdProvider.notifier).state = verificationId;
        state = const AsyncData(null);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signInWithOTP(String otp) async {
    final verificationId = ref.read(verificationIdProvider);
    if (verificationId == null) return;
    state = const AsyncLoading();
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    state = await AsyncValue.guard(() =>
      FirebaseAuth.instance.signInWithCredential(credential).then((_) {}));
  }
}
