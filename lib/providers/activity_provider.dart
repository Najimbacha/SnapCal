import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/services/health_connect_service.dart';
import '../core/services/app_lifecycle_service.dart';

part 'activity_provider.g.dart';

class ActivitySummary {
  final int steps;
  final double activeCalories;
  final List<Workout> workouts;
  final bool healthConnected;
  final DateTime? lastSynced;
  const ActivitySummary({this.steps = 0, this.activeCalories = 0, this.workouts = const [], this.healthConnected = false, this.lastSynced});
  ActivitySummary copyWith({int? steps, double? activeCalories, List<Workout>? workouts, bool? healthConnected, DateTime? lastSynced}) =>
      ActivitySummary(steps: steps ?? this.steps, activeCalories: activeCalories ?? this.activeCalories, workouts: workouts ?? this.workouts, healthConnected: healthConnected ?? this.healthConnected, lastSynced: lastSynced ?? this.lastSynced);
  factory ActivitySummary.empty() => const ActivitySummary();
}

class Workout {
  final String name;
  final int calories;
  final Duration duration;
  const Workout({required this.name, required this.calories, required this.duration});
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
      final calories = await _health.getTodayActiveCaloriesBurned(fallbackSteps: steps);
      return ActivitySummary(steps: steps, activeCalories: calories.calories.toDouble(), healthConnected: true, lastSynced: DateTime.now());
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
  Future<void> startTracking() async {}

  Future<void> addManualWorkout(String name, int calories, Duration duration) async {
    final summary = state.valueOrNull ?? ActivitySummary.empty();
    state = AsyncData(summary.copyWith(workouts: [...summary.workouts, Workout(name: name, calories: calories, duration: duration)]));
  }

  Future<void> deleteManualWorkout(int index) async {
    final summary = state.valueOrNull;
    if (summary == null || index >= summary.workouts.length) return;
    state = AsyncData(summary.copyWith(workouts: [...summary.workouts.take(index), ...summary.workouts.skip(index + 1)]));
  }

  Future<void> updateStepGoal(int goal) async {}
}
