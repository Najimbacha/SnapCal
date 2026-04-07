import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart'; // MealPlan model
import '../models/grocery_item.dart'; // GroceryItem model
import '../models/user_settings.dart'; // UserSettings model

/// Generic Nutrition Result from AI, Barcode, or Manual Entry
class NutritionResult {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  NutritionResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    return NutritionResult(
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
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal() : _dio = Dio() {
    debugPrint(
      '🔑 AIService: Gemini Key Length: ${AppConstants.geminiApiKey.length}',
    );
    debugPrint(
      '🔑 AIService: Groq Key Length: ${AppConstants.groqApiKey.length}',
    );
  }

  final Dio _dio;

  /// Main method: Tries Groq first (faster), falls back to Gemini, then Manual
  Future<NutritionResult> analyzeFood(Uint8List imageBytes) async {
    String groqError = "Unknown";
    try {
      // 1. Try Groq first (faster, higher free limits)
      print("Attempting analysis with Groq...");
      return await _detectWithGroq(imageBytes);
    } catch (e) {
      groqError = _extractDioError(e);
      print("Groq failed ($groqError). Switching to Gemini...");
      try {
        // 2. Fallback to Gemini
        return await _detectWithGeminiRetry(imageBytes, maxRetries: 2);
      } catch (e2) {
        return _getFallbackResult("AI Analysis failed. Please enter details manually.");
      }
    }
  }

  /// Gemini with automatic retry for 429 rate-limit errors
  Future<NutritionResult> _detectWithGeminiRetry(
    Uint8List imageBytes, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _detectWithGemini(imageBytes);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429 && attempt < maxRetries) {
          final waitSeconds = 15 * (attempt + 1); // 15s, 30s, 45s
          print(
            "⏳ Rate limited. Retrying in ${waitSeconds}s (attempt ${attempt + 1}/$maxRetries)...",
          );
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        rethrow;
      }
    }
    throw GeminiException(
      'Gemini rate limit exceeded after $maxRetries retries',
    );
  }

  /// Primary: Google Gemini 2.0 Flash
  Future<NutritionResult> _detectWithGemini(Uint8List imageBytes) async {
    if (AppConstants.geminiApiKey.isEmpty) {
      throw GeminiException(
        'Gemini API key is missing. Ensure GEMINI_API_KEY is set via --dart-define.',
      );
    }
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
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
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
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      if (text != null) {
        return _parseResponse(text);
      }
    }
    throw GeminiException('Gemini returned empty response');
  }

  /// Fallback: Groq (Llama 3.2 11B Vision)
  Future<NutritionResult> _detectWithGroq(Uint8List imageBytes) async {
    if (AppConstants.groqApiKey.isEmpty) {
      throw GeminiException(
        'Groq API key is missing. Ensure GROQ_API_KEY is set via --dart-define.',
      );
    }
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
          debugPrint("✅ Groq RAW Response: $content");
          return _parseResponse(content.toString());
        }
      }
      throw GeminiException('Groq returned empty response');
    } catch (e) {
      rethrow;
    }
  }

  /// Shared JSON Parser (Runs in Background Isolate)
  Future<NutritionResult> _parseResponse(String text) async {
    debugPrint("🔍 Parsing JSON from: $text");
    try {
      return await compute(_parseNutritionJsonInIsolate, text);
    } catch (e) {
      print("Parsing Error: $e");
      throw GeminiException('Failed to parse JSON');
    }
  }

  NutritionResult _getFallbackResult([String? errorMessage]) {
    return NutritionResult(
      foodName: errorMessage != null ? 'Error: $errorMessage' : 'Unknown Food',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
  }

  /// Generate Weekly Meal Plan & Grocery List
  Future<PlanGenerationResult?> generateWeeklyMealPlan(
    UserSettings settings,
  ) async {
    try {
      final prompt = _buildMealPlanPrompt(settings);

      // We reuse the Gemini structure but with text input only
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
          'generationConfig': {
            // Higher output tokens for a full week plan
            'maxOutputTokens': 4096,
            'temperature': 0.7, // More creativity for recipes
          },
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;
        if (text != null) {
          // Parse in background isolate
          return await compute(_parseMealPlanJsonInIsolate, text);
        }
      }
      return null;
    } catch (e) {
      print("Meal Planning Error: $e");
      return null;
    }
  }

  String _buildMealPlanPrompt(UserSettings settings) {
    return '''
    Generate a 7-day weekly meal plan and a consolidated grocery list.
    Target Calories: ${settings.dailyCalorieGoal} kcal/day.
    Target Macros: Protein ${settings.dailyProteinGoal}g, Carbs ${settings.dailyCarbGoal}g, Fat ${settings.dailyFatGoal}g.
    
    The output MUST be valid JSON with this exact structure:
    {
      "week_plan": {
        "0": [{"name": "Breakfast name", "calories": 500}, ...], // 0 is Monday
        ...
        "6": [...] // 6 is Sunday
      },
      "grocery_list": [
        {"name": "Item name", "amount": "Qty", "category": "Produce/Meat/Dairy/etc"}
      ]
    }
    Include 3 meals (Breakfast, Lunch, Dinner) per day.
    Keep names concise.
    ''';
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

  // --- Static/Top-Level Functions for Compute ---

  static NutritionResult _parseNutritionJsonInIsolate(String text) {
    final String jsonString = _extractJsonStatic(text);
    final jsonResult = jsonDecode(jsonString) as Map<String, dynamic>;
    return NutritionResult.fromJson(jsonResult);
  }

  static PlanGenerationResult _parseMealPlanJsonInIsolate(String text) {
    String jsonString = _extractJsonStatic(text);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    // Parse Plan
    final weekPlanMap = json['week_plan'] as Map<String, dynamic>;
    final Map<int, List<Meal>> weeklyMeals = {};

    weekPlanMap.forEach((key, value) {
      final dayIndex = int.parse(key);
      final mealsList =
          (value as List)
              .map(
                (m) => Meal(
                  id: const Uuid().v4(),
                  timestamp:
                      DateTime.now().millisecondsSinceEpoch, // Placeholder
                  dateString: 'Day $dayIndex', // Placeholder
                  foodName: m['name'],
                  calories:
                      m['calories'] is int
                          ? m['calories']
                          : (m['calories'] as num).round(),
                  macros: Macros.empty(), // Details not fetched to save tokens
                ),
              )
              .toList();
      weeklyMeals[dayIndex] = mealsList;
    });

    final plan = MealPlan.createEmpty().copyWith(weeklyMeals: weeklyMeals);

    // Parse Grocery List
    final groceryListJson = json['grocery_list'] as List;
    final groceryList =
        groceryListJson
            .map(
              (item) => GroceryItem(
                name: item['name'],
                amount: item['amount'],
                category: item['category'],
              ),
            )
            .toList();

    return PlanGenerationResult(plan: plan, groceryList: groceryList);
  }

  static String _extractJsonStatic(String rawResponse) {
    final regex = RegExp(r'\{[\s\S]*\}');
    final match = regex.firstMatch(rawResponse);
    if (match != null) {
      return match.group(0)!;
    }
    throw GeminiException('No JSON found in response');
  }
}

class PlanGenerationResult {
  final MealPlan plan;
  final List<GroceryItem> groceryList;

  PlanGenerationResult({required this.plan, required this.groceryList});
}

/// Custom exception for Gemini API errors
class GeminiException implements Exception {
  final String message;

  GeminiException(this.message);

  @override
  String toString() => message;
}
