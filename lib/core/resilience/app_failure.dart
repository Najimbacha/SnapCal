import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

enum AppFailureType {
  offline,
  timeout,
  unauthorized,
  permissionDenied,
  validation,
  conflict,
  notFound,
  quotaExceeded,
  server,
  badResponse,
  cancelled,
  storageCorrupt,
  uploadInterrupted,
  paymentPending,
  storeUnavailable,
  unknown,
}

class AppFailure implements Exception {
  final AppFailureType type;
  final String message;
  final String? code;
  final int? statusCode;
  final Duration? retryAfter;
  final Object? rawError;

  const AppFailure({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.retryAfter,
    this.rawError,
  });

  bool get isRetryable {
    switch (type) {
      case AppFailureType.offline:
      case AppFailureType.timeout:
      case AppFailureType.server:
      case AppFailureType.quotaExceeded:
      case AppFailureType.uploadInterrupted:
      case AppFailureType.storeUnavailable:
        return true;
      case AppFailureType.unauthorized:
      case AppFailureType.permissionDenied:
      case AppFailureType.validation:
      case AppFailureType.conflict:
      case AppFailureType.notFound:
      case AppFailureType.badResponse:
      case AppFailureType.cancelled:
      case AppFailureType.storageCorrupt:
      case AppFailureType.paymentPending:
      case AppFailureType.unknown:
        return false;
    }
  }

  bool get isOfflineLike =>
      type == AppFailureType.offline || type == AppFailureType.timeout;

  AppFailure copyWith({
    AppFailureType? type,
    String? message,
    String? code,
    int? statusCode,
    Duration? retryAfter,
    Object? rawError,
  }) {
    return AppFailure(
      type: type ?? this.type,
      message: message ?? this.message,
      code: code ?? this.code,
      statusCode: statusCode ?? this.statusCode,
      retryAfter: retryAfter ?? this.retryAfter,
      rawError: rawError ?? this.rawError,
    );
  }

  static AppFailure fromError(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) return error;

    if (error is TimeoutException) {
      return AppFailure(
        type: AppFailureType.timeout,
        message: error.message ?? 'The request timed out. Please try again.',
        rawError: error,
      );
    }

    if (error is DioException) {
      return _fromDio(error);
    }

    if (error is FirebaseException) {
      return _fromFirebase(error);
    }

    if (error is PlatformException) {
      return _fromPlatform(error);
    }

    if (error is SocketException) {
      return AppFailure(
        type: AppFailureType.offline,
        message: 'No internet connection. Please try again when online.',
        rawError: error,
      );
    }

    if (error is HiveError ||
        error is StateError && error.message.toLowerCase().contains('hive')) {
      return AppFailure(
        type: AppFailureType.storageCorrupt,
        message: 'Local data is temporarily unavailable.',
        rawError: error,
      );
    }

    if (error is FormatException || error is TypeError) {
      return AppFailure(
        type: AppFailureType.badResponse,
        message: 'The server returned data this app could not read.',
        rawError: error,
      );
    }

    return AppFailure(
      type: AppFailureType.unknown,
      message: error.toString(),
      rawError: error,
    );
  }

  static AppFailure _fromDio(DioException error) {
    final status = error.response?.statusCode;
    final retryAfter = _retryAfter(
      error.response?.headers.value('retry-after'),
    );

    if (error.type == DioExceptionType.cancel) {
      return AppFailure(
        type: AppFailureType.cancelled,
        message: 'The request was cancelled.',
        statusCode: status,
        rawError: error,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AppFailure(
        type: AppFailureType.timeout,
        message: 'The request timed out. Please try again.',
        statusCode: status,
        rawError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AppFailure(
        type: AppFailureType.offline,
        message: 'No internet connection. Please try again when online.',
        statusCode: status,
        rawError: error,
      );
    }

    if (status == 401 || status == 403) {
      return AppFailure(
        type: status == 403
            ? AppFailureType.permissionDenied
            : AppFailureType.unauthorized,
        message: 'Your session needs to be refreshed.',
        statusCode: status,
        rawError: error,
      );
    }

    if (status == 404) {
      return AppFailure(
        type: AppFailureType.notFound,
        message: 'The requested data was not found.',
        statusCode: status,
        rawError: error,
      );
    }

    if (status == 408 || status == 409) {
      return AppFailure(
        type: status == 409 ? AppFailureType.conflict : AppFailureType.timeout,
        message: status == 409
            ? 'This data changed elsewhere. Please refresh and try again.'
            : 'The request timed out. Please try again.',
        statusCode: status,
        rawError: error,
      );
    }

    if (status == 429) {
      return AppFailure(
        type: AppFailureType.quotaExceeded,
        message: 'Service quota was reached. Please try again shortly.',
        statusCode: status,
        retryAfter: retryAfter,
        rawError: error,
      );
    }

    if (status != null && status >= 500) {
      return AppFailure(
        type: AppFailureType.server,
        message: 'The service is temporarily unavailable.',
        statusCode: status,
        rawError: error,
      );
    }

    if (status != null && status >= 400) {
      return AppFailure(
        type: AppFailureType.validation,
        message: 'The request could not be completed.',
        statusCode: status,
        rawError: error,
      );
    }

    return AppFailure(
      type: AppFailureType.unknown,
      message: error.message ?? 'Network request failed.',
      statusCode: status,
      rawError: error,
    );
  }

  static AppFailure _fromFirebase(FirebaseException error) {
    final code = error.code.toLowerCase();
    if (code.contains('network') || code == 'unavailable') {
      return AppFailure(
        type: AppFailureType.offline,
        message: 'Cloud sync is unavailable. Changes are saved locally.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('deadline') || code.contains('timeout')) {
      return AppFailure(
        type: AppFailureType.timeout,
        message: 'Cloud sync timed out. Changes are saved locally.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('permission') ||
        code.contains('unauthenticated') ||
        code.contains('requires-recent-login')) {
      return AppFailure(
        type:
            code.contains('permission')
                ? AppFailureType.permissionDenied
                : AppFailureType.unauthorized,
        message: error.message ?? 'Please sign in again to continue.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('not-found')) {
      return AppFailure(
        type: AppFailureType.notFound,
        message: error.message ?? 'The requested data was not found.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('already-exists') || code.contains('aborted')) {
      return AppFailure(
        type: AppFailureType.conflict,
        message: error.message ?? 'This data changed elsewhere.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('cancel')) {
      return AppFailure(
        type: AppFailureType.cancelled,
        message: error.message ?? 'The operation was cancelled.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('storage') ||
        code.contains('object-not-found') ||
        code.contains('retry-limit-exceeded')) {
      return AppFailure(
        type: AppFailureType.uploadInterrupted,
        message: error.message ?? 'Upload was interrupted. It will retry.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('quota') || code.contains('resource-exhausted')) {
      return AppFailure(
        type: AppFailureType.quotaExceeded,
        message: 'Cloud quota was reached. Changes are saved locally.',
        code: error.code,
        rawError: error,
      );
    }
    return AppFailure(
      type: AppFailureType.unknown,
      message: error.message ?? error.code,
      code: error.code,
      rawError: error,
    );
  }

  static AppFailure _fromPlatform(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('cancel')) {
      return AppFailure(
        type: AppFailureType.cancelled,
        message: error.message ?? 'The operation was cancelled.',
        code: error.code,
        rawError: error,
      );
    }
    if (code.contains('network') || code.contains('internet')) {
      return AppFailure(
        type: AppFailureType.offline,
        message: error.message ?? 'No internet connection.',
        code: error.code,
        rawError: error,
      );
    }
    return AppFailure(
      type: AppFailureType.unknown,
      message: error.message ?? error.code,
      code: error.code,
      rawError: error,
    );
  }

  static Duration? _retryAfter(String? value) {
    if (value == null || value.isEmpty) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) return Duration(seconds: seconds);
    try {
      final date = HttpDate.parse(value);
      final diff = date.difference(DateTime.now());
      return diff.isNegative ? null : diff;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'AppFailure($type, $message)';
}
