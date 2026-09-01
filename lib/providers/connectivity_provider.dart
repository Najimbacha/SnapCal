import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Current connectivity, seeded with the actual state.
///
/// `onConnectivityChanged` only emits when connectivity *changes*, so on a
/// cold start — and on every hot reload, which rebuilds the provider — the
/// stream sat empty until the OS happened to report a change. Anything reading
/// it saw "no value" and rendered the offline banner over a perfectly online
/// app. Seeding with `checkConnectivity()` gives the first frame the truth.
@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(ConnectivityRef ref) async* {
  final connectivity = Connectivity();
  try {
    yield await connectivity.checkConnectivity();
  } catch (_) {
    // Platform channel not ready: say nothing rather than claim offline.
  }
  yield* connectivity.onConnectivityChanged;
}
