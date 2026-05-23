import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      healthScore:
          _safeInt(json['health_score']) == 0
              ? 5
              : _safeInt(json['health_score']),
      insights:
          (json['insights'] as List?)?.map((e) => e.toString()).toList() ?? [],
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

  /// Generate text-only response — Gemini first, Groq as fallback
  Future<String> generateText(String prompt) async {
    // ── Tier 1 & 2: Gemini ──────────────────────────────────────────────
    final geminiKey = ConfigService().geminiApiKey;
    if (geminiKey.isNotEmpty) {
      final candidates = [
        {'id': 'gemini-3.5-flash', 'ver': 'v1beta'},
        {'id': 'gemini-2.5-flash', 'ver': 'v1beta'},
      ];
      for (var candidate in candidates) {
        final modelId = candidate['id']!;
        final apiVer  = candidate['ver']!;
        try {
          final response = await _dio.post(
            'https://generativelanguage.googleapis.com/$apiVer/models/$modelId:generateContent?key=$geminiKey',
            options: Options(
              headers: {'Content-Type': 'application/json'},
              sendTimeout: const Duration(seconds: 15),
            ),
            data: {
              'contents': [
                {
                  'parts': [{'text': prompt}],
                },
              ],
              'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
            },
          );
          if (response.statusCode == 200) {
            final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null) return text;
          }
        } catch (e) {
          debugPrint('❌ generateText Gemini ($modelId): $e');
        }
      }
    }

    // ── Tier 3: Groq (entire Gemini API down) ───────────────────────────
    debugPrint('⚠️ Gemini unavailable — falling back to Groq for text generation');
    return _generateTextWithGroq(prompt, maxTokens: 1024);
  }

  Future<String> generateMealInsight({
    required Meal meal,
    required UserSettings settings,
    required String languageCode,
  }) async {
    final languageName = languageNames[languageCode] ?? 'English';
    final prompt = '''
You are SnapCal's nutrition coach.
RESPOND ENTIRELY IN $languageName.
Give exactly one concise, practical meal improvement insight for this user.
Mention one specific macro or calorie observation and one specific next action.
Do not diagnose medical conditions. Keep it under 28 words.

Meal:
- Name: ${meal.foodName}
- Portion: ${meal.portion ?? 'not provided'}
- Calories: ${meal.calories} kcal
- Protein: ${meal.macros.protein}g
- Carbs: ${meal.macros.carbs}g
- Fat: ${meal.macros.fat}g

User daily targets:
- Calories: ${settings.dailyCalorieGoal} kcal
- Protein: ${settings.dailyProteinGoal}g
- Carbs: ${settings.dailyCarbGoal}g
- Fat: ${settings.dailyFatGoal}g
''';

    try {
      final response = await generateText(prompt);
      final cleaned =
          response
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim()
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .join(' ');
      if (cleaned.isNotEmpty) return cleaned;
    } catch (e) {
      debugPrint('Meal insight generation failed: $e');
    }

    return _fallbackMealInsight(meal, settings, languageCode);
  }

  String _fallbackMealInsight(
    Meal meal,
    UserSettings settings,
    String languageCode,
  ) {
    final proteinGap = settings.dailyProteinGoal - meal.macros.protein;
    switch (languageCode) {
      case 'ar':
        return proteinGap > 25
            ? 'البروتين في هذه الوجبة منخفض لهدفك. أضف مصدراً خفيفاً للبروتين في الوجبة التالية.'
            : 'هذه الوجبة مناسبة أكثر عند موازنتها بخضار أو ماء خلال اليوم.';
      case 'es':
        return proteinGap > 25
            ? 'Esta comida queda baja en proteína para tu meta. Añade una fuente magra en la próxima comida.'
            : 'Esta comida encaja mejor si la equilibras con verduras o agua durante el día.';
      case 'fr':
        return proteinGap > 25
            ? 'Ce repas est faible en protéines pour ton objectif. Ajoute une source maigre au prochain repas.'
            : 'Ce repas s’équilibre mieux avec des légumes ou de l’eau dans la journée.';
      default:
        return proteinGap > 25
            ? 'This meal is light on protein for your goal. Add a lean protein source at your next meal.'
            : 'This meal fits better when balanced with vegetables or water later today.';
    }
  }

  /// Calls backend proxy to analyze food image (Groq/Gemini fallback is handled on the server)
  Future<List<NutritionResult>> analyzeFood(
    Uint8List imageBytes, {
    String language = 'en',
  }) async {
    try {
      debugPrint("Attempting food analysis via backend proxy...");
      final base64Image = await compute(base64Encode, imageBytes);
      final proxyUrl = ConfigService().backendProxyUrl;
      final endpoint = '$proxyUrl${AppConstants.backendScanFoodPath}';

      // Fetch Firebase ID Token for secure backend auth validation
      final user = FirebaseAuth.instance.currentUser;
      String? idToken;
      if (user != null) {
        idToken = await user.getIdToken();
      }

      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (idToken != null) 'Authorization': 'Bearer $idToken',
          },
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
        data: {
          'image': base64Image,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final text = response.data?.toString();
        if (text != null) {
          return await _parseResponse(text);
        }
      }
      throw GeminiException('Backend returned invalid response (status: ${response.statusCode})');
    } catch (e) {
      final errorDetail = _extractDioError(e);
      debugPrint("Proxy scan failed: $errorDetail");
      throw GeminiException("AI Scan failed via proxy: $errorDetail");
    }
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

  /// Generate Weekly Meal Plan & Grocery List
  /// Chain: Gemini 3.5-flash → Gemini 2.5-flash → Groq 70b → Groq 8b → null (static fallback)
  Future<PlanGenerationResult?> generateWeeklyMealPlan(
    UserSettings settings,
  ) async {
    final prompt = _buildMealPlanPrompt(settings);

    // ── Tier 1 & 2: Gemini ──────────────────────────────────────────────
    final geminiKey = ConfigService().geminiApiKey;
    if (geminiKey.isNotEmpty) {
      final candidates = [
        {'id': 'gemini-3.5-flash', 'ver': 'v1beta'},
        {'id': 'gemini-2.5-flash', 'ver': 'v1beta'},
      ];
      for (var candidate in candidates) {
        final modelId = candidate['id']!;
        final apiVer  = candidate['ver']!;
        try {
          debugPrint('🍽️ MealPlanner: trying Gemini $modelId...');
          final response = await _dio.post(
            'https://generativelanguage.googleapis.com/$apiVer/models/$modelId:generateContent?key=$geminiKey',
            options: Options(headers: {'Content-Type': 'application/json'}),
            data: {
              'contents': [
                {
                  'parts': [{'text': prompt}],
                },
              ],
              'generationConfig': {'maxOutputTokens': 4096, 'temperature': 0.7},
            },
          );
          if (response.statusCode == 200) {
            final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null) return await compute(_parseMealPlanJsonInIsolate, text);
          }
        } catch (e) {
          debugPrint('❌ MealPlanner Gemini ($modelId) failed: $e');
        }
      }
    }

    // ── Tier 3 & 4: Groq (entire Gemini API down) ───────────────────────
    debugPrint('⚠️ Gemini down — falling back to Groq for meal plan');
    try {
      final groqText = await _generateTextWithGroq(prompt, maxTokens: 4096);
      return await compute(_parseMealPlanJsonInIsolate, groqText);
    } catch (e) {
      debugPrint('❌ MealPlanner Groq also failed: $e');
    }

    return null; // Provider will use static fallback plan
  }

  /// Regenerate a single day's meals
  /// Chain: Gemini 3.5-flash → Gemini 2.5-flash → Groq 70b → Groq 8b → null
  Future<PlanGenerationResult?> regenerateDay(
    UserSettings settings,
    int dayIndex,
    Map<int, List<Meal>> existingWeeklyMeals,
  ) async {
    final existingMealsContext = <String>[];
    final languageName = languageNames[settings.languageCode] ?? 'English';
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    existingWeeklyMeals.forEach((day, meals) {
      if (day != dayIndex) {
        for (final m in meals) {
          existingMealsContext.add('${m.foodName} (${dayNames[day]})');
        }
      }
    });

    final calorieFloor = settings.gender == 'female' ? 1200 : 1500;
    final safeTarget = settings.dailyCalorieGoal < calorieFloor
        ? calorieFloor
        : settings.dailyCalorieGoal;

    final prompt = '''
You are a certified nutrition expert. Generate meals for ONE day only (${dayNames[dayIndex]}).
STRICT LANGUAGE RULE: YOU MUST RESPOND ENTIRELY IN THE $languageName LANGUAGE. All meal types, meal names, portions, ingredients, grocery item names, and grocery categories MUST be in $languageName.
User: Goal ${settings.goalMode} | $safeTarget kcal | P${settings.dailyProteinGoal}g C${settings.dailyCarbGoal}g F${settings.dailyFatGoal}g
Meals/day: ${settings.mealsPerDay} | Restriction: ${settings.dietaryRestriction} | Cuisine: ${settings.cuisinePreference}
Do NOT repeat: ${existingMealsContext.join(', ')}
Output ONLY valid JSON:
{"week_plan":{"$dayIndex":[{"meal_type":"Breakfast","name":"Name","portion":"1 bowl","calories":400,"protein_g":20,"carbs_g":45,"fat_g":12,"ingredients":["item"],"prep_time_mins":10}]},"grocery_list":[{"name":"Item","amount":"Qty","category":"Produce"}]}
''';

    // ── Tier 1 & 2: Gemini ──────────────────────────────────────────────
    final geminiKey = ConfigService().geminiApiKey;
    if (geminiKey.isNotEmpty) {
      final candidates = [
        {'id': 'gemini-3.5-flash', 'ver': 'v1beta'},
        {'id': 'gemini-2.5-flash', 'ver': 'v1beta'},
      ];
      for (var candidate in candidates) {
        try {
          final response = await _dio.post(
            'https://generativelanguage.googleapis.com/${candidate['ver']}/models/${candidate['id']}:generateContent?key=$geminiKey',
            options: Options(headers: {'Content-Type': 'application/json'}),
            data: {
              'contents': [
                {
                  'parts': [{'text': prompt}],
                },
              ],
              'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7},
            },
          );
          if (response.statusCode == 200) {
            final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null) return await compute(_parseMealPlanJsonInIsolate, text);
          }
        } catch (e) {
          debugPrint('❌ Regen day Gemini (${candidate['id']}) failed: $e');
        }
      }
    }

    // ── Tier 3 & 4: Groq (entire Gemini API down) ───────────────────────
    debugPrint('⚠️ Gemini down — falling back to Groq for day regen');
    try {
      final groqText = await _generateTextWithGroq(prompt, maxTokens: 1024);
      return await compute(_parseMealPlanJsonInIsolate, groqText);
    } catch (e) {
      debugPrint('❌ Regen day Groq also failed: $e');
    }

    return null;
  }

  /// Tier 3 & 4: Generate text via Groq when Gemini is unavailable.
  /// Tries llama-3.3-70b-versatile first, then llama-3.1-8b-instant.
  Future<String> _generateTextWithGroq(
    String prompt, {
    int maxTokens = 1024,
  }) async {
    final apiKey = ConfigService().groqApiKey;
    if (apiKey.isEmpty) throw GeminiException('Groq API key missing');

    // 70b = better quality for structured JSON; 8b = faster, higher rate limits
    final models = [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
    ];

    Object? lastError;

    for (final model in models) {
      try {
        debugPrint('🦙 Groq text fallback: trying $model...');
        final response = await _dio.post(
          AppConstants.groqApiUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 20),
          ),
          data: {
            'model': model,
            'messages': [
              {
                'role': 'user',
                'content': prompt,
              },
            ],
            'max_tokens': maxTokens,
            'temperature': 0.7,
          },
        );

        if (response.statusCode == 200) {
          final content =
              response.data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            debugPrint('✅ Groq $model succeeded');
            return content;
          }
        }
      } catch (e) {
        lastError = e;
        debugPrint('❌ Groq $model failed: $e');
      }
    }

    throw lastError ?? GeminiException('All Groq text candidates failed');
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

    // Anchor all dates to the start of the current week (today's Monday)
    final now = DateTime.now();
    final weekdayOffset = now.weekday - 1; // Mon=0
    final weekStart = DateTime(now.year, now.month, now.day - weekdayOffset);

    weekPlanMap.forEach((key, value) {
      int? dayIndex = int.tryParse(key);
      if (dayIndex == null) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('mon')) {
          dayIndex = 0;
        } else if (lowerKey.contains('tue')) {
          dayIndex = 1;
        } else if (lowerKey.contains('wed')) {
          dayIndex = 2;
        } else if (lowerKey.contains('thu')) {
          dayIndex = 3;
        } else if (lowerKey.contains('fri')) {
          dayIndex = 4;
        } else if (lowerKey.contains('sat')) {
          dayIndex = 5;
        } else if (lowerKey.contains('sun')) {
          dayIndex = 6;
        }
      }
      if (dayIndex == null) return;

      final dayDate = weekStart.add(Duration(days: dayIndex));
      final dateStr =
          '${dayDate.year.toString().padLeft(4, '0')}-'
          '${dayDate.month.toString().padLeft(2, '0')}-'
          '${dayDate.day.toString().padLeft(2, '0')}';

      final mealsList = (value as List).asMap().entries.map((entry) {
        final mealIndex = entry.key;
        final m = entry.value as Map<String, dynamic>;
        // Give each meal a realistic time: 8am, 11am, 2pm, 5pm, 8pm
        final mealHour = 8 + (mealIndex * 3);
        final mealTimestamp = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          mealHour,
        ).millisecondsSinceEpoch;

        return Meal(
          id: const Uuid().v4(),
          timestamp: mealTimestamp,
          dateString: dateStr,
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
              (m['ingredients'] as List?)?.map((e) => e.toString()).toList(),
          prepTimeMins: _safeInt(m['prep_time_mins']),
          synced: true,
          scanSource: 'meal_planner',
        );
      }).toList();

      weeklyMeals[dayIndex] = mealsList;
    });

    final plan = MealPlan.createEmpty(
      start: weekStart,
    ).copyWith(weeklyMeals: weeklyMeals);

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
