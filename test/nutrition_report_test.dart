import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/screens/reports/widgets/nutrition_report_view.dart';

Meal _meal(String date, int kcal, {int p = 0, int c = 0, int f = 0}) => Meal(
  id: '$date-$kcal',
  timestamp: 0,
  dateString: date,
  foodName: 'Food',
  calories: kcal,
  macros: Macros(protein: p, carbs: c, fat: f),
);

void main() {
  final today = DateTime(2026, 9, 11, 15);

  NutritionReportSummary summarize(int days, Map<String, List<Meal>> byDate) =>
      NutritionReportSummary.compute(
        days: days,
        today: today,
        mealsForDate: (d) => byDate[d] ?? const [],
      );

  test('an empty period reports nothing logged, not made-up numbers', () {
    final s = summarize(7, {});
    expect(s.loggedDays, 0);
    expect(s.consistencyPercent, 0);
    expect(s.avgCalories, 0);
    expect(s.dailyCalories, List.filled(7, 0));
  });

  test('averages cover logged days only; consistency counts them', () {
    final s = summarize(7, {
      '2026-09-11': [
        _meal('2026-09-11', 500, p: 30, c: 50, f: 10),
        _meal('2026-09-11', 700, p: 40, c: 60, f: 20),
      ],
      '2026-09-09': [_meal('2026-09-09', 1800, p: 110, c: 190, f: 60)],
      // Outside the last 7 days: ignored.
      '2026-09-04': [_meal('2026-09-04', 9999)],
    });
    expect(s.loggedDays, 2);
    expect(s.consistencyPercent, 29); // 2 of 7
    expect(s.avgCalories, 1500); // (1200 + 1800) / 2
    expect(s.avgProtein, 90);
    expect(s.avgCarbs, 150);
    expect(s.avgFat, 45);
    // Oldest first, today last.
    expect(s.dailyCalories, [0, 0, 0, 0, 1800, 0, 1200]);
  });

  test('monthly covers 30 days and crosses month ends', () {
    final s = summarize(30, {
      '2026-08-13': [_meal('2026-08-13', 2000)],
      '2026-08-12': [_meal('2026-08-12', 2000)], // day 31: outside
    });
    expect(s.dailyCalories.length, 30);
    expect(s.dailyCalories.first, 2000);
    expect(s.loggedDays, 1);
    expect(s.consistencyPercent, 3);
  });
}
