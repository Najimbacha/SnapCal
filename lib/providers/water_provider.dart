import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/water_log.dart';
import '../data/repositories/water_repository.dart';
import '../core/utils/date_utils.dart' as app_date;
import 'achievements_provider.dart';
import 'current_day_provider.dart';
import 'settings_provider.dart';
import 'repository_providers.dart';

part 'water_provider.g.dart';

class WaterState {
  final int todayTotal;
  final int goal;
  const WaterState({required this.todayTotal, this.goal = 2500});
  WaterState copyWith({int? todayTotal, int? goal}) => WaterState(
    todayTotal: todayTotal ?? this.todayTotal,
    goal: goal ?? this.goal,
  );
}

@Riverpod(keepAlive: true)
class Water extends _$Water {
  @override
  Future<WaterState> build() async {
    // Rebuilt when the day changes, so the morning starts at zero rather than
    // at last night's total.
    final todayStr = ref.watch(currentDayProvider);
    final repo = await ref.watch(waterRepositoryProvider.future);
    final total = repo.getTotalWater(todayStr);
    // The goal was a constant here, unchangeable and the same for everyone.
    //
    // Selected, not the whole settings object: every meal log saves
    // settings (the streak), and watching all of it rebuilt this provider
    // and re-read the day on each one.
    final goal = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.effectiveWaterGoalMl),
    );
    return WaterState(todayTotal: total, goal: goal ?? 2500);
  }

  Future<void> addWater(int ml) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    final todayStr = app_date.DateUtils.getTodayString();
    await repo.addWater(
      WaterLog(
        dateString: todayStr,
        amountMl: ml,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _publishTodayTotal(repo);
    unawaited(ref.read(achievementsProvider.notifier).refreshAchievements());
  }

  /// Takes back today's most recent glass. Only today's: this removed the
  /// latest log of any day, so "−" on a fresh morning, at zero, deleted last
  /// night's water instead.
  Future<void> removeWater(int ml) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    await repo.removeLastLog(dateString: app_date.DateUtils.getTodayString());
    _publishTodayTotal(repo);
  }

  Future<void> resetToday() async {
    final repo = await ref.read(waterRepositoryProvider.future);
    await repo.clearLogsForDate(app_date.DateUtils.getTodayString());
    _publishTodayTotal(repo);
  }

  /// Saves the goal. It only ever lived in memory, so it was back to the
  /// default on the next launch -- and nothing called this at all.
  Future<void> setGoal(int goal) async {
    await ref.read(settingsProvider.notifier).setWaterGoal(goal);
  }

  /// The current state, or an empty day when the first load never produced
  /// one. These actions force-unwrapped `state.valueOrNull` and crashed on
  /// the tap that logged water whenever that load had failed.
  WaterState get _current =>
      state.valueOrNull ?? const WaterState(todayTotal: 0);

  /// The total always comes from the repository, which is what was just
  /// written to, not from whatever state happened to be loaded.
  void _publishTodayTotal(WaterRepository repo) {
    final total = repo.getTotalWater(app_date.DateUtils.getTodayString());
    state = AsyncData(_current.copyWith(todayTotal: total));
  }
}
