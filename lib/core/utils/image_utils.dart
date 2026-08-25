import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';

/// Thrown when an image cannot be decoded at all (unsupported or corrupt
/// format, e.g. HEIC edge cases or truncated files). Distinct from a size
/// failure so the UI can offer a retake instead of a misleading "too large"
/// message (BUG-016).
class UnsupportedImageException implements Exception {
  const UnsupportedImageException();

  @override
  String toString() => 'UnsupportedImageException: image could not be decoded';
}

/// Utility class for image processing
class ImageUtils {
  ImageUtils._();

  /// Compress and resize image to reduce bandwidth (Async).
  ///
  /// Returns null when the bytes are not decodable as an image.
  static Future<Uint8List?> compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return compute(_compressImageIsolate, bytes);
  }

  /// Compress image from bytes (Async version for UI).
  ///
  /// Returns null when the bytes are not decodable as an image.
  static Future<Uint8List?> compressImageBytesAsync(Uint8List bytes) async {
    return compute(_compressImageIsolate, bytes);
  }

  /// Original sync version (kept for internal use or simple needs)
  static Uint8List? compressImageBytes(Uint8List bytes) {
    return _compressInternal(bytes);
  }

  /// The actual internal logic used by both sync and async methods.
  ///
  /// Returning the original bytes on decode failure would only move the
  /// failure downstream into a misleading size error; callers need to know
  /// decoding itself failed.
  static Uint8List? _compressInternal(Uint8List bytes) {
    final image = img.decodeImage(bytes);

    if (image == null) {
      return null;
    }

    // Resize if larger than max size
    img.Image resized;
    if (image.width > AppConstants.maxImageSize ||
        image.height > AppConstants.maxImageSize) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: AppConstants.maxImageSize);
      } else {
        resized = img.copyResize(image, height: AppConstants.maxImageSize);
      }
    } else {
      resized = image;
    }

    // Encode as JPEG with quality setting
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: AppConstants.imageQuality),
    );
  }

  /// Top-level helper for compute
  static Uint8List? _compressImageIsolate(Uint8List bytes) {
    return _compressInternal(bytes);
  }
}
