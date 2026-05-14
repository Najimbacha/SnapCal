import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/state/async_ui_state.dart';
import 'package:snapcal/core/utils/async_guard.dart';

void main() {
  group('AsyncUiState', () {
    test('distinguishes blocking load from background refresh', () {
      const loading = AsyncUiState.loading();
      const refreshing = AsyncUiState.refreshing();

      expect(loading.isBusy, isTrue);
      expect(loading.isBlocking, isTrue);
      expect(refreshing.isBusy, isTrue);
      expect(refreshing.isBlocking, isFalse);
    });

    test('tracks error state without implying busy work', () {
      const state = AsyncUiState.error('Failed');

      expect(state.hasError, isTrue);
      expect(state.isBusy, isFalse);
      expect(state.message, 'Failed');
    });
  });

  group('runSilently', () {
    test('returns null instead of throwing on failure', () async {
      final result = await runSilently<int>(
        'test failure',
        () async => throw StateError('boom'),
      );

      expect(result, isNull);
    });

    test('returns null on timeout', () async {
      final result = await runSilently<int>(
        'test timeout',
        () => Future.delayed(const Duration(seconds: 1), () => 1),
        timeout: const Duration(milliseconds: 10),
      );

      expect(result, isNull);
    });
  });
}
