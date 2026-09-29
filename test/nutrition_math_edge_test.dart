import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/utils/date_utils.dart' as app_date;
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/quick_food.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/providers/calorie_budget_provider.dart';

const _rice = QuickFood(
  nutritionId: 'rice',
  name: 'Rice',
  caloriesPer100g: 130,
  proteinPer100g: 2.7,
  carbsPer100g: 28.2,
  fatPer100g: 0.3,
  defaultServingG: 150,
  regions: {'international'},
);

void main() {
  group('a serving of a food', () {
    test('scales with its weight', () {
      expect(_rice.caloriesFor(100), 130);
      expect(_rice.caloriesFor(200), 260);
      expect(_rice.caloriesFor(150), 195);
      final macros = _rice.macrosFor(200);
      expect(macros.protein, 5); // 5.4
      expect(macros.carbs, 56); // 56.4
      expect(macros.fat, 1); // 0.6
    });

    test('rounds a part-gram serving to the nearest calorie', () {
      expect(_rice.caloriesFor(0.5), 1); // 0.65
      expect(_rice.caloriesFor(33.3), 43); // 43.29
      expect(_rice.caloriesFor(115.0), 150); // 149.5 rounds up
    });

    test('is nothing at zero or below, never negative', () {
      expect(_rice.caloriesFor(0), 0);
      expect(_rice.caloriesFor(-50), 0);
      final none = _rice.macrosFor(-50);
      expect([none.protein, none.carbs, none.fat], [0, 0, 0]);
    });

    test('stays exact for a very large serving', () {
      expect(_rice.caloriesFor(5000), 6500);
      expect(_rice.macrosFor(5000).carbs, 1410);
    });
  });

  group('the day\'s calorie budget', () {
    test('1,200 eaten of 2,000 leaves 800; 300 more leaves 500', () {
      expect(const CalorieBudget(eaten: 1200, baseGoal: 2000).left, 800);
      expect(const CalorieBudget(eaten: 1500, baseGoal: 2000).left, 500);
    });

    test('going over the goal shows how far over, as a negative', () {
      const over = CalorieBudget(eaten: 2350, baseGoal: 2000);
      expect(over.left, -350);
      expect(over.progress, closeTo(1.175, 0.0001));
    });

    test('walking calories raise the goal for the day', () {
      const budget = CalorieBudget(
        eaten: 1500,
        baseGoal: 2000,
        activityBonus: 320,
      );
      expect(budget.goal, 2320);
      expect(budget.left, 820);
    });

    test('the ring never overflows and never divides by zero', () {
      expect(const CalorieBudget(eaten: 0, baseGoal: 2000).progress, 0);
      expect(const CalorieBudget(eaten: 9000, baseGoal: 2000).progress, 1.4);
      expect(const CalorieBudget(eaten: 500, baseGoal: 0).progress, 1.4);
      expect(const CalorieBudget(eaten: 0, baseGoal: 0).progress, 0);
    });
  });

  group('a scan reply', () {
    test('uses the matched serving over the top-level figures', () {
      final result = NutritionResult.fromJson({
        'food_name': 'French fries',
        'calories': 999,
        'nutrition': {
          'per100g': {'calories': 312, 'protein': 3.4},
          'actual': {'calories': 468, 'protein': 5, 'carbs': 62, 'fat': 22},
        },
        'weight_g': 150,
      });
      expect(result.calories, 468);
      expect(result.protein, 5);
      expect(result.carbs, 62);
      expect(result.fat, 22);
      expect(result.weightG, 150);
      expect(result.nutritionPer100g, {'calories': 312, 'protein': 3.4});
      expect(result.matched, isTrue);
    });

    test('reads numbers sent as text or with decimals', () {
      final result = NutritionResult.fromJson({
        'food_name': 'Dal',
        'calories': '250',
        'protein': 12.6,
        'carbs': '30',
        'fat': 'a lot',
      });
      expect(result.calories, 250);
      expect(result.protein, 13);
      expect(result.carbs, 30);
      expect(result.fat, 0);
    });

    test('never shows negative or impossible figures', () {
      final result = NutritionResult.fromJson({
        'food_name': 'Glitch',
        'calories': -200,
        'protein': 9000,
        'carbs': 9000,
        'fat': -1,
        'health_score': 42,
      });
      expect(result.calories, 0);
      expect(result.protein, 500);
      expect(result.carbs, 800);
      expect(result.fat, 0);
      expect(result.healthScore, 10);
      expect(NutritionResult.fromJson({'calories': 99999}).calories, 5000);
    });

    test('an empty reply is an unknown food at zero, not a crash', () {
      final result = NutritionResult.fromJson({});
      expect(result.foodName, 'Unknown Food');
      expect(result.portion, 'Standard portion');
      expect(result.calories, 0);
      expect(result.healthScore, 5);
      expect(result.insights, isEmpty);
      expect(result.matched, isFalse);
      expect(
        NutritionResult.fromJson({'food_name': '   '}).foodName,
        'Unknown Food',
      );
    });

    test(
      'ignores fields it does not know and nutrition of the wrong shape',
      () {
        final result = NutritionResult.fromJson({
          'food_name': 'Tea',
          'calories': 2,
          'nutrition': 'n/a',
          'brand_new_field': {'nested': true},
          'insights': [1, 'Low sugar'],
        });
        expect(result.calories, 2);
        expect(result.nutritionPer100g, isNull);
        expect(result.insights, ['1', 'Low sugar']);
      },
    );

    test('a food the server says it did not match stays unmatched', () {
      final result = NutritionResult.fromJson({
        'food_name': 'Mystery stew',
        'calories': 300,
        'matched': false,
      });
      expect(result.matched, isFalse);
    });
  });

  group('a meal read back from the cloud', () {
    test('keeps every field through a round trip', () {
      final meal = Meal(
        id: 'm1',
        timestamp: 1767225540000,
        dateString: '2025-12-31',
        foodName: 'Biryani',
        calories: 585,
        macros: Macros(protein: 24, carbs: 84, fat: 18),
        mealType: 'Dinner',
        portion: '300 g',
        scanConfidence: 0.9,
        scanSource: 'ai_scan',
        originalCalories: 600,
        userCorrected: true,
        weightG: 300,
        nutritionMatchId: 'biryani',
        nutritionPer100g: {'calories': 195.0},
      );
      final back = Meal.fromJson(meal.toJson());
      expect(back.toJson(), meal.toJson());
    });

    test('accepts figures stored with decimals', () {
      final meal = Meal.fromJson({
        'id': 'm2',
        'timestamp': 1,
        'dateString': '2026-01-01',
        'foodName': 'Soup',
        'calories': 120.6,
        'macros': {'protein': 4.4, 'carbs': 15.5, 'fat': 3.0},
        'weightG': 250,
      });
      expect(meal.calories, 121);
      expect(meal.macros.protein, 4);
      expect(meal.macros.carbs, 16);
      expect(meal.macros.fat, 3);
      expect(meal.weightG, 250.0);
      expect(meal.synced, isFalse);
      expect(meal.userCorrected, isFalse);
    });
  });

  group('which meal a time of day belongs to', () {
    String at(int hour, [int minute = 0]) => app_date
        .DateUtils.suggestedMealType(DateTime(2026, 9, 30, hour, minute));

    test('changes exactly on the hour', () {
      expect(at(0), 'Snack');
      expect(at(4, 59), 'Snack');
      expect(at(5), 'Breakfast');
      expect(at(10, 59), 'Breakfast');
      expect(at(11), 'Lunch');
      expect(at(15, 59), 'Lunch');
      expect(at(16), 'Snack');
      expect(at(17, 59), 'Snack');
      expect(at(18), 'Dinner');
      expect(at(22, 59), 'Dinner');
      expect(at(23), 'Snack');
      expect(at(23, 59), 'Snack');
    });
  });

  group('the day a meal is filed under', () {
    test('changes at midnight, not before', () {
      expect(
        app_date.DateUtils.getDateString(
          DateTime(2025, 12, 31, 23, 59, 59, 999),
        ),
        '2025-12-31',
      );
      expect(
        app_date.DateUtils.getDateString(DateTime(2026, 1, 1)),
        '2026-01-01',
      );
    });

    test('rolls over month ends, leap days and years', () {
      expect(app_date.DateUtils.getNextDay('2024-02-28'), '2024-02-29');
      expect(app_date.DateUtils.getNextDay('2024-02-29'), '2024-03-01');
      expect(app_date.DateUtils.getNextDay('2025-02-28'), '2025-03-01');
      expect(app_date.DateUtils.getNextDay('2025-04-30'), '2025-05-01');
      expect(app_date.DateUtils.getPreviousDay('2026-01-01'), '2025-12-31');
      expect(app_date.DateUtils.getPreviousDay('2024-03-01'), '2024-02-29');
    });

    test('a damaged stored date falls back to today instead of crashing', () {
      final today = app_date.DateUtils.getTodayString();
      // An out-of-range date such as 2026-13-40 is rolled forward by Dart
      // (to 2027-02-09) rather than rejected; it still never throws.
      expect(() => app_date.DateUtils.parseDate('2026-13-40'), returnsNormally);
      for (final bad in ['', 'garbage', '2026-09']) {
        expect(
          app_date.DateUtils.getDateString(app_date.DateUtils.parseDate(bad)),
          today,
          reason: bad,
        );
      }
      expect(
        app_date.DateUtils.getDateString(
          app_date.DateUtils.parseDate('2026-9-5'),
        ),
        '2026-09-05',
      );
    });

    test('today is neither past nor future; tomorrow is future', () {
      final today = app_date.DateUtils.getTodayString();
      expect(app_date.DateUtils.isToday(today), isTrue);
      expect(app_date.DateUtils.isFuture(today), isFalse);
      expect(
        app_date.DateUtils.isFuture(app_date.DateUtils.getNextDay(today)),
        isTrue,
      );
      expect(
        app_date.DateUtils.isFuture(app_date.DateUtils.getPreviousDay(today)),
        isFalse,
      );
    });
  });
}
