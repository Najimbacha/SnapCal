/// Pure planner math.
///
/// This is deliberately free of Hive, l10n and ChangeNotifier so that the
/// logic where the planner's bugs live is unit-testable in isolation. Splitting,
/// portion-fitting and grocery aggregation all live here; the provider and the
/// screen are thin shells over these functions.
library;

import 'planner_models.dart';

// ── Slot splitting ───────────────────────────────────────────────────────────

/// Split the daily calorie goal across meal slots. Mirrors the provider's
/// `_mealSplits` verbatim so the deterministic stage can never fail.
List<double> mealSplits(int mealsPerDay) {
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

/// Meal slot names for a given meals-per-day count.
List<String> mealTypes(int mealsPerDay) {
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

// ── Portion fitting ──────────────────────────────────────────────────────────

/// Adjust a day's portion grams so the day lands inside a tolerance band of its
/// target — changing how much is on the plate, never the nutrition attached to
/// an unchanged plate. A proportional pass followed by a bounded protein-first
/// correction is enough; there is no solver here.
///
/// [kcalTolerance] and [macroTolerance] are the acceptance bands. Returns the
/// fitted meals (grams may differ; per100g is untouched).
List<PlannedMeal> fitDay(
  List<PlannedMeal> meals,
  DayTarget target, {
  int kcalTolerance = 100,
  int macroTolerance = 15,
}) {
  if (meals.isEmpty) return meals;

  final flat = _flat(meals);
  if (flat.isEmpty) return meals;

  var totalCal = _sumCal(flat);
  if (totalCal <= 0) return meals;

  // 1) Proportional pass: scale every gram by target/current, clamped to
  //    bounds, iterated a few times to settle after clamping.
  for (var i = 0; i < 4; i++) {
    totalCal = _sumCal(flat);
    if (totalCal <= 0) break;
    final factor = target.calories / totalCal;
    var changed = false;
    for (final ref in flat) {
      final f = ref.food;
      final next = (f.grams * factor).clamp(f.minGrams, f.maxGrams);
      if (next != f.grams) {
        ref.food = f.copyWith(grams: next);
        changed = true;
      }
    }
    if (!changed) break;
  }

  // 2) Bounded protein-first correction.
  var currentProt = _sumProt(flat);
  final gap = target.protein - currentProt;
  if (gap.abs() > macroTolerance) {
    final ordered = [
      for (final ref in flat) (prot: _protPerCal(ref.food), ref: ref),
    ];
    // Protein density = protein per calorie. High helps add protein without
    // calories; low helps trim protein while dropping calories.
    ordered.sort((a, b) => b.prot.compareTo(a.prot));

    if (gap > 0) {
      // Need more protein; bump the densest foods first, holding the calorie
      // band and each food's portion ceiling.
      var remaining = gap;
      for (final e in ordered) {
        if (remaining <= macroTolerance) break;
        final f = e.ref.food;
        if (_protPerCal(f) <= 0) continue;
        final headroom = (target.calories + kcalTolerance) - _sumCal(flat);
        if (headroom <= 0) break;
        final cPerG = _calPerG(f);
        final pPerG = _protPerG(f);
        if (pPerG <= 0) continue;
        // Max grams we can add before hitting the calorie headroom.
        final maxByCal = cPerG <= 0 ? double.infinity : headroom / cPerG;
        final maxByCeil = f.maxGrams - f.grams;
        final add = [
          remaining * 100 / pPerG,
          maxByCal,
          maxByCeil,
        ].reduce((a, b) => a < b ? a : b);
        if (add <= 0) continue;
        final snapped = _snap(f.grams + add);
        final delta = snapped - f.grams;
        if (delta <= 0) continue;
        final protAdded = (pPerG * delta / 100).round();
        e.ref.food = f.copyWith(grams: snapped);
        remaining -= protAdded;
      }
    } else {
      // Too much protein; trim the densest foods toward the floor, holding the
      // calorie band and each food's portion floor.
      var remaining = -gap;
      for (final e in ordered) {
        if (remaining <= macroTolerance) break;
        final f = e.ref.food;
        final pPerG = _protPerG(f);
        if (pPerG <= 0) continue;
        final cPerG = _calPerG(f);
        // How much can we cut before calories fall below the lower band.
        final calFloor = (target.calories - kcalTolerance);
        final maxByCal =
            cPerG <= 0 ? double.infinity : (_sumCal(flat) - calFloor) / cPerG;
        final maxByFloor = f.grams - f.minGrams;
        final cut = [
          remaining * 100 / pPerG,
          maxByCal,
          maxByFloor,
        ].reduce((a, b) => a < b ? a : b);
        if (cut <= 0) continue;
        final snapped = _snap(f.grams - cut);
        final delta = f.grams - snapped;
        if (delta <= 0) continue;
        final protLost = (pPerG * delta / 100).round();
        e.ref.food = f.copyWith(grams: snapped);
        remaining -= protLost;
      }
    }
  }

  // 3) Final restructure back into meals, preserving the original slot/name.
  final fitted = List<PlannedMeal>.from(meals);
  for (final ref in flat) {
    final rebuiltFoods = List<PlannedFood>.from(fitted[ref.mi].foods);
    rebuiltFoods[ref.fi] = ref.food;
    fitted[ref.mi] = fitted[ref.mi].copyWith(foods: rebuiltFoods);
  }
  return fitted;
}

// ── Grocery aggregation ──────────────────────────────────────────────────────

/// Sum resolved foods across a horizon by a stable id (the nutrition-DB key,
/// falling back to a lowercased name when unresolved). Every occurrence of the
/// same food becomes one line carrying its *total* grams — fixing the
/// "first amount wins" bug — so oats across five days is "385 g oats", not
/// "1 cup oats".
///
/// Categories are derived from the resolved nutrition-DB id (an English slug)
/// before falling back to the display name, so the grouping still works for
/// ar/es/fr where ingredient names come back localized (BUG-017).
List<AggregatedFood> aggregateGroceries(List<PlannedMeal> meals) {
  final byId = <String, AggregatedFood>{};
  for (final meal in meals) {
    for (final food in meal.foods) {
      final id = food.foodId ?? 'name:${food.name.toLowerCase()}';
      final categorySource = food.foodId?.replaceAll('_', ' ') ?? food.name;
      final existing = byId[id];
      if (existing == null) {
        byId[id] = AggregatedFood(
          id: id,
          name: food.name,
          grams: food.grams,
          category: guessGroceryCategory(categorySource),
        );
      } else {
        byId[id] = AggregatedFood(
          id: id,
          name: existing.name,
          grams: existing.grams + food.grams,
          category: existing.category,
        );
      }
    }
  }
  return byId.values.toList();
}

// ── Category guessing (pure, DB-agnostic) ────────────────────────────────────

/// Best-effort grocery category for a food name. Kept pure and deterministic so
/// it is testable; a resolved DB entry supplies the canonical category later.
String guessGroceryCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('salmon') ||
      n.contains('tuna') ||
      n.contains('fish') ||
      n.contains('shrimp') ||
      n.contains('seafood')) {
    return 'Seafood';
  }
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
      n.contains('meat') ||
      n.contains('lentil') ||
      n.contains('chickpea') ||
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
      n.contains('avocado') ||
      n.contains('spinach') ||
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

// ── Internal helpers ─────────────────────────────────────────────────────────

/// Mutable reference to a single PlannedFood within a day, used by the fitter
/// so it can move grams in place then rebuild the meals once at the end.
class _Slot {
  final int mi;
  final int fi;
  PlannedFood food;
  _Slot(this.mi, this.fi, this.food);
}

List<_Slot> _flat(List<PlannedMeal> meals) => [
  for (var mi = 0; mi < meals.length; mi++)
    for (var fi = 0; fi < meals[mi].foods.length; fi++)
      _Slot(mi, fi, meals[mi].foods[fi]),
];

int _sumCal(List<_Slot> flat) => flat.fold(0, (s, r) => s + r.food.calories);
int _sumProt(List<_Slot> flat) => flat.fold(0, (s, r) => s + r.food.protein);

double _calPerG(PlannedFood f) => (f.per100g['calories'] ?? 0) / 100;
double _protPerG(PlannedFood f) => (f.per100g['protein'] ?? 0) / 100;

/// Protein per calorie. A high value means "adds protein without adding much
/// energy"; a low value means the food is calorie-heavy. Zero/per-negative is
/// caught by callers.
double _protPerCal(PlannedFood f) {
  final cal = f.per100g['calories'] ?? 0;
  final prot = f.per100g['protein'] ?? 0;
  if (cal <= 0) return 0;
  return prot / cal;
}

double _snap(double grams) => (grams.roundToDouble()).clamp(0, double.infinity);
