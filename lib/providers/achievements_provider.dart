import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/achievement.dart';

part 'achievements_provider.g.dart';

class AchievementDefs {
  static List<Achievement> all() => [
    Achievement(id: 'first_flame', titleKey: 'achievement_first_flame', descriptionKey: 'achievement_first_flame_desc', emoji: '🕯️', categoryIndex: 0, targetValue: 1),
    Achievement(id: 'consistency_king', titleKey: 'achievement_consistency_king', descriptionKey: 'achievement_consistency_king_desc', emoji: '🔥', categoryIndex: 0, targetValue: 7),
    Achievement(id: 'iron_will', titleKey: 'achievement_iron_will', descriptionKey: 'achievement_iron_will_desc', emoji: '⚡', categoryIndex: 0, targetValue: 30),
    Achievement(id: 'unstoppable', titleKey: 'achievement_unstoppable', descriptionKey: 'achievement_unstoppable_desc', emoji: '💎', categoryIndex: 0, targetValue: 100),
    Achievement(id: 'bullseye', titleKey: 'achievement_bullseye', descriptionKey: 'achievement_bullseye_desc', emoji: '🎯', categoryIndex: 1, targetValue: 1),
    Achievement(id: 'precision_pro', titleKey: 'achievement_precision_pro', descriptionKey: 'achievement_precision_pro_desc', emoji: '🏹', categoryIndex: 1, targetValue: 7),
    Achievement(id: 'macro_master', titleKey: 'achievement_macro_master', descriptionKey: 'achievement_macro_master_desc', emoji: '🧬', categoryIndex: 1, targetValue: 1),
    Achievement(id: 'perfect_week', titleKey: 'achievement_perfect_week', descriptionKey: 'achievement_perfect_week_desc', emoji: '👑', categoryIndex: 1, targetValue: 7),
    Achievement(id: 'first_sip', titleKey: 'achievement_first_sip', descriptionKey: 'achievement_first_sip_desc', emoji: '💧', categoryIndex: 2, targetValue: 1),
    Achievement(id: 'hydration_hero', titleKey: 'achievement_hydration_hero', descriptionKey: 'achievement_hydration_hero_desc', emoji: '🌊', categoryIndex: 2, targetValue: 30),
    Achievement(id: 'ocean_mode', titleKey: 'achievement_ocean_mode', descriptionKey: 'achievement_ocean_mode_desc', emoji: '🐋', categoryIndex: 2, targetValue: 100),
    Achievement(id: 'first_snap', titleKey: 'achievement_first_snap', descriptionKey: 'achievement_first_snap_desc', emoji: '📸', categoryIndex: 3, targetValue: 1),
    Achievement(id: 'snap_master', titleKey: 'achievement_snap_master', descriptionKey: 'achievement_snap_master_desc', emoji: '🏅', categoryIndex: 3, targetValue: 100),
    Achievement(id: 'snap_legend', titleKey: 'achievement_snap_legend', descriptionKey: 'achievement_snap_legend_desc', emoji: '🏆', categoryIndex: 3, targetValue: 500),
    Achievement(id: 'first_checkin', titleKey: 'achievement_first_checkin', descriptionKey: 'achievement_first_checkin_desc', emoji: '🪞', categoryIndex: 4, targetValue: 1),
    Achievement(id: 'transformation', titleKey: 'achievement_transformation', descriptionKey: 'achievement_transformation_desc', emoji: '🦋', categoryIndex: 4, targetValue: 10),
    Achievement(id: 'journey_video', titleKey: 'achievement_journey_video', descriptionKey: 'achievement_journey_video_desc', emoji: '🎬', categoryIndex: 4, targetValue: 1),
  ];
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
    if (_box!.isEmpty) {
      for (final a in AchievementDefs.all()) {
        await _box!.put(a.id, a);
      }
    }
    return _box!.values.toList();
  }

  Achievement? consumePendingCelebration() {
    return state.valueOrNull?.firstWhereOrNull((a) => a.isUnlocked && a.unlockedAt != null);
  }

  int get totalUnlocked => state.valueOrNull?.where((a) => a.isUnlocked).length ?? 0;
  int get totalCount => state.valueOrNull?.length ?? 0;

  List<Achievement> byCategory(AchievementCategory cat) =>
      state.valueOrNull?.where((a) => a.category == cat).toList() ?? [];

  Future<void> checkAchievements({
    required int totalMealsLogged, required int currentStreak,
    required int waterGoalDays, required int calorieGoalStreak,
    required int photosLogged, required bool hasGeneratedVideo,
    required bool hitMacrosToday, required int perfectWeekDays,
  }) async {
    final checks = <String, int>{
      'first_flame': totalMealsLogged, 'consistency_king': currentStreak,
      'iron_will': currentStreak, 'unstoppable': currentStreak,
      'bullseye': calorieGoalStreak > 0 ? 1 : 0, 'precision_pro': calorieGoalStreak,
      'macro_master': hitMacrosToday ? 1 : 0, 'perfect_week': perfectWeekDays,
      'first_sip': waterGoalDays > 0 ? 1 : 0, 'hydration_hero': waterGoalDays,
      'ocean_mode': waterGoalDays, 'first_snap': totalMealsLogged > 0 ? 1 : 0,
      'snap_master': totalMealsLogged, 'snap_legend': totalMealsLogged,
      'first_checkin': photosLogged, 'transformation': photosLogged,
      'journey_video': hasGeneratedVideo ? 1 : 0,
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

  Future<void> clear() async {
    await _box?.clear();
    state = const AsyncData([]);
  }
}
