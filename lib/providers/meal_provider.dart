import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/meal.dart';
import '../data/repositories/meal_repository.dart';
import '../core/utils/date_utils.dart' as app_date;
import 'settings_provider.dart';

/// Provider for managing meal state
class MealProvider with ChangeNotifier {
  final MealRepository _repository;
  final Uuid _uuid = const Uuid();

  List<Meal> _todaysMeals = [];
  List<Meal> _selectedDateMeals = [];
  String _selectedDate = app_date.DateUtils.getTodayString();
  bool _isLoading = false;

  MealProvider(this._repository) {
    _loadTodaysMeals();
  }

  // Getters
  List<Meal> get todaysMeals => _todaysMeals;
  List<Meal> get selectedDateMeals => _selectedDateMeals;
  String get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  /// Get today's total calories
  int get todaysTotalCalories {
    return _todaysMeals.fold(0, (sum, meal) => sum + meal.calories);
  }

  /// Get today's total macros
  Macros get todaysTotalMacros {
    int protein = 0;
    int carbs = 0;
    int fat = 0;

    for (final meal in _todaysMeals) {
      protein += meal.macros.protein;
      carbs += meal.macros.carbs;
      fat += meal.macros.fat;
    }

    return Macros(protein: protein, carbs: carbs, fat: fat);
  }

  /// Get selected date's total calories
  int get selectedDateTotalCalories {
    return _selectedDateMeals.fold(0, (sum, meal) => sum + meal.calories);
  }

  /// Get today's meal count
  int get todaysMealCount => _todaysMeals.length;

  /// Get recent meals for home screen
  List<Meal> get recentMeals => _todaysMeals.take(2).toList();

  /// Load today's meals
  Future<void> _loadTodaysMeals() async {
    _isLoading = true;
    notifyListeners();

    _todaysMeals = _repository.getTodaysMeals();

    _isLoading = false;
    notifyListeners();
  }

  /// Load meals for selected date
  Future<void> loadMealsForDate(String dateString) async {
    _selectedDate = dateString;
    _isLoading = true;
    notifyListeners();

    _selectedDateMeals = _repository.getMealsByDate(dateString);

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new meal
  Future<void> addMeal({
    required String foodName,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String? imageUri,
    SettingsProvider? settings,
  }) async {
    final prevCal = todaysTotalCalories;
    final prevPro = todaysTotalMacros.protein;

    final now = DateTime.now();
    final meal = Meal(
      id: _uuid.v4(),
      timestamp: now.millisecondsSinceEpoch,
      dateString: app_date.DateUtils.getDateString(now),
      imageUri: imageUri,
      foodName: foodName,
      calories: calories,
      macros: Macros(protein: protein, carbs: carbs, fat: fat),
      synced: false,
    );

    await _repository.addMeal(meal);
    await _loadTodaysMeals();

    // Trigger goal alerts if settings provided
    if (settings != null) {
      final newCal = todaysTotalCalories;
      final newPro = todaysTotalMacros.protein;

      if (prevCal < settings.dailyCalorieGoal &&
          newCal >= settings.dailyCalorieGoal) {
        settings.triggerGoalAlert(
          'Goal Reached! 🚀',
          'You\'ve hit your daily calorie goal of ${settings.dailyCalorieGoal} kcal!',
        );
      }

      if (prevPro < settings.dailyProteinGoal &&
          newPro >= settings.dailyProteinGoal) {
        settings.triggerGoalAlert(
          'Protein Goal Met! 💪',
          'Great job! You\'ve reached your ${settings.dailyProteinGoal}g protein target.',
        );
      }
    }

    // Also refresh selected date if it's today
    if (_selectedDate == app_date.DateUtils.getTodayString()) {
      _selectedDateMeals = _todaysMeals;
    }

    notifyListeners();
  }

  /// Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    await _repository.updateMeal(meal);
    await _loadTodaysMeals();
    await loadMealsForDate(_selectedDate);
  }

  /// Delete a meal
  Future<void> deleteMeal(String id) async {
    await _repository.deleteMeal(id);
    await _loadTodaysMeals();
    await loadMealsForDate(_selectedDate);
  }

  /// Get calorie trend for the last 7 days
  List<double> getWeeklyCalorieTrend() {
    final List<double> trend = [];
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateString = app_date.DateUtils.getDateString(date);
      final meals = _repository.getMealsByDate(dateString);
      final total = meals.fold(0, (sum, meal) => sum + meal.calories);
      trend.add(total.toDouble());
    }
    return trend;
  }

  /// Get macro summary for the last 7 days
  Macros getWeeklyMacroSummary() {
    int protein = 0;
    int carbs = 0;
    int fat = 0;
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateString = app_date.DateUtils.getDateString(date);
      final meals = _repository.getMealsByDate(dateString);
      for (final meal in meals) {
        protein += meal.macros.protein;
        carbs += meal.macros.carbs;
        fat += meal.macros.fat;
      }
    }
    return Macros(protein: protein, carbs: carbs, fat: fat);
  }

  /// Get weekly average calories
  int getWeeklyAverageCalories() {
    final trend = getWeeklyCalorieTrend();
    if (trend.isEmpty) return 0;
    final total = trend.reduce((a, b) => a + b);
    return (total / trend.length).round();
  }

  /// Get goal consistency percentage (last 7 days)
  String getGoalConsistency(int dailyGoal) {
    int successCount = 0;
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateString = app_date.DateUtils.getDateString(date);
      final meals = _repository.getMealsByDate(dateString);
      final totalCals = meals.fold(0, (sum, meal) => sum + meal.calories);

      // Considered successful if logged something and not grossly over goal (>110%)
      // Or if exactly 0, maybe they didn't track, so not a "success".
      if (totalCals > 0 && totalCals <= (dailyGoal * 1.1)) {
        successCount++;
      }
    }
    return '${((successCount / 7) * 100).round()}%';
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _loadTodaysMeals();
    await loadMealsForDate(_selectedDate);
  }

  /// Navigate to previous day
  void goToPreviousDay() {
    loadMealsForDate(app_date.DateUtils.getPreviousDay(_selectedDate));
  }

  /// Navigate to next day
  void goToNextDay() {
    loadMealsForDate(app_date.DateUtils.getNextDay(_selectedDate));
  }

  /// Go to today
  void goToToday() {
    loadMealsForDate(app_date.DateUtils.getTodayString());
  }
}
