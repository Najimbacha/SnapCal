import 'package:flutter/widgets.dart';

import '../data/models/activity_summary.dart';
import '../data/repositories/activity_repository.dart';
import '../data/services/activity_service.dart';

class ActivityProvider with ChangeNotifier, WidgetsBindingObserver {
  ActivityProvider({ActivityRepository? repository})
    : _repository = repository ?? ActivityRepository() {
    WidgetsBinding.instance.addObserver(this);
    syncNow();
  }

  final ActivityRepository _repository;

  ActivitySummary _today = ActivitySummary.empty(DateTime.now());
  List<ActivitySummary> _week = const [];
  ActivityTrackingStatus _trackingStatus = ActivityTrackingStatus.loading;
  bool _isSyncing = false;
  bool _hasAttemptedConnection = false;
  bool _disposed = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  ActivitySummary get today => _today;
  List<ActivitySummary> get week => _week;
  ActivityTrackingStatus get trackingStatus => _trackingStatus;
  bool get isConnected =>
      _trackingStatus == ActivityTrackingStatus.connected ||
      _trackingStatus == ActivityTrackingStatus.emptyData;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String get sourceName => _repository.service.sourceName;

  int get steps => _today.steps;
  int get stepGoal => _today.stepGoal;
  int get burnedCalories => _today.activityCalories;
  bool get caloriesAreEstimated => _today.activityCaloriesEstimated;
  String get caloriesLabel =>
      caloriesAreEstimated ? 'Estimated calories' : 'Active calories';
  int get manualWorkoutCalories => _today.manualWorkoutCalories;
  int get stepStreak => _today.stepStreak;
  int get activityScore => _today.activityScore;
  bool get isTracking => isConnected;
  String get status => isConnected ? 'connected' : 'not connected';

  int netCalories(int foodCalories) => foodCalories - burnedCalories;

  void updateWeight(double? weight) {
    // Health Connect active calories are preferred; step calories are fallback.
  }

  Future<bool> authorize() => startTracking();

  Future<bool> connect() => startTracking();

  Future<bool> startTracking() async {
    try {
      _hasAttemptedConnection = true;
      _trackingStatus = ActivityTrackingStatus.loading;
      _notify();
      _trackingStatus = await _repository.connect();
      if (isConnected) {
        await syncNow();
        return true;
      }
      _notify();
      return false;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    _trackingStatus = ActivityTrackingStatus.notConnected;
    _today = ActivitySummary.empty(DateTime.now());
    _week = const [];
    _notify();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _setSyncing(true);
    try {
      _trackingStatus = await _repository.refreshTrackingStatus();
      if (isConnected) {
        _today = await _repository.fetchToday();
        _week = await _repository.fetchLast7Days();
        if (_today.steps == 0 &&
            _today.activityCalories == 0 &&
            _today.workouts.isEmpty) {
          _trackingStatus = ActivityTrackingStatus.emptyData;
        }
        _lastSyncedAt = await _repository.getLastSyncedAt();
      } else {
        _today = ActivitySummary.empty(DateTime.now());
        _week = const [];
      }
      _errorMessage = null;
      _notify();
    } catch (error) {
      _setError(error);
    } finally {
      _setSyncing(false);
    }
  }

  Future<void> updateStepGoal(int goal) async {
    await _repository.setStepGoal(goal);
    await syncNow();
  }

  Future<void> addManualWorkout({
    required String type,
    required int calories,
    required DateTime start,
    required Duration duration,
  }) async {
    await _repository.addManualWorkout(
      type: type,
      calories: calories,
      start: start,
      duration: duration,
    );
    await syncNow();
  }

  Future<void> deleteManualWorkout(WorkoutEntry workout) async {
    await _repository.deleteManualWorkout(workout.id, workout.start);
    await syncNow();
  }

  Future<int> getWeeklySteps() async {
    if (_week.isEmpty) await syncNow();
    return _week.fold<int>(0, (sum, day) => sum + day.steps);
  }

  Future<List<ActivitySummary>> fetchSummariesForRange(
    DateTime start,
    DateTime end,
  ) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final summaries = <ActivitySummary>[];
    var current = normalizedStart;
    while (!current.isAfter(normalizedEnd)) {
      summaries.add(await _repository.fetchSummary(current));
      current = current.add(const Duration(days: 1));
    }
    return summaries;
  }

  ActivitySummary? cachedSummaryForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_sameDay(_today.date, normalized)) return _today;
    for (final summary in _week) {
      if (_sameDay(summary.date, normalized)) return summary;
    }
    return null;
  }

  Future<void> openHealthConnectSettings() {
    return _repository.service.openHealthConnectSettings();
  }

  Future<void> openInstallOrUpdate() {
    return _repository.service.openInstallOrUpdate();
  }

  String statusLabel() {
    switch (_trackingStatus) {
      case ActivityTrackingStatus.loading:
        return 'Loading';
      case ActivityTrackingStatus.connected:
        return 'Connected';
      case ActivityTrackingStatus.emptyData:
        return 'No Health Connect data today';
      case ActivityTrackingStatus.permissionDenied:
        return 'Permission denied';
      case ActivityTrackingStatus.healthConnectUnavailable:
        return 'Health Connect unavailable';
      case ActivityTrackingStatus.error:
        return 'Tracking error';
      case ActivityTrackingStatus.notConnected:
        return 'Not connected';
    }
  }

  void _setSyncing(bool value) {
    if (_isSyncing == value) return;
    _isSyncing = value;
    _notify();
  }

  void _setError(Object error) {
    _trackingStatus = ActivityTrackingStatus.error;
    _errorMessage = error.toString();
    debugPrint('Activity sync error: $error');
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (isConnected || _hasAttemptedConnection)) {
      syncNow();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
