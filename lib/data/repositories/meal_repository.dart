import 'package:hive/hive.dart';
import '../models/meal.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing meal data in Hive
class MealRepository {
  late Box<Meal> _mealsBox;

  /// Initialize the repository
  Future<void> init() async {
    _mealsBox = await Hive.openBox<Meal>(AppConstants.mealsBoxName);
  }

  /// Get all meals
  List<Meal> getAllMeals() {
    return _mealsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get meals for a specific date
  List<Meal> getMealsByDate(String dateString) {
    return _mealsBox.values
        .where((meal) => meal.dateString == dateString)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get today's meals
  List<Meal> getTodaysMeals() {
    final today = _getDateString(DateTime.now());
    return getMealsByDate(today);
  }

  /// Get meal count for today
  int getTodaysMealCount() {
    return getTodaysMeals().length;
  }

  /// Add a new meal
  Future<void> addMeal(Meal meal) async {
    await _mealsBox.put(meal.id, meal);
  }

  /// Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    await _mealsBox.put(meal.id, meal);
  }

  /// Delete a meal
  Future<void> deleteMeal(String id) async {
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
