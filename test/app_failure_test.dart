import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/resilience/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('maps timeout errors', () {
      final failure = AppFailure.fromError(TimeoutException('slow'));

      expect(failure.type, AppFailureType.timeout);
      expect(failure.isRetryable, isTrue);
    });

    test('maps Dio 403 to permission denied', () {
      final failure = AppFailure.fromError(
        DioException(
          requestOptions: RequestOptions(path: '/protected'),
          response: Response(
            requestOptions: RequestOptions(path: '/protected'),
            statusCode: 403,
          ),
        ),
      );

      expect(failure.type, AppFailureType.permissionDenied);
      expect(failure.isRetryable, isFalse);
    });

    test('maps Firebase quota errors', () {
      final failure = AppFailure.fromError(
        FirebaseException(plugin: 'cloud_firestore', code: 'resource-exhausted'),
      );

      expect(failure.type, AppFailureType.quotaExceeded);
      expect(failure.isRetryable, isTrue);
    });

    test('maps Platform cancellation', () {
      final failure = AppFailure.fromError(
        PlatformException(code: 'operation_cancelled'),
      );

      expect(failure.type, AppFailureType.cancelled);
      expect(failure.isRetryable, isFalse);
    });
  });
}
