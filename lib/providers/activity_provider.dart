import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/activity_repository.dart';
import '../data/models/activity_summary.dart' show WorkoutEntry;
import '../data/services/health_connect_service.dart';
import '../core/services/app_lifecycle_service.dart';
import 'calorie_budget_provider.dart';
import 'current_day_provider.dart';

part 'activity_provider.g.dart';

/// Live Health Connect snapshot for the current day (steps, active calories,
/// plus persisted manual workouts). This is deliberately a different type
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
  final String id;
  final String name;
  final int calories;
  final Duration duration;
  final DateTime? start;
  final bool isManual;
  const Workout({
    this.id = '',
    required this.name,
    required this.calories,
    required this.duration,
    this.start,
    this.isManual = false,
  });
}

@Riverpod(keepAlive: true)
class Activity extends _$Activity {
  @override
  Future<ActivitySummary> build() async {
    AppLifecycleService().addListener(_onResume);
    ref.onDispose(() => AppLifecycleService().removeListener(_onResume));
    var manualWorkouts = <Workout>[];
    try {
      final repository = ref.watch(activityRepositoryProvider);
      final health = repository.service;
      final now = DateTime.now();
      final manualEntries = await repository.getWorkoutsForDate(now);
      manualWorkouts = manualEntries.map(_fromManualWorkout).toList();
      final manualCalories = manualWorkouts.fold<int>(
        0,
        (sum, workout) => sum + workout.calories,
      );
      final hasPermissions = await health.hasPermissions();
      if (!hasPermissions) {
        return ActivitySummary(
          activeCalories: manualCalories.toDouble(),
          workouts: manualWorkouts,
        );
      }
      final steps = await health.getTodaySteps();
      final calories = await health.getTodayActiveCaloriesBurned(
        fallbackSteps: steps,
      );
      final healthWorkout = await health.getTodayWorkoutSummary();
      final workouts = <Workout>[
        if (healthWorkout.hasWorkout)
          Workout(
            id: 'health-connect-${now.year}-${now.month}-${now.day}',
            name: healthWorkout.primaryType ?? WorkoutEntry.defaultType,
            calories: healthWorkout.calories,
            duration: healthWorkout.duration,
            start: DateTime(now.year, now.month, now.day),
          ),
        ...manualWorkouts,
      ];
      final totalCalories = calories.calories + manualCalories;
      // Remembered so the next opening starts from today's figure.
      unawaited(
        ActivityBonusMemory.write(ref.read(currentDayProvider), totalCalories),
      );
      return ActivitySummary(
        steps: steps,
        activeCalories: totalCalories.toDouble(),
        activeCaloriesEstimated: calories.isEstimated,
        workouts: workouts,
        healthConnected: true,
        lastSynced: DateTime.now(),
      );
    } catch (_) {
      final manualCalories = manualWorkouts.fold<int>(
        0,
        (sum, workout) => sum + workout.calories,
      );
      return ActivitySummary(
        activeCalories: manualCalories.toDouble(),
        workouts: manualWorkouts,
      );
    }
  }

  Workout _fromManualWorkout(WorkoutEntry workout) => Workout(
    id: workout.id,
    name: workout.type,
    calories: workout.calories,
    duration: workout.duration,
    start: workout.start,
    isManual: true,
  );

  void _onResume() {
    // Steps may have moved while the app was out of sight; a pull of the
    // notification shade is no reason to read Health Connect again.
    if (AppLifecycleService().cameBack) ref.invalidateSelf();
  }

  HealthConnectService get _health =>
      ref.read(activityRepositoryProvider).service;

  Future<bool> authorize() => _health.requestPermissions();
  Future<bool> isConnected() => _health.hasPermissions();
  Future<void> disconnect() => _health.disconnect();

  Future<void> addManualWorkout(
    String name,
    int calories,
    Duration duration,
  ) async {
    final start = DateTime.now();
    final saved = await ref
        .read(activityRepositoryProvider)
        .addManualWorkout(
          type: name,
          calories: calories,
          start: start,
          duration: duration,
        );
    final summary = state.valueOrNull ?? ActivitySummary.empty();
    state = AsyncData(
      summary.copyWith(
        activeCalories: summary.activeCalories + saved.calories,
        workouts: [...summary.workouts, _fromManualWorkout(saved)],
      ),
    );
  }

  Future<void> deleteManualWorkout(int index) async {
    final summary = state.valueOrNull;
    if (summary == null || index >= summary.workouts.length) return;
    final workout = summary.workouts[index];
    if (!workout.isManual) return;
    await ref
        .read(activityRepositoryProvider)
        .deleteManualWorkout(workout.id, workout.start!);
    state = AsyncData(
      summary.copyWith(
        activeCalories: (summary.activeCalories - workout.calories).clamp(
          0,
          double.infinity,
        ),
        workouts: [
          ...summary.workouts.take(index),
          ...summary.workouts.skip(index + 1),
        ],
      ),
    );
  }
}

/// Health Connect, for screens that read history rather than today.
final healthConnectServiceProvider = Provider<HealthConnectService>(
  (ref) => HealthConnectService(),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(service: ref.watch(healthConnectServiceProvider)),
);

/// The daily step goal, saved on the phone.
///
/// Every screen hardcoded 10,000 while the activity store kept a goal that
/// could be set -- and was already tested -- with nothing reading it.
final stepGoalProvider = FutureProvider<int>(
  (ref) => ref.watch(activityRepositoryProvider).getStepGoal(),
);

Future<void> setStepGoal(WidgetRef ref, int goal) async {
  await ref.read(activityRepositoryProvider).setStepGoal(goal);
  ref.invalidate(stepGoalProvider);
}

/// The last seven days of steps, for the week chart.
///
/// The chart used to be drawn from a week of zeros -- `ActivitySummary.empty`
/// for each day -- and shown to Pro users as their history.
final activityWeekProvider = FutureProvider<List<DailySteps>>((ref) async {
  final summary = ref.watch(activityProvider).valueOrNull;
  if (summary?.healthConnected != true) return const <DailySteps>[];
  return ref.watch(activityRepositoryProvider).weeklySteps();
});

/// Days in a row the step goal has been met. It was hardcoded to zero.
final stepStreakProvider = FutureProvider<int>((ref) async {
  final summary = ref.watch(activityProvider).valueOrNull;
  if (summary?.healthConnected != true) return 0;
  return ref.watch(activityRepositoryProvider).getStepStreak();
});
