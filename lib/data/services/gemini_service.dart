import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/config_service.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart'; // MealPlan model
import '../models/grocery_item.dart'; // GroceryItem model
import '../models/user_settings.dart'; // UserSettings model

/// Generic Nutrition Result from AI, Barcode, or Manual Entry
class NutritionResult {
  final String foodName;
  final String portion;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int healthScore; // 1-10
  final List<String> insights;

  NutritionResult({
    required this.foodName,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.healthScore = 5,
    this.insights = const [],
  });

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    return NutritionResult(
      foodName: json['food_name'] as String? ?? 'Unknown Food',
      portion: json['portion'] as String? ?? 'Standard portion',
      calories: _safeInt(json['calories']),
      protein: _safeInt(json['protein']),
      carbs: _safeInt(json['carbs']),
      fat: _safeInt(json['fat']),
      healthScore: _safeInt(json['health_score']) == 0 ? 5 : _safeInt(json['health_score']),
      insights: (json['insights'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// Service for interacting with AI models (Gemini + Groq Fallback)
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal() : _dio = Dio();

  final Dio _dio;

  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
  };

  /// Main method: Tries Groq first (faster), falls back to Gemini, then Manual
  Future<List<NutritionResult>> analyzeFood(Uint8List imageBytes, {String language = 'en'}) async {
    String groqError = "Unknown";
    try {
      // 1. Try Groq first (faster, higher free limits)
      debugPrint("Attempting analysis with Groq...");
      return await _detectWithGroq(imageBytes, language: language);
    } catch (e) {
      groqError = _extractDioError(e);
      debugPrint("Groq failed ($groqError). Switching to Gemini...");
      try {
        // 2. Fallback to Gemini
        return await _detectWithGeminiRetry(imageBytes, language: language, maxRetries: 2);
      } catch (e2) {
        final geminiError = _extractDioError(e2);
        return [
          _getFallbackResult(
            "AI Failed. Groq: $groqError | Gemini: $geminiError",
          ),
        ];
      }
    }
  }

  /// Gemini with automatic retry for 429 rate-limit errors
  Future<List<NutritionResult>> _detectWithGeminiRetry(
    Uint8List imageBytes, {
    String language = 'en',
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _detectWithGemini(imageBytes, language: language);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429 && attempt < maxRetries) {
          final waitSeconds = 15 * (attempt + 1); // 15s, 30s, 45s
          debugPrint(
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

  /// Primary: Google Gemini (with Auto-Hunting)
  Future<List<NutritionResult>> _detectWithGemini(Uint8List imageBytes, {String language = 'en'}) async {
    final apiKey = ConfigService().geminiApiKey;
    if (apiKey.isEmpty) throw GeminiException('API Key missing');

    final base64Image = await compute(base64Encode, imageBytes);

    // Prioritize ultra-low-cost models first to save on API costs
    final candidates = [
      {'id': 'gemini-1.5-flash-8b', 'ver': 'v1'}, // Ultra-cheap, fast
      {'id': 'gemini-1.5-flash', 'ver': 'v1'},
      {'id': 'gemini-2.0-flash', 'ver': 'v1'},
    ];

    Object? lastError;

    for (var candidate in candidates) {
      final modelId = candidate['id']!;
      final apiVer = candidate['ver']!;

      try {
        debugPrint('🧠 AIService: Hunting Gemini ($modelId on $apiVer)...');
        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/$apiVer/models/$modelId:generateContent?key=$apiKey',
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 10),
          ),
          data: {
            'contents': [
              {
                'parts': [
                  {'text': AppConstants.getGeminiSystemPrompt(language)},
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
              'maxOutputTokens': 512,
            }, // Reduced max tokens for a simple JSON output
          },
        );

        if (response.statusCode == 200) {
          final text =
              response.data['candidates']?[0]?['content']?['parts']?[0]?['text']
                  as String?;
          if (text != null) {
            return await _parseResponse(text);
          }
        }
      } catch (e) {
        lastError = e;
        debugPrint('❌ Hunting failed for $modelId: $e');
        continue; // Try next candidate
      }
    }

    throw lastError ?? GeminiException('All Gemini candidates failed');
  }

  /// Fallback: Groq (with Auto-Hunting)
  Future<List<NutritionResult>> _detectWithGroq(Uint8List imageBytes, {String language = 'en'}) async {
    final apiKey = ConfigService().groqApiKey;
    if (apiKey.isEmpty) throw GeminiException('API Key missing');

    final base64Image = await compute(base64Encode, imageBytes);
    final imageUrl = "data:image/jpeg;base64,$base64Image";

    // List of Vision models to hunt through
    final candidates = [
      'meta-llama/llama-4-scout-17b-16e-instruct',
      'llama-3.2-11b-vision',
      'llama-3.2-90b-vision',
    ];

    Object? lastError;

    for (var modelId in candidates) {
      try {
        debugPrint('🧠 AIService: Hunting Groq ($modelId)...');
        final response = await _dio.post(
          AppConstants.groqApiUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 10),
          ),
          data: {
            'model': modelId,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': AppConstants.getGeminiSystemPrompt(language)},
                  {
                    'type': 'image_url',
                    'image_url': {'url': imageUrl},
                  },
                ],
              },
            ],
          },
        );

        if (response.statusCode == 200) {
          final content = response.data['choices']?[0]?['message']?['content'];
          if (content != null) {
            return await _parseResponse(content.toString());
          }
        }
      } catch (e) {
        lastError = e;
        debugPrint('❌ Hunting failed for $modelId: $e');
        continue;
      }
    }

    throw lastError ?? GeminiException('All Groq candidates failed');
  }

  /// Shared JSON Parser (Runs in Background Isolate)
  Future<List<NutritionResult>> _parseResponse(String text) async {
    debugPrint("🔍 Parsing JSON from: $text");
    try {
      return await compute(_parseNutritionJsonInIsolate, text);
    } catch (e) {
      debugPrint("Parsing Error: $e");
      throw GeminiException('Failed to parse JSON');
    }
  }

  NutritionResult _getFallbackResult([String? errorMessage]) {
    return NutritionResult(
      foodName: errorMessage != null ? 'Error: $errorMessage' : 'Unknown Food',
      portion: 'Unknown portion',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      healthScore: 5,
      insights: [],
    );
  }

  /// Generate Weekly Meal Plan & Grocery List (with AI Hunter)
  Future<PlanGenerationResult?> generateWeeklyMealPlan(
    UserSettings settings,
  ) async {
    final prompt = _buildMealPlanPrompt(settings);
    final apiKey = ConfigService().geminiApiKey;
    if (apiKey.isEmpty) return null;

    // Prioritize ultra-low-cost models first
    final candidates = [
      {'id': 'gemini-1.5-flash-8b', 'ver': 'v1'},
      {'id': 'gemini-1.5-flash', 'ver': 'v1'},
      {'id': 'gemini-2.0-flash', 'ver': 'v1'},
    ];

    for (var candidate in candidates) {
      final modelId = candidate['id']!;
      final apiVer = candidate['ver']!;
      try {
        debugPrint('🍽️ MealPlanner: Hunting $modelId...');
        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/$apiVer/models/$modelId:generateContent?key=$apiKey',
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
              'maxOutputTokens': 4096,
              'temperature': 0.7,
            }, // Reduced from 8192 since meal plan JSON is relatively small
          },
        );
        if (response.statusCode == 200) {
          final text =
              response.data['candidates']?[0]?['content']?['parts']?[0]?['text']
                  as String?;
          if (text != null) {
            return await compute(_parseMealPlanJsonInIsolate, text);
          }
        }
      } catch (e) {
        debugPrint('❌ MealPlanner failed for $modelId: $e');
        continue;
      }
    }
    return null;
  }

  /// Regenerate a single day's meals with context of existing meals
  Future<PlanGenerationResult?> regenerateDay(
    UserSettings settings,
    int dayIndex,
    Map<int, List<Meal>> existingWeeklyMeals,
  ) async {
    final existingMealsContext = <String>[];
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    existingWeeklyMeals.forEach((day, meals) {
      if (day != dayIndex) {
        for (final m in meals) {
          existingMealsContext.add('${m.foodName} (${dayNames[day]})');
        }
      }
    });

    final calorieFloor = settings.gender == 'female' ? 1200 : 1500;
    final safeTarget =
        settings.dailyCalorieGoal < calorieFloor
            ? calorieFloor
            : settings.dailyCalorieGoal;

    final prompt = '''
You are a certified nutrition expert. Generate meals for ONE day only (${dayNames[dayIndex]}).
User: Goal ${settings.goalMode} | $safeTarget kcal | P${settings.dailyProteinGoal}g C${settings.dailyCarbGoal}g F${settings.dailyFatGoal}g
Meals/day: ${settings.mealsPerDay} | Restriction: ${settings.dietaryRestriction} | Cuisine: ${settings.cuisinePreference}
Do NOT repeat: ${existingMealsContext.join(', ')}
Output ONLY valid JSON:
{"week_plan":{"$dayIndex":[{"meal_type":"Breakfast","name":"Name","portion":"1 bowl","calories":400,"protein_g":20,"carbs_g":45,"fat_g":12,"ingredients":["item"],"prep_time_mins":10}]},"grocery_list":[{"name":"Item","amount":"Qty","category":"Produce"}]}
''';

    final apiKey = ConfigService().geminiApiKey;
    if (apiKey.isEmpty) return null;

    // Prioritize ultra-low-cost models
    final candidates = [
      {'id': 'gemini-1.5-flash-8b', 'ver': 'v1'},
      {'id': 'gemini-1.5-flash', 'ver': 'v1'},
      {'id': 'gemini-2.0-flash', 'ver': 'v1'},
    ];

    for (var candidate in candidates) {
      try {
        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/${candidate['ver']}/models/${candidate['id']}:generateContent?key=$apiKey',
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7},
          },
        );
        if (response.statusCode == 200) {
          final text =
              response.data['candidates']?[0]?['content']?['parts']?[0]?['text']
                  as String?;
          if (text != null) {
            return await compute(_parseMealPlanJsonInIsolate, text);
          }
        }
      } catch (e) {
        debugPrint('❌ Regen day failed: $e');
        continue;
      }
    }
    return null;
  }

  String _buildMealPlanPrompt(UserSettings settings) {
    final languageName = languageNames[settings.languageCode] ?? 'English';
    final calorieFloor = settings.gender == 'female' ? 1200 : 1500;
    final safeTarget =
        settings.dailyCalorieGoal < calorieFloor
            ? calorieFloor
            : settings.dailyCalorieGoal;
    return '''
You are a certified nutrition expert. Generate a realistic 7-day meal plan.
STRICT LANGUAGE RULE: YOU MUST RESPOND ENTIRELY IN THE $languageName LANGUAGE. All meal names, descriptions, and ingredients MUST be in $languageName.
Rules:
- Everyday ingredients, practical meals, no chef-level cooking
- Vary meals across 7 days (no repeats on consecutive days)
- ${settings.mealsPerDay} meals per day
- Respect restriction: ${settings.dietaryRestriction}
- Cuisine: ${settings.cuisinePreference}
- NEVER below $calorieFloor kcal/day
- Output ONLY valid JSON

User: Goal ${settings.goalMode} | Gender ${settings.gender ?? 'n/a'} | Age ${settings.age ?? 25}
Weight ${settings.startingWeight ?? 70}kg | Height ${settings.height ?? 170}cm | Activity ${settings.activityLevel ?? 'active'}
Target: $safeTarget kcal | P${settings.dailyProteinGoal}g C${settings.dailyCarbGoal}g F${settings.dailyFatGoal}g

JSON:
{"week_plan":{"0":[{"meal_type":"Breakfast","name":"Oatmeal with Banana","portion":"1 large bowl","calories":420,"protein_g":18,"carbs_g":55,"fat_g":14,"ingredients":["1 cup oats","1 banana","1 tbsp peanut butter"],"prep_time_mins":10}]},"grocery_list":[{"name":"Rolled oats","amount":"500g","category":"Grains"}]}
Keys 0-6 = Monday-Sunday. Each day must have exactly ${settings.mealsPerDay} meals.
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

  static List<NutritionResult> _parseNutritionJsonInIsolate(String text) {
    final String jsonString = _extractJsonStatic(text);
    final jsonResult = jsonDecode(jsonString) as Map<String, dynamic>;

    // New format: {"items": [...]}
    if (jsonResult.containsKey('items') && jsonResult['items'] is List) {
      return (jsonResult['items'] as List)
          .map((item) => NutritionResult.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Backward compat: single object {"food_name": ...}
    return [NutritionResult.fromJson(jsonResult)];
  }

  static PlanGenerationResult _parseMealPlanJsonInIsolate(String text) {
    String jsonString = _extractJsonStatic(text);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    final weekPlanMap = json['week_plan'] as Map<String, dynamic>;
    final Map<int, List<Meal>> weeklyMeals = {};

    weekPlanMap.forEach((key, value) {
      final dayIndex = int.parse(key);
      final List<Meal> mealsList =
          (value as List)
              .map(
                (m) => Meal(
                  id: const Uuid().v4(),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  dateString: 'Day $dayIndex',
                  foodName: m['name'] ?? 'Unnamed Meal',
                  portion: m['portion'] as String? ?? 'Standard portion',
                  calories: _safeInt(m['calories']),
                  macros: Macros(
                    protein: _safeInt(m['protein_g']),
                    carbs: _safeInt(m['carbs_g']),
                    fat: _safeInt(m['fat_g']),
                  ),
                  mealType: m['meal_type'] as String?,
                  ingredients:
                      (m['ingredients'] as List?)
                          ?.map((e) => e.toString())
                          .toList(),
                  prepTimeMins: _safeInt(m['prep_time_mins']),
                ),
              )
              .toList();
      weeklyMeals[dayIndex] = mealsList;
    });

    final plan = MealPlan.createEmpty().copyWith(weeklyMeals: weeklyMeals);

    final groceryListJson = json['grocery_list'] as List? ?? [];
    final groceryList =
        groceryListJson
            .map(
              (item) => GroceryItem(
                name: item['name'] ?? '',
                amount: item['amount'] ?? '',
                category: item['category'] ?? 'Other',
              ),
            )
            .toList();

    return PlanGenerationResult(plan: plan, groceryList: groceryList);
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
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
