import 'package:hive/hive.dart';
import '../models/activity_summary.dart';
import '../services/activity_service.dart';
import '../services/health_connect_service.dart';

class ActivityRepository {
  ActivityRepository({HealthConnectService? service})
    : _service = service ?? HealthConnectService();

  final HealthConnectService _service;

  static const String _boxName = 'activity_box';
  static const String _statusKey = 'tracking_status';
  static const String _lastSyncedAtKey = 'last_synced_at';
  static const String _stepGoalKey = 'step_goal';
  static const int defaultStepGoal = 10000;
  static const double caloriesPerStep = 0.04;

  HealthConnectService get service => _service;

  Future<Box> get _box async => Hive.openBox(_boxName);

  String dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }

  Future<ActivityTrackingStatus> getSavedStatus() async {
    final box = await _box;
    final name = box.get(_statusKey) as String?;
    if (name == 'disconnected') return ActivityTrackingStatus.notConnected;
    if (name == 'unsupported') {
      return ActivityTrackingStatus.healthConnectUnavailable;
    }
    return ActivityTrackingStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => ActivityTrackingStatus.notConnected,
    );
  }

  Future<ActivityTrackingStatus> refreshTrackingStatus() async {
    final status = await _resolveStatus(requestPermission: false);
    await saveStatus(status);
    return status;
  }

  Future<ActivityTrackingStatus> connect() async {
    final status = await _resolveStatus(requestPermission: true);
    await saveStatus(status);
    return status;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    await saveStatus(ActivityTrackingStatus.notConnected);
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

  Future<ActivitySummary> fetchToday() {
    return fetchSummary(DateTime.now());
  }

  Future<ActivitySummary> fetchSummary(DateTime date) async {
    final stepGoal = await getStepGoal();
    final hasPermissions = await _service.hasPermissions();
    if (!hasPermissions) {
      return normalize(
        date: date,
        steps: 0,
        stepGoal: stepGoal,
        activityCalories: 0,
        activityCaloriesEstimated: true,
        workouts: const [],
        stepStreak: 0,
      );
    }

    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end =
        _sameDay(start, now)
            ? now
            : DateTime(date.year, date.month, date.day + 1);
    final steps = await _service.getStepsForDateRange(start, end);
    final calories =
        _sameDay(start, now)
            ? await _service.getTodayActiveCaloriesBurned(fallbackSteps: steps)
            : HealthConnectCalories(
              calories: (steps * caloriesPerStep).round(),
              isEstimated: true,
            );
    final workoutSummary =
        _sameDay(start, now)
            ? await _service.getTodayWorkoutSummary()
            : await _service.getWorkoutSummaryForRange(start, end);
    final workouts = _workoutsFromSummary(start, workoutSummary);
    await _markSynced();
    return normalize(
      date: date,
      steps: steps,
      stepGoal: stepGoal,
      activityCalories: calories.calories,
      activityCaloriesEstimated: calories.isEstimated,
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
    int? activityCalories,
    bool activityCaloriesEstimated = true,
    required List<WorkoutEntry> workouts,
    required int stepStreak,
  }) {
    final workoutCalories = workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.calories,
    );
    final displayCalories =
        activityCalories ?? (steps * caloriesPerStep).round();
    final stepScore = ((steps / stepGoal.clamp(1, 100000)) * 70).clamp(0, 70);
    final workoutScore = (workoutCalories / 10).clamp(0, 20);
    final streakScore = stepStreak.clamp(0, 10);

    final sortedWorkouts = List<WorkoutEntry>.from(workouts)
      ..sort((a, b) => b.start.compareTo(a.start));

    return ActivitySummary(
      date: DateTime(date.year, date.month, date.day),
      steps: steps.clamp(0, 999999),
      stepGoal: stepGoal,
      activityCalories: displayCalories.clamp(0, 99999),
      activityCaloriesEstimated: activityCaloriesEstimated,
      manualWorkoutCalories: 0,
      stepStreak: stepStreak,
      activityScore: (stepScore + workoutScore + streakScore).round(),
      workouts: sortedWorkouts,
    );
  }

  Future<int> getStepStreak() async {
    final goal = await getStepGoal();
    final today = DateTime.now();
    var streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day);
      final end =
          _sameDay(start, today)
              ? today
              : DateTime(date.year, date.month, date.day + 1);
      final steps = await _service.getStepsForDateRange(start, end);
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
      id: 'legacy-manual-${start.millisecondsSinceEpoch}',
      type: type.trim().isEmpty ? WorkoutEntry.defaultType : type.trim(),
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

  String _workoutsKey(String date) => 'manual_workouts_$date';

  Future<ActivityTrackingStatus> _resolveStatus({
    required bool requestPermission,
  }) async {
    final availability = await _service.checkAvailability();
    if (availability != HealthConnectAvailability.available) {
      return ActivityTrackingStatus.healthConnectUnavailable;
    }

    final hasPermissions = await _service.hasPermissions();
    if (hasPermissions) return ActivityTrackingStatus.connected;
    if (!requestPermission) return ActivityTrackingStatus.notConnected;

    final granted = await _service.requestPermissions();
    return granted
        ? ActivityTrackingStatus.connected
        : ActivityTrackingStatus.permissionDenied;
  }

  List<WorkoutEntry> _workoutsFromSummary(
    DateTime date,
    HealthConnectWorkoutSummary summary,
  ) {
    if (!summary.hasWorkout) return const [];
    return [
      WorkoutEntry(
        id: 'health-connect-${dateKey(date)}',
        type: summary.primaryType ?? WorkoutEntry.defaultType,
        start: date,
        end: date.add(summary.duration),
        calories: summary.calories,
      ),
    ];
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
