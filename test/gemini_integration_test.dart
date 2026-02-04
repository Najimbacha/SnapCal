import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/gemini_service.dart';

void main() {
  group('GeminiService Integration Test', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService();
    });

    test('analyzeFood returns valid result for dummy image', () async {
      // 1x1 pixel transparent GIF/PNG or just random bytes might fail validation by Gemini.
      // Let's use a minimal valid JPEG header.
      // This is a minimal white JPEG.
      final String base64Image =
          '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD//2Q==';

      final Uint8List imageBytes = base64Decode(base64Image);

      const bool runIntegration = true; // Set to true to hit real API

      if (runIntegration) {
        try {
          final result = await service.analyzeFood(imageBytes);
          print('Food Name: ${result.foodName}');
          print('Calories: ${result.calories}');

          expect(result, isNotNull);
          expect(result.calories, isNotNull);
          // We can't guarantee the AI recognizes a white pixel as food, but it should return a valid object or throw specific error, not crash.
        } catch (e) {
          print('API Error: $e');
          // If it's a rate limit or auth error, we want to know.
          if (e.toString().contains('Invalid API key')) {
            fail('Invalid API Key');
          }
          if (e.toString().contains('Rate limit exceeded')) {
            print('Rate limit hit, skipping assertion.');
            return;
          }
          // Rethrow if unexpected
          rethrow;
        }
      }
    });
  });
}
