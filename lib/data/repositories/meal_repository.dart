import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/meal.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing meal data in Hive
class MealRepository {
  late Box<Meal> _mealsBox;
  late Box<List<String>> _indexBox;

  /// Initialize the repository
  Future<void> init() async {
    _mealsBox = await Hive.openBox<Meal>(AppConstants.mealsBoxName);
    _indexBox = await Hive.openBox<List<String>>(AppConstants.mealIndexBoxName);

    // Initial migration: if meals exist but index is empty
    if (_mealsBox.isNotEmpty && _indexBox.isEmpty) {
      debugPrint('📦 MealRepository: Rebuilding date index...');
      final Map<String, List<String>> tempIndex = {};

      for (final meal in _mealsBox.values) {
        final date = meal.dateString;
        if (!tempIndex.containsKey(date)) {
          tempIndex[date] = [];
        }
        if (!tempIndex[date]!.contains(meal.id)) {
          tempIndex[date]!.add(meal.id);
        }
      }

      // Batch save the reconstructed index
      await _indexBox.putAll(tempIndex);
      debugPrint('✅ MealRepository: Index rebuilt successfully');
    }
  }

  /// Get all meals
  List<Meal> getAllMeals() {
    return _mealsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get meals for a specific date
  List<Meal> getMealsByDate(String dateString) {
    final ids = _indexBox.get(dateString) ?? [];
    if (ids.isEmpty) return [];

    return ids.map((id) => _mealsBox.get(id)).whereType<Meal>().toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get today's meals
  List<Meal> getTodaysMeals() {
    final today = _getDateString(DateTime.now());
    return getMealsByDate(today);
  }

  /// Get meal count for today
  int getTodaysMealCount() {
    final today = _getDateString(DateTime.now());
    return (_indexBox.get(today) ?? []).length;
  }

  /// Add a new meal
  Future<void> addMeal(Meal meal) async {
    await _mealsBox.put(meal.id, meal);

    // Update index
    final date = meal.dateString;
    final ids = _indexBox.get(date) ?? [];
    if (!ids.contains(meal.id)) {
      ids.add(meal.id);
      await _indexBox.put(date, ids);
    }
  }

  /// Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    final oldMeal = _mealsBox.get(meal.id);
    await _mealsBox.put(meal.id, meal);

    // If date changed, update index
    if (oldMeal != null && oldMeal.dateString != meal.dateString) {
      // Remove from old date index
      final oldDate = oldMeal.dateString;
      final oldIds = _indexBox.get(oldDate) ?? [];
      oldIds.remove(meal.id);
      if (oldIds.isEmpty) {
        await _indexBox.delete(oldDate);
      } else {
        await _indexBox.put(oldDate, oldIds);
      }

      // Add to new date index
      final newDate = meal.dateString;
      final newIds = _indexBox.get(newDate) ?? [];
      if (!newIds.contains(meal.id)) {
        newIds.add(meal.id);
        await _indexBox.put(newDate, newIds);
      }
    }
  }

  /// Delete a meal
  Future<void> deleteMeal(String id) async {
    final meal = _mealsBox.get(id);
    if (meal != null) {
      final date = meal.dateString;
      final ids = _indexBox.get(date) ?? [];
      ids.remove(id);
      if (ids.isEmpty) {
        await _indexBox.delete(date);
      } else {
        await _indexBox.put(date, ids);
      }
    }
    await _mealsBox.delete(id);
  }

  /// Get meal by ID
  Meal? getMealById(String id) {
    return _mealsBox.get(id);
  }

  /// Calculate total calories for a date
  int getTotalCalories(String dateString) {
    final meals = getMealsByDate(dateString);
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  /// Calculate total macros for a date
  Macros getTotalMacros(String dateString) {
    final meals = getMealsByDate(dateString);
    int protein = 0;
    int carbs = 0;
    int fat = 0;

    for (final meal in meals) {
      protein += meal.macros.protein;
      carbs += meal.macros.carbs;
      fat += meal.macros.fat;
    }

    return Macros(protein: protein, carbs: carbs, fat: fat);
  }

  /// Get recent meals (last N meals)
  List<Meal> getRecentMeals({int count = 2}) {
    final allMeals = getAllMeals();
    return allMeals.take(count).toList();
  }

  /// Clear all meals (for testing)
  Future<void> clearAll() async {
    await _mealsBox.clear();
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
