import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/core/resilience/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('maps timeout errors', () {
      final failure = AppFailure.fromError(TimeoutException('slow'));

      expect(failure.type, AppFailureType.timeout);
      expect(failure.isRetryable, isTrue);
    });

    test('a Pro daily fair-use 429 is a daily limit that is not retried', () {
      final failure = AppFailure.fromError(
        DioException(
          requestOptions: RequestOptions(path: '/api/ai/text'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/ai/text'),
            statusCode: 429,
            data: {
              'error':
                  'Daily fair-use limit reached. Please try again tomorrow.',
            },
          ),
        ),
      );

      expect(failure.type, AppFailureType.quotaExceeded);
      expect(failure.statusCode, 429);
      expect(failure.isDailyLimit, isTrue);
      expect(failure.isRetryable, isFalse);
    });

    test(
      'an ordinary rate-limit 429 is still a short wait that is retried',
      () {
        final failure = AppFailure.fromError(
          DioException(
            requestOptions: RequestOptions(path: '/v1/scan'),
            response: Response(
              requestOptions: RequestOptions(path: '/v1/scan'),
              statusCode: 429,
              data: {'error': 'Too many requests.'},
            ),
          ),
        );

        expect(failure.isDailyLimit, isFalse);
        expect(failure.isRetryable, isTrue);
      },
    );

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
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'resource-exhausted',
        ),
      );

      expect(failure.type, AppFailureType.quotaExceeded);
      expect(failure.isRetryable, isTrue);
    });

    group('every server answer becomes a failure the app can act on', () {
      DioException status(int code, {Object? body, String? retryAfter}) =>
          DioException(
            requestOptions: RequestOptions(path: '/v1/scan'),
            response: Response(
              requestOptions: RequestOptions(path: '/v1/scan'),
              statusCode: code,
              data: body,
              headers: Headers.fromMap({
                if (retryAfter != null) 'retry-after': [retryAfter],
              }),
            ),
          );

      // (status, type, retried)
      const cases = [
        (400, AppFailureType.validation, false),
        (401, AppFailureType.unauthorized, false),
        (404, AppFailureType.notFound, false),
        (408, AppFailureType.timeout, true),
        (409, AppFailureType.conflict, false),
        (422, AppFailureType.validation, false),
        (500, AppFailureType.server, true),
        (502, AppFailureType.server, true),
        (503, AppFailureType.server, true),
      ];
      for (final (code, type, retried) in cases) {
        test('$code', () {
          final failure = AppFailure.fromError(status(code));
          expect(failure.type, type);
          expect(failure.statusCode, code);
          expect(failure.isRetryable, retried);
          expect(failure.message, isNotEmpty);
        });
      }

      test('402, the free scan limit, goes to the paywall and is never '
          'retried', () {
        final failure = AppFailure.fromError(status(402));
        expect(failure.type, AppFailureType.quotaExceeded);
        expect(failure.isDailyLimit, isFalse);
        expect(failure.isRetryable, isFalse);
      });

      test('a 429 waits as long as the server asks', () {
        expect(
          AppFailure.fromError(status(429, retryAfter: '30')).retryAfter,
          const Duration(seconds: 30),
        );
        expect(
          AppFailure.fromError(status(429, retryAfter: 'soon')).retryAfter,
          isNull,
        );
      });

      test('a daily-limit 429 with the reason as plain text is still the '
          'daily limit', () {
        final failure = AppFailure.fromError(
          status(429, body: 'Daily fair-use limit reached.'),
        );
        expect(failure.isDailyLimit, isTrue);
        expect(failure.isRetryable, isFalse);
      });
    });

    group('no connection and slow connections', () {
      DioException dio(DioExceptionType type) => DioException(
        requestOptions: RequestOptions(path: '/v1/scan'),
        type: type,
      );

      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        test('$type is a timeout that is retried', () {
          final failure = AppFailure.fromError(dio(type));
          expect(failure.type, AppFailureType.timeout);
          expect(failure.isOfflineLike, isTrue);
          expect(failure.isRetryable, isTrue);
        });
      }

      test('no internet is offline and retried', () {
        for (final error in [
          dio(DioExceptionType.connectionError),
          const SocketException('Failed host lookup'),
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ]) {
          final failure = AppFailure.fromError(error);
          expect(failure.type, AppFailureType.offline, reason: '$error');
          expect(failure.isRetryable, isTrue, reason: '$error');
        }
      });

      test('a request the user cancelled is not retried', () {
        final failure = AppFailure.fromError(dio(DioExceptionType.cancel));
        expect(failure.type, AppFailureType.cancelled);
        expect(failure.isRetryable, isFalse);
      });
    });

    test('a reply the app cannot read is a bad response, not retried', () {
      for (final error in <Object>[
        const FormatException('Unexpected character'),
        TypeError(),
      ]) {
        final failure = AppFailure.fromError(error);
        expect(failure.type, AppFailureType.badResponse);
        expect(failure.isRetryable, isFalse);
      }
    });

    test('broken local storage is reported as such', () {
      final failure = AppFailure.fromError(HiveError('box is corrupted'));
      expect(failure.type, AppFailureType.storageCorrupt);
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
