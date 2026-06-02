import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../data/models/grocery_item.dart';
import '../data/models/meal.dart';
import '../data/models/meal_plan.dart';
import '../data/models/user_settings.dart';
import '../data/services/gemini_service.dart';
import '../core/state/async_ui_state.dart';
import 'settings_provider.dart';
import '../l10n/generated/app_localizations.dart';

class PlannerProvider with ChangeNotifier {
  static const String _planBoxName = 'meal_plan_box';
  static const String _groceryBoxName = 'grocery_list_box';

  final AIService _aiService;
  SettingsProvider _settingsProvider;

  Box<MealPlan>? _planBox;
  Box<GroceryItem>? _groceryBox;

  MealPlan? _currentPlan;
  List<GroceryItem> _groceryList = [];
  final Set<String> _loggedPlannedMealIds = {};
  String _prepTimePreference = 'balanced';
  String _budgetPreference = 'standard';
  late int _syncedCalorieGoal;
  late int _syncedProteinGoal;
  late int _syncedCarbGoal;
  late int _syncedFatGoal;

  // Shown when AI fails and fallback plan is used instead
  String? _fallbackNotice;
  String? get fallbackNotice => _fallbackNotice;
  String? _rebalanceNotice;
  String? get rebalanceNotice => _rebalanceNotice;
  void clearFallbackNotice() {
    _fallbackNotice = null;
    notifyListeners();
  }

  void clearRebalanceNotice() {
    _rebalanceNotice = null;
    notifyListeners();
  }

  AsyncUiState _uiState = const AsyncUiState.loading();
  bool get isLoading => _uiState.isBlocking;
  bool get isRefreshing => _uiState.isRefreshing;
  AsyncUiState get uiState => _uiState;
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;
  bool _isRegenerating = false;
  bool get isRegenerating => _isRegenerating;
  bool _isSwappingMeal = false;
  bool get isSwappingMeal => _isSwappingMeal;
  bool _isRebalancing = false;
  bool get isRebalancing => _isRebalancing;
  String? _error;
  String? get error => _error;
  int _regenCountThisWeek = 0;
  int get regenCountThisWeek => _regenCountThisWeek;
  String get _languageCode {
    final code = _settingsProvider.languageCode;
    return AppLocalizations.supportedLocales.any(
          (locale) => locale.languageCode == code,
        )
        ? code
        : 'en';
  }

  AppLocalizations get _l10n => lookupAppLocalizations(Locale(_languageCode));
  String get _timeoutMessage => switch (_languageCode) {
    'ar' => 'انتهت مهلة الطلب. حاول مرة أخرى.',
    'es' => 'La solicitud agotó el tiempo. Inténtalo de nuevo.',
    'fr' => 'La demande a expiré. Réessayez.',
    _ => 'Request timed out. Please try again.',
  };

  void updateSettings(SettingsProvider settings) {
    final nutritionChanged = _hasNutritionGoalChange(settings);
    _settingsProvider = settings;
    _captureNutritionGoals(settings);

    if (nutritionChanged && _currentPlan != null) {
      unawaited(_syncCurrentPlanNutritionToSettings());
      return;
    }

    notifyListeners();
  }

  MealPlan? get currentPlan => _currentPlan;
  bool get isCurrentPlanExpired {
    final plan = _currentPlan;
    if (plan == null) return false;
    final today = _dateOnly(DateTime.now());
    final end = _dateOnly(plan.endDate);
    return today.isAfter(end);
  }

  bool get currentPlanContainsToday {
    final plan = _currentPlan;
    if (plan == null) return false;
    final today = _dateOnly(DateTime.now());
    final start = _dateOnly(plan.startDate);
    final end = _dateOnly(plan.endDate);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  int? get currentPlanTodayIndex {
    final plan = _currentPlan;
    if (plan == null || !currentPlanContainsToday) return null;
    return _dateOnly(
      DateTime.now(),
    ).difference(_dateOnly(plan.startDate)).inDays;
  }

  List<GroceryItem> get groceryList => _groceryList;
  Set<String> get loggedPlannedMealIds =>
      Set.unmodifiable(_loggedPlannedMealIds);
  String get prepTimePreference => _prepTimePreference;
  String get budgetPreference => _budgetPreference;

  PlannerProvider(this._aiService, this._settingsProvider) {
    _captureNutritionGoals(_settingsProvider);
    _init();
  }

  bool _hasNutritionGoalChange(SettingsProvider settings) {
    return settings.dailyCalorieGoal != _syncedCalorieGoal ||
        settings.dailyProteinGoal != _syncedProteinGoal ||
        settings.dailyCarbGoal != _syncedCarbGoal ||
        settings.dailyFatGoal != _syncedFatGoal;
  }

  void _captureNutritionGoals(SettingsProvider settings) {
    _syncedCalorieGoal = settings.dailyCalorieGoal;
    _syncedProteinGoal = settings.dailyProteinGoal;
    _syncedCarbGoal = settings.dailyCarbGoal;
    _syncedFatGoal = settings.dailyFatGoal;
  }

  Future<void> _syncCurrentPlanNutritionToSettings() async {
    final plan = _currentPlan;
    if (plan == null || _isGenerating || _isRegenerating || _isSwappingMeal) {
      notifyListeners();
      return;
    }

    final updatedMeals = <int, List<Meal>>{};
    for (final entry in plan.weeklyMeals.entries) {
      updatedMeals[entry.key] = _scalePlannedMealsToDailyTargets(entry.value);
    }

    _currentPlan = plan.copyWith(weeklyMeals: updatedMeals);
    await _planBox?.put('current', _currentPlan!);
    notifyListeners();
  }

  List<Meal> _scalePlannedMealsToDailyTargets(List<Meal> meals) {
    if (meals.isEmpty) return meals;

    final originalCalories = meals
        .fold<int>(0, (sum, meal) => sum + meal.calories)
        .clamp(1, 99999);
    final originalProtein = meals
        .fold<int>(0, (sum, meal) => sum + meal.macros.protein)
        .clamp(1, 99999);
    final originalCarbs = meals
        .fold<int>(0, (sum, meal) => sum + meal.macros.carbs)
        .clamp(1, 99999);
    final originalFat = meals
        .fold<int>(0, (sum, meal) => sum + meal.macros.fat)
        .clamp(1, 99999);

    var allocatedCalories = 0;
    var allocatedProtein = 0;
    var allocatedCarbs = 0;
    var allocatedFat = 0;

    return List.generate(meals.length, (index) {
      final meal = meals[index];
      final isLast = index == meals.length - 1;
      final calories =
          isLast
              ? (_settingsProvider.dailyCalorieGoal - allocatedCalories)
                  .clamp(0, 5000)
                  .toInt()
              : ((_settingsProvider.dailyCalorieGoal * meal.calories) /
                      originalCalories)
                  .round();
      final protein =
          isLast
              ? (_settingsProvider.dailyProteinGoal - allocatedProtein)
                  .clamp(0, 350)
                  .toInt()
              : ((_settingsProvider.dailyProteinGoal * meal.macros.protein) /
                      originalProtein)
                  .round();
      final carbs =
          isLast
              ? (_settingsProvider.dailyCarbGoal - allocatedCarbs)
                  .clamp(0, 600)
                  .toInt()
              : ((_settingsProvider.dailyCarbGoal * meal.macros.carbs) /
                      originalCarbs)
                  .round();
      final fat =
          isLast
              ? (_settingsProvider.dailyFatGoal - allocatedFat)
                  .clamp(0, 250)
                  .toInt()
              : ((_settingsProvider.dailyFatGoal * meal.macros.fat) /
                      originalFat)
                  .round();

      allocatedCalories += calories;
      allocatedProtein += protein;
      allocatedCarbs += carbs;
      allocatedFat += fat;

      return meal.copyWith(
        calories: calories,
        macros: Macros(protein: protein, carbs: carbs, fat: fat),
      );
    });
  }

  Future<void> _init() async {
    try {
      if (!Hive.isBoxOpen(_planBoxName)) {
        _planBox = await Hive.openBox<MealPlan>(_planBoxName);
      } else {
        _planBox = Hive.box<MealPlan>(_planBoxName);
      }

      if (!Hive.isBoxOpen(_groceryBoxName)) {
        _groceryBox = await Hive.openBox<GroceryItem>(_groceryBoxName);
      } else {
        _groceryBox = Hive.box<GroceryItem>(_groceryBoxName);
      }

      _loadData();
      _uiState =
          _currentPlan == null
              ? const AsyncUiState.empty()
              : const AsyncUiState.success();
    } catch (e) {
      debugPrint('⚠️ PlannerProvider: failed to initialize: $e');
      _error = _l10n.error_generic;
      _uiState = AsyncUiState.error(_error);
    } finally {
      notifyListeners();
    }
  }

  void _loadData() {
    if (_planBox != null && _planBox!.isNotEmpty) {
      _currentPlan = _planBox!.get('current');
    }

    if (_groceryBox != null) {
      _groceryList = _groceryBox!.values.toList();
    }
  }

  Future<void> generateWeeklyPlan() async {
    if (_isGenerating) return;
    _isGenerating = true;
    _uiState =
        _currentPlan == null
            ? const AsyncUiState.loading()
            : const AsyncUiState.refreshing();
    _error = null;
    notifyListeners();

    try {
      final userSettings = _settingsProvider.settings;
      final result = await _aiService
          .generateWeeklyMealPlan(
            userSettings,
            prepTimePreference: _prepTimePreference,
            budgetPreference: _budgetPreference,
          )
          .timeout(const Duration(seconds: 60));

      final finalResult = result ?? buildFallbackPlan(userSettings);
      if (result == null) {
        _fallbackNotice = _l10n.error_generic;
      }

      if (finalResult.plan.weeklyMeals.isNotEmpty) {
        _currentPlan = finalResult.plan;
        _loggedPlannedMealIds.clear();
        await _planBox?.put('current', _currentPlan!);

        await _groceryBox?.clear();
        _groceryList =
            finalResult.groceryList.isNotEmpty
                ? finalResult.groceryList
                : _buildGroceriesFromPlan(_currentPlan!);
        await _groceryBox?.addAll(_groceryList);
        _regenCountThisWeek = 0;
      } else {
        throw Exception('API returned empty meal plan');
      }
    } catch (e) {
      debugPrint('Error generating plan: $e');
      final isTimeout =
          e is TimeoutException ||
          (e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout));

      final isOffline =
          e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.cancel);

      final errorMsg =
          isOffline
              ? _l10n.error_offline
              : (isTimeout ? _timeoutMessage : _l10n.error_generic);

      if (_currentPlan == null && !isOffline) {
        final fallback = buildFallbackPlan(_settingsProvider.settings);
        _currentPlan = fallback.plan;
        _loggedPlannedMealIds.clear();
        await _planBox?.put('current', _currentPlan!);
        await _groceryBox?.clear();
        _groceryList =
            fallback.groceryList.isNotEmpty
                ? fallback.groceryList
                : _buildGroceriesFromPlan(_currentPlan!);
        await _groceryBox?.addAll(_groceryList);
        _regenCountThisWeek = 0;
        _fallbackNotice = errorMsg;
      } else if (_currentPlan == null) {
        _error = errorMsg;
      } else {
        _fallbackNotice = errorMsg;
      }
    } finally {
      _isGenerating = false;
      _uiState =
          _currentPlan == null
              ? (_error == null
                  ? const AsyncUiState.empty()
                  : AsyncUiState.error(_error))
              : const AsyncUiState.success();
      notifyListeners();
    }
  }

  /// Regenerate a single day's meals (Pro only).
  Future<void> regenerateDay(int dayIndex) async {
    if (_currentPlan == null) return;

    if (_isRegenerating) return;
    _isRegenerating = true;
    _uiState = const AsyncUiState.refreshing();
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService
          .regenerateDay(
            _settingsProvider.settings,
            dayIndex,
            _currentPlan!.weeklyMeals,
          )
          .timeout(const Duration(seconds: 30));

      if (result != null && result.plan.weeklyMeals.containsKey(dayIndex)) {
        final updatedMeals = Map<int, List<Meal>>.from(
          _currentPlan!.weeklyMeals,
        );
        final oldDayIngredients =
            (updatedMeals[dayIndex] ?? const <Meal>[])
                .expand((m) => m.ingredients ?? const <String>[])
                .map(
                  (ingredient) => _parseIngredient(ingredient).$1.toLowerCase(),
                )
                .where((ingredient) => ingredient.isNotEmpty)
                .toSet();
        updatedMeals[dayIndex] = result.plan.weeklyMeals[dayIndex]!;
        _currentPlan = _currentPlan!.copyWith(weeklyMeals: updatedMeals);
        await _planBox?.put('current', _currentPlan!);

        // Remove old grocery items that belong to the regenerated day,
        // then merge new items (deduplicated by name).
        _groceryList.removeWhere(
          (g) => oldDayIngredients.contains(g.name.toLowerCase()),
        );
        await _groceryBox?.clear();
        await _groceryBox?.addAll(_groceryList);

        final existingNames =
            _groceryList.map((g) => g.name.toLowerCase()).toSet();
        final newItems =
            result.groceryList.isNotEmpty
                ? result.groceryList
                : _buildGroceriesFromMeals(result.plan.weeklyMeals[dayIndex]!);
        for (final newItem in newItems) {
          if (!existingNames.contains(newItem.name.toLowerCase())) {
            _groceryList.add(newItem);
            await _groceryBox?.add(newItem);
            existingNames.add(newItem.name.toLowerCase());
          }
        }

        _regenCountThisWeek++;
      } else {
        throw Exception('API returned empty day regeneration');
      }
    } catch (e) {
      debugPrint('Error regenerating day: $e');
      final isTimeout =
          e is TimeoutException ||
          (e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout));

      final isOffline =
          e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.cancel);

      _error =
          isOffline
              ? _l10n.error_offline
              : (isTimeout ? _timeoutMessage : _l10n.error_generic);
    } finally {
      _isRegenerating = false;
      _uiState = const AsyncUiState.success();
      notifyListeners();
    }
  }

  /// Swap a single meal in the weekly plan for an alternative
  Future<void> swapMeal(
    int dayIndex,
    Meal mealToSwap, {
    String? craving,
    String? swapIntent,
  }) async {
    if (_currentPlan == null) return;

    if (_isSwappingMeal) return;
    _isSwappingMeal = true;
    _uiState = const AsyncUiState.refreshing();
    _error = null;
    notifyListeners();

    try {
      // Collect all existing meals in the weekly plan so AI doesn't duplicate them
      final existingMealsInPlan =
          _currentPlan!.weeklyMeals.values.expand((meals) => meals).toList();

      final newMeal = await _aiService
          .regenerateSingleMeal(
            _settingsProvider.settings,
            mealToSwap,
            existingMealsInPlan,
            craving: craving,
            swapIntent: swapIntent,
          )
          .timeout(const Duration(seconds: 25));

      final finalMeal =
          _isValidSwapMeal(newMeal, mealToSwap, existingMealsInPlan)
              ? newMeal!
              : _buildFallbackSwapMeal(mealToSwap, swapIntent: swapIntent);

      final updatedMeals = Map<int, List<Meal>>.from(_currentPlan!.weeklyMeals);
      final dayMeals = List<Meal>.from(updatedMeals[dayIndex] ?? []);
      final index = dayMeals.indexWhere((m) => m.id == mealToSwap.id);
      if (index != -1) {
        final adjustedNewMeal = finalMeal.copyWith(
          id: mealToSwap.id,
          timestamp: mealToSwap.timestamp,
          dateString: mealToSwap.dateString,
          mealType: mealToSwap.mealType,
        );
        dayMeals[index] = adjustedNewMeal;
        updatedMeals[dayIndex] = dayMeals;
        _currentPlan = _currentPlan!.copyWith(weeklyMeals: updatedMeals);
        _loggedPlannedMealIds.remove(mealToSwap.id);
        await _planBox?.put('current', _currentPlan!);

        // Update grocery list
        final oldIngredients =
            mealToSwap.ingredients
                ?.map((i) => _parseIngredient(i).$1.toLowerCase())
                .toSet() ??
            {};

        // Remove grocery list items matching old ingredients
        _groceryList.removeWhere((g) {
          final gName = g.name.toLowerCase();
          return oldIngredients.any(
            (oi) => gName.contains(oi) || oi.contains(gName),
          );
        });

        // Add new ingredients
        final newIngredients = adjustedNewMeal.ingredients ?? [];
        final existingNames =
            _groceryList.map((g) => g.name.toLowerCase()).toSet();

        for (final ingredient in newIngredients) {
          final parsed = _parseIngredient(ingredient);
          final ingName = parsed.$1;
          final ingNameLower = ingName.toLowerCase();

          if (ingName.isNotEmpty && !existingNames.contains(ingNameLower)) {
            final newItem = GroceryItem(
              name: ingName,
              amount: parsed.$2,
              category: _localizedCategory(_guessCategory(ingName)),
            );
            _groceryList.add(newItem);
            existingNames.add(ingNameLower);
          }
        }

        await _groceryBox?.clear();
        await _groceryBox?.addAll(_groceryList);

        _regenCountThisWeek++;
      } else {
        _error = _l10n.error_generic;
      }
    } catch (e) {
      debugPrint('Error swapping meal: $e');
      final isTimeout =
          e is TimeoutException ||
          (e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout));

      final isOffline =
          e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.cancel);

      _error =
          isOffline
              ? _l10n.error_offline
              : (isTimeout ? _timeoutMessage : _l10n.error_generic);
    } finally {
      _isSwappingMeal = false;
      _uiState = const AsyncUiState.success();
      notifyListeners();
    }
  }

  bool _isValidSwapMeal(Meal? meal, Meal oldMeal, List<Meal> existingMeals) {
    if (meal == null) return false;
    if (meal.foodName.trim().isEmpty) return false;
    if (meal.foodName.toLowerCase() == oldMeal.foodName.toLowerCase()) {
      return false;
    }
    final existingNames =
        existingMeals
            .where((m) => m.id != oldMeal.id)
            .map((m) => m.foodName.toLowerCase())
            .toSet();
    if (existingNames.contains(meal.foodName.toLowerCase())) return false;
    if (meal.calories <= 0) return false;
    if (meal.macros.protein < 0 ||
        meal.macros.carbs < 0 ||
        meal.macros.fat < 0) {
      return false;
    }
    return true;
  }

  Meal _buildFallbackSwapMeal(Meal mealToSwap, {String? swapIntent}) {
    final settings = _settingsProvider.settings;
    final restriction = settings.dietaryRestriction ?? 'none';
    final cuisine = settings.cuisinePreference ?? 'international';
    final options = _fallbackMealOptions(
      restriction,
      cuisine,
      mealToSwap.mealType ?? 'Breakfast',
    );

    final selectedOption = _selectFallbackSwapOption(
      options,
      mealToSwap,
      swapIntent: swapIntent,
    );

    final splits = _mealSplits(settings.mealsPerDay ?? 3);
    final mealTypeIndex =
        (mealToSwap.mealType?.toLowerCase() == 'breakfast')
            ? 0
            : (mealToSwap.mealType?.toLowerCase() == 'lunch')
            ? 1
            : 2;
    final split = (mealTypeIndex < splits.length) ? splits[mealTypeIndex] : 0.3;
    final calorieGoal = settings.dailyCalorieGoal.clamp(900, 5000);
    final proteinGoal = settings.dailyProteinGoal.clamp(20, 350);
    final carbGoal = settings.dailyCarbGoal.clamp(20, 600);
    final fatGoal = settings.dailyFatGoal.clamp(10, 250);

    return Meal(
      id: mealToSwap.id,
      timestamp: mealToSwap.timestamp,
      dateString: mealToSwap.dateString,
      foodName: selectedOption.$1,
      calories: (calorieGoal * split).round(),
      macros: Macros(
        protein: (proteinGoal * split).round(),
        carbs: (carbGoal * split).round(),
        fat: (fatGoal * split).round(),
      ),
      mealType: mealToSwap.mealType,
      portion: selectedOption.$3,
      prepTimeMins: selectedOption.$4,
      ingredients: selectedOption.$2,
      synced: true,
      scanSource: 'planner_fallback_swap',
      aiRationale: _fallbackRationale(
        mealToSwap.mealType ?? 'meal',
        swapIntent,
      ),
    );
  }

  (String, List<String>, String, int) _selectFallbackSwapOption(
    List<(String, List<String>, String, int)> options,
    Meal oldMeal, {
    String? swapIntent,
  }) {
    final usable =
        options
            .where(
              (opt) => opt.$1.toLowerCase() != oldMeal.foodName.toLowerCase(),
            )
            .toList();
    final pool = usable.isEmpty ? List.of(options) : usable;
    if (swapIntent == 'faster_prep') {
      pool.sort((a, b) => a.$4.compareTo(b.$4));
    } else if (swapIntent == 'cheaper') {
      pool.sort((a, b) => a.$2.length.compareTo(b.$2.length));
    }
    return pool.first;
  }

  String _fallbackRationale(String mealType, String? swapIntent) {
    switch (_languageCode) {
      case 'ar':
        switch (swapIntent) {
          case 'lower_calorie':
            return 'خيار أخف يساعد على إبقاء اليوم قريباً من هدف السعرات.';
          case 'higher_protein':
            return 'هذا الخيار يرفع حضور البروتين في اليوم.';
          case 'faster_prep':
            return 'يعتمد على مكونات سريعة لتحضير أسهل.';
          case 'cheaper':
            return 'يعتمد على مكونات بسيطة وأفضل من حيث التكلفة.';
          default:
            return 'متوازن مع السعرات والماكروز وتوقيت الوجبات.';
        }
      case 'es':
        switch (swapIntent) {
          case 'lower_calorie':
            return 'Una opcion mas ligera mantiene el dia cerca del objetivo.';
          case 'higher_protein':
            return 'Esta comida da mas protagonismo a la proteina.';
          case 'faster_prep':
            return 'Usa ingredientes rapidos para preparar con menos esfuerzo.';
          case 'cheaper':
            return 'Usa ingredientes simples para mejor valor.';
          default:
            return 'Equilibrado para tus calorias, macros y horario.';
        }
      case 'fr':
        switch (swapIntent) {
          case 'lower_calorie':
            return 'Une option plus legere garde la journee proche de l objectif.';
          case 'higher_protein':
            return 'Ce repas met davantage l accent sur les proteines.';
          case 'faster_prep':
            return 'Des ingredients rapides rendent la preparation plus simple.';
          case 'cheaper':
            return 'Des ingredients simples offrent un meilleur rapport qualite prix.';
          default:
            return 'Equilibre pour vos calories, macros et horaires de repas.';
        }
      default:
        switch (swapIntent) {
          case 'lower_calorie':
            return 'A lighter $mealType keeps the day closer to target.';
          case 'higher_protein':
            return 'This $mealType keeps protein more prominent for the day.';
          case 'faster_prep':
            return 'This $mealType uses quick ingredients for easier prep.';
          case 'cheaper':
            return 'This $mealType uses simple ingredients for better value.';
          default:
            return 'Balanced for your calories, macros, and meal timing.';
        }
    }
  }

  void setPlanningPreferences({
    required String prepTimePreference,
    required String budgetPreference,
  }) {
    _prepTimePreference = prepTimePreference;
    _budgetPreference = budgetPreference;
  }

  void markPlannedMealLogged(String mealId) {
    _loggedPlannedMealIds.add(mealId);
    notifyListeners();
  }

  Future<void> rebalanceAfterMealLog({
    required Meal loggedMeal,
    required List<Meal> loggedMealsForDate,
  }) async {
    if (_currentPlan == null || _isRebalancing) return;
    if (loggedMeal.scanSource == 'meal_planner') return;

    final dayIndex = _dayIndexForDateString(loggedMeal.dateString);
    if (dayIndex == null) return;

    final dayMeals = List<Meal>.from(_currentPlan!.weeklyMeals[dayIndex] ?? []);
    if (dayMeals.isEmpty) return;

    final remainingIndexes = <int>[];
    for (var i = 0; i < dayMeals.length; i++) {
      final meal = dayMeals[i];
      final isLogged = _loggedPlannedMealIds.contains(meal.id);
      final isAfterLoggedMeal = meal.timestamp > loggedMeal.timestamp;
      if (!isLogged && isAfterLoggedMeal) remainingIndexes.add(i);
    }
    if (remainingIndexes.isEmpty) return;

    _isRebalancing = true;
    notifyListeners();
    try {
      final consumedCalories = loggedMealsForDate.fold<int>(
        0,
        (sum, meal) => sum + meal.calories,
      );
      final consumedProtein = loggedMealsForDate.fold<int>(
        0,
        (sum, meal) => sum + meal.macros.protein,
      );
      final consumedCarbs = loggedMealsForDate.fold<int>(
        0,
        (sum, meal) => sum + meal.macros.carbs,
      );
      final consumedFat = loggedMealsForDate.fold<int>(
        0,
        (sum, meal) => sum + meal.macros.fat,
      );

      final targetCalories =
          (_settingsProvider.dailyCalorieGoal - consumedCalories)
              .clamp(0, 5000)
              .toInt();
      final targetProtein =
          (_settingsProvider.dailyProteinGoal - consumedProtein)
              .clamp(0, 350)
              .toInt();
      final targetCarbs =
          (_settingsProvider.dailyCarbGoal - consumedCarbs)
              .clamp(0, 600)
              .toInt();
      final targetFat =
          (_settingsProvider.dailyFatGoal - consumedFat).clamp(0, 250).toInt();

      final remainingMeals = remainingIndexes.map((i) => dayMeals[i]).toList();
      final adjustedMeals = _scaleRemainingMeals(
        remainingMeals,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFat: targetFat,
      );

      for (var i = 0; i < remainingIndexes.length; i++) {
        dayMeals[remainingIndexes[i]] = adjustedMeals[i];
      }

      final updatedMeals = Map<int, List<Meal>>.from(_currentPlan!.weeklyMeals);
      updatedMeals[dayIndex] = dayMeals;
      _currentPlan = _currentPlan!.copyWith(weeklyMeals: updatedMeals);
      await _planBox?.put('current', _currentPlan!);
      _rebalanceNotice = _buildRebalanceNotice(
        remainingIndexes.length,
        targetCalories,
        targetProtein,
      );
    } catch (e) {
      debugPrint('Error rebalancing plan: $e');
    } finally {
      _isRebalancing = false;
      notifyListeners();
    }
  }

  List<Meal> _scaleRemainingMeals(
    List<Meal> meals, {
    required int targetCalories,
    required int targetProtein,
    required int targetCarbs,
    required int targetFat,
  }) {
    final originalCalories = meals
        .fold<int>(0, (sum, meal) => sum + meal.calories)
        .clamp(1, 99999);
    final originalProtein = meals
        .fold<int>(0, (sum, meal) => sum + meal.macros.protein)
        .clamp(1, 99999);
    final originalCarbs = meals
        .fold<int>(0, (sum, meal) => sum + meal.macros.carbs)
        .clamp(1, 99999);
    final originalFat = meals
        .fold<int>(0, (sum, meal) => sum + meal.macros.fat)
        .clamp(1, 99999);

    var allocatedCalories = 0;
    var allocatedProtein = 0;
    var allocatedCarbs = 0;
    var allocatedFat = 0;

    return List.generate(meals.length, (index) {
      final meal = meals[index];
      final isLast = index == meals.length - 1;
      final calories =
          isLast
              ? (targetCalories - allocatedCalories).clamp(0, 5000).toInt()
              : ((targetCalories * meal.calories) / originalCalories).round();
      final protein =
          isLast
              ? (targetProtein - allocatedProtein).clamp(0, 350).toInt()
              : ((targetProtein * meal.macros.protein) / originalProtein)
                  .round();
      final carbs =
          isLast
              ? (targetCarbs - allocatedCarbs).clamp(0, 600).toInt()
              : ((targetCarbs * meal.macros.carbs) / originalCarbs).round();
      final fat =
          isLast
              ? (targetFat - allocatedFat).clamp(0, 250).toInt()
              : ((targetFat * meal.macros.fat) / originalFat).round();

      allocatedCalories += calories;
      allocatedProtein += protein;
      allocatedCarbs += carbs;
      allocatedFat += fat;

      return meal.copyWith(
        calories: calories,
        macros: Macros(protein: protein, carbs: carbs, fat: fat),
        portion: calories == 0 ? 'Skip or keep very light' : meal.portion,
        aiRationale: _rebalanceRationale(calories, protein),
        scanSource: 'meal_planner_rebalanced',
      );
    });
  }

  String _rebalanceRationale(int calories, int protein) {
    if (_languageCode == 'ar') {
      if (calories == 0) {
        return 'تم التعديل بعد تسجيلك؛ اجعل هذه الوجبة خفيفة جداً عند الحاجة.';
      }
      if (protein >= 25) {
        return 'تمت الموازنة بعد تسجيلك للحفاظ على البروتين والبقاء ضمن الهدف.';
      }
      return 'تمت الموازنة بعد تسجيلك لإبقاء بقية اليوم على المسار.';
    }
    if (_languageCode == 'es') {
      if (calories == 0) {
        return 'Ajustado despues de tu registro; mantén esta comida muy ligera si hace falta.';
      }
      if (protein >= 25) {
        return 'Reequilibrado tras tu registro para cuidar la proteina y mantener el objetivo.';
      }
      return 'Reequilibrado tras tu registro para mantener el resto del dia en marcha.';
    }
    if (_languageCode == 'fr') {
      if (calories == 0) {
        return 'Ajuste apres votre saisie ; gardez ce repas tres leger si necessaire.';
      }
      if (protein >= 25) {
        return 'Reequilibre apres votre saisie pour proteger les proteines et rester sur cible.';
      }
      return 'Reequilibre apres votre saisie pour garder le reste de la journee sur la bonne voie.';
    }
    if (calories == 0) {
      return 'Adjusted after your log; keep this meal very light if needed.';
    }
    if (protein >= 25) {
      return 'Rebalanced after your log to protect protein while staying on target.';
    }
    return 'Rebalanced after your log to keep the rest of the day on track.';
  }

  String _buildRebalanceNotice(
    int mealCount,
    int caloriesLeft,
    int proteinLeft,
  ) {
    if (caloriesLeft <= 0) {
      return _l10n.planner_rebalance_notice_light;
    }
    if (proteinLeft > 25) {
      return _l10n.planner_rebalance_notice_protein;
    }
    return _l10n.planner_rebalance_notice_adjusted(mealCount);
  }

  int? _dayIndexForDateString(String dateString) {
    if (_currentPlan == null) return null;
    for (var day = 0; day < 7; day++) {
      final date = _currentPlan!.startDate.add(Duration(days: day));
      if (_dateString(date) == dateString) return day;
    }
    return null;
  }

  // Simple helper to parse "1 cup oats" or "2 eggs" into (name, amount)
  (String, String) _parseIngredient(String raw) {
    final trimmed = raw.trim();
    final firstSpace = trimmed.indexOf(' ');
    if (firstSpace == -1) return (trimmed, '');
    final quantity = trimmed.substring(0, firstSpace);
    final name = trimmed.substring(firstSpace + 1);
    if (RegExp(r'^[0-9¼½¾⅓⅔⅛\-./\s]+$').hasMatch(quantity) ||
        [
          'a',
          'an',
          'few',
          'some',
          'one',
          'two',
        ].contains(quantity.toLowerCase())) {
      return (name, quantity);
    }
    return (trimmed, '');
  }

  List<GroceryItem> _buildGroceriesFromPlan(MealPlan plan) {
    return _buildGroceriesFromMeals(
      plan.weeklyMeals.values.expand((meals) => meals).toList(),
    );
  }

  List<GroceryItem> _buildGroceriesFromMeals(List<Meal> meals) {
    final itemsByName = <String, GroceryItem>{};
    for (final meal in meals) {
      for (final ingredient in meal.ingredients ?? const <String>[]) {
        final parsed = _parseIngredient(ingredient);
        final name = parsed.$1.trim();
        if (name.isEmpty) continue;
        final normalized = name.toLowerCase();
        itemsByName.putIfAbsent(
          normalized,
          () => GroceryItem(
            name: name,
            amount: parsed.$2,
            category: _localizedCategory(_guessCategory(name)),
          ),
        );
      }
    }
    return itemsByName.values.toList();
  }

  // Simple category guessing helper
  String _guessCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('oil') ||
        n.contains('butter') ||
        n.contains('margarine') ||
        n.contains('dressing')) {
      return 'Oils';
    }
    if (n.contains('egg') ||
        n.contains('yogurt') ||
        n.contains('milk') ||
        n.contains('cheese') ||
        n.contains('cream') ||
        n.contains('feta')) {
      return 'Dairy';
    }
    if (n.contains('chicken') ||
        n.contains('beef') ||
        n.contains('turkey') ||
        n.contains('pork') ||
        n.contains('lamb') ||
        n.contains('steak') ||
        n.contains('kebab') ||
        n.contains('shawarma') ||
        n.contains('meat')) {
      return 'Protein';
    }
    if (n.contains('salmon') ||
        n.contains('tuna') ||
        n.contains('fish') ||
        n.contains('shrimp') ||
        n.contains('seafood')) {
      return 'Seafood';
    }
    if (n.contains('lentil') ||
        n.contains('chickpea') ||
        n.contains('bean') ||
        n.contains('tofu') ||
        n.contains('tempeh') ||
        n.contains('hummus')) {
      return 'Protein';
    }
    if (n.contains('rice') ||
        n.contains('oat') ||
        n.contains('quinoa') ||
        n.contains('bread') ||
        n.contains('toast') ||
        n.contains('pasta') ||
        n.contains('couscous') ||
        n.contains('flour') ||
        n.contains('tortilla') ||
        n.contains('wrap')) {
      return 'Grains';
    }
    if (n.contains('apple') ||
        n.contains('banana') ||
        n.contains('berry') ||
        n.contains('berries') ||
        n.contains('orange') ||
        n.contains('lemon') ||
        n.contains('fruit') ||
        n.contains('avocado')) {
      return 'Produce';
    }
    if (n.contains('spinach') ||
        n.contains('greens') ||
        n.contains('lettuce') ||
        n.contains('tomato') ||
        n.contains('cucumber') ||
        n.contains('carrot') ||
        n.contains('broccoli') ||
        n.contains('onion') ||
        n.contains('garlic') ||
        n.contains('pepper') ||
        n.contains('herb') ||
        n.contains('salad') ||
        n.contains('vegetable') ||
        n.contains('veggie')) {
      return 'Produce';
    }
    return 'Other';
  }

  String _localizedCategory(String category) {
    final map = switch (_languageCode) {
      'ar' => {
        'Produce': 'الخضار والفواكه',
        'Grains': 'الحبوب',
        'Protein': 'البروتين',
        'Dairy': 'الألبان',
        'Oils': 'الزيوت',
        'Seafood': 'المأكولات البحرية',
        'Other': 'أخرى',
      },
      'es' => {
        'Produce': 'Frutas y verduras',
        'Grains': 'Cereales',
        'Protein': 'Proteínas',
        'Dairy': 'Lácteos',
        'Oils': 'Aceites',
        'Seafood': 'Mariscos',
        'Other': 'Otros',
      },
      'fr' => {
        'Produce': 'Fruits et légumes',
        'Grains': 'Céréales',
        'Protein': 'Protéines',
        'Dairy': 'Produits laitiers',
        'Oils': 'Huiles',
        'Seafood': 'Fruits de mer',
        'Other': 'Autres',
      },
      _ => <String, String>{},
    };
    return map[category] ?? category;
  }

  PlanGenerationResult buildFallbackPlan(
    UserSettings settings, {
    int? onlyDayIndex,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final mealsPerDay = (settings.mealsPerDay ?? 3).clamp(2, 5);
    final calorieGoal = settings.dailyCalorieGoal.clamp(900, 5000);
    final proteinGoal = settings.dailyProteinGoal.clamp(20, 350);
    final carbGoal = settings.dailyCarbGoal.clamp(20, 600);
    final fatGoal = settings.dailyFatGoal.clamp(10, 250);
    final dayIndexes =
        onlyDayIndex == null ? List<int>.generate(7, (i) => i) : [onlyDayIndex];
    final weeklyMeals = MealPlan.createEmpty(start: start).weeklyMeals;

    for (final day in dayIndexes) {
      final splits = _mealSplits(mealsPerDay);
      final types = _mealTypes(mealsPerDay);
      weeklyMeals[day] = [
        for (var index = 0; index < mealsPerDay; index++)
          _fallbackMeal(
            settings: settings,
            day: day,
            index: index,
            type: types[index],
            calories: (calorieGoal * splits[index]).round(),
            protein: (proteinGoal * splits[index]).round(),
            carbs: (carbGoal * splits[index]).round(),
            fat: (fatGoal * splits[index]).round(),
            date: start.add(Duration(days: day)),
          ),
      ];
    }

    return PlanGenerationResult(
      plan: MealPlan.createEmpty(
        start: start,
      ).copyWith(weeklyMeals: weeklyMeals),
      groceryList: _fallbackGroceries(settings),
    );
  }

  Meal _fallbackMeal({
    required UserSettings settings,
    required int day,
    required int index,
    required String type,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required DateTime date,
  }) {
    final restriction = settings.dietaryRestriction ?? 'none';
    final cuisine = settings.cuisinePreference ?? 'international';
    final options = _fallbackMealOptions(restriction, cuisine, type);
    final selected = options[(day + index) % options.length];
    final ingredients = selected.$2;
    final timestamp =
        DateTime(
          date.year,
          date.month,
          date.day,
          8 + (index * 3),
          0,
        ).millisecondsSinceEpoch;

    return Meal(
      id: 'planner_${day}_${index}_${date.millisecondsSinceEpoch}',
      timestamp: timestamp,
      dateString: _dateString(date),
      foodName: selected.$1,
      calories: calories,
      macros: Macros(protein: protein, carbs: carbs, fat: fat),
      mealType: type,
      portion: selected.$3,
      prepTimeMins: selected.$4,
      ingredients: ingredients,
      synced: true,
      scanSource: 'planner_fallback',
      aiRationale: _fallbackRationale(type, null),
    );
  }

  List<double> _mealSplits(int mealsPerDay) {
    switch (mealsPerDay) {
      case 2:
        return const [0.44, 0.56];
      case 4:
        return const [0.25, 0.12, 0.35, 0.28];
      case 5:
        return const [0.22, 0.10, 0.30, 0.10, 0.28];
      case 3:
      default:
        return const [0.28, 0.38, 0.34];
    }
  }

  List<String> _mealTypes(int mealsPerDay) {
    switch (mealsPerDay) {
      case 2:
        return const ['Breakfast', 'Dinner'];
      case 4:
        return const ['Breakfast', 'Snack', 'Lunch', 'Dinner'];
      case 5:
        return const ['Breakfast', 'Snack', 'Lunch', 'Snack', 'Dinner'];
      case 3:
      default:
        return const ['Breakfast', 'Lunch', 'Dinner'];
    }
  }

  List<(String, List<String>, String, int)> _fallbackMealOptions(
    String restriction,
    String cuisine,
    String type,
  ) {
    final isVegan = restriction == 'vegan';
    final isVegetarian = restriction == 'vegetarian' || isVegan;
    final isKeto = restriction == 'keto';
    final isMiddleEastern = cuisine == 'middle eastern';
    final isMediterranean = cuisine == 'mediterranean';
    final localized = _localizedFallbackMealOptions(
      type,
      isVegetarian: isVegetarian,
      isVegan: isVegan,
      isKeto: isKeto,
    );
    if (localized != null) return localized;

    if (type == 'Breakfast') {
      if (isKeto) {
        return const [
          (
            'Eggs with avocado',
            ['2 eggs', '1 avocado', 'spinach'],
            '1 plate',
            12,
          ),
          (
            'Greek yogurt bowl',
            ['Greek yogurt', 'chia seeds', 'walnuts'],
            '1 bowl',
            5,
          ),
        ];
      }
      if (isVegan) {
        return const [
          (
            'Oats with banana and tahini',
            ['oats', 'banana', 'tahini'],
            '1 bowl',
            8,
          ),
          (
            'Tofu scramble toast',
            ['tofu', 'whole grain toast', 'tomato'],
            '1 plate',
            14,
          ),
        ];
      }
      return const [
        (
          'Greek yogurt and oats',
          ['Greek yogurt', 'oats', 'berries'],
          '1 bowl',
          6,
        ),
        (
          'Egg toast with fruit',
          ['eggs', 'whole grain bread', 'apple'],
          '1 plate',
          10,
        ),
      ];
    }

    if (type == 'Snack') {
      return const [
        (
          'Protein snack box',
          ['Greek yogurt', 'berries', 'almonds'],
          '1 box',
          4,
        ),
        (
          'Hummus and vegetables',
          ['hummus', 'cucumber', 'carrots'],
          '1 plate',
          5,
        ),
      ];
    }

    if (type == 'Lunch') {
      if (isVegetarian) {
        return const [
          (
            'Lentil quinoa bowl',
            ['lentils', 'quinoa', 'cucumber', 'olive oil'],
            '1 bowl',
            18,
          ),
          (
            'Chickpea salad plate',
            ['chickpeas', 'tomato', 'greens', 'tahini'],
            '1 plate',
            12,
          ),
        ];
      }
      if (isMiddleEastern) {
        return const [
          (
            'Chicken shawarma rice bowl',
            ['chicken breast', 'rice', 'yogurt sauce'],
            '1 bowl',
            22,
          ),
          (
            'Grilled kebab salad',
            ['lean beef', 'greens', 'cucumber', 'tahini'],
            '1 plate',
            18,
          ),
        ];
      }
      return const [
        (
          'Grilled chicken grain bowl',
          ['chicken breast', 'brown rice', 'greens'],
          '1 bowl',
          20,
        ),
        (
          'Tuna potato salad',
          ['tuna', 'potato', 'greens', 'olive oil'],
          '1 plate',
          14,
        ),
      ];
    }

    if (isVegetarian) {
      return const [
        (
          'Tofu vegetable stir fry',
          ['tofu', 'mixed vegetables', 'rice'],
          '1 plate',
          20,
        ),
        (
          'Bean and sweet potato bowl',
          ['black beans', 'sweet potato', 'avocado'],
          '1 bowl',
          18,
        ),
      ];
    }
    if (isMediterranean) {
      return const [
        (
          'Salmon with couscous',
          ['salmon', 'couscous', 'zucchini'],
          '1 plate',
          20,
        ),
        (
          'Chicken feta salad',
          ['chicken breast', 'feta', 'greens', 'olive oil'],
          '1 plate',
          12,
        ),
      ];
    }
    return const [
      ('Salmon rice plate', ['salmon', 'rice', 'broccoli'], '1 plate', 18),
      (
        'Turkey vegetable bowl',
        ['turkey', 'sweet potato', 'green beans'],
        '1 bowl',
        16,
      ),
    ];
  }

  List<(String, List<String>, String, int)>? _localizedFallbackMealOptions(
    String type, {
    required bool isVegetarian,
    required bool isVegan,
    required bool isKeto,
  }) {
    switch (_languageCode) {
      case 'ar':
        if (type == 'Breakfast') {
          if (isKeto) {
            return const [
              ('بيض مع أفوكادو', ['بيض', 'أفوكادو', 'سبانخ'], 'طبق واحد', 12),
              (
                'زبادي يوناني بالمكسرات',
                ['زبادي يوناني', 'بذور الشيا', 'جوز'],
                'وعاء واحد',
                5,
              ),
            ];
          }
          if (isVegan) {
            return const [
              (
                'شوفان بالموز والطحينة',
                ['شوفان', 'موز', 'طحينة'],
                'وعاء واحد',
                8,
              ),
              (
                'توست توفو مخفوق',
                ['توفو', 'خبز حبوب كاملة', 'طماطم'],
                'طبق واحد',
                14,
              ),
            ];
          }
          return const [
            (
              'زبادي يوناني بالشوفان',
              ['زبادي يوناني', 'شوفان', 'توت'],
              'وعاء واحد',
              6,
            ),
            (
              'توست بالبيض وفاكهة',
              ['بيض', 'خبز حبوب كاملة', 'تفاح'],
              'طبق واحد',
              10,
            ),
          ];
        }
        if (type == 'Snack') {
          return const [
            (
              'علبة سناك بروتين',
              ['زبادي يوناني', 'توت', 'لوز'],
              'علبة واحدة',
              4,
            ),
            ('حمص وخضار', ['حمص', 'خيار', 'جزر'], 'طبق واحد', 5),
          ];
        }
        if (type == 'Lunch') {
          if (isVegetarian) {
            return const [
              (
                'وعاء عدس وكينوا',
                ['عدس', 'كينوا', 'خيار', 'زيت زيتون'],
                'وعاء واحد',
                18,
              ),
              (
                'طبق سلطة حمص',
                ['حمص', 'طماطم', 'خضار ورقية', 'طحينة'],
                'طبق واحد',
                12,
              ),
            ];
          }
          return const [
            (
              'وعاء دجاج وحبوب',
              ['صدر دجاج', 'أرز بني', 'خضار ورقية'],
              'وعاء واحد',
              20,
            ),
            (
              'سلطة تونة وبطاطس',
              ['تونة', 'بطاطس', 'خضار ورقية', 'زيت زيتون'],
              'طبق واحد',
              14,
            ),
          ];
        }
        if (isVegetarian) {
          return const [
            ('توفو بالخضار', ['توفو', 'خضار مشكلة', 'أرز'], 'طبق واحد', 20),
            (
              'وعاء فاصوليا وبطاطا حلوة',
              ['فاصوليا سوداء', 'بطاطا حلوة', 'أفوكادو'],
              'وعاء واحد',
              18,
            ),
          ];
        }
        return const [
          ('سلمون مع أرز', ['سلمون', 'أرز', 'بروكلي'], 'طبق واحد', 18),
          (
            'وعاء ديك رومي وخضار',
            ['ديك رومي', 'بطاطا حلوة', 'فاصوليا خضراء'],
            'وعاء واحد',
            16,
          ),
        ];
      case 'es':
        if (type == 'Breakfast') {
          if (isKeto) {
            return const [
              (
                'Huevos con aguacate',
                ['huevos', 'aguacate', 'espinaca'],
                '1 plato',
                12,
              ),
              (
                'Bol de yogur griego',
                ['yogur griego', 'semillas de chia', 'nueces'],
                '1 bol',
                5,
              ),
            ];
          }
          if (isVegan) {
            return const [
              (
                'Avena con banana y tahini',
                ['avena', 'banana', 'tahini'],
                '1 bol',
                8,
              ),
              (
                'Tostada con tofu revuelto',
                ['tofu', 'pan integral', 'tomate'],
                '1 plato',
                14,
              ),
            ];
          }
          return const [
            (
              'Yogur griego con avena',
              ['yogur griego', 'avena', 'frutos rojos'],
              '1 bol',
              6,
            ),
            (
              'Tostada con huevo y fruta',
              ['huevos', 'pan integral', 'manzana'],
              '1 plato',
              10,
            ),
          ];
        }
        if (type == 'Snack') {
          return const [
            (
              'Caja de snack proteico',
              ['yogur griego', 'frutos rojos', 'almendras'],
              '1 caja',
              4,
            ),
            (
              'Hummus con verduras',
              ['hummus', 'pepino', 'zanahorias'],
              '1 plato',
              5,
            ),
          ];
        }
        if (type == 'Lunch') {
          if (isVegetarian) {
            return const [
              (
                'Bol de lentejas y quinoa',
                ['lentejas', 'quinoa', 'pepino', 'aceite de oliva'],
                '1 bol',
                18,
              ),
              (
                'Plato de ensalada de garbanzos',
                ['garbanzos', 'tomate', 'hojas verdes', 'tahini'],
                '1 plato',
                12,
              ),
            ];
          }
          return const [
            (
              'Bol de pollo con cereales',
              ['pechuga de pollo', 'arroz integral', 'hojas verdes'],
              '1 bol',
              20,
            ),
            (
              'Ensalada de atun y papa',
              ['atun', 'papa', 'hojas verdes', 'aceite de oliva'],
              '1 plato',
              14,
            ),
          ];
        }
        if (isVegetarian) {
          return const [
            (
              'Salteado de tofu y verduras',
              ['tofu', 'verduras mixtas', 'arroz'],
              '1 plato',
              20,
            ),
            (
              'Bol de frijoles y batata',
              ['frijoles negros', 'batata', 'aguacate'],
              '1 bol',
              18,
            ),
          ];
        }
        return const [
          (
            'Plato de salmon con arroz',
            ['salmon', 'arroz', 'brocoli'],
            '1 plato',
            18,
          ),
          (
            'Bol de pavo con verduras',
            ['pavo', 'batata', 'judias verdes'],
            '1 bol',
            16,
          ),
        ];
      case 'fr':
        if (type == 'Breakfast') {
          if (isKeto) {
            return const [
              (
                'Oeufs avec avocat',
                ['oeufs', 'avocat', 'epinards'],
                '1 assiette',
                12,
              ),
              (
                'Bol yaourt grec',
                ['yaourt grec', 'graines de chia', 'noix'],
                '1 bol',
                5,
              ),
            ];
          }
          if (isVegan) {
            return const [
              (
                'Avoine banane tahini',
                ['avoine', 'banane', 'tahini'],
                '1 bol',
                8,
              ),
              (
                'Toast tofu brouille',
                ['tofu', 'pain complet', 'tomate'],
                '1 assiette',
                14,
              ),
            ];
          }
          return const [
            (
              'Yaourt grec et avoine',
              ['yaourt grec', 'avoine', 'fruits rouges'],
              '1 bol',
              6,
            ),
            (
              'Toast aux oeufs et fruit',
              ['oeufs', 'pain complet', 'pomme'],
              '1 assiette',
              10,
            ),
          ];
        }
        if (type == 'Snack') {
          return const [
            (
              'Boite collation proteinee',
              ['yaourt grec', 'fruits rouges', 'amandes'],
              '1 boite',
              4,
            ),
            (
              'Houmous et legumes',
              ['houmous', 'concombre', 'carottes'],
              '1 assiette',
              5,
            ),
          ];
        }
        if (type == 'Lunch') {
          if (isVegetarian) {
            return const [
              (
                'Bol lentilles quinoa',
                ['lentilles', 'quinoa', 'concombre', 'huile d olive'],
                '1 bol',
                18,
              ),
              (
                'Assiette salade pois chiches',
                ['pois chiches', 'tomate', 'jeunes pousses', 'tahini'],
                '1 assiette',
                12,
              ),
            ];
          }
          return const [
            (
              'Bol poulet et cereales',
              ['blanc de poulet', 'riz complet', 'jeunes pousses'],
              '1 bol',
              20,
            ),
            (
              'Salade thon pomme de terre',
              ['thon', 'pomme de terre', 'jeunes pousses', 'huile d olive'],
              '1 assiette',
              14,
            ),
          ];
        }
        if (isVegetarian) {
          return const [
            (
              'Tofu saute aux legumes',
              ['tofu', 'legumes melanges', 'riz'],
              '1 assiette',
              20,
            ),
            (
              'Bol haricots et patate douce',
              ['haricots noirs', 'patate douce', 'avocat'],
              '1 bol',
              18,
            ),
          ];
        }
        return const [
          ('Saumon avec riz', ['saumon', 'riz', 'brocoli'], '1 assiette', 18),
          (
            'Bol dinde et legumes',
            ['dinde', 'patate douce', 'haricots verts'],
            '1 bol',
            16,
          ),
        ];
      default:
        return null;
    }
  }

  List<GroceryItem> _fallbackGroceries(UserSettings settings) {
    final localized = _localizedFallbackGroceries(settings);
    if (localized != null) return localized;

    final restriction = settings.dietaryRestriction ?? 'none';
    final isVegan = restriction == 'vegan';
    final isVegetarian = restriction == 'vegetarian' || isVegan;

    final items = <GroceryItem>[
      GroceryItem(name: 'Oats', amount: '500g', category: 'Grains'),
      GroceryItem(name: 'Berries', amount: '2 packs', category: 'Produce'),
      GroceryItem(name: 'Brown rice', amount: '1 bag', category: 'Grains'),
      GroceryItem(name: 'Mixed greens', amount: '2 bags', category: 'Produce'),
      GroceryItem(name: 'Cucumber', amount: '4', category: 'Produce'),
      GroceryItem(name: 'Tomatoes', amount: '6', category: 'Produce'),
      GroceryItem(name: 'Olive oil', amount: '1 bottle', category: 'Oils'),
    ];

    if (isVegetarian) {
      items.addAll([
        GroceryItem(
          name: isVegan ? 'Tofu' : 'Greek yogurt',
          amount: '4 servings',
          category: 'Protein',
        ),
        GroceryItem(name: 'Chickpeas', amount: '4 cans', category: 'Protein'),
        GroceryItem(name: 'Lentils', amount: '500g', category: 'Protein'),
      ]);
    } else {
      items.addAll([
        GroceryItem(
          name: 'Chicken breast',
          amount: '1.2kg',
          category: 'Protein',
        ),
        GroceryItem(name: 'Salmon', amount: '4 fillets', category: 'Seafood'),
        GroceryItem(name: 'Eggs', amount: '12', category: 'Dairy'),
      ]);
    }

    return items;
  }

  List<GroceryItem>? _localizedFallbackGroceries(UserSettings settings) {
    final restriction = settings.dietaryRestriction ?? 'none';
    final isVegan = restriction == 'vegan';
    final isVegetarian = restriction == 'vegetarian' || isVegan;

    switch (_languageCode) {
      case 'ar':
        final items = <GroceryItem>[
          GroceryItem(name: 'شوفان', amount: '500غ', category: 'الحبوب'),
          GroceryItem(
            name: 'توت',
            amount: 'عبوتان',
            category: 'الخضار والفواكه',
          ),
          GroceryItem(name: 'أرز بني', amount: 'كيس واحد', category: 'الحبوب'),
          GroceryItem(
            name: 'خضار ورقية',
            amount: 'كيسان',
            category: 'الخضار والفواكه',
          ),
          GroceryItem(name: 'خيار', amount: '4', category: 'الخضار والفواكه'),
          GroceryItem(name: 'طماطم', amount: '6', category: 'الخضار والفواكه'),
          GroceryItem(
            name: 'زيت زيتون',
            amount: 'زجاجة واحدة',
            category: 'الزيوت',
          ),
        ];
        items.addAll(
          isVegetarian
              ? [
                GroceryItem(
                  name: isVegan ? 'توفو' : 'زبادي يوناني',
                  amount: '4 حصص',
                  category: 'البروتين',
                ),
                GroceryItem(name: 'حمص', amount: '4 علب', category: 'البروتين'),
                GroceryItem(name: 'عدس', amount: '500غ', category: 'البروتين'),
              ]
              : [
                GroceryItem(
                  name: 'صدر دجاج',
                  amount: '1.2كغ',
                  category: 'البروتين',
                ),
                GroceryItem(
                  name: 'سلمون',
                  amount: '4 شرائح',
                  category: 'المأكولات البحرية',
                ),
                GroceryItem(name: 'بيض', amount: '12', category: 'الألبان'),
              ],
        );
        return items;
      case 'es':
        final items = <GroceryItem>[
          GroceryItem(name: 'Avena', amount: '500 g', category: 'Cereales'),
          GroceryItem(
            name: 'Frutos rojos',
            amount: '2 paquetes',
            category: 'Frutas y verduras',
          ),
          GroceryItem(
            name: 'Arroz integral',
            amount: '1 bolsa',
            category: 'Cereales',
          ),
          GroceryItem(
            name: 'Hojas verdes',
            amount: '2 bolsas',
            category: 'Frutas y verduras',
          ),
          GroceryItem(
            name: 'Pepino',
            amount: '4',
            category: 'Frutas y verduras',
          ),
          GroceryItem(
            name: 'Tomates',
            amount: '6',
            category: 'Frutas y verduras',
          ),
          GroceryItem(
            name: 'Aceite de oliva',
            amount: '1 botella',
            category: 'Aceites',
          ),
        ];
        items.addAll(
          isVegetarian
              ? [
                GroceryItem(
                  name: isVegan ? 'Tofu' : 'Yogur griego',
                  amount: '4 porciones',
                  category: 'Proteínas',
                ),
                GroceryItem(
                  name: 'Garbanzos',
                  amount: '4 latas',
                  category: 'Proteínas',
                ),
                GroceryItem(
                  name: 'Lentejas',
                  amount: '500 g',
                  category: 'Proteínas',
                ),
              ]
              : [
                GroceryItem(
                  name: 'Pechuga de pollo',
                  amount: '1.2 kg',
                  category: 'Proteínas',
                ),
                GroceryItem(
                  name: 'Salmon',
                  amount: '4 filetes',
                  category: 'Mariscos',
                ),
                GroceryItem(name: 'Huevos', amount: '12', category: 'Lácteos'),
              ],
        );
        return items;
      case 'fr':
        final items = <GroceryItem>[
          GroceryItem(name: 'Avoine', amount: '500 g', category: 'Céréales'),
          GroceryItem(
            name: 'Fruits rouges',
            amount: '2 barquettes',
            category: 'Fruits et légumes',
          ),
          GroceryItem(
            name: 'Riz complet',
            amount: '1 sac',
            category: 'Céréales',
          ),
          GroceryItem(
            name: 'Jeunes pousses',
            amount: '2 sachets',
            category: 'Fruits et légumes',
          ),
          GroceryItem(
            name: 'Concombre',
            amount: '4',
            category: 'Fruits et légumes',
          ),
          GroceryItem(
            name: 'Tomates',
            amount: '6',
            category: 'Fruits et légumes',
          ),
          GroceryItem(
            name: 'Huile d olive',
            amount: '1 bouteille',
            category: 'Huiles',
          ),
        ];
        items.addAll(
          isVegetarian
              ? [
                GroceryItem(
                  name: isVegan ? 'Tofu' : 'Yaourt grec',
                  amount: '4 portions',
                  category: 'Protéines',
                ),
                GroceryItem(
                  name: 'Pois chiches',
                  amount: '4 boites',
                  category: 'Protéines',
                ),
                GroceryItem(
                  name: 'Lentilles',
                  amount: '500 g',
                  category: 'Protéines',
                ),
              ]
              : [
                GroceryItem(
                  name: 'Blanc de poulet',
                  amount: '1.2 kg',
                  category: 'Protéines',
                ),
                GroceryItem(
                  name: 'Saumon',
                  amount: '4 filets',
                  category: 'Fruits de mer',
                ),
                GroceryItem(
                  name: 'Oeufs',
                  amount: '12',
                  category: 'Produits laitiers',
                ),
              ],
        );
        return items;
      default:
        return null;
    }
  }

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool get canRegenerate {
    const maxRegenPerWeek = 3;
    return _settingsProvider.isPro && _regenCountThisWeek < maxRegenPerWeek;
  }

  Future<void> toggleGroceryItem(String id) async {
    try {
      final index = _groceryList.indexWhere((i) => i.id == id);
      if (index != -1) {
        final item = _groceryList[index];
        item.isChecked = !item.isChecked;
        notifyListeners();
        await item.save();
      }
    } catch (e) {
      debugPrint('Error toggling grocery item: $e');
      final index = _groceryList.indexWhere((i) => i.id == id);
      if (index != -1) {
        _groceryList[index].isChecked = !_groceryList[index].isChecked;
        notifyListeners();
      }
    }
  }

  Future<void> clearGroceryList() async {
    await _groceryBox?.clear();
    _groceryList = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Format grocery list for sharing
  String getFormattedGroceryList() {
    if (_groceryList.isEmpty) return '';

    final grouped = <String, List<String>>{};
    for (final item in _groceryList) {
      final cat =
          item.category.isNotEmpty
              ? item.category
              : _localizedCategory('Other');
      grouped
          .putIfAbsent(cat, () => [])
          .add(
            item.amount.isNotEmpty
                ? '${item.name} — ${item.amount}'
                : item.name,
          );
    }

    final categoryEmojis = {
      'produce': '🥬',
      'grains': '🌾',
      'protein': '🥩',
      'meat': '🥩',
      'dairy': '🧀',
      'fruits': '🍎',
      'vegetables': '🥬',
      'snacks': '🍿',
      'beverages': '🥤',
      'condiments': '🧂',
      'oils': '🫒',
      'other': '📦',
      'frozen': '🧊',
      'bakery': '🍞',
      'seafood': '🐟',
      'spices': '🌶️',
    };

    final title = switch (_languageCode) {
      'ar' => '🛒 قائمة مشتريات SnapCal',
      'es' => '🛒 Lista de compras de SnapCal',
      'fr' => '🛒 Liste de courses SnapCal',
      _ => '🛒 SnapCal Grocery List',
    };
    final buffer = StringBuffer('$title\n');
    grouped.forEach((category, items) {
      final emoji = categoryEmojis[category.toLowerCase()] ?? '📦';
      buffer.writeln('\n$emoji ${category.toUpperCase()}');
      for (final item in items) {
        buffer.writeln('  • $item');
      }
    });

    return buffer.toString();
  }

  /// Clear all planner data (logout)
  Future<void> clear() async {
    await _planBox?.clear();
    await _groceryBox?.clear();
    _currentPlan = null;
    _groceryList = [];
    _loggedPlannedMealIds.clear();
    _regenCountThisWeek = 0;
    _error = null;
    _fallbackNotice = null;
    notifyListeners();
  }
}
