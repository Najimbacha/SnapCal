import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/services/config_service.dart';
import 'gemini_service.dart';

/// Suggested recipe or coaching tip from AI
class AssistantResponse {
  final String title;
  final String content;
  final String type; // 'recipe', 'coaching', or 'action'
  // For recipes: {calories, protein, carbs, fat}
  final Map<String, int>? macros;
  final List<AssistantAction>? actions; // Actionable buttons

  AssistantResponse({
    required this.title,
    required this.content,
    required this.type,
    this.macros,
    this.actions,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    // Handle content being either a String or a List of Strings
    String parsedContent = '';
    final rawContent = json['content'];
    if (rawContent is String) {
      parsedContent = rawContent;
    } else if (rawContent is List) {
      parsedContent = rawContent.map((e) => e.toString()).join('\n');
    }

    return AssistantResponse(
      title: json['title'] as String? ?? '',
      content: parsedContent,
      type: json['type'] as String? ?? 'coaching',
      macros:
          json['macros'] != null
              ? Map<String, int>.from(json['macros'] as Map)
              : null,
      actions:
          json['actions'] != null
              ? (json['actions'] as List)
                  .map(
                    (e) => AssistantAction.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : null,
    );
  }
}

class AssistantAction {
  final String label;
  final String type; // 'add_to_diary', 'set_reminder', 'show_recipe'
  final Map<String, dynamic>? data;

  AssistantAction({required this.label, required this.type, this.data});

  factory AssistantAction.fromJson(Map<String, dynamic> json) {
    return AssistantAction(
      label: json['label'] as String? ?? 'Action',
      type: json['type'] as String? ?? 'unknown',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'type': type, 'data': data};
}

/// Service for AI-powered nutrition coaching and recipe suggestions
class AssistantService {
  late final Dio _dio = ApiClient.dio;

  /// Get recommendations based on current macros and goals
  Future<List<AssistantResponse>> getRecommendations({
    required int currentCalories,
    required int targetCalories,
    required Map<String, int> currentMacros,
    required Map<String, int> targetMacros,
    List<String> mealNames = const [],
    String dietaryRestriction = 'none',
    String? userQuery,
    String language = 'en',
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    String? goalMode,
    String? activityLevel,
    String? foodDislikes,
    String? medicalNotes,
  }) async {
    try {
      final prompt = _buildPrompt(
        currentCalories: currentCalories,
        targetCalories: targetCalories,
        currentMacros: currentMacros,
        targetMacros: targetMacros,
        mealNames: mealNames,
        dietaryRestriction: dietaryRestriction,
        userQuery: userQuery,
        language: language,
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        targetWeight: targetWeight,
        goalMode: goalMode,
        activityLevel: activityLevel,
        foodDislikes: foodDislikes,
        medicalNotes: medicalNotes,
      );

      final endpoint = '${ConfigService().backendProxyUrl}/api/ai/text';
      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        ),
        data: {
          'prompt': prompt,
          'maxOutputTokens': 500,
          'timeoutMs': 25000,
        },
      );

      final text = response.data is Map ? response.data['text'] as String? : null;

      if (text != null) {
        debugPrint("Assistant Raw Response: $text");
        try {
          String jsonString = _extractJson(text);
          jsonString = _sanitizeJsonString(jsonString);
          final dynamic decoded = jsonDecode(jsonString);
          if (decoded is List) {
            return decoded.map((e) => AssistantResponse.fromJson(e as Map<String, dynamic>)).toList();
          } else if (decoded is Map) {
            return [AssistantResponse.fromJson(decoded as Map<String, dynamic>)];
          }
        } catch (_) {
          // Response is not JSON — treat as plain text coaching
          final clean = text.trim();
          return [AssistantResponse(title: '', content: clean, type: 'coaching')];
        }
        return [];
      }

      throw GeminiException('Failed to get response from AI backend');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String? detail;
      if (responseData is Map) {
        final err = responseData['error'];
        detail = err is Map ? err['message'] : err?.toString();
      }

      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw GeminiException(
          'Unauthorized: Please check your authentication.',
        );
      }
      if (e.response?.statusCode == 400) {
        throw GeminiException(
          'Bad Request: ${detail ?? 'Invalid request parameters.'}',
        );
      }
      throw GeminiException('${detail ?? e.message}');
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException('AI Parser Error: $e');
    }
  }

  /// Analyze an image for coaching or food tracking
  Future<List<AssistantResponse>> analyzeImage({
    required Uint8List imageBytes,
    String? userQuery,
    required int currentCalories,
    required int targetCalories,
    String language = 'en',
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    String? goalMode,
    String? activityLevel,
    String? foodDislikes,
    String? medicalNotes,
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final languageName = AIService.languageNames[language] ?? 'English';

      final prompt = """
You are the SnapCal AI Wellness Coach.
STRICT LANGUAGE RULE: YOU MUST RESPOND ENTIRELY IN THE $languageName LANGUAGE.

USER COACH PROFILE:
- Age: ${age ?? 'N/A'}
- Gender: ${gender ?? 'N/A'}
- Height: ${height ?? 'N/A'} cm
- Current Weight: ${weight ?? 'N/A'} kg
- Goal Weight: ${targetWeight ?? 'N/A'} kg
- Goal Type: ${goalMode ?? 'N/A'}
- Activity Level: ${activityLevel ?? 'N/A'}
- Food Dislikes: ${foodDislikes ?? 'None specified'}
- Medical Notes: ${medicalNotes ?? 'None specified'}

The user has sent a photo. ${userQuery != null ? "User says: $userQuery" : "Analyze what is in the photo."}

${userQuery == null ? "If it's food, provide nutrition info. If it's a body photo, provide encouragement and progress tips." : ""}

STRICT BREVITY RULES:
1. BE EXTREMELY CONCISE. Respond in 1-2 short sentences maximum.
2. NO CONVERSATIONAL FLUFF. No "It looks like...", "As your coach...", or "I'm here to help...".
3. Provide the answer directly and immediately.
4. If it's not a wellness photo, say "Please upload a meal or progress photo." and nothing else.

FORMAT:
- Return a JSON LIST [ ... ] containing exactly ONE object.
- 'type': 'coaching' or 'recipe'
- 'title': 1-2 words max.
- 'content': Direct and short.
- 'actions': Action objects only if highly relevant.

User Stats: $currentCalories / $targetCalories kcal.
""";

      debugPrint("🧠 AssistantService: Analyzing image via backend proxy...");

      final endpoint = '${ConfigService().backendProxyUrl}/api/ai/image';
      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        ),
        data: {
          'prompt': prompt,
          'image': base64Image,
          'language': language,
        },
      );

      final text = response.data is Map ? response.data['text'] as String? : null;
      if (text != null) {
        final jsonString = _extractJson(text);
        final jsonResult = jsonDecode(jsonString) as List<dynamic>;
        return jsonResult
            .map((e) => AssistantResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw GeminiException(
        'Failed to analyze image (no response from backend)',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.response?.data?['error']?['message'] ?? e.message;
      debugPrint("❌ AssistantService Image Error ($status): $msg");
      throw GeminiException('Image Analysis Failed ($status): $msg');
    } catch (e) {
      debugPrint("❌ AssistantService Error: $e");
      throw GeminiException('Image Analysis Error: $e');
    }
  }

  String _buildPrompt({
    required int currentCalories,
    required int targetCalories,
    required Map<String, int> currentMacros,
    required Map<String, int> targetMacros,
    required List<String> mealNames,
    required String dietaryRestriction,
    String? userQuery,
    String language = 'en',
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    String? goalMode,
    String? activityLevel,
    String? foodDislikes,
    String? medicalNotes,
  }) {
    final languageName = AIService.languageNames[language] ?? 'English';
    final remainingCalories = targetCalories - currentCalories;
    final remainingProtein = targetMacros['protein']! - currentMacros['protein']!;

    return """
You are Fajar, a friendly and knowledgeable AI nutritionist.

PERSONALITY:
- Warm, encouraging, and conversational — like a supportive friend who's also a nutrition expert
- Answer questions directly and thoroughly when asked
- Use the user's data as context, not as a script
- If they ask "what is X", explain X clearly with examples
- If they ask for advice, give practical actionable suggestions
- Never sound robotic or like you're just reading numbers

CONTEXT (use only when relevant):
- User: ${age ?? '?'}yo ${gender ?? '?'}, goal: ${goalMode ?? '?'}, diet: $dietaryRestriction
- Today: ${currentCalories}cal/${targetCalories}cal | Protein: ${currentMacros['protein']}g/${targetMacros['protein']}g | Carbs: ${currentMacros['carbs']}g/${targetMacros['carbs']}g | Fat: ${currentMacros['fat']}g/${targetMacros['fat']}g
- Meals logged: ${mealNames.isEmpty ? 'None yet' : mealNames.join(', ')}

Respond in $languageName. Keep it natural — 2-4 sentences. No markdown, no JSON, no bullet points.

USER QUESTION: ${userQuery ?? "Give a friendly greeting and ask how you can help with their nutrition goals."}
""";
  }

  String _extractJson(String text) {
    // Find the first occurrence of either '[' or '{'
    int startList = text.indexOf('[');
    int startObject = text.indexOf('{');

    int start = -1;
    if (startList != -1 && startObject != -1) {
      start = startList < startObject ? startList : startObject;
    } else if (startList != -1) {
      start = startList;
    } else if (startObject != -1) {
      start = startObject;
    }

    if (start != -1) {
      // Find the last occurrence of the matching closing character
      int endList = text.lastIndexOf(']');
      int endObject = text.lastIndexOf('}');
      int end = (start == startList) ? endList : endObject;

      if (end != -1 && end > start) {
        return text.substring(start, end + 1);
      }
    }

    // Fallback to trimming backticks
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

  String _sanitizeJsonString(String text) {
    bool inString = false;
    bool isEscaped = false;
    StringBuffer result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      String char = text[i];

      if (inString) {
        if (char == '"' && !isEscaped) {
          inString = false;
          result.write(char);
        } else if (char == '\n') {
          result.write('\\n');
        } else if (char == '\r') {
          // Ignore \r to prevent double escaping issues on Windows
        } else {
          if (char == '\\' && !isEscaped) {
            isEscaped = true;
          } else {
            isEscaped = false;
          }
          result.write(char);
        }
      } else {
        if (char == '"') {
          inString = true;
        }
        result.write(char);
      }
    }
    return result.toString();
  }
}
