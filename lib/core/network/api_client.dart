import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../resilience/timeout_policy.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = _createDio();

  static String? _cachedAppCheckToken;
  static DateTime? _lastAppCheckAttempt;

  /// App Check tokens are cached by the SDK, but every failed mint attempt
  /// hits Firebase's exchange endpoint, and a burst of startup requests can
  /// trip its rate limiter ("Too many attempts"), which then masks a correct
  /// registration. Cooldown both success and failure paths to one attempt per
  /// window so retry storms cannot cause or prolong that throttle.
  static const _appCheckCooldown = Duration(seconds: 60);

  /// Last App Check minting error, exposed for diagnostics screens and tests.
  ///
  /// A null token makes the interceptor send the request without the
  /// `X-Firebase-AppCheck` header, and the backend answers 401
  /// "App Check required." — an error that otherwise looks like an auth
  /// problem and leaves no trace of its real cause. Keep the cause visible
  /// here and in Crashlytics.
  static String? lastAppCheckError;
  static int _appCheckFailureCount = 0;
  static String? _reportedAppCheckError;

  static Future<String?> _appCheckToken({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final last = _lastAppCheckAttempt;
    if (!forceRefresh &&
        last != null &&
        now.difference(last) < _appCheckCooldown) {
      return _cachedAppCheckToken;
    }
    _lastAppCheckAttempt = now;
    try {
      final token = await FirebaseAppCheck.instance
          .getToken(forceRefresh)
          .timeout(TimeoutPolicy.auth);
      if (token != null && token.isNotEmpty) {
        if (_appCheckFailureCount > 0) {
          debugPrint(
            '✅ ApiClient: App Check recovered after '
            '$_appCheckFailureCount failure(s)',
          );
        }
        _cachedAppCheckToken = token;
        _appCheckFailureCount = 0;
        lastAppCheckError = null;
        _reportedAppCheckError = null;
      }
      return token;
    } catch (error, stackTrace) {
      _appCheckFailureCount += 1;
      lastAppCheckError = error.toString();
      debugPrint(
        '⚠️ ApiClient: App Check token unavailable '
        '(failure #$_appCheckFailureCount) — requests will be rejected '
        'with 401 "App Check required.": $error',
      );
      _reportAppCheckFailure(error, stackTrace);
      return null;
    }
  }

  /// Reports one Crashlytics non-fatal per distinct App Check error.
  ///
  /// Deduplicated by message so a device stuck in a failure loop produces one
  /// report per cause, not one per request. Reset on the next success.
  static void _reportAppCheckFailure(Object error, StackTrace stackTrace) {
    final signature = error.toString();
    if (signature == _reportedAppCheckError) return;
    _reportedAppCheckError = signature;
    unawaited(
      FirebaseCrashlytics.instance
          .recordError(
            error,
            stackTrace,
            reason:
                'App Check token unavailable — backend will reject requests '
                'with 401 "App Check required."',
            information: [
              DiagnosticsNode.message(
                'consecutiveFailures=$_appCheckFailureCount',
              ),
            ],
            fatal: false,
          )
          .catchError((_) {}),
    );
  }

  static bool _isAppCheckRejection(DioException error) {
    if (error.response?.statusCode != 401) return false;
    return '${error.response?.data}'.contains('App Check');
  }

  static Dio _createDio() {
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        // App Check tokens are attached to every request by default. The
        // production backend fails closed on App Check, so skipping locally
        // would turn every /api call into a 401. Individual calls may opt out
        // via options.extra['skipAppCheck'] = true.
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-Request-ID'] ??= const Uuid().v4();
          if (options.extra['skipAppCheck'] != true) {
            final appCheckToken = await _appCheckToken();
            if (appCheckToken != null && appCheckToken.isNotEmpty) {
              options.headers['X-Firebase-AppCheck'] ??= appCheckToken;
            }
          }
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && options.extra['skipAuth'] != true) {
            final token = await user.getIdToken().timeout(TimeoutPolicy.auth);
            options.headers['Authorization'] ??= 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;

          // A 401 that names App Check is not an auth problem: refreshing the
          // ID token cannot fix it, and doing so doubles the load while
          // hiding the cause. Force one fresh App Check mint instead.
          if (_isAppCheckRejection(error) &&
              error.requestOptions.extra['skipAppCheck'] != true &&
              error.requestOptions.extra['_retriedAppCheck'] != true) {
            debugPrint(
              '⚠️ ApiClient: backend rejected App Check — retrying once with '
              'a freshly minted token',
            );
            final fresh = await _appCheckToken(forceRefresh: true);
            if (fresh != null && fresh.isNotEmpty) {
              final retryOptions = error.requestOptions;
              retryOptions.extra['_retriedAppCheck'] = true;
              retryOptions.headers['X-Firebase-AppCheck'] = fresh;
              try {
                final response = await client.fetch<dynamic>(retryOptions);
                handler.resolve(response);
                return;
              } catch (_) {
                // Fall through: surface the original failure below.
              }
            }
            handler.next(error);
            return;
          }

          final user = FirebaseAuth.instance.currentUser;
          final canRetryAuth =
              user != null &&
              error.requestOptions.extra['skipAuth'] != true &&
              error.requestOptions.extra['_retriedAuth'] != true &&
              (status == 401 || status == 403);

          if (!canRetryAuth) {
            handler.next(error);
            return;
          }

          try {
            final token = await user
                .getIdToken(true)
                .timeout(TimeoutPolicy.auth);
            final retryOptions = error.requestOptions;
            retryOptions.extra['_retriedAuth'] = true;
            retryOptions.headers['Authorization'] = 'Bearer $token';

            final response = await client.fetch<dynamic>(retryOptions);
            handler.resolve(response);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );

    return client;
  }
}
