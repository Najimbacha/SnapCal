import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

/// Response from Gemini API
class GeminiAnalysisResult {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  GeminiAnalysisResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GeminiAnalysisResult(
      foodName: json['food_name'] as String? ?? 'Unknown Food',
      calories: json['calories'] as int? ?? 0,
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
    );
  }
}

/// Service for interacting with AI models (Gemini + Groq Fallback)
class AIService {
  final Dio _dio;

  AIService() : _dio = Dio();

  /// Main method: Tries Gemini first, falls back to Groq, then Manual
  Future<GeminiAnalysisResult> analyzeFood(Uint8List imageBytes) async {
    String geminiError = "Unknown";
    try {
      // 1. Try Free Gemini First
      print("Attempting analysis with Gemini...");
      return await _detectWithGemini(imageBytes);
    } catch (e) {
      geminiError = _extractDioError(e);
      print("Gemini failed ($e). Switching to Groq...");
      try {
        // 2. Fallback to Free Groq
        return await _detectWithGroq(imageBytes);
      } catch (e2) {
        // 3. Last Resort: Manual Entry
        String groqError = _extractDioError(e2);
        String combinedError = "Gem: $geminiError | Groq: $groqError";
        print("All AIs failed. $combinedError");
        return _getFallbackResult(combinedError);
      }
    }
  }

  /// Primary: Google Gemini 2.5 Flash
  Future<GeminiAnalysisResult> _detectWithGemini(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await _dio.post(
        '${AppConstants.geminiApiUrl}?key=${AppConstants.geminiApiKey}',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': AppConstants.geminiSystemPrompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 1024,
          },
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;

        if (text != null) {
          return _parseResponse(text);
        }
      }
      throw GeminiException('Gemini returned empty response');
    } catch (e) {
      rethrow;
    }
  }

  /// Fallback: Groq (Llama 3.2 11B Vision)
  Future<GeminiAnalysisResult> _detectWithGroq(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final imageUrl = "data:image/jpeg;base64,$base64Image";

      final response = await _dio.post(
        AppConstants.groqApiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConstants.groqApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "meta-llama/llama-4-scout-17b-16e-instruct",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": AppConstants.geminiSystemPrompt},
                {
                  "type": "image_url",
                  "image_url": {"url": imageUrl},
                },
              ],
            },
          ],
          "max_tokens": 1024,
          "stream": false,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return _parseResponse(content.toString());
        }
      }
      throw GeminiException('Groq returned empty response');
    } catch (e) {
      rethrow;
    }
  }

  /// Shared JSON Parser
  GeminiAnalysisResult _parseResponse(String text) {
    print("Raw API Response: $text"); // Requested Debug Log

    try {
      String jsonString = _extractJson(text);
      final jsonResult = jsonDecode(jsonString) as Map<String, dynamic>;
      return GeminiAnalysisResult.fromJson(jsonResult);
    } catch (e) {
      print("Parsing Error: $e");
      throw GeminiException('Failed to parse JSON');
    }
  }

  /// Extracts JSON object from raw text using Regex
  String _extractJson(String rawResponse) {
    final regex = RegExp(r'\{[\s\S]*\}');
    final match = regex.firstMatch(rawResponse);
    if (match != null) {
      return match.group(0)!;
    }
    throw GeminiException('No JSON found in response');
  }

  GeminiAnalysisResult _getFallbackResult([String? errorMessage]) {
    return GeminiAnalysisResult(
      foodName: errorMessage != null ? 'Error: $errorMessage' : 'Unknown Food',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
  }

  /// Extracts detailed error message from DioException
  String _extractDioError(Object error) {
    if (error is DioException) {
      if (error.response != null && error.response!.data != null) {
        try {
          final data = error.response!.data;
          if (data is Map<String, dynamic> && data.containsKey('error')) {
            final err = data['error'];
            if (err is Map && err.containsKey('message')) {
              return err['message'].toString();
            }
          }
        } catch (_) {}
      }
      return "${error.response?.statusCode ?? 'Error'}";
    }
    return error.toString();
  }
}

/// Custom exception for Gemini API errors
class GeminiException implements Exception {
  final String message;

  GeminiException(this.message);

  @override
  String toString() => message;
}
