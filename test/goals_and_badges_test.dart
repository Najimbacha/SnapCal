import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/providers/achievements_provider.dart';

Meal _meal(String date, int kcal, {int p = 0, int c = 0, int f = 0}) => Meal(
  id: '$date-$kcal-$p',
  timestamp: 0,
  dateString: date,
  foodName: 'Food',
  calories: kcal,
  macros: Macros(protein: p, carbs: c, fat: f),
);

void main() {
  group('water goal from body weight', () {
    test('about 35 ml per kilo, rounded and kept sensible', () {
      expect(waterGoalForWeightKg(70), 2450);
      expect(waterGoalForWeightKg(60), 2100);
      // Very light and very heavy people stay inside drinkable bounds.
      expect(waterGoalForWeightKg(30), 1500);
      expect(waterGoalForWeightKg(200), 4000);
    });

    test('no weight means the old fixed goal', () {
      expect(waterGoalForWeightKg(null), 2500);
      expect(waterGoalForWeightKg(0), 2500);
      expect(UserSettings.defaults().effectiveWaterGoalMl, 2500);
    });

    test('a goal the user set wins over the calculated one', () {
      final settings = UserSettings.defaults().copyWith(
        startingWeight: 70,
        waterGoalMl: 3000,
      );
      expect(settings.effectiveWaterGoalMl, 3000);
      expect(
        UserSettings.defaults()
            .copyWith(startingWeight: 70)
            .effectiveWaterGoalMl,
        2450,
      );
    });
  });

  group('badge progress', () {
    final today = DateTime(2026, 9, 12);
    final settings = UserSettings.defaults().copyWith(
      dailyCalorieGoal: 2000,
      dailyProteinGoal: 100,
      dailyCarbGoal: 200,
      dailyFatGoal: 60,
      currentStreak: 4,
    );

    AchievementStats statsFor({
      List<Meal> meals = const [],
      Map<String, int> water = const {},
      int waterGoal = 2500,
      int photos = 0,
    }) => AchievementStats.from(
      meals: meals,
      waterByDate: water,
      waterGoalMl: waterGoal,
      settings: settings,
      photosLogged: photos,
      today: today,
    );

    test('an empty diary earns nothing', () {
      final stats = statsFor();
      expect(stats.totalMealsLogged, 0);
      expect(stats.calorieGoalStreak, 0);
      expect(stats.waterGoalDays, 0);
      expect(stats.perfectWeekDays, 0);
      expect(stats.hitMacrosToday, isFalse);
    });

    test('days within a tenth of the calorie goal make a streak', () {
      final stats = statsFor(
        meals: [
          _meal('2026-09-12', 1950),
          _meal('2026-09-11', 2100),
          _meal('2026-09-10', 1900),
          // Well under: the streak stops here.
          _meal('2026-09-09', 900),
          _meal('2026-09-08', 2000),
        ],
      );
      expect(stats.calorieGoalStreak, 3);
      expect(stats.totalMealsLogged, 5);
    });

    test('a day still in progress does not break yesterday\'s streak', () {
      final stats = statsFor(
        meals: [
          // Nothing logged today yet.
          _meal('2026-09-11', 2000),
          _meal('2026-09-10', 2000),
        ],
      );
      expect(stats.calorieGoalStreak, 2);
    });

    test('water days count only when the goal is reached', () {
      final stats = statsFor(
        water: {
          '2026-09-12': 2600,
          '2026-09-11': 2500,
          '2026-09-10': 1200,
          '2025-01-01': 3000,
        },
      );
      expect(stats.waterGoalDays, 3);
    });

    test('a perfect day needs both the calories and the water', () {
      final stats = statsFor(
        meals: [_meal('2026-09-12', 2000), _meal('2026-09-11', 2000)],
        water: {'2026-09-12': 2500, '2026-09-11': 1000},
      );
      expect(stats.perfectWeekDays, 1);
    });

    test('today\'s macros count when all three are close', () {
      final close = statsFor(
        meals: [_meal('2026-09-12', 2000, p: 95, c: 205, f: 58)],
      );
      expect(close.hitMacrosToday, isTrue);

      final proteinShort = statsFor(
        meals: [_meal('2026-09-12', 2000, p: 40, c: 205, f: 58)],
      );
      expect(proteinShort.hitMacrosToday, isFalse);
    });

    test('photos and the streak are carried through', () {
      final stats = statsFor(photos: 3);
      expect(stats.photosLogged, 3);
      expect(stats.currentStreak, 4);
    });
  });
}
