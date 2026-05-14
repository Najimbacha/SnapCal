import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

class ActivityProvider with ChangeNotifier {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  Timer? _throttleTimer;

  int _steps = 0;
  int _burnedCalories = 0;
  bool _isTracking = false;
  String _status = 'stationary';
  double _userWeight = 70.0; // Default fallback

  Box? _box;

  // Storage keys
  static const String _boxName = 'activity_box';
  static const String _offsetKey = 'steps_offset';
  static const String _lastResetKey = 'last_reset_date';

  int get steps => _steps;
  int get burnedCalories => _burnedCalories;
  bool get isTracking => _isTracking;
  String get status => _status;

  ActivityProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    _box = await Hive.openBox(_boxName);
    final status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      startTracking();
    }
  }

  /// Update user weight for personalized calorie calculation
  void updateWeight(double? weight) {
    if (weight != null && weight != _userWeight) {
      _userWeight = weight;
      _recalculateCalories();
    }
  }

  void _recalculateCalories() {
    // Scientific formula: Weight(kg) * 0.0006 kcal per step
    _burnedCalories = (_steps * (_userWeight * 0.0006)).toInt();
    notifyListeners();
  }

  Future<bool> authorize() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      await startTracking();
      return true;
    }
    return false;
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    // Ensure box is open
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }

    _stepCountStream = Pedometer.stepCountStream;
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

    _stepSubscription = _stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );

    _statusSubscription = _pedestrianStatusStream.listen(
      _onStatusChange,
      onError: _onStatusError,
    );

    _isTracking = true;
    notifyListeners();
  }

  void _onStatusChange(PedestrianStatus event) {
    _status = event.status;
    notifyListeners();
  }

  void _onStepCount(StepCount event) {
    if (_box == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastReset = _box!.get(_lastResetKey);

    int offset = _box!.get(_offsetKey, defaultValue: -1);

    // REBOOT-PROOF LOGIC
    if (lastReset != today || offset == -1 || event.steps < offset) {
      offset = event.steps;
      _box!.put(_offsetKey, offset);
      _box!.put(_lastResetKey, today);
    }

    _steps = (event.steps - offset).clamp(0, 999999);

    // Personalized calorie calculation
    _burnedCalories = (_steps * (_userWeight * 0.0006)).toInt();

    // PERFORMANCE OPTIMIZATION: Throttle UI updates to max once per second
    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      notifyListeners();
      _throttleTimer = Timer(const Duration(seconds: 1), () {});
    }

    _box!.put('steps_$today', _steps);
  }

  /// Get total steps for the last 7 days
  Future<int> getWeeklySteps() async {
    if (_box == null || !_box!.isOpen) _box = await Hive.openBox(_boxName);
    int total = 0;
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = date.toIso8601String().split('T')[0];
      total += _box!.get('steps_$dateString', defaultValue: 0) as int;
    }
    return total;
  }

  void _onStepCountError(Object error) {
    debugPrint('Pedometer Error: $error');
    _isTracking = false;
    notifyListeners();
  }

  void _onStatusError(Object error) {
    debugPrint('Pedestrian Status Error: $error');
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _throttleTimer?.cancel();
    super.dispose();
  }
}
