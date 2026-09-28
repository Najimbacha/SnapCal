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

    test('a server asking for minutes is not waited on', () async {
      var attempts = 0;
      final watch = Stopwatch()..start();
      final result = await SafeAsync.run<int>(
        label: 'rate limited',
        retryPolicy: RetryPolicy.network,
        operation: () async {
          attempts++;
          throw const AppFailure(
            type: AppFailureType.quotaExceeded,
            message: 'Too many',
            statusCode: 429,
            retryAfter: Duration(minutes: 15),
          );
        },
      );
      expect(result.failure?.statusCode, 429);
      expect(attempts, 1);
      expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('a scan is not sent twice after a timeout or a 429', () async {
      for (final failure in const [
        AppFailure(type: AppFailureType.timeout, message: 'slow'),
        AppFailure(
          type: AppFailureType.quotaExceeded,
          message: 'busy',
          statusCode: 429,
        ),
      ]) {
        var attempts = 0;
        final result = await SafeAsync.run<int>(
          label: 'scan',
          retryPolicy: RetryPolicy.scan,
          operation: () async {
            attempts++;
            throw failure;
          },
        );
        expect(result.isFailure, isTrue);
        expect(attempts, 1, reason: failure.type.name);
      }
    });

    test('a scan whose AI failed on the server is tried once more', () async {
      var attempts = 0;
      final result = await SafeAsync.run<int>(
        label: 'scan',
        retryPolicy: RetryPolicy.scan,
        operation: () async {
          attempts++;
          if (attempts == 1) {
            throw const AppFailure(
              type: AppFailureType.server,
              message: 'AI failed',
              statusCode: 502,
            );
          }
          return 3;
        },
      );
      expect(result.requireData, 3);
      expect(attempts, 2);
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

    test(
      'fireAndReport reports background failures without throwing',
      () async {
        AppFailure? reported;

        await SafeAsync.fireAndReport(
          label: 'background failure',
          operation: () async => throw TimeoutException('slow background work'),
          timeout: const Duration(milliseconds: 5),
          onFailure: (failure) => reported = failure,
        );

        expect(reported, isNotNull);
        expect(reported?.type, AppFailureType.timeout);
      },
    );
  });
}
