import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/pref_scoping.dart';
import 'activity_provider.dart';
import 'current_day_provider.dart';
import 'meal_provider.dart';
import 'settings_provider.dart';

/// Today's calories: what was eaten, the goal, and what is left.
///
/// Worked out here once and read by Home, the Food Log, the coach and the
/// home-screen widget. Each used to work it out on its own, and only Home
/// added a Pro user's walking calories to the goal -- so the same day read
/// "1,100 left" on Home and "780 left" on the Food Log.
@immutable
class CalorieBudget {
  const CalorieBudget({
    required this.eaten,
    required this.baseGoal,
    this.activityBonus = 0,
    this.settled = true,
  });

  final int eaten;

  /// The goal the user set.
  final int baseGoal;

  /// Calories burned moving today, added to the goal for Pro.
  final int activityBonus;

  /// False only while a Pro user's walking calories are still unknown --
  /// neither the phone's step data nor today's remembered figure is in.
  final bool settled;

  int get goal => baseGoal + activityBonus;
  int get left => goal - eaten;
  double get progress => (eaten / math.max(goal, 1)).clamp(0.0, 1.4);

  @override
  bool operator ==(Object other) =>
      other is CalorieBudget &&
      other.eaten == eaten &&
      other.baseGoal == baseGoal &&
      other.activityBonus == activityBonus &&
      other.settled == settled;

  @override
  int get hashCode => Object.hash(eaten, baseGoal, activityBonus, settled);
}

/// Today's walking calories as last seen, kept on the phone.
///
/// The phone's step data takes a moment to arrive after the app opens. Home
/// opened on the plain goal and jumped by the day's walking calories a
/// second later; now it opens on the figure from earlier today and moves
/// only by what was walked since.
abstract final class ActivityBonusMemory {
  static const _dayKey = 'activity_bonus_day';
  static const _kcalKey = 'activity_bonus_kcal';

  static Future<int?> read(String day) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(scopedPrefKey(_dayKey)) != day) return null;
      return prefs.getInt(scopedPrefKey(_kcalKey));
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String day, int kcal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(scopedPrefKey(_dayKey), day);
      await prefs.setInt(scopedPrefKey(_kcalKey), kcal);
    } catch (_) {
      // Only a head start for the next opening; nothing is lost without it.
    }
  }
}

/// Today's remembered walking calories.
///
/// With none for today yet -- the first opening of the day -- it waits a
/// moment for the phone's step data instead, so Home shows an outline
/// rather than a figure that jumps; after that it settles on 0 so a slow or
/// silent phone never holds Home back for long.
final rememberedActivityBonusProvider = FutureProvider<int>((ref) async {
  final day = ref.watch(currentDayProvider);
  final remembered = await ActivityBonusMemory.read(day);
  if (remembered != null) return remembered;
  await Future<void>.delayed(rememberedActivityWait);
  return 0;
});

/// How long a first opening of the day waits for the phone's step data.
@visibleForTesting
Duration rememberedActivityWait = const Duration(seconds: 2);

final calorieBudgetProvider = Provider<CalorieBudget>((ref) {
  final meals = ref.watch(todaysMealsProvider).valueOrNull ?? const [];
  final eaten = meals.fold<int>(0, (sum, m) => sum + m.calories);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final baseGoal = math.max(settings?.dailyCalorieGoal ?? 2000, 1);
  if (!ref.watch(effectiveIsProProvider)) {
    return CalorieBudget(eaten: eaten, baseGoal: baseGoal);
  }

  final live = ref.watch(activityProvider).valueOrNull;
  if (live != null) {
    return CalorieBudget(
      eaten: eaten,
      baseGoal: baseGoal,
      activityBonus: live.activeCalories.round(),
    );
  }
  final remembered = ref.watch(rememberedActivityBonusProvider);
  return CalorieBudget(
    eaten: eaten,
    baseGoal: baseGoal,
    activityBonus: remembered.valueOrNull ?? 0,
    settled: remembered.hasValue || remembered.hasError,
  );
});
