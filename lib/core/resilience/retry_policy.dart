import 'dart:math';

import 'app_failure.dart';

class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final bool Function(AppFailure failure)? retryIf;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 350),
    this.maxDelay = const Duration(seconds: 4),
    this.retryIf,
  });

  static const none = RetryPolicy(maxAttempts: 1);

  static const network = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 450),
    maxDelay: Duration(seconds: 5),
  );

  static const auth = RetryPolicy(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 2),
  );

  static const ai = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 700),
    maxDelay: Duration(seconds: 6),
  );

  static const cloudSync = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 600),
    maxDelay: Duration(seconds: 6),
  );

  static const upload = RetryPolicy(
    maxAttempts: 4,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 12),
  );

  static const paymentVerification = RetryPolicy(
    maxAttempts: 4,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 8),
  );

  static const localStorage = RetryPolicy(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 250),
    maxDelay: Duration(seconds: 1),
  );

  bool shouldRetry(AppFailure failure, int attempt) {
    if (attempt >= maxAttempts) return false;
    if (retryIf != null) return retryIf!(failure);
    return failure.isRetryable;
  }

  Duration delayForAttempt(int attempt) {
    final baseMs = initialDelay.inMilliseconds * pow(2, attempt - 1);
    final capped = min(baseMs.toInt(), maxDelay.inMilliseconds);
    final jitter = Random().nextInt(160);
    return Duration(milliseconds: capped + jitter);
  }
}
