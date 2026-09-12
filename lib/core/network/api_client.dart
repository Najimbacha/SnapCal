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

  /// When a failing mint may be tried again.
  ///
  /// The cooldown above did not apply to a forced refresh, and every rejected
  /// request forced one: a device whose App Check cannot be minted produced
  /// twenty-odd attempts a minute, each one a Crashlytics report, until
  /// Firebase itself answered "Too many attempts" -- which then hid the real
  /// cause and delayed recovery.
  static DateTime? _appCheckRetryAfter;

  /// One second after the first failure, then two, four, and so on to a
  /// minute. Attempts inside the wait use the cached token, or none, without
  /// touching Firebase.
  @visibleForTesting
  static Duration appCheckBackoffFor(int consecutiveFailures) {
    if (consecutiveFailures <= 0) return Duration.zero;
    final seconds = 1 << (consecutiveFailures - 1).clamp(0, 6);
    return Duration(seconds: seconds > 60 ? 60 : seconds);
  }

  static bool get _appCheckBackingOff {
    final until = _appCheckRetryAfter;
    return until != null && DateTime.now().isBefore(until);
  }

  static Future<String?> _appCheckToken({bool forceRefresh = false}) async {
    final now = DateTime.now();
    // A forced refresh does not get to jump the backoff: it was the forced
    // path, one per rejected request, that made the storm.
    final retryAfter = _appCheckRetryAfter;
    if (retryAfter != null && now.isBefore(retryAfter)) {
      return _cachedAppCheckToken;
    }
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
        _appCheckRetryAfter = null;
        lastAppCheckError = null;
      }
      return token;
    } catch (error, stackTrace) {
      _appCheckFailureCount += 1;
      _appCheckRetryAfter = now.add(appCheckBackoffFor(_appCheckFailureCount));
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

  /// Reports one Crashlytics non-fatal per run of failures.
  ///
  /// This deduplicated by message, and the messages alternate -- "App
  /// attestation failed" from Firebase, then its own "Too many attempts" --
  /// so each new wording was reported again and the dashboard filled with one
  /// fault. One report per episode; the next success resets it.
  static void _reportAppCheckFailure(Object error, StackTrace stackTrace) {
    if (_appCheckFailureCount != 1) return;
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
          // Nothing to gain from a fresh mint while minting is backing off,
          // and the attempt logged a line per request.
          if (_isAppCheckRejection(error) &&
              !_appCheckBackingOff &&
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
