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

  test(
    'a warm host does not suppress warming a different backend URL',
    () async {
      var backend = 'https://old.test';
      final probed = <String>[];
      final service = BackendWarmupService(
        backendUrl: () => backend,
        probe: (url) async => probed.add(url),
      );

      await service.prewarm();
      backend = 'https://new.test';
      await service.prewarm();
      await service.prewarm();

      expect(probed, ['https://old.test/startup', 'https://new.test/startup']);
    },
  );

  test(
    'an in-flight probe is not shared with a different backend URL',
    () async {
      var backend = 'https://old.test';
      final pending = Completer<void>();
      final probed = <String>[];
      final service = BackendWarmupService(
        backendUrl: () => backend,
        probe: (url) {
          probed.add(url);
          return url.startsWith('https://old.test')
              ? pending.future
              : Future.value();
        },
      );

      final slow = service.prewarm();
      backend = 'https://new.test';
      await service.prewarm();

      expect(probed, ['https://old.test/startup', 'https://new.test/startup']);
      pending.complete();
      await slow;
    },
  );

  test('equivalent URL spellings share one warmup', () async {
    var backend = 'https://example.test/';
    var calls = 0;
    final service = BackendWarmupService(
      backendUrl: () => backend,
      probe: (_) async => calls++,
    );

    await service.prewarm();
    backend = 'https://example.test';
    await service.prewarm();

    expect(calls, 1);
  });

  for (final (base, expected) in [
    ('https://example.test', 'https://example.test/startup'),
    ('https://example.test/', 'https://example.test/startup'),
    ('https://example.test/api', 'https://example.test/api/startup'),
    ('https://example.test/api/', 'https://example.test/api/startup'),
  ]) {
    test('warmup probes the startup endpoint under $base', () async {
      String? requestedUrl;
      final service = BackendWarmupService(
        backendUrl: () => base,
        probe: (url) async => requestedUrl = url,
      );

      await service.prewarm();

      expect(requestedUrl, expected);
    });
  }

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
