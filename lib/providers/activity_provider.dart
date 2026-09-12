import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/activity_repository.dart';
import '../data/services/health_connect_service.dart';
import '../core/services/app_lifecycle_service.dart';

part 'activity_provider.g.dart';

/// Live Health Connect snapshot for the current day (steps, active calories,
/// plus in-session manual workouts). This is deliberately a different type
/// from the persisted daily rollup in data/models/activity_summary.dart,
/// which the activity repository writes for history and charts.
class ActivitySummary {
  final int steps;
  final double activeCalories;

  /// True when [activeCalories] was derived from steps because Health Connect
  /// returned no ACTIVE_ENERGY_BURNED records. Comes from record metadata,
  /// never from connection state.
  final bool activeCaloriesEstimated;
  final List<Workout> workouts;
  final bool healthConnected;
  final DateTime? lastSynced;
  const ActivitySummary({
    this.steps = 0,
    this.activeCalories = 0,
    this.activeCaloriesEstimated = true,
    this.workouts = const [],
    this.healthConnected = false,
    this.lastSynced,
  });
  ActivitySummary copyWith({
    int? steps,
    double? activeCalories,
    bool? activeCaloriesEstimated,
    List<Workout>? workouts,
    bool? healthConnected,
    DateTime? lastSynced,
  }) => ActivitySummary(
    steps: steps ?? this.steps,
    activeCalories: activeCalories ?? this.activeCalories,
    activeCaloriesEstimated:
        activeCaloriesEstimated ?? this.activeCaloriesEstimated,
    workouts: workouts ?? this.workouts,
    healthConnected: healthConnected ?? this.healthConnected,
    lastSynced: lastSynced ?? this.lastSynced,
  );
  factory ActivitySummary.empty() => const ActivitySummary();
}

class Workout {
  final String name;
  final int calories;
  final Duration duration;
  const Workout({
    required this.name,
    required this.calories,
    required this.duration,
  });
}

@Riverpod(keepAlive: true)
class Activity extends _$Activity {
  final HealthConnectService _health = HealthConnectService();

  @override
  Future<ActivitySummary> build() async {
    AppLifecycleService().addListener(_onResume);
    ref.onDispose(() => AppLifecycleService().removeListener(_onResume));
    try {
      final hasPermissions = await _health.hasPermissions();
      if (!hasPermissions) return ActivitySummary.empty();
      final steps = await _health.getTodaySteps();
      final calories = await _health.getTodayActiveCaloriesBurned(
        fallbackSteps: steps,
      );
      return ActivitySummary(
        steps: steps,
        activeCalories: calories.calories.toDouble(),
        activeCaloriesEstimated: calories.isEstimated,
        healthConnected: true,
        lastSynced: DateTime.now(),
      );
    } catch (_) {
      return ActivitySummary.empty();
    }
  }

  void _onResume() {
    if (AppLifecycleService().isResumed) ref.invalidateSelf();
  }

  Future<bool> authorize() => _health.requestPermissions();
  Future<bool> isConnected() => _health.hasPermissions();
  Future<void> disconnect() => _health.disconnect();

  Future<void> addManualWorkout(
    String name,
    int calories,
    Duration duration,
  ) async {
    final summary = state.valueOrNull ?? ActivitySummary.empty();
    state = AsyncData(
      summary.copyWith(
        workouts: [
          ...summary.workouts,
          Workout(name: name, calories: calories, duration: duration),
        ],
      ),
    );
  }

  Future<void> deleteManualWorkout(int index) async {
    final summary = state.valueOrNull;
    if (summary == null || index >= summary.workouts.length) return;
    state = AsyncData(
      summary.copyWith(
        workouts: [
          ...summary.workouts.take(index),
          ...summary.workouts.skip(index + 1),
        ],
      ),
    );
  }
}

/// The daily step goal, saved on the phone.
///
/// Every screen hardcoded 10,000 while the activity store kept a goal that
/// could be set -- and was already tested -- with nothing reading it.
final _activityRepository = ActivityRepository();

final stepGoalProvider = FutureProvider<int>(
  (ref) => _activityRepository.getStepGoal(),
);

Future<void> setStepGoal(WidgetRef ref, int goal) async {
  await _activityRepository.setStepGoal(goal);
  ref.invalidate(stepGoalProvider);
}

/// The last seven days of steps, for the week chart.
///
/// The chart used to be drawn from a week of zeros -- `ActivitySummary.empty`
/// for each day -- and shown to Pro users as their history.
final activityWeekProvider = FutureProvider<List<DailySteps>>((ref) async {
  final summary = ref.watch(activityProvider).valueOrNull;
  if (summary?.healthConnected != true) return const <DailySteps>[];
  return _activityRepository.weeklySteps();
});

/// Days in a row the step goal has been met. It was hardcoded to zero.
final stepStreakProvider = FutureProvider<int>((ref) async {
  final summary = ref.watch(activityProvider).valueOrNull;
  if (summary?.healthConnected != true) return 0;
  return _activityRepository.getStepStreak();
});
