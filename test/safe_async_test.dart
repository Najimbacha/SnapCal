import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/resilience/app_failure.dart';
import 'package:snapcal/core/resilience/operation_gate.dart';
import 'package:snapcal/core/resilience/retry_policy.dart';
import 'package:snapcal/core/resilience/safe_async.dart';

void main() {
  group('SafeAsync', () {
    test('returns success data', () async {
      final result = await SafeAsync.run<int>(
        label: 'success',
        operation: () async => 7,
      );

      expect(result.isSuccess, isTrue);
      expect(result.requireData, 7);
    });

    test('maps timeout to AppFailure', () async {
      final result = await SafeAsync.run<int>(
        label: 'timeout',
        timeout: const Duration(milliseconds: 5),
        operation: () async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 1;
        },
      );

      expect(result.isFailure, isTrue);
      expect(result.failure?.type, AppFailureType.timeout);
    });

    test('retries retryable failures then succeeds', () async {
      var attempts = 0;

      final result = await SafeAsync.run<int>(
        label: 'retry',
        retryPolicy: const RetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 1),
          maxDelay: Duration(milliseconds: 2),
        ),
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw TimeoutException('slow');
          }
          return 9;
        },
      );

      expect(result.isSuccess, isTrue);
      expect(result.requireData, 9);
      expect(attempts, 3);
    });

    test('operation gate prevents duplicate work', () async {
      final gate = OperationGate();
      final first = gate.runExclusive('save', () async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return true;
      });
      final second = await gate.runExclusive('save', () async => false);

      expect(second, isNull);
      expect(await first, isTrue);
    });

    test('fireAndReport reports background failures without throwing', () async {
      AppFailure? reported;

      await SafeAsync.fireAndReport(
        label: 'background failure',
        operation: () async => throw TimeoutException('slow background work'),
        timeout: const Duration(milliseconds: 5),
        onFailure: (failure) => reported = failure,
      );

      expect(reported, isNotNull);
      expect(reported?.type, AppFailureType.timeout);
    });
  });
}
