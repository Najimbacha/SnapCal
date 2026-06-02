import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TransformationVideoService {
  static final TransformationVideoService _instance =
      TransformationVideoService._internal();
  factory TransformationVideoService() => _instance;
  TransformationVideoService._internal();

  /// Generates a transformation video from a list of image paths
  Future<String?> generateVideo(List<String> imagePaths) async {
    if (imagePaths.length < 2) {
      debugPrint("❌ VideoService: Not enough images (need at least 2)");
      return null;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/transformation_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Create a text file containing the image list for FFmpeg concat demuxer
      final listFile = File('${tempDir.path}/images.txt');
      final buffer = StringBuffer();

      // Duration per image (e.g., 0.8 seconds)
      const duration = 0.8;

      for (var path in imagePaths) {
        buffer.writeln("file '$path'");
        buffer.writeln("duration $duration");
      }
      // FFmpeg requires the last file to be repeated without duration to end
      buffer.writeln("file '${imagePaths.last}'");

      await listFile.writeAsString(buffer.toString());

      // FFmpeg command to compile images with a simple crossfade effect
      // -f concat: use the concat demuxer
      // -safe 0: allow absolute paths
      // -pix_fmt yuv420p: compatibility for most players
      final command =
          "-f concat -safe 0 -i ${listFile.path} -vsync vfr -pix_fmt yuv420p $outputPath";

      debugPrint("🎬 VideoService: Starting render: $command");

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint("✅ VideoService: Render Complete! Path: $outputPath");
        return outputPath;
      } else {
        final logs = await session.getLogs();
        debugPrint(
          "❌ VideoService: Render Failed with code $returnCode. Logs: $logs",
        );
        return null;
      }
    } catch (e) {
      debugPrint("❌ VideoService: Exception during video generation: $e");
      return null;
    }
  }
}
