import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/screens/reports/stats_data.dart';

Meal _meal(String date, int kcal) => Meal(
  id: '$date-$kcal',
  timestamp: 0,
  dateString: date,
  foodName: 'Food',
  calories: kcal,
  macros: Macros(protein: 30, carbs: 40, fat: 10),
);

BodyMetric _weight(DateTime date, double kg) =>
    BodyMetric(id: date.toIso8601String(), date: date, weight: kg);

void main() {
  final today = DateTime(2026, 9, 11, 15);

  NutritionReportSummary summarize(int days, Map<String, List<Meal>> byDate) =>
      NutritionReportSummary.compute(
        days: days,
        today: today,
        mealsForDate: (d) => byDate[d] ?? const [],
      );

  group('the headline numbers', () {
    test('a week under the target reports the gap, not a failure', () {
      final s = summarize(7, {
        '2026-09-09': [_meal('2026-09-09', 1800)],
        '2026-09-10': [_meal('2026-09-10', 1700)],
        '2026-09-11': [_meal('2026-09-11', 1900)],
      });

      expect(s.avgCalories, 1800);
      expect(s.gapTo(2000), -200);
      expect(s.onTarget(2000), isFalse);
      expect(s.loggedDays, 3);
      expect(s.consistencyPercent, 43);
    });

    test('within a twentieth of the target counts as on it', () {
      final s = summarize(1, {
        '2026-09-11': [_meal('2026-09-11', 2080)],
      });

      expect(s.gapTo(2000), 80);
      expect(s.onTarget(2000), isTrue);
    });

    test('a day with nothing logged is not counted as a day under', () {
      final s = summarize(3, {
        '2026-09-11': [_meal('2026-09-11', 2400)],
      });

      expect(s.daysOver(2000), 1);
      // Two days hold no meals: nothing was measured, so nothing is claimed.
      expect(s.daysUnder(2000), 0);
    });

    test('no target means no gap to report rather than a wild number', () {
      final s = summarize(1, {
        '2026-09-11': [_meal('2026-09-11', 2400)],
      });

      expect(s.gapTo(0), 0);
      expect(s.onTarget(0), isFalse);
      expect(s.daysOver(0), 0);
    });

    test('an empty period has nothing to show', () {
      final s = summarize(7, {});

      expect(s.hasData, isFalse);
      expect(s.avgCalories, 0);
      expect(s.peakCalories, 0);
      expect(s.consistencyPercent, 0);
    });

    test('the peak scales the chart, and the target can exceed it', () {
      final s = summarize(2, {
        '2026-09-10': [_meal('2026-09-10', 1200)],
        '2026-09-11': [_meal('2026-09-11', 1500)],
      });

      expect(s.peakCalories, 1500);
      expect(s.dailyCalories, [1200, 1500]);
    });
  });

  group('the weight trend', () {
    test('reads only the weigh-ins inside the period, oldest first', () {
      final trend = WeightTrend.from(
        days: 7,
        today: today,
        all: [
          _weight(DateTime(2026, 9, 11), 79.0),
          // Older than the window: belongs to a longer period, not this one.
          _weight(DateTime(2026, 8, 20), 84.0),
          _weight(DateTime(2026, 9, 6), 80.5),
        ],
      );

      expect(trend, isNotNull);
      expect(trend!.entries.length, 2);
      expect(trend.startKg, 80.5);
      expect(trend.latestKg, 79.0);
      expect(trend.changeKg, closeTo(-1.5, 0.001));
      expect(trend.hasTrend, isTrue);
    });

    test('a single weigh-in gives a weight but no direction', () {
      final trend = WeightTrend.from(
        days: 7,
        today: today,
        all: [_weight(DateTime(2026, 9, 10), 77.2)],
      );

      expect(trend!.hasTrend, isFalse);
      expect(trend.changeKg, 0);
    });

    test('nothing in the period returns null, so the screen can ask', () {
      final trend = WeightTrend.from(
        days: 7,
        today: today,
        all: [_weight(DateTime(2026, 7, 1), 88.0)],
      );

      expect(trend, isNull);
    });

    test('an empty history returns null rather than an empty chart', () {
      expect(
        WeightTrend.from(days: 30, today: today, all: const []),
        isNull,
      );
    });
  });
}
