import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/body_metric.dart';
import '../../data/models/meal.dart';

/// A period's nutrition, worked out from the meals actually logged.
///
/// The report used to show typed-in zeros -- "0" calories, "0%" consistency,
/// an empty chart and "0g" of every macro -- to every user, Pro included,
/// whatever they had logged. Everything here comes from real meals.
class NutritionReportSummary {
  const NutritionReportSummary({
    required this.days,
    required this.dailyCalories,
    required this.loggedDays,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
  });

  final int days;

  /// Calories per day, oldest first; zero for a day with nothing logged.
  final List<int> dailyCalories;
  final int loggedDays;

  /// Averages over the days that have meals, so a day that was simply not
  /// logged does not drag them down as if nothing had been eaten.
  final int avgCalories;
  final int avgProtein;
  final int avgCarbs;
  final int avgFat;

  /// The share of the period's days with at least one meal logged.
  int get consistencyPercent =>
      days == 0 ? 0 : (loggedDays * 100 / days).round();

  bool get hasData => loggedDays > 0;

  /// The highest day in the period, for scaling a chart.
  int get peakCalories =>
      dailyCalories.isEmpty ? 0 : dailyCalories.reduce((a, b) => a > b ? a : b);

  /// Logged days that went over [target]. Days with nothing logged are not
  /// counted as under: nothing was measured, so nothing is claimed.
  int daysOver(int target) =>
      target <= 0
          ? 0
          : dailyCalories.where((kcal) => kcal > 0 && kcal > target).length;

  int daysUnder(int target) =>
      target <= 0
          ? 0
          : dailyCalories.where((kcal) => kcal > 0 && kcal <= target).length;

  /// How far the average day sits from [target]: negative is under.
  int gapTo(int target) => target <= 0 ? 0 : avgCalories - target;

  /// Within a twentieth of the target either way counts as on it: nobody eats
  /// to the calorie, and "17 over" read as a failure.
  bool onTarget(int target) =>
      target > 0 && (gapTo(target)).abs() <= (target / 20);

  static NutritionReportSummary compute({
    required int days,
    required DateTime today,
    required List<Meal> Function(String date) mealsForDate,
  }) {
    final calories = <int>[];
    var logged = 0;
    var totalKcal = 0, protein = 0, carbs = 0, fat = 0;
    for (var i = days - 1; i >= 0; i--) {
      final date = app_date.DateUtils.getDateString(
        DateTime(today.year, today.month, today.day - i),
      );
      final meals = mealsForDate(date);
      final dayKcal = meals.fold<int>(0, (sum, m) => sum + m.calories);
      calories.add(dayKcal);
      if (meals.isEmpty) continue;
      logged++;
      totalKcal += dayKcal;
      protein += meals.fold<int>(0, (sum, m) => sum + m.macros.protein);
      carbs += meals.fold<int>(0, (sum, m) => sum + m.macros.carbs);
      fat += meals.fold<int>(0, (sum, m) => sum + m.macros.fat);
    }
    int average(int total) => logged == 0 ? 0 : (total / logged).round();
    return NutritionReportSummary(
      days: days,
      dailyCalories: calories,
      loggedDays: logged,
      avgCalories: average(totalKcal),
      avgProtein: average(protein),
      avgCarbs: average(carbs),
      avgFat: average(fat),
    );
  }
}

/// The weight side of the period: where it started, where it is, and whether
/// that is the direction the user asked for.
class WeightTrend {
  const WeightTrend({
    required this.startKg,
    required this.latestKg,
    required this.entries,
    required this.latestOn,
  });

  final double startKg;
  final double latestKg;

  /// Weigh-ins inside the period, oldest first.
  final List<BodyMetric> entries;
  final DateTime latestOn;

  double get changeKg => latestKg - startKg;

  /// A single weigh-in says where you are but nothing about a direction.
  bool get hasTrend => entries.length > 1;

  /// Reads the period's weigh-ins out of the full history.
  ///
  /// Returns null when the period holds nothing to show, so the screen can
  /// ask for a weigh-in instead of drawing an empty chart.
  static WeightTrend? from({
    required List<BodyMetric> all,
    required int days,
    required DateTime today,
  }) {
    final start = DateTime(today.year, today.month, today.day - (days - 1));
    final inPeriod =
        all.where((m) => !m.date.isBefore(start)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (inPeriod.isEmpty) return null;
    return WeightTrend(
      startKg: inPeriod.first.weight,
      latestKg: inPeriod.last.weight,
      entries: inPeriod,
      latestOn: inPeriod.last.date,
    );
  }
}
