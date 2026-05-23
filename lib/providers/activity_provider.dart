import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';

import '../data/models/activity_summary.dart';
import '../data/repositories/activity_repository.dart';
import '../data/services/activity_service.dart';

class ActivityProvider with ChangeNotifier {
  ActivityProvider({ActivityRepository? repository})
    : _repository = repository ?? ActivityRepository() {
    syncNow();
  }

  final ActivityRepository _repository;

  ActivitySummary _today = ActivitySummary.empty(DateTime.now());
  List<ActivitySummary> _week = const [];
  ActivityTrackingStatus _trackingStatus = ActivityTrackingStatus.disconnected;
  bool _isSyncing = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;
  String _motionStatus = 'stationary';

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  ActivitySummary get today => _today;
  List<ActivitySummary> get week => _week;
  ActivityTrackingStatus get trackingStatus => _trackingStatus;
  bool get isConnected => _trackingStatus == ActivityTrackingStatus.connected;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String get sourceName => _repository.service.sourceName;

  int get steps => _today.steps;
  int get stepGoal => _today.stepGoal;
  int get burnedCalories => _today.activityCalories;
  int get manualWorkoutCalories => _today.manualWorkoutCalories;
  int get stepStreak => _today.stepStreak;
  int get activityScore => _today.activityScore;
  bool get isTracking => isConnected;
  String get status => _motionStatus;

  int netCalories(int foodCalories) => foodCalories - burnedCalories;

  void updateWeight(double? weight) {
    // Step calories are intentionally estimated with a fixed formula.
  }

  Future<bool> authorize() => startTracking();

  Future<bool> connect() => startTracking();

  Future<bool> startTracking() async {
    try {
      _trackingStatus = await _repository.connect();
      if (isConnected) {
        _listenToPedometer();
        await syncNow();
        return true;
      }
      notifyListeners();
      return false;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<void> disconnect() async {
    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();
    _stepSubscription = null;
    _statusSubscription = null;
    await _repository.disconnect();
    _trackingStatus = ActivityTrackingStatus.disconnected;
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _setSyncing(true);
    try {
      _trackingStatus = await _repository.refreshTrackingStatus();
      _today = await _repository.fetchToday();
      _week = await _repository.fetchLast7Days();
      _lastSyncedAt = await _repository.getLastSyncedAt();
      if (isConnected) _listenToPedometer();
      _errorMessage = null;
      notifyListeners();
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

  String statusLabel() {
    switch (_trackingStatus) {
      case ActivityTrackingStatus.connected:
        return 'Tracking enabled';
      case ActivityTrackingStatus.permissionDenied:
        return 'Permission denied';
      case ActivityTrackingStatus.unsupported:
        return 'Unsupported device';
      case ActivityTrackingStatus.error:
        return 'Tracking error';
      case ActivityTrackingStatus.disconnected:
        return 'Tracking off';
    }
  }

  void _listenToPedometer() {
    if (_stepSubscription != null) return;

    _stepSubscription = _repository.service.stepCountStream.listen(
      (event) async {
        try {
          _today = await _repository.recordStepReading(event.steps);
          _week = await _repository.fetchLast7Days();
          _lastSyncedAt = await _repository.getLastSyncedAt();
          notifyListeners();
        } catch (error) {
          debugPrint('Pedometer step error: $error');
        }
      },
      onError: (Object error) {
        debugPrint('Pedometer stream error: $error');
        _setError(error);
      },
    );

    _statusSubscription = _repository.service.pedestrianStatusStream.listen(
      (event) {
        _motionStatus = event.status;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Pedestrian status error: $error');
      },
    );
  }

  void _setSyncing(bool value) {
    if (_isSyncing == value) return;
    _isSyncing = value;
    notifyListeners();
  }

  void _setError(Object error) {
    _trackingStatus = ActivityTrackingStatus.error;
    _errorMessage = error.toString();
    notifyListeners();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
