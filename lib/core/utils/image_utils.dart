import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';

/// Utility class for image processing
class ImageUtils {
  ImageUtils._();

  /// Compress and resize image to reduce bandwidth (Async)
  static Future<Uint8List> compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return compute(_compressImageIsolate, bytes);
  }

  /// Compress image from bytes (Async version for UI)
  static Future<Uint8List> compressImageBytesAsync(Uint8List bytes) async {
    return compute(_compressImageIsolate, bytes);
  }

  /// Original sync version (kept for internal use or simple needs)
  static Uint8List compressImageBytes(Uint8List bytes) {
    return _compressInternal(bytes);
  }

  /// The actual internal logic used by both sync and async methods
  static Uint8List _compressInternal(Uint8List bytes) {
    final image = img.decodeImage(bytes);

    if (image == null) {
      return bytes;
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
  static Uint8List _compressImageIsolate(Uint8List bytes) {
    return _compressInternal(bytes);
  }
}
