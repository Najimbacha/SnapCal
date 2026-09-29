import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/services/backend_warmup_service.dart';

void main() {
  test('concurrent warmups share one backend probe', () async {
    final pending = Completer<void>();
    var calls = 0;
    final service = BackendWarmupService(
      backendUrl: () => 'https://example.test',
      probe: (_) {
        calls++;
        return pending.future;
      },
    );

    final first = service.prewarm();
    final second = service.prewarm();

    expect(calls, 1);
    pending.complete();
    await Future.wait([first, second]);
  });

  test('a recent successful warmup is reused', () async {
    var calls = 0;
    final service = BackendWarmupService(
      backendUrl: () => 'https://example.test',
      probe: (_) async => calls++,
    );

    await service.prewarm();
    await service.prewarm();

    expect(calls, 1);
  });

  test('failed warmup is silent and can be retried', () async {
    var calls = 0;
    final service = BackendWarmupService(
      backendUrl: () => 'https://example.test',
      probe: (_) async {
        calls++;
        if (calls == 1) throw TimeoutException('offline');
      },
    );

    await expectLater(service.prewarm(), completes);
    await expectLater(service.prewarm(), completes);

    expect(calls, 2);
  });
}
