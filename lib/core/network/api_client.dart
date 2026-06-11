import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../resilience/timeout_policy.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        extra: {'skipAppCheck': true},
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-Request-ID'] ??= const Uuid().v4();
          if (options.extra['skipAppCheck'] != true) {
            try {
              final appCheckToken = await FirebaseAppCheck.instance
                  .getToken()
                  .timeout(TimeoutPolicy.auth);
              if (appCheckToken != null && appCheckToken.isNotEmpty) {
                options.headers['X-Firebase-AppCheck'] ??= appCheckToken;
              }
            } catch (_) {
              // The backend can enforce App Check in production. In debug or
              // during startup, continue so user-friendly backend errors can
              // explain the failure instead of blocking locally.
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
