import 'dart:async';
import 'package:flutter/foundation.dart';

typedef AsyncOperation<T> = Future<T> Function();

Future<T?> runSilently<T>(
  String label,
  AsyncOperation<T> operation, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  try {
    return await operation().timeout(timeout);
  } catch (e, stack) {
    debugPrint('⚠️ $label failed gracefully: $e');
    debugPrintStack(stackTrace: stack);
    return null;
  }
}
