import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class ResilienceUtils {
  ResilienceUtils._();

  /// Execute an async operation with a strict timeout and automatic retry logic (with exponential backoff and jitter)
  static Future<T> runWithRetryAndTimeout<T>({
    required Future<T> Function() operation,
    Duration timeoutDuration = const Duration(seconds: 15),
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(Exception)? retryIf,
  }) async {
    int attempts = 0;

    while (true) {
      attempts++;
      try {
        // Enforce strict timeout
        return await operation().timeout(
          timeoutDuration,
          onTimeout: () {
            throw TimeoutException(
              'Request timed out after ${timeoutDuration.inSeconds}s',
            );
          },
        );
      } on Exception catch (e) {
        final isLastAttempt = attempts >= maxAttempts;
        final shouldRetry = retryIf == null || retryIf(e);

        if (isLastAttempt || !shouldRetry) {
          debugPrint(
            '❌ ResilienceUtils: Attempts exhausted or retry denied. Error: $e',
          );
          rethrow;
        }

        // Exponential backoff delay: delay = initialDelay * 2^(attempt - 1) + random jitter
        final delayMs =
            (initialDelay.inMilliseconds * pow(2, attempts - 1)).toInt();
        final jitter = Random().nextInt(
          100,
        ); // 0-100ms jitter to prevent sync collisions
        final totalDelay = Duration(milliseconds: delayMs + jitter);

        debugPrint(
          '⚠️ ResilienceUtils: Attempt $attempts failed ($e). Retrying in ${totalDelay.inMilliseconds}ms...',
        );
        await Future.delayed(totalDelay);
      }
    }
  }
}
