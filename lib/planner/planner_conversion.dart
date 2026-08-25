/// Bridges the persisted [Meal] (Hive) model and the planner's [PlannedMeal].
///
/// A generated plan comes back as free-text meals with invented numbers. To
/// make nutrition derived rather than hand-written, each [Meal] is turned into
/// a [PlannedMeal] carrying a per-100g table plus a portion in grams. When the
/// plan is already resolved (has `nutritionPer100g` and `weightG`), those are
/// used as-is; otherwise per100g is back-computed from the model's numbers at a
/// sane reference portion — exactly what `_Item.from` already does for a scan.
library;

import '../data/models/meal.dart';
import 'planner_models.dart';

const double _defaultPortionGrams = 150;

/// Build a [PlannedMeal] from a [Meal]. A Meal maps onto one [PlannedFood]
/// (the dish-level nutrition), which is the granularity the fitter works at.
PlannedMeal plannedMealFromMeal(Meal meal) {
  final weight = _weightFor(meal);
  final per100g = _per100gFor(meal, weight);

  return PlannedMeal(
    slot: meal.mealType ?? 'Meal',
    name: meal.foodName,
    rationale: meal.aiRationale,
    foods: [
      PlannedFood.from(
        foodId: meal.nutritionMatchId,
        name: meal.foodName,
        per100g: per100g,
        grams: weight,
        servingGrams: weight,
      ),
    ],
  );
}

/// Write fitted nutrition back onto a [Meal], preserving all the fields the
/// rest of the app cares about (id, timestamps, meal type, ingredients...).
/// Only the derived figures — calories, macros, grams and the nutrition source
/// — are rewritten, and they all follow from the same per-100g table.
Meal mealFromPlanned(PlannedMeal planned, Meal base) {
  final grams = planned.foods.fold<double>(0, (s, f) => s + f.grams);
  final nutrition =
      planned.foods.isNotEmpty
          ? planned.foods.first.per100g
          : <String, double>{};

  return base.copyWith(
    calories: planned.calories,
    macros: Macros(
      protein: planned.protein,
      carbs: planned.carbs,
      fat: planned.fat,
    ),
    weightG: grams,
    nutritionPer100g: {
      'calories': (nutrition['calories'])?.round() ?? 0,
      'protein': (nutrition['protein'])?.round() ?? 0,
      'carbs': (nutrition['carbs'])?.round() ?? 0,
      'fat': (nutrition['fat'])?.round() ?? 0,
    },
    nutritionMatchId:
        planned.foods.isNotEmpty ? planned.foods.first.foodId : null,
  );
}

/// The portion weight for a meal, preferring a resolved weight but falling back
/// to a number parsed out of the portion string ("1 large bowl" -> 1, interpreted
/// as a gram-less hint) and ultimately a sane 150 g reference.
double _weightFor(Meal meal) {
  if (meal.weightG != null && meal.weightG! > 0) {
    return meal.weightG!.toDouble();
  }
  final portion = meal.portion;
  if (portion != null && portion.isNotEmpty) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(portion);
    if (match != null) {
      final parsed = double.tryParse(match.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }
  }
  return _defaultPortionGrams;
}

Map<String, dynamic> _per100gFor(Meal meal, double weight) {
  final existing = meal.nutritionPer100g;
  if (existing != null && existing.isNotEmpty && weight > 0) {
    double read(String k) {
      final v = existing[k];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    return {
      'calories': read('calories'),
      'protein': read('protein'),
      'carbs': read('carbs'),
      'fat': read('fat'),
    };
  }

  // Back-compute from the model's invented figures at the reference weight.
  final weightG = weight <= 0 ? double.infinity : weight;
  double normalize(int value) => (value * 100 / weightG).roundToDouble();

  return {
    'calories': normalize(meal.calories),
    'protein': normalize(meal.macros.protein),
    'carbs': normalize(meal.macros.carbs),
    'fat': normalize(meal.macros.fat),
  };
}

/// Wrap a [Meal] into a single-food [PlannedMeal], used by the fitting stage.
PlannedMeal plannedFromMeal(Meal meal) => plannedMealFromMeal(meal);
