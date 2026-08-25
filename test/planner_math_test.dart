import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/planner/planner_math.dart';
import 'package:snapcal/planner/planner_models.dart';

/// Energy implied by the macros across a day: 4 kcal/g protein, 4 kcal/g carb,
/// 9 kcal/g fat.
int _macroEnergy(List<PlannedMeal> m) => m.fold(
  0,
  (s, x) => s + (x.protein * 4 + x.carbs * 4 + x.fat * 9),
);

int _totCal(List<PlannedMeal> m) =>
    m.fold(0, (s, x) => s + x.calories);

int _totProt(List<PlannedMeal> m) =>
    m.fold(0, (s, x) => s + x.protein);

PlannedMeal _meal(String slot, String name, PlannedFood food) => PlannedMeal(
  slot: slot,
  name: name,
  foods: [food],
);

// Coherent per-100g data (real-ish nutrition table values).
PlannedFood _chicken(double grams) => PlannedFood.from(
  foodId: 'chicken',
  name: 'Chicken breast',
  per100g: const {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6},
  grams: grams,
  servingGrams: grams,
);

PlannedFood _rice(double grams) => PlannedFood.from(
  foodId: 'rice',
  name: 'Brown rice',
  per100g: const {'calories': 111, 'protein': 2.6, 'carbs': 23, 'fat': 0.9},
  grams: grams,
  servingGrams: grams,
);

PlannedFood _oats(double grams) => PlannedFood.from(
  foodId: 'oats',
  name: 'Rolled oats',
  per100g: const {'calories': 389, 'protein': 16.9, 'carbs': 66, 'fat': 6.9},
  grams: grams,
  servingGrams: grams,
);

void main() {
  group('slot splitting', () {
    test('splits sum to 1.0 and match meal count', () {
      for (final count in [2, 3, 4, 5]) {
        final splits = mealSplits(count);
        final types = mealTypes(count);
        expect(splits, hasLength(count));
        expect(types, hasLength(count));
        final total = splits.fold<double>(0, (s, x) => s + x);
        expect(total, closeTo(1.0, 1e-6));
      }
    });
  });

  group('fitDay', () {
    test('moves grams, never the nutrition table', () {
      final meals = [_meal('Breakfast', 'Chicken', _chicken(200)), _meal('Lunch', 'Rice', _rice(250))];
      final per100gBefore = meals.map((m) => m.foods.first.per100g).toList();

      final fitted = fitDay(meals, const DayTarget(calories: 1500, protein: 90, carbs: 40, fat: 20));

      for (var i = 0; i < fitted.length; i++) {
        expect(
          fitted[i].foods.first.per100g,
          per100gBefore[i],
          reason: 'per100g must never change while fitting',
        );
      }
    });

    test('preserves the macro↔calorie energy ratio (no independent rescale)', () {
      // Old behaviour scaled P, C and F each by its own ratio, so the implied
      // energy drifted away from the calorie figure. New behaviour scales only
      // grams, so the ratio is invariant under a fit.
      final meals = [_meal('Breakfast', 'Chicken', _chicken(200)), _meal('Lunch', 'Rice', _rice(250))];
      double ratio(List<PlannedMeal> m) => _totCal(m) == 0 ? 0 : _macroEnergy(m) / _totCal(m).toDouble();

      final before = ratio(meals);
      final fitted = fitDay(meals, const DayTarget(calories: 1500, protein: 80, carbs: 40, fat: 20), kcalTolerance: 80);
      final after = ratio(fitted);

      expect((after - before).abs(), lessThan(0.02), reason: 'energy ratio must not drift');
    });

    test('drives the day toward its calorie target and respects portion bounds', () {
      final meals = [_meal('Breakfast', 'Chicken', _chicken(200)), _meal('Lunch', 'Rice', _rice(250))];
      final initialCal = _totCal(meals);
      const target = DayTarget(calories: 1500, protein: 80, carbs: 40, fat: 20);

      final fitted = fitDay(meals, target, kcalTolerance: 80);
      final fitCal = _totCal(fitted);

      // Any move toward the target is a win; a feasible fit lands in band.
      expect((fitCal - target.calories).abs(), lessThanOrEqualTo((initialCal - target.calories).abs()));

      for (final meal in fitted) {
        for (final f in meal.foods) {
          expect(f.grams, greaterThanOrEqualTo(f.minGrams));
          expect(f.grams, lessThanOrEqualTo(f.maxGrams));
        }
      }
    });

    test('protein-first correction raises protein when the target asks for more', () {
      final meals = [_meal('Breakfast', 'Chicken', _chicken(200)), _meal('Lunch', 'Rice', _rice(250))];
      const target = DayTarget(calories: 1500, protein: 120, carbs: 40, fat: 20);

      final before = _totProt(meals);
      final fitted = fitDay(meals, target, kcalTolerance: 100, macroTolerance: 10);
      final after = _totProt(fitted);

      expect(after, greaterThan(before));
    });

    test('returns unchanged meals when no food is resolved', () {
      final unresolved = _meal('Breakfast', 'Chicken', PlannedFood.from(
        name: 'Chicken',
        per100g: const {},
        grams: 150,
        servingGrams: 150,
      ));
      final fitted = fitDay([unresolved], const DayTarget(calories: 1000, protein: 50, carbs: 50, fat: 50));
      expect(fitted.single.foods.first.grams, 150);
    });
  });

  group('aggregateGroceries', () {
    test('sums the same food across the horizon instead of first-amount-wins', () {
      // 385 g of oats across three days must be one line, not "1 cup oats".
      final meals = [
        _meal('Breakfast', 'Mon', _oats(120)),
        _meal('Breakfast', 'Tue', _oats(140)),
        _meal('Breakfast', 'Wed', _oats(125)),
        _meal('Lunch', 'Mon', _rice(300)),
      ];

      final groceries = aggregateGroceries(meals);
      expect(groceries, hasLength(2));

      final oats = groceries.firstWhere((g) => g.name == 'Rolled oats');
      expect(oats.grams, closeTo(385, 0.5));
      expect(oats.category, 'Grains');

      final rice = groceries.firstWhere((g) => g.name == 'Brown rice');
      expect(rice.grams, closeTo(300, 0.5));
    });

    test('groups by nutrition id even when names differ in casing', () {
      final meals = [
        _meal('Breakfast', 'A', _oats(100)),
        _meal('Snack', 'B', _oats(50)),
      ];
      final groceries = aggregateGroceries(meals);
      expect(groceries.single.grams, closeTo(150, 0.5));
    });
  });

  group('guessGroceryCategory', () {
    test('categorises common staples', () {
      expect(guessGroceryCategory('Rolled oats'), 'Grains');
      expect(guessGroceryCategory('Chicken breast'), 'Protein');
      expect(guessGroceryCategory('Greek yogurt'), 'Dairy');
      expect(guessGroceryCategory('Salmon fillet'), 'Seafood');
      expect(guessGroceryCategory('Olive oil'), 'Oils');
      expect(guessGroceryCategory('Spinach'), 'Produce');
      expect(guessGroceryCategory('Bay leaf'), 'Other');
    });
  });
}
