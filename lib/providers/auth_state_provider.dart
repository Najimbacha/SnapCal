import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<User?> authState(AuthStateRef ref) {
  return FirebaseAuth.instance.userChanges();
}

@Riverpod(keepAlive: true)
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
}

@Riverpod(keepAlive: true)
bool isAnonymous(IsAnonymousRef ref) {
  return ref.watch(authStateProvider).valueOrNull?.isAnonymous ?? true;
}
