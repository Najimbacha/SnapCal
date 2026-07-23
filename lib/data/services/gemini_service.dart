import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/resilience/timeout_policy.dart';
import '../../core/services/config_service.dart';
import '../../core/utils/image_utils.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../models/grocery_item.dart';
import '../models/user_settings.dart';

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
  final List<String> alternatives;

  // v2 fields (nullable for backward compat)
  final double? weightG;
  final double? confidence;
  final String? nutritionMatchId;
  final bool matched;
  final Map<String, dynamic>? nutritionPer100g;
  final Map<String, dynamic>? nutritionActual;

  NutritionResult({
    required this.foodName,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.healthScore = 5,
    this.insights = const [],
    this.alternatives = const [],
    this.weightG,
    this.confidence,
    this.nutritionMatchId,
    this.matched = true,
    this.nutritionPer100g,
    this.nutritionActual,
  });

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    final healthScore = _safeInt(json['health_score']);

    // Extract v2 nested nutrition if present
    final Map<String, dynamic>? nutrition =
        json['nutrition'] is Map ? Map<String, dynamic>.from(json['nutrition']) : null;
    final Map<String, dynamic>? per100g =
        nutrition?['per100g'] is Map ? Map<String, dynamic>.from(nutrition!['per100g']) : null;
    final Map<String, dynamic>? actual =
        nutrition?['actual'] is Map ? Map<String, dynamic>.from(nutrition!['actual']) : null;

    // Use v2 nutrition.actual values if available and top-level values are null
    final int calories;
    final int protein;
    final int carbs;
    final int fat;

    if (actual != null) {
      calories = _safeInt(actual['calories']).clamp(0, 5000);
      protein = _safeInt(actual['protein']).clamp(0, 500);
      carbs = _safeInt(actual['carbs']).clamp(0, 800);
      fat = _safeInt(actual['fat']).clamp(0, 500);
    } else {
      calories = _safeInt(json['calories']).clamp(0, 5000);
      protein = _safeInt(json['protein']).clamp(0, 500);
      carbs = _safeInt(json['carbs']).clamp(0, 800);
      fat = _safeInt(json['fat']).clamp(0, 500);
    }

    final bool matched = json['matched'] == true || (json['matched'] != false && (actual != null || (json['calories'] != null && _safeInt(json['calories']) > 0)));

    return NutritionResult(
      foodName: _safeText(json['food_name'], 'Unknown Food'),
      portion: _safeText(json['portion'], 'Standard portion'),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      healthScore: healthScore == 0 ? 5 : healthScore.clamp(1, 10),
      insights:
          (json['insights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      alternatives:
          (json['alternatives'] as List?)?.map((e) => e.toString()).toList() ?? [],
      weightG: (json['weight_g'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      nutritionMatchId: json['nutrition_match_id']?.toString(),
      matched: matched,
      nutritionPer100g: per100g,
      nutritionActual: actual,
    );
  }

  static String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
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
  AIService._internal() : _dio = ApiClient.dio;

  final Dio _dio;

  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
  };

  /// Generate text-only response — Gemini first, Groq as fallback
  Future<String> generateText(String prompt) async {
    return _generateTextViaBackend(prompt, maxOutputTokens: 1024);
  }

  Future<String> _generateTextViaBackend(
    String prompt, {
    int maxOutputTokens = 2048,
    String? responseMimeType,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final endpoint = '${ConfigService().backendProxyUrl}/api/ai/text';
    final response = await _dio.post(
      endpoint,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: timeout,
      ),
      data: {
        'prompt': prompt,
        'maxOutputTokens': maxOutputTokens,
        if (responseMimeType != null) 'responseMimeType': responseMimeType,
        'timeoutMs': timeout.inMilliseconds,
      },
    );
    final text = response.data is Map ? response.data['text'] as String? : null;
    if (text == null || text.isEmpty) {
      throw GeminiException('Backend returned an empty AI response');
    }
    return text;
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
      final cleaned = response
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
    if (FirebaseAuth.instance.currentUser == null) {
      throw GeminiException('Please sign in before scanning food.');
    }
    final bytes = await ImageUtils.compressImageBytesAsync(imageBytes);
    if (bytes.length > AppConstants.maxImageUploadBytes) {
      throw GeminiException('Image is too large to upload safely.');
    }
    final base64Image = await compute(base64Encode, bytes);
    final proxyUrl = ConfigService().backendProxyUrl;

    try {
      final response = await _dio.post(
        '$proxyUrl/v1/scan',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: TimeoutPolicy.aiScan,
        ),
        data: {'image': base64Image, 'language': language},
      );
      if (response.statusCode != 200) {
        final body = response.data is Map ? jsonEncode(response.data) : response.data.toString();
        debugPrint('❌ Scan failed: status=${response.statusCode}, body=$body');
        throw GeminiException('Scan failed (status: ${response.statusCode}): $body');
      }
      final text = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      return _parseResponse(text);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data is Map ? jsonEncode(e.response?.data) : e.response?.data.toString();
      debugPrint('❌ Scan DioException: type=${e.type}, status=$status, body=$body');
      rethrow;
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
    UserSettings settings, {
    String prepTimePreference = 'balanced',
    String budgetPreference = 'standard',
  }) async {
    final prompt = _buildMealPlanPrompt(
      settings,
      prepTimePreference: prepTimePreference,
      budgetPreference: budgetPreference,
    );
    try {
      final text = await _generateTextViaBackend(
        prompt,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
        timeout: const Duration(seconds: 55),
      );
      return await compute(_parseMealPlanJsonInIsolate, text);
    } catch (e) {
      debugPrint('❌ MealPlanner backend failed: $e');
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
STRICT LANGUAGE RULE: YOU MUST RESPOND ENTIRELY IN THE $languageName LANGUAGE. All meal types, meal names, portions, ingredients, grocery item names, and grocery categories MUST be in $languageName.
User: Goal ${settings.goalMode} | $safeTarget kcal | P${settings.dailyProteinGoal}g C${settings.dailyCarbGoal}g F${settings.dailyFatGoal}g
Meals/day: ${settings.mealsPerDay} | Restriction: ${settings.dietaryRestriction} | Cuisine: ${settings.cuisinePreference}
Do NOT repeat: ${existingMealsContext.join(', ')}
Output ONLY valid JSON:
{"week_plan":{"$dayIndex":[{"meal_type":"Breakfast","name":"Name","portion":"1 bowl","calories":400,"protein_g":20,"carbs_g":45,"fat_g":12,"ingredients":["item"],"prep_time_mins":10}]},"grocery_list":[{"name":"Item","amount":"Qty","category":"Produce"}]}
''';
    try {
      final text = await _generateTextViaBackend(
        prompt,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
      );
      return await compute(_parseMealPlanJsonInIsolate, text);
    } catch (e) {
      debugPrint('❌ Regen day backend failed: $e');
    }

    return null;
  }

  /// Regenerate a single meal
  /// Chain: Backend proxy → null
  Future<Meal?> regenerateSingleMeal(
    UserSettings settings,
    Meal oldMeal,
    List<Meal> existingMealsInPlan, {
    String? craving,
    String? swapIntent,
  }) async {
    final existingMealsContext =
        existingMealsInPlan.map((m) => m.foodName).toSet().toList();
    final languageName = languageNames[settings.languageCode] ?? 'English';
    final cravingInstruction =
        (craving != null && craving.trim().isNotEmpty)
            ? '\n- STRICT CRITICAL RULE: The alternative meal MUST match this user craving/preference: "$craving".'
            : '';
    final intentInstruction = _swapIntentInstruction(swapIntent);

    final prompt = '''
You are a certified nutrition expert. Generate ONE alternative meal to replace this meal: "${oldMeal.foodName}" (${oldMeal.mealType ?? 'Meal'}).
STRICT LANGUAGE RULE: YOU MUST RESPOND ENTIRELY IN THE $languageName LANGUAGE. All meal types, meal names, portions, ingredients, grocery item names, and grocery categories MUST be in $languageName.
Rules:
- Keep the meal practical and nutritionally valid: Current Calories: ${oldMeal.calories} kcal, Protein: ${oldMeal.macros.protein}g, Carbs: ${oldMeal.macros.carbs}g, Fat: ${oldMeal.macros.fat}g.
$intentInstruction$cravingInstruction
- Everyday ingredients, practical meals, no chef-level cooking.
- Include one short "ai_rationale" sentence explaining why this replacement fits.
- Do NOT repeat the old meal: "${oldMeal.foodName}" or any of these existing meals in the plan: ${existingMealsContext.join(', ')}.
- Output ONLY valid JSON of this exact structure:
{"meal_type":"${oldMeal.mealType ?? 'Breakfast'}","name":"Alternative Meal Name","portion":"1 portion","calories":400,"protein_g":20,"carbs_g":45,"fat_g":12,"ingredients":["item 1","item 2"],"prep_time_mins":15,"ai_rationale":"One concise sentence."}
''';
    try {
      final text = await _generateTextViaBackend(
        prompt,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
      );
      return await compute(_parseSingleMealJsonInIsolate, text);
    } catch (e) {
      debugPrint('❌ Swap Meal backend failed: $e');
    }

    return null;
  }

  String _buildMealPlanPrompt(
    UserSettings settings, {
    String prepTimePreference = 'balanced',
    String budgetPreference = 'standard',
  }) {
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
- Prep time preference: ${_plannerPrepTimeInstruction(prepTimePreference)}
- Budget preference: ${_plannerBudgetInstruction(budgetPreference)}
- Include one short "ai_rationale" sentence for every meal.
- NEVER below $calorieFloor kcal/day
- Output ONLY valid JSON

User: Goal ${settings.goalMode} | Gender ${settings.gender ?? 'n/a'} | Age ${settings.age ?? 25}
Weight ${settings.startingWeight ?? 70}kg | Height ${settings.height ?? 170}cm | Activity ${settings.activityLevel ?? 'active'}
Target: $safeTarget kcal | P${settings.dailyProteinGoal}g C${settings.dailyCarbGoal}g F${settings.dailyFatGoal}g

JSON:
{"week_plan":{"0":[{"meal_type":"Breakfast","name":"Oatmeal with Banana","portion":"1 large bowl","calories":420,"protein_g":18,"carbs_g":55,"fat_g":14,"ingredients":["1 cup oats","1 banana","1 tbsp peanut butter"],"prep_time_mins":10,"ai_rationale":"Fits your morning calories with steady carbs and protein."}]},"grocery_list":[{"name":"Rolled oats","amount":"500g","category":"Grains"}]}
Keys 0-6 = Day 1 to Day 7. Each day must have exactly ${settings.mealsPerDay} meals.
''';
  }

  String _plannerPrepTimeInstruction(String value) {
    switch (value) {
      case 'quick':
        return 'favor meals that take 15 minutes or less';
      case 'batch':
        return 'favor meals that can be batch-prepped or reused efficiently';
      case 'balanced':
      default:
        return 'keep cooking effort practical for everyday use';
    }
  }

  String _plannerBudgetInstruction(String value) {
    switch (value) {
      case 'budget':
        return 'prioritize lower-cost pantry staples and common ingredients';
      case 'premium':
        return 'allow higher-quality ingredients while staying realistic';
      case 'standard':
      default:
        return 'balance value, quality, and availability';
    }
  }

  String _swapIntentInstruction(String? value) {
    switch (value) {
      case 'lower_calorie':
        return '- Swap intent: make the replacement lower calorie than the original while preserving meal type.';
      case 'higher_protein':
        return '- Swap intent: make the replacement higher in protein density than the original.';
      case 'faster_prep':
        return '- Swap intent: make the replacement take 15 minutes or less.';
      case 'cheaper':
        return '- Swap intent: use common low-cost ingredients and avoid premium items.';
      default:
        return '- Swap intent: keep a similar calorie and macro profile.';
    }
  }

  // --- Static/Top-Level Functions for Compute ---

  static List<NutritionResult> _parseNutritionJsonInIsolate(String text) {
    final String jsonString = _extractJsonStatic(text);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw const FormatException('Nutrition response must be a JSON object.');
    }
    final jsonResult = Map<String, dynamic>.from(decoded);

    // v2 response from enrichScanResults: {"items": [...]}
    if (jsonResult.containsKey('items') && jsonResult['items'] is List) {
      final parsed =
          (jsonResult['items'] as List)
              .whereType<Map>()
              .map(
                (item) =>
                    NutritionResult.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
      if (parsed.isEmpty) {
        throw const FormatException('Nutrition response contained no items.');
      }
      return parsed;
    }

    // v2 food detection raw: {"foods": [...]}
    if (jsonResult.containsKey('foods') && jsonResult['foods'] is List) {
      final foods = jsonResult['foods'] as List;
      // This is the raw AI detection response (before enrichment).
      // The backend should have enriched this already, but handle defensively.
      final parsed = foods.whereType<Map>().map((food) {
        final name = food['name']?.toString() ?? 'Unknown Food';
        final weight = (food['estimated_weight_g'] ?? food['weight_g'] ?? 0);
        return NutritionResult(
          foodName: name,
          portion: weight > 0 ? '${weight}g' : 'Unknown',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          weightG: (weight as num?)?.toDouble(),
          confidence: (food['confidence'] as num?)?.toDouble(),
          matched: false,
          nutritionPer100g: null,
          nutritionActual: null,
        );
      }).toList();
      if (parsed.isEmpty) {
        throw const FormatException('Nutrition response contained no items.');
      }
      return parsed;
    }

    // Backward compat: single object {"food_name": ...}
    return [NutritionResult.fromJson(jsonResult)];
  }

  static PlanGenerationResult _parseMealPlanJsonInIsolate(String text) {
    String jsonString = _extractJsonStatic(text);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw const FormatException('Meal plan response must be a JSON object.');
    }
    final json = Map<String, dynamic>.from(decoded);

    final rawWeekPlan = json['week_plan'];
    if (rawWeekPlan is! Map) {
      throw const FormatException('Meal plan response missing week_plan.');
    }
    final weekPlanMap = Map<String, dynamic>.from(rawWeekPlan);
    final Map<int, List<Meal>> weeklyMeals = {};

    // Anchor dates starting from today
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day);

    weekPlanMap.forEach((key, value) {
      int? dayIndex = int.tryParse(key);
      if (dayIndex == null) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('day 1')) {
          dayIndex = 0;
        } else if (lowerKey.contains('day 2')) {
          dayIndex = 1;
        } else if (lowerKey.contains('day 3')) {
          dayIndex = 2;
        } else if (lowerKey.contains('day 4')) {
          dayIndex = 3;
        } else if (lowerKey.contains('day 5')) {
          dayIndex = 4;
        } else if (lowerKey.contains('day 6')) {
          dayIndex = 5;
        } else if (lowerKey.contains('day 7')) {
          dayIndex = 6;
        }
      }
      if (dayIndex == null) return;

      final dayDate = weekStart.add(Duration(days: dayIndex));
      final dateStr =
          '${dayDate.year.toString().padLeft(4, '0')}-'
          '${dayDate.month.toString().padLeft(2, '0')}-'
          '${dayDate.day.toString().padLeft(2, '0')}';

      if (value is! List) return;
      final mealsList =
          value.whereType<Map>().toList().asMap().entries.map((entry) {
            final mealIndex = entry.key;
            final m = Map<String, dynamic>.from(entry.value);
            // Give each meal a realistic time: 8am, 11am, 2pm, 5pm, 8pm
            final mealHour = 8 + (mealIndex * 3);
            final mealTimestamp =
                DateTime(
                  dayDate.year,
                  dayDate.month,
                  dayDate.day,
                  mealHour,
                ).millisecondsSinceEpoch;

            return Meal(
              id: const Uuid().v4(),
              timestamp: mealTimestamp,
              dateString: dateStr,
              foodName: _safeString(m['name'], 'Unnamed Meal'),
              portion: _safeString(m['portion'], 'Standard portion'),
              calories: _safeInt(m['calories']).clamp(0, 5000),
              macros: Macros(
                protein: _safeInt(m['protein_g']).clamp(0, 500),
                carbs: _safeInt(m['carbs_g']).clamp(0, 800),
                fat: _safeInt(m['fat_g']).clamp(0, 500),
              ),
              mealType: m['meal_type']?.toString(),
              ingredients:
                  (m['ingredients'] as List?)
                      ?.map((e) => e.toString())
                      .toList(),
              prepTimeMins: _safeInt(m['prep_time_mins']),
              aiRationale: m['ai_rationale']?.toString(),
              synced: true,
              scanSource: 'meal_planner',
            );
          }).toList();

      weeklyMeals[dayIndex] = mealsList;
    });
    if (weeklyMeals.isEmpty) {
      throw const FormatException('Meal plan response contained no meals.');
    }

    final plan = MealPlan.createEmpty(
      start: weekStart,
    ).copyWith(weeklyMeals: weeklyMeals);

    final groceryListJson = json['grocery_list'] as List? ?? [];
    final parsedGroceryList =
        groceryListJson
            .whereType<Map>()
            .map(
              (item) => GroceryItem(
                name: _safeString(item['name'], ''),
                amount: _safeString(item['amount'], ''),
                category: _safeString(item['category'], 'Other'),
              ),
            )
            .where((item) => item.name.trim().isNotEmpty)
            .toList();
    final groceryList =
        parsedGroceryList.isNotEmpty
            ? parsedGroceryList
            : _buildGroceryListFromMeals(weeklyMeals);

    return PlanGenerationResult(plan: plan, groceryList: groceryList);
  }

  static List<GroceryItem> _buildGroceryListFromMeals(
    Map<int, List<Meal>> weeklyMeals,
  ) {
    final grouped = <String, ({String name, String amount})>{};

    for (final meal in weeklyMeals.values.expand((meals) => meals)) {
      for (final rawIngredient in meal.ingredients ?? const <String>[]) {
        final parsed = _parseIngredientStatic(rawIngredient);
        final normalized = parsed.name.toLowerCase();
        if (normalized.isEmpty || grouped.containsKey(normalized)) continue;
        grouped[normalized] = parsed;
      }
    }

    return grouped.values
        .map(
          (item) => GroceryItem(
            name: item.name,
            amount: item.amount,
            category: 'Other',
          ),
        )
        .toList();
  }

  static ({String name, String amount}) _parseIngredientStatic(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (name: '', amount: '');

    final firstSpace = trimmed.indexOf(' ');
    if (firstSpace == -1) return (name: trimmed, amount: '');

    final firstToken = trimmed.substring(0, firstSpace);
    final remaining = trimmed.substring(firstSpace + 1).trim();
    final looksLikeQuantity =
        RegExp(r'^[0-9¼½¾⅓⅔⅛\-./]+$').hasMatch(firstToken) ||
        {
          'a',
          'an',
          'few',
          'some',
          'one',
          'two',
          'three',
          '1',
          '2',
          '3',
        }.contains(firstToken.toLowerCase());

    if (looksLikeQuantity && remaining.isNotEmpty) {
      return (name: remaining, amount: firstToken);
    }
    return (name: trimmed, amount: '');
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _safeString(dynamic value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String _extractJsonStatic(String rawResponse) {
    final regex = RegExp(r'\{[\s\S]*\}');
    final match = regex.firstMatch(rawResponse);
    if (match != null) {
      return match.group(0)!;
    }
    throw GeminiException('No JSON found in response');
  }

  static Meal _parseSingleMealJsonInIsolate(String text) {
    final String jsonString = _extractJsonStatic(text);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw const FormatException('Meal response must be a JSON object.');
    }
    final m = Map<String, dynamic>.from(decoded);
    return Meal(
      id: const Uuid().v4(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      dateString: '',
      foodName: _safeString(m['name'], 'Unnamed Meal'),
      portion: _safeString(m['portion'], 'Standard portion'),
      calories: _safeInt(m['calories']).clamp(0, 5000),
      macros: Macros(
        protein: _safeInt(m['protein_g']).clamp(0, 500),
        carbs: _safeInt(m['carbs_g']).clamp(0, 800),
        fat: _safeInt(m['fat_g']).clamp(0, 500),
      ),
      mealType: m['meal_type']?.toString(),
      ingredients:
          (m['ingredients'] as List?)?.map((e) => e.toString()).toList(),
      prepTimeMins: _safeInt(m['prep_time_mins']),
      synced: true,
      scanSource: 'meal_planner_swap',
      aiRationale: m['ai_rationale']?.toString(),
    );
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
