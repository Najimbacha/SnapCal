import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'gemini_service.dart';

/// Suggested recipe or coaching tip from AI
class AssistantResponse {
  final String title;
  final String content;
  final String type; // 'recipe' or 'coaching'
  final Map<String, int>?
  macros; // For recipes: {calories, protein, carbs, fat}

  AssistantResponse({
    required this.title,
    required this.content,
    required this.type,
    this.macros,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'coaching',
      macros:
          json['macros'] != null
              ? Map<String, int>.from(json['macros'] as Map)
              : null,
    );
  }
}

/// Service for AI-powered nutrition coaching and recipe suggestions
class AssistantService {
  final Dio _dio;

  AssistantService() : _dio = Dio();

  /// Get recommendations based on current macros and goals
  Future<List<AssistantResponse>> getRecommendations({
    required int currentCalories,
    required int targetCalories,
    required Map<String, int> currentMacros,
    required Map<String, int> targetMacros,
    String? userQuery,
  }) async {
    try {
      final prompt = _buildPrompt(
        currentCalories: currentCalories,
        targetCalories: targetCalories,
        currentMacros: currentMacros,
        targetMacros: targetMacros,
        userQuery: userQuery,
      );

      final response = await _dio.post(
        '${AppConstants.geminiApiUrl}?key=${AppConstants.geminiApiKey}',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 2048},
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;

        if (text != null) {
          final cleanedText = _cleanResponse(text);
          final jsonResult = jsonDecode(cleanedText) as List<dynamic>;
          return jsonResult
              .map((e) => AssistantResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      throw GeminiException('Failed to get recommendations: Invalid response');
    } on DioException catch (e) {
      throw GeminiException('Network error: ${e.message}');
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException('Assistant Error: $e');
    }
  }

  String _buildPrompt({
    required int currentCalories,
    required int targetCalories,
    required Map<String, int> currentMacros,
    required Map<String, int> targetMacros,
    String? userQuery,
  }) {
    final remainingCalories = targetCalories - currentCalories;
    final remainingProtein =
        targetMacros['protein']! - currentMacros['protein']!;
    final remainingCarbs = targetMacros['carbs']! - currentMacros['carbs']!;
    final remainingFat = targetMacros['fat']! - currentMacros['fat']!;

    return """
You are a expert nutrition coach for the app SnapCal.
Your goal is to provide specific, actionable advice and recipe suggestions based on a user's progress for today.

Todays Progress:
- Calories: $currentCalories / $targetCalories (Remaining: $remainingCalories)
- Protein: ${currentMacros['protein']}g / ${targetMacros['protein']}g (Remaining: ${remainingProtein}g)
- Carbs: ${currentMacros['carbs']}g / ${targetMacros['carbs']}g (Remaining: ${remainingCarbs}g)
- Fat: ${currentMacros['fat']}g / ${targetMacros['fat']}g (Remaining: ${remainingFat}g)

${userQuery != null ? "User Question: $userQuery" : "The user wants general coaching and recipe suggestions for the rest of the day."}

REQUIREMENTS:
1. Return a JSON LIST of 2-3 items.
2. Each item must have: 'title', 'content', 'type' (either 'recipe' or 'coaching'), and 'macros' (optional, only for recipes).
3. 'macros' should be a map: {"calories": int, "protein": int, "carbs": int, "fat": int}.
4. Be supportive and professional.
5. If the user is over their limit, provide tips on how to manage the rest of the day (e.g., light activity, hydration).
6. Recipes should be quick and easy to log in SnapCal.

FORMAT:
[
  {
    "title": "...",
    "content": "...",
    "type": "recipe",
    "macros": {"calories": 300, "protein": 25, "carbs": 10, "fat": 8}
  },
  {
    "title": "...",
    "content": "...",
    "type": "coaching"
  }
]
""";
  }

  String _cleanResponse(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
