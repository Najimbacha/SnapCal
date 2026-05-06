/// Weekly nutrition report data model
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final double avgWater;
  final int totalSteps;
  final int daysOnTrack;
  final int daysLogged;
  final int currentStreak;
  final List<String> aiInsights;
  final List<double> dailyCalories;
  final List<double> dailyProtein;
  final List<double> dailyWater;
  final DateTime generatedAt;

  WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.avgWater,
    required this.totalSteps,
    required this.daysOnTrack,
    required this.daysLogged,
    required this.currentStreak,
    required this.aiInsights,
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyWater,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  double get calorieGoalDiff => avgCalories > 0 ? avgCalories : 0;
  bool get isNewThisWeek => generatedAt.isAfter(
    DateTime.now().subtract(const Duration(days: 7)),
  );
}
