import 'dart:io';

import 'package:flutter/foundation.dart';

/// Keeps a scan image only when the meal that references it is durable.
class MealImageTransaction {
  const MealImageTransaction._();

  static Future<T> run<T>({
    required Future<String?> Function() persistImage,
    required Future<T> Function(String? imageUri) saveMeal,
    Future<void> Function(String path)? removeImage,
  }) async {
    final imageUri = await persistImage();
    try {
      return await saveMeal(imageUri);
    } catch (error, stack) {
      if (imageUri != null) {
        try {
          await (removeImage ?? _removeImage)(imageUri);
        } catch (cleanupError) {
          debugPrint('Unable to remove unsaved meal image: $cleanupError');
        }
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  static Future<void> _removeImage(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
