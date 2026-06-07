import 'onboarding_draft.dart';

class OnboardingPaceCalculator {
  OnboardingPaceCalculator._();

  static const double _caloriesPerKg = 7700.0;

  static double weeklyRateKgFor(GoalType goal, Pace pace) {
    switch (goal) {
      case GoalType.loseWeight:
        switch (pace) {
          case Pace.gentle:
            return 0.25;
          case Pace.balanced:
            return 0.50;
          case Pace.faster:
            return 0.75;
        }
      case GoalType.buildMuscle:
        switch (pace) {
          case Pace.gentle:
            return 0.125;
          case Pace.balanced:
            return 0.250;
          case Pace.faster:
            return 0.375;
        }
      case GoalType.maintainWeight:
      case GoalType.trackNutrition:
        return 0;
    }
  }

  static DateTime estimatedTargetDate(
    double currentKg,
    double targetKg,
    double weeklyRateKg,
  ) {
    if (weeklyRateKg <= 0 || (targetKg - currentKg).abs() < 0.001) {
      return DateTime.now();
    }
    final deltaKg = (targetKg - currentKg).abs();
    final weeks = deltaKg / weeklyRateKg;
    final days = (weeks * 7).round();
    return DateTime.now().add(Duration(days: days));
  }

  static int deriveTimelineMonths(double deltaKg, double weeklyRateKg) {
    if (weeklyRateKg <= 0 || deltaKg.abs() < 0.001) return 1;
    final weeks = deltaKg.abs() / weeklyRateKg;
    final months = (weeks / 4.345).ceil();
    return months.clamp(1, 24).toInt();
  }

  static double dailyCalorieAdjustmentFromWeeklyRate(double weeklyRateKg) {
    return weeklyRateKg * _caloriesPerKg / 7;
  }

  static String formatWeeklyRateValue(
    double weeklyRateKg,
    MeasurementSystem system,
  ) {
    if (system == MeasurementSystem.imperial) {
      return (weeklyRateKg * 2.20462).toStringAsFixed(1);
    }
    return weeklyRateKg
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String weeklyRateUnit(MeasurementSystem system) {
    return system == MeasurementSystem.metric ? 'kg' : 'lb';
  }
}
