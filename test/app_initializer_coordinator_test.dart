import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/services/app_initializer.dart';

void main() {
  test(
    'overlapping startup retries share one initialization attempt',
    () async {
      final coordinator = AppInitializationCoordinator();
      final pending = Completer<void>();
      var calls = 0;

      Future<void> initialize() {
        calls++;
        return pending.future;
      }

      final first = coordinator.run(initialize);
      final retry = coordinator.run(initialize);
      expect(calls, 1);

      pending.complete();
      await Future.wait([first, retry]);
      await coordinator.run(initialize);
      expect(calls, 1, reason: 'successful core startup must stay initialized');
    },
  );

  test('a failed startup can be retried', () async {
    final coordinator = AppInitializationCoordinator();
    var calls = 0;

    await expectLater(
      coordinator.run(() async {
        calls++;
        throw StateError('first launch failed');
      }),
      throwsStateError,
    );

    await coordinator.run(() async => calls++);
    expect(calls, 2);
  });
}
