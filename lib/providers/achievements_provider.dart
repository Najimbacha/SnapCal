import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/models/achievement.dart';
import '../data/models/meal.dart';
import '../data/models/user_settings.dart';
import 'metrics_provider.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

part 'achievements_provider.g.dart';

class AchievementDefs {
  static List<Achievement> all() => [
    Achievement(
      id: 'first_flame',
      titleKey: 'achievement_first_flame',
      descriptionKey: 'achievement_first_flame_desc',
      emoji: '🕯️',
      categoryIndex: 0,
      targetValue: 1,
    ),
    Achievement(
      id: 'consistency_king',
      titleKey: 'achievement_consistency_king',
      descriptionKey: 'achievement_consistency_king_desc',
      emoji: '🔥',
      categoryIndex: 0,
      targetValue: 7,
    ),
    Achievement(
      id: 'iron_will',
      titleKey: 'achievement_iron_will',
      descriptionKey: 'achievement_iron_will_desc',
      emoji: '⚡',
      categoryIndex: 0,
      targetValue: 30,
    ),
    Achievement(
      id: 'unstoppable',
      titleKey: 'achievement_unstoppable',
      descriptionKey: 'achievement_unstoppable_desc',
      emoji: '💎',
      categoryIndex: 0,
      targetValue: 100,
    ),
    Achievement(
      id: 'bullseye',
      titleKey: 'achievement_bullseye',
      descriptionKey: 'achievement_bullseye_desc',
      emoji: '🎯',
      categoryIndex: 1,
      targetValue: 1,
    ),
    Achievement(
      id: 'precision_pro',
      titleKey: 'achievement_precision_pro',
      descriptionKey: 'achievement_precision_pro_desc',
      emoji: '🏹',
      categoryIndex: 1,
      targetValue: 7,
    ),
    Achievement(
      id: 'macro_master',
      titleKey: 'achievement_macro_master',
      descriptionKey: 'achievement_macro_master_desc',
      emoji: '🧬',
      categoryIndex: 1,
      targetValue: 1,
    ),
    Achievement(
      id: 'perfect_week',
      titleKey: 'achievement_perfect_week',
      descriptionKey: 'achievement_perfect_week_desc',
      emoji: '👑',
      categoryIndex: 1,
      targetValue: 7,
    ),
    Achievement(
      id: 'first_sip',
      titleKey: 'achievement_first_sip',
      descriptionKey: 'achievement_first_sip_desc',
      emoji: '💧',
      categoryIndex: 2,
      targetValue: 1,
    ),
    Achievement(
      id: 'hydration_hero',
      titleKey: 'achievement_hydration_hero',
      descriptionKey: 'achievement_hydration_hero_desc',
      emoji: '🌊',
      categoryIndex: 2,
      targetValue: 30,
    ),
    Achievement(
      id: 'ocean_mode',
      titleKey: 'achievement_ocean_mode',
      descriptionKey: 'achievement_ocean_mode_desc',
      emoji: '🐋',
      categoryIndex: 2,
      targetValue: 100,
    ),
    Achievement(
      id: 'first_snap',
      titleKey: 'achievement_first_snap',
      descriptionKey: 'achievement_first_snap_desc',
      emoji: '📸',
      categoryIndex: 3,
      targetValue: 1,
    ),
    Achievement(
      id: 'snap_master',
      titleKey: 'achievement_snap_master',
      descriptionKey: 'achievement_snap_master_desc',
      emoji: '🏅',
      categoryIndex: 3,
      targetValue: 100,
    ),
    Achievement(
      id: 'snap_legend',
      titleKey: 'achievement_snap_legend',
      descriptionKey: 'achievement_snap_legend_desc',
      emoji: '🏆',
      categoryIndex: 3,
      targetValue: 500,
    ),
    Achievement(
      id: 'first_checkin',
      titleKey: 'achievement_first_checkin',
      descriptionKey: 'achievement_first_checkin_desc',
      emoji: '🪞',
      categoryIndex: 4,
      targetValue: 1,
    ),
    Achievement(
      id: 'transformation',
      titleKey: 'achievement_transformation',
      descriptionKey: 'achievement_transformation_desc',
      emoji: '🦋',
      categoryIndex: 4,
      targetValue: 10,
    ),
  ];
}

/// What the badges are measured against, worked out from what is logged.
///
/// Nothing ever called [Achievements.checkAchievements], so every badge sat
/// at zero for every user, for good.
class AchievementStats {
  const AchievementStats({
    required this.totalMealsLogged,
    required this.currentStreak,
    required this.waterGoalDays,
    required this.calorieGoalStreak,
    required this.photosLogged,
    required this.hitMacrosToday,
    required this.perfectWeekDays,
  });

  final int totalMealsLogged;
  final int currentStreak;
  final int waterGoalDays;
  final int calorieGoalStreak;
  final int photosLogged;
  final bool hitMacrosToday;
  final int perfectWeekDays;

  /// Within a tenth of the target counts as hitting it: nobody lands on a
  /// calorie goal exactly, and a badge that needs them to is never won.
  static bool _withinTenth(num value, num target) =>
      target > 0 && value >= target * 0.9 && value <= target * 1.1;

  static AchievementStats from({
    required List<Meal> meals,
    required Map<String, int> waterByDate,
    required int waterGoalMl,
    required UserSettings settings,
    required int photosLogged,
    required DateTime today,
  }) {
    final caloriesByDate = <String, int>{};
    final proteinByDate = <String, int>{};
    final carbsByDate = <String, int>{};
    final fatByDate = <String, int>{};
    for (final meal in meals) {
      final date = meal.dateString;
      caloriesByDate[date] = (caloriesByDate[date] ?? 0) + meal.calories;
      proteinByDate[date] = (proteinByDate[date] ?? 0) + meal.macros.protein;
      carbsByDate[date] = (carbsByDate[date] ?? 0) + meal.macros.carbs;
      fatByDate[date] = (fatByDate[date] ?? 0) + meal.macros.fat;
    }

    String dayAt(int daysAgo) => app_date.DateUtils.getDateString(
      DateTime(today.year, today.month, today.day - daysAgo),
    );

    bool hitCalories(String date) =>
        _withinTenth(caloriesByDate[date] ?? 0, settings.dailyCalorieGoal);
    bool hitWater(String date) =>
        waterGoalMl > 0 && (waterByDate[date] ?? 0) >= waterGoalMl;

    // Today counts once it is met, but a day still in progress must not break
    // a streak that yesterday earned.
    var streak = 0;
    for (var i = hitCalories(dayAt(0)) ? 0 : 1; i < 365; i++) {
      if (!hitCalories(dayAt(i))) break;
      streak++;
    }

    var perfectWeekDays = 0;
    for (var i = 0; i < 7; i++) {
      final date = dayAt(i);
      if (hitCalories(date) && hitWater(date)) perfectWeekDays++;
    }

    final todayKey = dayAt(0);
    final hitMacrosToday =
        _withinTenth(proteinByDate[todayKey] ?? 0, settings.dailyProteinGoal) &&
        _withinTenth(carbsByDate[todayKey] ?? 0, settings.dailyCarbGoal) &&
        _withinTenth(fatByDate[todayKey] ?? 0, settings.dailyFatGoal);

    return AchievementStats(
      totalMealsLogged: meals.length,
      currentStreak: settings.currentStreak,
      waterGoalDays:
          waterGoalMl <= 0
              ? 0
              : waterByDate.values.where((ml) => ml >= waterGoalMl).length,
      calorieGoalStreak: streak,
      photosLogged: photosLogged,
      hitMacrosToday: hitMacrosToday,
      perfectWeekDays: perfectWeekDays,
    );
  }
}

@Riverpod(keepAlive: true)
class Achievements extends _$Achievements {
  Box<Achievement>? _box;

  @override
  Future<List<Achievement>> build() async {
    const boxName = 'achievements_box';
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<Achievement>(boxName);
    } else {
      _box = Hive.box<Achievement>(boxName);
    }
    final defs = AchievementDefs.all();
    if (_box!.isEmpty) {
      for (final a in defs) {
        await _box!.put(a.id, a);
      }
    }
    // A badge that no longer exists -- the journey video went with the
    // feature it measured -- would otherwise sit in the box of everyone who
    // already has one, locked for ever.
    final known = defs.map((a) => a.id).toSet();
    for (final key in _box!.keys.toList()) {
      if (!known.contains(key)) await _box!.delete(key);
    }
    return _box!.values.toList();
  }

  Achievement? consumePendingCelebration() {
    return state.valueOrNull?.firstWhereOrNull(
      (a) => a.isUnlocked && a.unlockedAt != null,
    );
  }

  int get totalUnlocked =>
      state.valueOrNull?.where((a) => a.isUnlocked).length ?? 0;
  int get totalCount => state.valueOrNull?.length ?? 0;

  List<Achievement> byCategory(AchievementCategory cat) =>
      state.valueOrNull?.where((a) => a.category == cat).toList() ?? [];

  Future<void> checkAchievements({
    required int totalMealsLogged,
    required int currentStreak,
    required int waterGoalDays,
    required int calorieGoalStreak,
    required int photosLogged,
    required bool hitMacrosToday,
    required int perfectWeekDays,
  }) async {
    final checks = <String, int>{
      'first_flame': totalMealsLogged,
      'consistency_king': currentStreak,
      'iron_will': currentStreak,
      'unstoppable': currentStreak,
      'bullseye': calorieGoalStreak > 0 ? 1 : 0,
      'precision_pro': calorieGoalStreak,
      'macro_master': hitMacrosToday ? 1 : 0,
      'perfect_week': perfectWeekDays,
      'first_sip': waterGoalDays > 0 ? 1 : 0,
      'hydration_hero': waterGoalDays,
      'ocean_mode': waterGoalDays,
      'first_snap': totalMealsLogged > 0 ? 1 : 0,
      'snap_master': totalMealsLogged,
      'snap_legend': totalMealsLogged,
      'first_checkin': photosLogged,
      'transformation': photosLogged,
    };
    if (_box == null) return;
    for (final entry in checks.entries) {
      final achievement = _box!.get(entry.key);
      if (achievement == null || achievement.isUnlocked) continue;
      achievement.currentProgress = entry.value;
      if (entry.value >= achievement.targetValue) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now().millisecondsSinceEpoch;
      }
      await _box!.put(entry.key, achievement);
    }
    state = AsyncData(_box!.values.toList());
  }

  /// Measures every badge against what is logged, and unlocks what is due.
  Future<void> refreshAchievements() async {
    try {
      await future;
      if (_box == null) return;
      final mealRepo = await ref.read(mealRepositoryProvider.future);
      final waterRepo = await ref.read(waterRepositoryProvider.future);
      final settings = await ref.read(settingsProvider.future);
      final metrics = await ref.read(bodyMetricsProvider.future);
      final stats = AchievementStats.from(
        meals: mealRepo.getAllMeals(),
        waterByDate: waterRepo.totalsByDate(),
        waterGoalMl: settings.effectiveWaterGoalMl,
        settings: settings,
        photosLogged: metrics.where((m) => m.photoFrontPath != null).length,
        today: DateTime.now(),
      );
      await checkAchievements(
        totalMealsLogged: stats.totalMealsLogged,
        currentStreak: stats.currentStreak,
        waterGoalDays: stats.waterGoalDays,
        calorieGoalStreak: stats.calorieGoalStreak,
        photosLogged: stats.photosLogged,
        hitMacrosToday: stats.hitMacrosToday,
        perfectWeekDays: stats.perfectWeekDays,
      );
    } catch (e) {
      debugPrint('Achievement refresh skipped: $e');
    }
  }

  Future<void> clear() async {
    await _box?.clear();
    state = const AsyncData([]);
  }
}
