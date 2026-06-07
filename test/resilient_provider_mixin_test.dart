import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/resilience/app_failure.dart';
import 'package:snapcal/core/resilience/resilient_provider_mixin.dart';
import 'package:snapcal/core/resilience/retry_policy.dart';
import 'package:snapcal/core/state/async_ui_state.dart';

class _HarnessProvider extends ChangeNotifier with ResilientProviderMixin {
  AsyncUiState state = const AsyncUiState.idle();

  Future<void> runList({
    required Future<List<int>> Function() operation,
    List<int>? fallbackData,
    String? operationKey,
    Duration? timeout,
    RetryPolicy retryPolicy = RetryPolicy.none,
  }) async {
    await guardOperation<List<int>>(
      label: 'list operation',
      operation: operation,
      operationKey: operationKey,
      timeout: timeout,
      retryPolicy: retryPolicy,
      fallbackData: fallbackData,
      emptyMessage: 'No rows',
      setState: (next) => state = next,
      isEmpty: (data) => data.isEmpty,
    );
  }
}

void main() {
  group('ResilientProviderMixin.guardOperation', () {
    test('maps successful empty data to empty state', () async {
      final provider = _HarnessProvider();

      await provider.runList(operation: () async => <int>[]);

      expect(provider.state.phase, AsyncUiPhase.empty);
      expect(provider.state.message, 'No rows');
    });

    test('maps offline failure with fallback to partial state', () async {
      final provider = _HarnessProvider();

      await provider.runList(
        fallbackData: const [1, 2],
        operation:
            () async =>
                throw const AppFailure(
                  type: AppFailureType.offline,
                  message: 'Offline',
                ),
      );

      expect(provider.state.phase, AsyncUiPhase.partial);
      expect(provider.state.isStale, isTrue);
      expect(provider.state.failure?.type, AppFailureType.offline);
    });

    test(
      'duplicate operation does not cancel the in-flight operation',
      () async {
        final provider = _HarnessProvider();
        final completer = Completer<List<int>>();

        final first = provider.runList(
          operationKey: 'refresh',
          operation: () => completer.future,
        );
        await Future<void>.delayed(Duration.zero);

        await provider.runList(
          operationKey: 'refresh',
          operation: () async => <int>[99],
        );
        completer.complete(<int>[1]);
        await first;

        expect(provider.state.phase, AsyncUiPhase.success);
      },
    );

    test('disposed provider cancels in-flight operation safely', () async {
      final provider = _HarnessProvider();
      final completer = Completer<List<int>>();

      final pending = provider.runList(operation: () => completer.future);
      await Future<void>.delayed(Duration.zero);
      provider.dispose();
      completer.complete(<int>[1]);
      await pending;

      expect(provider.isProviderActive, isFalse);
    });
  });
}
