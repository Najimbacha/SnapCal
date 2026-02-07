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
        AppConstants.groqApiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConstants.groqApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final text = data['choices']?[0]?['message']?['content'] as String?;

        if (text != null) {
          print("Assistant Raw Response: $text");
          final jsonString = _extractJson(text);
          final jsonResult = jsonDecode(jsonString) as List<dynamic>;
          return jsonResult
              .map((e) => AssistantResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      throw GeminiException('Failed to get response from Groq');
    } on DioException catch (e) {
      throw GeminiException('Network error: ${e.message}');
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException('AI Parser Error: $e');
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
You are the "SnapCal AI Nutritionist," a high-end personal health and nutrition expert.
Your goal is to provide supportive, data-driven coaching and meal suggestions to help the user hit their goals.

CURRENT USER STATUS (CONTEXT):
- Calories: $currentCalories / $targetCalories (Remaining: $remainingCalories kcal)
- Protein: ${currentMacros['protein']}g / ${targetMacros['protein']}g (Remaining: ${remainingProtein}g)
- Carbs: ${currentMacros['carbs']}g / ${targetMacros['carbs']}g (Remaining: ${remainingCarbs}g)
- Fat: ${currentMacros['fat']}g / ${targetMacros['fat']}g (Remaining: ${remainingFat}g)

${userQuery != null ? "USER QUESTION: $userQuery" : "The user wants a daily progress check and personalized meal/coaching suggestions."}

STRICT PERSONA RULES:
1. YOU ARE A NUTRITIONIST. Start by acknowledging the user warmly if they greet you.
2. BE SHORT AND PRECISE. Avoid fluff or long explanations. Get straight to the point.
3. STAY UNBIASED. Provide objective, science-based nutritional advice without personal opinions or marketing bias.
4. ALWAYS steer the conversation back to their health, macros, and nutrition goals.
5. ONLY answer questions related to nutrition, fitness, diet (Keto, Paleo, Fasting, etc.), or cooking.
6. If the user asks about unrelated topics, politely decline and offer to help with their diet instead.
7. Use the user's "Remaining" macros to suggest exactly what they should eat NEXT.
8. Be professional and encouraging.

RESPONSE REQUIREMENTS:
- You MUST return a JSON LIST [ ... ] containing 2-3 objects.
- Each object represents a "Card" in the UI.
- 'type' must be either 'recipe' or 'coaching'.
- 'title' should be catchy (e.g., "Protein Power Up").
- 'content' should be a short, actionable paragraph.
- 'macros' (optional for recipes): {"calories": int, "protein": int, "carbs": int, "fat": int}.

EXAMPLE JSON OUTPUT (ONLY RETURN THIS FORMAT):
[
  {
    "title": "Nutritionist Tip",
    "content": "You are doing great on calories, but you need 30g more protein. Try a protein shake or chicken breast.",
    "type": "coaching"
  },
  {
    "title": "Keto Lunch Idea",
    "content": "Since you have 500 kcal left and need low carbs, try a Tuna Salad with extra virgin olive oil.",
    "type": "recipe",
    "macros": {"calories": 420, "protein": 35, "carbs": 5, "fat": 28}
  }
]
""";
  }

  String _extractJson(String text) {
    // Look for the first '[' and last ']'
    final regex = RegExp(r'\[[\s\S]*\]');
    final match = regex.firstMatch(text);
    if (match != null) {
      return match.group(0)!;
    }
    // Fallback to trimming backticks
    String cleaned = text.trim();
    if (cleaned.startsWith('```json'))
      cleaned = cleaned.substring(7);
    else if (cleaned.startsWith('```'))
      cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```'))
      cleaned = cleaned.substring(0, cleaned.length - 3);
    return cleaned.trim();
  }
}
