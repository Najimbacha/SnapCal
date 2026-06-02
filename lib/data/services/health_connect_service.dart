import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

enum HealthConnectAvailability {
  available,
  unavailable,
  updateRequired,
  unsupportedPlatform,
}

class HealthConnectCalories {
  final int calories;
  final bool isEstimated;

  const HealthConnectCalories({
    required this.calories,
    required this.isEstimated,
  });
}

class HealthConnectWorkoutSummary {
  final int workoutCount;
  final Duration duration;
  final int calories;
  final String? primaryType;

  const HealthConnectWorkoutSummary({
    required this.workoutCount,
    required this.duration,
    required this.calories,
    this.primaryType,
  });

  static const empty = HealthConnectWorkoutSummary(
    workoutCount: 0,
    duration: Duration.zero,
    calories: 0,
  );

  bool get hasWorkout => workoutCount > 0;
}

class HealthConnectService {
  HealthConnectService({Health? health}) : _health = health ?? Health();

  static const _settingsChannel = MethodChannel('snapcal/health_connect');
  static const double caloriesPerStep = 0.04;

  final Health _health;
  bool _configured = false;

  List<HealthDataType> get _types => const [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  List<HealthDataAccess> get _readPermissions => const [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  String get sourceName => 'Health Connect';

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<HealthConnectAvailability> checkAvailability() async {
    if (!Platform.isAndroid) {
      return HealthConnectAvailability.unsupportedPlatform;
    }

    await _configure();
    final status = await _health.getHealthConnectSdkStatus();
    switch (status) {
      case HealthConnectSdkStatus.sdkAvailable:
        return HealthConnectAvailability.available;
      case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
        return HealthConnectAvailability.updateRequired;
      case HealthConnectSdkStatus.sdkUnavailable:
      case null:
        return HealthConnectAvailability.unavailable;
    }
  }

  Future<bool> hasPermissions() async {
    if (await checkAvailability() != HealthConnectAvailability.available) {
      return false;
    }
    final hasHealthPermissions = await _health.hasPermissions(
      _types,
      permissions: _readPermissions,
    );
    final activityRecognition = await Permission.activityRecognition.status;
    return (hasHealthPermissions ?? false) && activityRecognition.isGranted;
  }

  Future<bool> requestPermissions() async {
    if (await checkAvailability() != HealthConnectAvailability.available) {
      return false;
    }

    final recognition = await Permission.activityRecognition.request();
    if (!recognition.isGranted) return false;

    return _health.requestAuthorization(_types, permissions: _readPermissions);
  }

  Future<int> getTodaySteps() {
    final now = DateTime.now();
    return getStepsForDateRange(DateTime(now.year, now.month, now.day), now);
  }

  Future<int> getStepsForDateRange(DateTime start, DateTime end) async {
    await _configure();
    final steps = await _health.getTotalStepsInInterval(start, end);
    return (steps ?? 0).clamp(0, 999999);
  }

  Future<HealthConnectCalories> getTodayActiveCaloriesBurned({
    int? fallbackSteps,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final activeCalories = await _getActiveCalories(start, now);
    if (activeCalories != null) {
      return HealthConnectCalories(
        calories: activeCalories.clamp(0, 99999),
        isEstimated: false,
      );
    }

    final steps = fallbackSteps ?? await getStepsForDateRange(start, now);
    return HealthConnectCalories(
      calories: _estimateCaloriesFromSteps(steps),
      isEstimated: true,
    );
  }

  Future<HealthConnectWorkoutSummary> getTodayWorkoutSummary() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return getWorkoutSummaryForRange(start, now);
  }

  Future<HealthConnectWorkoutSummary> getWorkoutSummaryForRange(
    DateTime start,
    DateTime end,
  ) async {
    await _configure();
    if (!_health.isDataTypeAvailable(HealthDataType.WORKOUT)) {
      return HealthConnectWorkoutSummary.empty;
    }

    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: start,
      endTime: end,
    );
    final workouts = _health.removeDuplicates(points);
    if (workouts.isEmpty) return HealthConnectWorkoutSummary.empty;

    var calories = 0;
    var duration = Duration.zero;
    String? primaryType;

    for (final point in workouts) {
      duration += point.dateTo.difference(point.dateFrom);
      final value = point.value;
      if (value is WorkoutHealthValue) {
        calories += value.totalEnergyBurned ?? 0;
        primaryType ??= _formatWorkoutType(value.workoutActivityType.name);
      }
    }

    return HealthConnectWorkoutSummary(
      workoutCount: workouts.length,
      duration: duration,
      calories: calories.clamp(0, 99999),
      primaryType: primaryType,
    );
  }

  Future<void> openHealthConnectSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _settingsChannel.invokeMethod<void>('openHealthConnectSettings');
    } catch (error) {
      debugPrint('Health Connect settings unavailable: $error');
      await _health.installHealthConnect();
    }
  }

  Future<void> disconnect() async {
    try {
      await _health.revokePermissions();
    } catch (error) {
      debugPrint('Health Connect revoke failed: $error');
    }
  }

  Future<void> openInstallOrUpdate() async {
    await _configure();
    await _health.installHealthConnect();
  }

  Future<int?> _getActiveCalories(DateTime start, DateTime end) async {
    await _configure();
    if (!_health.isDataTypeAvailable(HealthDataType.ACTIVE_ENERGY_BURNED)) {
      return null;
    }

    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: start,
      endTime: end,
    );
    final unique = _health.removeDuplicates(points);
    if (unique.isEmpty) return null;

    final calories = unique.fold<double>(0, (sum, point) {
      final value = point.value;
      if (value is NumericHealthValue) {
        return sum + value.numericValue.toDouble();
      }
      return sum;
    });

    if (calories <= 0) return null;
    return calories.round();
  }

  int _estimateCaloriesFromSteps(int steps) {
    return (steps.clamp(0, 999999) * caloriesPerStep).round().clamp(0, 99999);
  }

  String _formatWorkoutType(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0] + part.substring(1).toLowerCase())
        .join(' ');
  }
}
