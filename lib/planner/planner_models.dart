/// Planner domain models.
///
/// Nutrition is a *derived* property, exactly like `_Item` in the scan result.
/// A `PlannedFood` owns a nutrition-per-100g table and a portion in grams; there
/// is no setter for any calorie or macro figure. Fitting a day to its target
/// therefore changes grams, and the numbers follow by multiplication — which is
/// what keeps a planned meal honest and a grocery list summable.
library;

/// One identified food in a planned meal.
///
/// [per100g] keys are `calories`, `protein`, `carbs`, `fat` (per 100g).
/// [foodId] is the nutrition-DB key (the provenance); when a food could not be
/// resolved it carries the raw name and a nullable [foodId].
class PlannedFood {
  final String? foodId;
  final String name;

  /// Nutrition per 100 g. `{calories, protein, carbs, fat}`.
  final Map<String, double> per100g;

  /// The portion in grams. This is the only field fitting is allowed to change.
  final double grams;

  /// Portion floor (¼ of a sane serving).
  final double minGrams;

  /// Portion ceiling (3× a sane serving).
  final double maxGrams;

  const PlannedFood({
    this.foodId,
    required this.name,
    required this.per100g,
    required this.grams,
    required this.minGrams,
    required this.maxGrams,
  });

  /// True when nutrition is real rather than back-computed from the model.
  bool get resolved => foodId != null && per100g.isNotEmpty;

  // ── Derived. There is no setter for any of these. ──
  int get calories => _calc('calories');
  int get protein => _calc('protein');
  int get carbs => _calc('carbs');
  int get fat => _calc('fat');

  int _calc(String field) {
    final per = per100g[field];
    if (per == null || per <= 0) return 0;
    return (per * grams / 100).round();
  }

  /// The nutrition-per-100g view expected by [Meal.nutritionPer100g].
  Map<String, dynamic> toNutritionPer100g() => {
    'calories': per100g['calories']?.round() ?? 0,
    'protein': per100g['protein']?.round() ?? 0,
    'carbs': per100g['carbs']?.round() ?? 0,
    'fat': per100g['fat']?.round() ?? 0,
  };

  PlannedFood copyWith({double? grams}) => PlannedFood(
    foodId: foodId,
    name: name,
    per100g: per100g,
    grams: grams ?? this.grams,
    minGrams: minGrams,
    maxGrams: maxGrams,
  );

  /// Builds a [PlannedFood] from a raw nutrition-per-100g map (int or double
  /// values are both accepted) plus a portion weight and a sane-serving bound.
  factory PlannedFood.from({
    String? foodId,
    required String name,
    required Map<String, dynamic> per100g,
    required double grams,
    required double servingGrams,
  }) {
    double read(String key) {
      final v = per100g[key];
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return PlannedFood(
      foodId: foodId,
      name: name,
      per100g: {
        'calories': read('calories'),
        'protein': read('protein'),
        'carbs': read('carbs'),
        'fat': read('fat'),
      },
      grams: grams,
      minGrams: (servingGrams * 0.25).roundToDouble(),
      maxGrams: (servingGrams * 3).roundToDouble(),
    );
  }
}

/// One meal slot (Breakfast / Lunch / Dinner / Snack).
class PlannedMeal {
  final String slot;
  final String name;
  final List<PlannedFood> foods;
  final String? rationale;

  const PlannedMeal({
    required this.slot,
    required this.name,
    required this.foods,
    this.rationale,
  });

  // ── Derived. ──
  int get calories => foods.fold(0, (s, f) => s + f.calories);
  int get protein => foods.fold(0, (s, f) => s + f.protein);
  int get carbs => foods.fold(0, (s, f) => s + f.carbs);
  int get fat => foods.fold(0, (s, f) => s + f.fat);

  PlannedMeal copyWith({
    String? name,
    List<PlannedFood>? foods,
    String? rationale,
  }) => PlannedMeal(
    slot: slot,
    name: name ?? this.name,
    foods: foods ?? this.foods,
    rationale: rationale ?? this.rationale,
  );
}

/// Daily nutrition target used by the portion fitter.
class DayTarget {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const DayTarget({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const empty = DayTarget(calories: 0, protein: 0, carbs: 0, fat: 0);
}

/// A grocery result aggregated from resolved foods: the same food summed across
/// the whole horizon is one line, with its total grams and a DB-derived category.
class AggregatedFood {
  final String id;
  final String name;
  final double grams;
  final String category;

  const AggregatedFood({
    required this.id,
    required this.name,
    required this.grams,
    required this.category,
  });
}
