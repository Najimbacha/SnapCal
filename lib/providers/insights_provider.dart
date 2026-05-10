import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/models/weekly_report.dart';
import '../data/services/gemini_service.dart';
import '../data/repositories/water_repository.dart';
import 'meal_provider.dart';
import 'settings_provider.dart';
import 'activity_provider.dart';
import '../core/utils/date_utils.dart' as app_date;

/// Provider for generating and managing Weekly AI Insights
class InsightsProvider with ChangeNotifier {
  final AIService _aiService = AIService();

  WeeklyReport? _currentReport;
  bool _isGenerating = false;
  String? _error;

  WeeklyReport? get currentReport => _currentReport;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get hasReport => _currentReport != null;

  /// Generate the weekly report by aggregating data from all providers
  Future<void> generateWeeklyReport({
    required MealProvider meals,
    required SettingsProvider settings,
    required ActivityProvider activity,
    required WaterRepository waterRepo,
    required String languageCode,
  }) async {
    if (_isGenerating) return;

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 6));

      // Aggregate 7 days of data
      final List<double> dailyCalories = [];
      final List<double> dailyProtein = [];
      final List<double> dailyCarbs = [];
      final List<double> dailyFat = [];
      final List<double> dailyWater = [];
      int daysOnTrack = 0;
      int daysLogged = 0;
      final calorieGoal = settings.dailyCalorieGoal;

      final weeklyMeals = meals.getWeeklyMeals();
      final weeklyWaterLogs = waterRepo.getWeeklyWater();

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateString = app_date.DateUtils.getDateString(date);

        // Meal data
        final dayMeals = weeklyMeals.where((m) => m.dateString == dateString).toList();
        final dayCal = dayMeals.fold<int>(0, (sum, m) => sum + m.calories).toDouble();
        final dayPro = dayMeals.fold<int>(0, (sum, m) => sum + m.macros.protein).toDouble();
        final dayCarb = dayMeals.fold<int>(0, (sum, m) => sum + m.macros.carbs).toDouble();
        final dayFat = dayMeals.fold<int>(0, (sum, m) => sum + m.macros.fat).toDouble();

        dailyCalories.add(dayCal);
        dailyProtein.add(dayPro);
        dailyCarbs.add(dayCarb);
        dailyFat.add(dayFat);

        // Water data
        final dayWaterLogs = weeklyWaterLogs.where((l) => l.dateString == dateString).toList();
        final dayWaterSum = dayWaterLogs.fold<int>(0, (sum, l) => sum + l.amountMl).toDouble();
        dailyWater.add(dayWaterSum);

        if (dayMeals.isNotEmpty) daysLogged++;
        if (dayCal > 0 && (dayCal - calorieGoal).abs() <= 100) daysOnTrack++;
      }

      final avgCal = dailyCalories.isNotEmpty
          ? dailyCalories.reduce((a, b) => a + b) / dailyCalories.length
          : 0.0;
      final avgPro = dailyProtein.isNotEmpty
          ? dailyProtein.reduce((a, b) => a + b) / dailyProtein.length
          : 0.0;
      final avgCarb = dailyCarbs.isNotEmpty
          ? dailyCarbs.reduce((a, b) => a + b) / dailyCarbs.length
          : 0.0;
      final avgFatVal = dailyFat.isNotEmpty
          ? dailyFat.reduce((a, b) => a + b) / dailyFat.length
          : 0.0;
      final avgWaterVal = dailyWater.isNotEmpty
          ? dailyWater.reduce((a, b) => a + b) / dailyWater.length
          : 0.0;

      // Generate AI insights
      List<String> aiInsights = [];
      try {
        aiInsights = await _generateAIInsights(
          avgCalories: avgCal,
          calorieGoal: calorieGoal,
          avgProtein: avgPro,
          proteinGoal: settings.dailyProteinGoal,
          avgCarbs: avgCarb,
          avgFat: avgFatVal,
          avgWater: avgWaterVal,
          daysOnTrack: daysOnTrack,
          daysLogged: daysLogged,
          currentStreak: settings.currentStreak,
          dailyProtein: dailyProtein,
          languageCode: languageCode,
        );
      } catch (e) {
        debugPrint('AI Insights Error: $e');
        aiInsights = _getFallbackInsights(avgCal, calorieGoal, daysOnTrack);
      }

      final weeklySteps = await activity.getWeeklySteps();

      _currentReport = WeeklyReport(
        weekStart: weekStart,
        weekEnd: now,
        avgCalories: avgCal,
        avgProtein: avgPro,
        avgCarbs: avgCarb,
        avgFat: avgFatVal,
        avgWater: avgWaterVal,
        totalSteps: weeklySteps,
        daysOnTrack: daysOnTrack,
        daysLogged: daysLogged,
        currentStreak: settings.currentStreak,
        aiInsights: aiInsights,
        dailyCalories: dailyCalories,
        dailyProtein: dailyProtein,
        dailyWater: dailyWater,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Weekly Report Error: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<List<String>> _generateAIInsights({
    required double avgCalories,
    required int calorieGoal,
    required double avgProtein,
    required int proteinGoal,
    required double avgCarbs,
    required double avgFat,
    required double avgWater,
    required int daysOnTrack,
    required int daysLogged,
    required int currentStreak,
    required List<double> dailyProtein,
    required String languageCode,
  }) async {
    final languageName = {
      'ar': 'Arabic', 'es': 'Spanish', 'fr': 'French'
    }[languageCode] ?? 'English';

    final prompt = '''
Analyze this weekly nutrition data and provide exactly 4 short, encouraging, actionable insights.
Be specific. Mention actual numbers. Use emoji at the start of each insight. 
Speak like a supportive coach, not a doctor.
RESPOND ENTIRELY IN $languageName.

Weekly Data:
- Average Calories: ${avgCalories.round()} kcal/day (Goal: $calorieGoal)
- Average Protein: ${avgProtein.round()}g/day (Goal: ${proteinGoal}g)
- Average Carbs: ${avgCarbs.round()}g/day
- Average Fat: ${avgFat.round()}g/day
- Average Water: ${avgWater.round()}ml/day
- Days on Track: $daysOnTrack/7
- Days Logged: $daysLogged/7
- Current Streak: $currentStreak days
- Daily Protein: ${dailyProtein.map((p) => p.round()).toList()}

Return ONLY a JSON array of 4 strings, no explanation. Example:
["insight 1", "insight 2", "insight 3", "insight 4"]
''';

    final response = await _aiService.generateText(prompt);
    
    // Parse the JSON array
    try {
      final cleaned = response.trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      // Try to split by newlines if JSON parsing fails
      return response.split('\n').where((l) => l.trim().isNotEmpty).take(4).toList();
    }
  }

  List<String> _getFallbackInsights(double avgCal, int goal, int daysOnTrack) {
    return [
      '📊 You averaged ${avgCal.round()} kcal/day this week.',
      '🎯 You were on track $daysOnTrack out of 7 days.',
      '💪 Keep logging consistently for better insights!',
      '🔥 Every day tracked is a step closer to your goal.',
    ];
  }
}
