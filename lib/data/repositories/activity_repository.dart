import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_summary.dart';
import '../services/activity_service.dart';

class ActivityRepository {
  ActivityRepository({ActivityService? service})
    : _service = service ?? ActivityService();

  final ActivityService _service;
  final Uuid _uuid = const Uuid();

  static const String _boxName = 'activity_box';
  static const String _statusKey = 'tracking_status';
  static const String _lastSyncedAtKey = 'last_synced_at';
  static const String _stepGoalKey = 'step_goal';
  static const String _offsetKey = 'steps_offset';
  static const String _lastResetKey = 'last_reset_date';
  static const int defaultStepGoal = 10000;
  static const double caloriesPerStep = 0.04;

  ActivityService get service => _service;

  Future<Box> get _box async => Hive.openBox(_boxName);

  String dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }

  Future<ActivityTrackingStatus> getSavedStatus() async {
    final box = await _box;
    final name = box.get(_statusKey) as String?;
    return ActivityTrackingStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => ActivityTrackingStatus.disconnected,
    );
  }

  Future<ActivityTrackingStatus> refreshTrackingStatus() async {
    final status = await _service.checkStatus();
    await saveStatus(status);
    return status;
  }

  Future<ActivityTrackingStatus> connect() async {
    final status = await _service.requestPermission();
    await saveStatus(status);
    return status;
  }

  Future<void> disconnect() async {
    await saveStatus(ActivityTrackingStatus.disconnected);
  }

  Future<void> saveStatus(ActivityTrackingStatus status) async {
    final box = await _box;
    await box.put(_statusKey, status.name);
  }

  Future<DateTime?> getLastSyncedAt() async {
    final box = await _box;
    final value = box.get(_lastSyncedAtKey) as int?;
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<int> getStepGoal() async {
    final box = await _box;
    return box.get(_stepGoalKey, defaultValue: defaultStepGoal) as int;
  }

  Future<void> setStepGoal(int goal) async {
    final box = await _box;
    await box.put(_stepGoalKey, goal.clamp(1000, 100000));
  }

  Future<ActivitySummary> recordStepReading(int rawSteps) async {
    final box = await _box;
    final today = dateKey(DateTime.now());
    final lastReset = box.get(_lastResetKey) as String?;
    var offset = box.get(_offsetKey, defaultValue: -1) as int;

    if (lastReset != today || offset == -1 || rawSteps < offset) {
      offset = rawSteps;
      await box.put(_offsetKey, offset);
      await box.put(_lastResetKey, today);
    }

    final steps = (rawSteps - offset).clamp(0, 999999);
    await box.put(_stepsKey(today), steps);
    await _markSynced();
    return fetchToday();
  }

  Future<ActivitySummary> fetchToday() {
    return fetchSummary(DateTime.now());
  }

  Future<ActivitySummary> fetchSummary(DateTime date) async {
    final box = await _box;
    final key = dateKey(date);
    final steps = box.get(_stepsKey(key), defaultValue: 0) as int;
    final stepGoal = await getStepGoal();
    final workouts = await getWorkoutsForDate(date);
    return normalize(
      date: date,
      steps: steps,
      stepGoal: stepGoal,
      workouts: workouts,
      stepStreak: await getStepStreak(),
    );
  }

  Future<List<ActivitySummary>> fetchLast7Days() async {
    final now = DateTime.now();
    final summaries = <ActivitySummary>[];
    for (int i = 6; i >= 0; i--) {
      summaries.add(
        await fetchSummary(
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
        ),
      );
    }
    return summaries;
  }

  ActivitySummary normalize({
    required DateTime date,
    required int steps,
    required int stepGoal,
    required List<WorkoutEntry> workouts,
    required int stepStreak,
  }) {
    final manualWorkoutCalories = workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.calories,
    );
    final estimatedActivityCalories = (steps * caloriesPerStep).round();
    final stepScore = ((steps / stepGoal.clamp(1, 100000)) * 70).clamp(0, 70);
    final workoutScore = (manualWorkoutCalories / 10).clamp(0, 20);
    final streakScore = stepStreak.clamp(0, 10);

    final sortedWorkouts = List<WorkoutEntry>.from(workouts)
      ..sort((a, b) => b.start.compareTo(a.start));

    return ActivitySummary(
      date: DateTime(date.year, date.month, date.day),
      steps: steps.clamp(0, 999999),
      stepGoal: stepGoal,
      activityCalories: estimatedActivityCalories,
      manualWorkoutCalories: manualWorkoutCalories.clamp(0, 99999),
      stepStreak: stepStreak,
      activityScore: (stepScore + workoutScore + streakScore).round(),
      workouts: sortedWorkouts,
    );
  }

  Future<int> getStepStreak() async {
    final goal = await getStepGoal();
    final box = await _box;
    final today = DateTime.now();
    var streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = DateTime(today.year, today.month, today.day).subtract(
        Duration(days: i),
      );
      final steps = box.get(_stepsKey(dateKey(date)), defaultValue: 0) as int;
      if (steps < goal) break;
      streak++;
    }

    return streak;
  }

  Future<WorkoutEntry> addManualWorkout({
    required String type,
    required int calories,
    required DateTime start,
    required Duration duration,
  }) async {
    final workout = WorkoutEntry(
      id: _uuid.v4(),
      type: type.trim().isEmpty ? 'Workout' : type.trim(),
      start: start,
      end: start.add(duration),
      calories: calories.clamp(0, 99999),
    );
    final box = await _box;
    final key = _workoutsKey(dateKey(start));
    final existing = (box.get(key, defaultValue: const []) as List).toList();
    existing.add(workout.toJson());
    await box.put(key, existing);
    await _markSynced();
    return workout;
  }

  Future<void> deleteManualWorkout(String id, DateTime date) async {
    final box = await _box;
    final key = _workoutsKey(dateKey(date));
    final existing = (box.get(key, defaultValue: const []) as List).toList();
    existing.removeWhere((item) {
      if (item is Map) return item['id'] == id;
      return false;
    });
    await box.put(key, existing);
    await _markSynced();
  }

  Future<List<WorkoutEntry>> getWorkoutsForDate(DateTime date) async {
    final box = await _box;
    final raw = box.get(_workoutsKey(dateKey(date)), defaultValue: const []);
    return (raw as List)
        .whereType<Map>()
        .map(WorkoutEntry.fromJson)
        .where((workout) => workout.id.isNotEmpty)
        .toList();
  }

  Future<void> _markSynced() async {
    final box = await _box;
    await box.put(_lastSyncedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  String _stepsKey(String date) => 'steps_$date';

  String _workoutsKey(String date) => 'manual_workouts_$date';
}
