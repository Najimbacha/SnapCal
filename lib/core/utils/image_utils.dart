import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';

/// Utility class for image processing
class ImageUtils {
  ImageUtils._();

  /// Compress and resize image to reduce bandwidth
  static Future<Uint8List> compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
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

  /// Compress image from bytes
  static Uint8List compressImageBytes(Uint8List bytes) {
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
}
