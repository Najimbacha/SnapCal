import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/weekly_report.dart';
import '../data/services/gemini_service.dart';
import '../data/repositories/water_repository.dart';
import '../core/utils/date_utils.dart' as app_date;
import 'meal_provider.dart';
import 'settings_provider.dart';
import 'repository_providers.dart';

part 'insights_provider.g.dart';

@Riverpod(keepAlive: true)
class Insights extends _$Insights {
  final AIService _aiService = AIService();

  @override
  Future<WeeklyReport?> build() => Future.value(null);

  Future<void> generateWeeklyReport({required String languageCode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final settings = await ref.read(settingsProvider.future);
      final waterRepo = await ref.read(waterRepositoryProvider.future);
      final repo = await ref.read(mealRepositoryProvider.future);

      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 6));

      final List<double> dailyCalories = [], dailyProtein = [], dailyCarbs = [], dailyFat = [], dailyWater = [];
      int daysOnTrack = 0, daysLogged = 0;
      final calorieGoal = settings.dailyCalorieGoal;

      final allMeals = repo.getAllMeals();
      final weekAgo = now.subtract(const Duration(days: 7));
      final weeklyMeals = allMeals.where((m) => DateTime.fromMillisecondsSinceEpoch(m.timestamp).isAfter(weekAgo)).toList();
      final weeklyWaterLogs = await waterRepo.getWeeklyWater();

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = app_date.DateUtils.getDateString(date);
        final dayMeals = weeklyMeals.where((m) => m.dateString == dateStr).toList();
        final dayCal = dayMeals.fold<double>(0, (s, m) => s + m.calories);
        final dayPro = dayMeals.fold<double>(0, (s, m) => s + m.macros.protein);
        final dayCarb = dayMeals.fold<double>(0, (s, m) => s + m.macros.carbs);
        final dayFat = dayMeals.fold<double>(0, (s, m) => s + m.macros.fat);
        dailyCalories.add(dayCal); dailyProtein.add(dayPro); dailyCarbs.add(dayCarb); dailyFat.add(dayFat);
        final dayWaterLogs = weeklyWaterLogs.where((l) => l.dateString == dateStr).toList();
        dailyWater.add(dayWaterLogs.fold<double>(0, (s, l) => s + l.amountMl));
        if (dayMeals.isNotEmpty) daysLogged++;
        if (dayCal > 0 && (dayCal - calorieGoal).abs() <= 100) daysOnTrack++;
      }

      double avg(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
      final avgCal = avg(dailyCalories), avgPro = avg(dailyProtein), avgCarb = avg(dailyCarbs);
      final avgFatVal = avg(dailyFat), avgWaterVal = avg(dailyWater);

      List<String> aiInsights = [];
      try {
        aiInsights = await _generateAIInsights(
          avgCalories: avgCal, calorieGoal: calorieGoal,
          avgProtein: avgPro, proteinGoal: settings.dailyProteinGoal,
          avgCarbs: avgCarb, avgFat: avgFatVal, avgWater: avgWaterVal,
          daysOnTrack: daysOnTrack, daysLogged: daysLogged,
          currentStreak: settings.currentStreak, dailyProtein: dailyProtein,
          languageCode: languageCode,
        );
      } catch (e) {
        debugPrint('AI Insights Error: $e');
        aiInsights = ['📊 You averaged ${avgCal.round()} kcal/day this week.', '🎯 You were on track $daysOnTrack out of 7 days.', '💪 Keep logging consistently for better insights!', '🔥 Every day tracked is a step closer to your goal.'];
      }

      return WeeklyReport(
        weekStart: weekStart, weekEnd: now,
        avgCalories: avgCal, avgProtein: avgPro, avgCarbs: avgCarb,
        avgFat: avgFatVal, avgWater: avgWaterVal,
        totalSteps: 0, daysOnTrack: daysOnTrack, daysLogged: daysLogged,
        currentStreak: settings.currentStreak, aiInsights: aiInsights,
        dailyCalories: dailyCalories, dailyProtein: dailyProtein, dailyWater: dailyWater,
      );
    });
  }

  Future<List<String>> _generateAIInsights({
    required double avgCalories, required int calorieGoal,
    required double avgProtein, required int proteinGoal,
    required double avgCarbs, required double avgFat,
    required double avgWater, required int daysOnTrack,
    required int daysLogged, required int currentStreak,
    required List<double> dailyProtein, required String languageCode,
  }) async {
    final languageName = {'ar': 'Arabic', 'es': 'Spanish', 'fr': 'French'}[languageCode] ?? 'English';
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
    try {
      final cleaned = response.trim().replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      return response.split('\n').where((l) => l.trim().isNotEmpty).take(4).toList();
    }
  }
}
