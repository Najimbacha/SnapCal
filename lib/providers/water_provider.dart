import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/water_log.dart';
import '../data/repositories/water_repository.dart';
import '../core/utils/date_utils.dart' as app_date;
import 'repository_providers.dart';

part 'water_provider.g.dart';

class WaterState {
  final int todayTotal;
  final int goal;
  const WaterState({required this.todayTotal, this.goal = 2500});
  WaterState copyWith({int? todayTotal, int? goal}) =>
      WaterState(todayTotal: todayTotal ?? this.todayTotal, goal: goal ?? this.goal);
}

@Riverpod(keepAlive: true)
class Water extends _$Water {
  @override
  Future<WaterState> build() async {
    final repo = await ref.watch(waterRepositoryProvider.future);
    final todayStr = app_date.DateUtils.getTodayString();
    final total = repo.getTotalWater(todayStr);
    return WaterState(todayTotal: total, goal: 2500);
  }

  Future<void> addWater(int ml) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    final todayStr = app_date.DateUtils.getTodayString();
    await repo.addWater(WaterLog(dateString: todayStr, amountMl: ml, timestamp: DateTime.now().millisecondsSinceEpoch));
    final total = repo.getTotalWater(todayStr);
    state = AsyncData(state.valueOrNull!.copyWith(todayTotal: total));
  }

  Future<void> removeWater(int ml) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    await repo.removeLastLog();
    final todayStr = app_date.DateUtils.getTodayString();
    final total = repo.getTotalWater(todayStr);
    state = AsyncData(state.valueOrNull!.copyWith(todayTotal: total));
  }

  Future<void> resetToday() async {
    final repo = await ref.read(waterRepositoryProvider.future);
    final todayStr = app_date.DateUtils.getTodayString();
    await repo.clearLogsForDate(todayStr);
    state = AsyncData(state.valueOrNull!.copyWith(todayTotal: 0));
  }

  Future<void> setGoal(int goal) async {
    state = AsyncData(state.valueOrNull!.copyWith(goal: goal));
  }

  Future<int> getTotalForDate(String date) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    return repo.getTotalWater(date);
  }

  Future<Map<String, int>> getTotalsForRange(DateTime start, DateTime end) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    final logs = repo.getWeeklyWater();
    final map = <String, int>{};
    for (final log in logs) {
      map[log.dateString] = (map[log.dateString] ?? 0) + log.amountMl;
    }
    return map;
  }
}
