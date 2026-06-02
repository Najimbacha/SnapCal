import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_failure.dart';
import 'app_result.dart';
import 'operation_gate.dart';
import 'retry_policy.dart';

class SafeAsync {
  SafeAsync._();

  static final OperationGate globalGate = OperationGate();

  static Future<AppResult<T>> run<T>({
    required String label,
    required Future<T> Function() operation,
    Duration? timeout,
    RetryPolicy retryPolicy = RetryPolicy.none,
    T? fallbackData,
    bool Function()? isActive,
    String? operationKey,
    OperationGate? gate,
  }) async {
    Future<AppResult<T>> guardedRun() async {
      var attempt = 0;
      while (true) {
        attempt++;
        if (isActive != null && !isActive()) {
          return AppResult.failure(
            const AppFailure(
              type: AppFailureType.cancelled,
              message: 'Operation was cancelled.',
            ),
            fallbackData: fallbackData,
          );
        }

        try {
          final Future<T> future = operation();
          final data =
              await (timeout == null ? future : future.timeout(timeout));
          if (isActive != null && !isActive()) {
            return AppResult.failure(
              const AppFailure(
                type: AppFailureType.cancelled,
                message: 'Operation was cancelled.',
              ),
              fallbackData: fallbackData,
            );
          }
          return AppResult.success(data);
        } catch (error, stackTrace) {
          final failure = AppFailure.fromError(error, stackTrace);
          debugPrint('⚠️ $label failed on attempt $attempt: $failure');

          if (!retryPolicy.shouldRetry(failure, attempt)) {
            return AppResult.failure(failure, fallbackData: fallbackData);
          }

          await Future.delayed(
            failure.retryAfter ?? retryPolicy.delayForAttempt(attempt),
          );
        }
      }
    }

    final key = operationKey;
    if (key == null) return guardedRun();

    final selectedGate = gate ?? globalGate;
    final result = await selectedGate.runExclusive(key, guardedRun);
    return result ??
        AppResult.failure(
          const AppFailure(
            type: AppFailureType.cancelled,
            message: 'Operation is already running.',
          ),
          fallbackData: fallbackData,
        );
  }

  static Future<T> runOrThrow<T>({
    required String label,
    required Future<T> Function() operation,
    Duration? timeout,
    RetryPolicy retryPolicy = RetryPolicy.none,
    bool Function()? isActive,
    String? operationKey,
    OperationGate? gate,
  }) async {
    final result = await run<T>(
      label: label,
      operation: operation,
      timeout: timeout,
      retryPolicy: retryPolicy,
      isActive: isActive,
      operationKey: operationKey,
      gate: gate,
    );
    if (result.isSuccess) return result.requireData;
    throw result.failure!;
  }

  static Future<void> fireAndReport({
    required String label,
    required Future<void> Function() operation,
    Duration? timeout,
    RetryPolicy retryPolicy = RetryPolicy.none,
    bool Function()? isActive,
    void Function(AppFailure failure)? onFailure,
  }) async {
    final result = await run<void>(
      label: label,
      operation: operation,
      timeout: timeout,
      retryPolicy: retryPolicy,
      isActive: isActive,
    );
    if (result.isFailure) {
      onFailure?.call(result.failure!);
    }
  }
}
