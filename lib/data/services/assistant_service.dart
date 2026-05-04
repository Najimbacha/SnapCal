import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/config_service.dart';
import 'gemini_service.dart';

/// Suggested recipe or coaching tip from AI
class AssistantResponse {
  final String title;
  final String content;
  final String type; // 'recipe', 'coaching', or 'action'
  final Map<String, int>? macros; // For recipes: {calories, protein, carbs, fat}
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
      macros: json['macros'] != null
          ? Map<String, int>.from(json['macros'] as Map)
          : null,
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((e) => AssistantAction.fromJson(e as Map<String, dynamic>))
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
  
  Map<String, dynamic> toJson() => {
    'label': label,
    'type': type,
    'data': data,
  };
}

/// Service for AI-powered nutrition coaching and recipe suggestions
class AssistantService {
  final Dio _dio;

  AssistantService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

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
      );

      final response = await _dio.post(
        AppConstants.groqApiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ConfigService().groqApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': ConfigService().groqCoachModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.6,
          'max_tokens': 256,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final text = data['choices']?[0]?['message']?['content'] as String?;

        if (text != null) {
          debugPrint("Assistant Raw Response: $text");
          String jsonString = _extractJson(text);
          
          // Sanitize: Only escape newlines that are inside JSON strings.
          jsonString = _sanitizeJsonString(jsonString);
          
          final dynamic decoded = jsonDecode(jsonString);
          
          if (decoded is List) {
            return decoded
                .map((e) => AssistantResponse.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (decoded is Map) {
            return [AssistantResponse.fromJson(decoded as Map<String, dynamic>)];
          }
          return [];
        }
      }

      throw GeminiException('Failed to get response from Groq');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String? detail;
      if (responseData is Map) {
        detail = responseData['error']?['message'] ?? responseData['message'];
      }

      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw GeminiException('Unauthorized: Please check your Groq API Key in Firebase Remote Config.');
      }
      if (e.response?.statusCode == 404) {
        throw GeminiException('Invalid Model: The Groq Model ID in Remote Config is incorrect.');
      }
      if (e.response?.statusCode == 400) {
        throw GeminiException('Bad Request: ${detail ?? 'Check your Remote Config values.'}');
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
  }) async {
    try {
      final apiKey = ConfigService().geminiApiKey;
      final modelId = ConfigService().geminiModelId;
      if (apiKey.isEmpty) throw GeminiException('Gemini API Key missing');

      final base64Image = base64Encode(imageBytes);
      
      final languageName = AIService.languageNames[language] ?? 'English';
      
      final prompt = """
You are the SnapCal AI Wellness Coach.
STRICT LANGUAGE RULE: YOU MUST RESPOND ENTIRELY IN THE $languageName LANGUAGE.
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

      debugPrint("🧠 AssistantService: Analyzing image with $modelId...");
      
      // Use v1beta for better compatibility with cutting-edge flash models
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
                },
              ],
            },
          ],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 1024},
        },
      );

      if (response.statusCode == 200) {
        final text = response.data['candidates']?[0]?['content']?[0]?['text'] ?? 
                     response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          final jsonString = _extractJson(text);
          final jsonResult = jsonDecode(jsonString) as List<dynamic>;
          return jsonResult
              .map((e) => AssistantResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      throw GeminiException('Failed to analyze image (Status: ${response.statusCode})');
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
  }) {
    final languageName = AIService.languageNames[language] ?? 'English';
    final remainingCalories = targetCalories - currentCalories;
    final remainingProtein =
        targetMacros['protein']! - currentMacros['protein']!;
    final remainingCarbs = targetMacros['carbs']! - currentMacros['carbs']!;
    final remainingFat = targetMacros['fat']! - currentMacros['fat']!;

    return """
You are the SnapCal AI Nutritionist. 
Your goal is to provide ultra-concise, direct nutritional feedback.
STRICT LANGUAGE RULE: YOU MUST RESPOND ENTIRELY IN THE $languageName LANGUAGE.

STRICT BREVITY RULES:
1. RESPONSE MUST BE 10-20 WORDS MAX.
2. NO INTRODUCTIONS. No "Hello", "Sure", or "I recommend".
3. START directly with the advice or data.
4. Use 1-2 bullet points only for data.

CURRENT USER STATUS:
- Calories: $currentCalories / $targetCalories (${remainingCalories > 0 ? "Rem: $remainingCalories" : "Over: ${remainingCalories.abs()}"} kcal)
- Macros: P:${currentMacros['protein']} / ${targetMacros['protein']}g (Rem: $remainingProtein g), C:${currentMacros['carbs']} / ${targetMacros['carbs']}g (Rem: $remainingCarbs g), F:${currentMacros['fat']} / ${targetMacros['fat']}g (Rem: $remainingFat g)

${userQuery != null ? "USER QUESTION: $userQuery" : "Provide one quick strategy."}

RESPONSE REQUIREMENTS:
- Return a JSON LIST [ ... ] with exactly ONE object.
- 'type': 'coaching'
- 'title': 1-2 words.
- 'content': Extreme brevity.
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
