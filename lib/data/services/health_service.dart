import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthData {
  final int steps;
  final int burnedCalories;

  HealthData({required this.steps, required this.burnedCalories});
  
  factory HealthData.empty() => HealthData(steps: 0, burnedCalories: 0);
}

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  /// Initialize and request permissions
  Future<bool> authorize() async {
    try {
      // On Android, we need to request Activity Recognition permission separately
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.activityRecognition.request();
        if (status.isDenied) return false;
      }

      // Request health data permissions
      bool? hasPermissions = await _health.hasPermissions(_types, permissions: _permissions);
      
      if (hasPermissions == false) {
        hasPermissions = await _health.requestAuthorization(_types, permissions: _permissions);
      }

      return hasPermissions ?? false;
    } catch (e) {
      debugPrint("❌ HealthService: Authorization Error: $e");
      return false;
    }
  }

  /// Fetch today's data
  Future<HealthData> fetchTodaysData() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // Fetch steps
      int steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;

      // Fetch active calories
      final List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      int calories = 0;
      for (var point in healthData) {
        if (point.value is NumericHealthValue) {
          calories += (point.value as NumericHealthValue).numericValue.toInt();
        }
      }

      return HealthData(steps: steps, burnedCalories: calories);
    } catch (e) {
      debugPrint("❌ HealthService: Fetch Error: $e");
      return HealthData.empty();
    }
  }
}
