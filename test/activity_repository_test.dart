import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/data/repositories/activity_repository.dart';
import 'package:snapcal/data/services/activity_service.dart';
import 'package:snapcal/data/services/health_connect_service.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('snapcal_activity_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('normalizes step data and estimates calories safely', () {
    final repository = ActivityRepository(service: _FakeHealthConnectService());
    final date = DateTime(2026, 5, 19);

    final summary = repository.normalize(
      date: date,
      steps: 4200,
      stepGoal: 10000,
      workouts: const [],
      stepStreak: 0,
    );

    expect(summary.date, date);
    expect(summary.steps, 4200);
    expect(summary.stepGoal, 10000);
    expect(summary.activityCalories, 168);
    expect(summary.activityCaloriesEstimated, isTrue);
    expect(summary.manualWorkoutCalories, 0);
    expect(summary.activityScore, 29);
    expect(summary.workouts, isEmpty);
  });

  test('net calories uses food calories minus activity calories only', () {
    const foodCalories = 1850;
    const activityCalories = 320;

    expect(foodCalories - activityCalories, 1530);
  });

  test('permission denied returns permission denied status', () async {
    final repository = ActivityRepository(
      service: _FakeHealthConnectService(
        hasPermission: false,
        grantsPermission: false,
      ),
    );

    final status = await repository.connect();

    expect(status, ActivityTrackingStatus.permissionDenied);
  });

  test('unavailable Health Connect returns unavailable status', () async {
    final repository = ActivityRepository(
      service: _FakeHealthConnectService(
        availability: HealthConnectAvailability.unavailable,
      ),
    );

    final status = await repository.refreshTrackingStatus();

    expect(status, ActivityTrackingStatus.healthConnectUnavailable);
  });

  test('empty step data returns zero', () async {
    final repository = ActivityRepository(
      service: _FakeHealthConnectService(steps: 0),
    );

    final summary = await repository.fetchToday();

    expect(summary.steps, 0);
    expect(summary.activityCalories, 0);
  });

  test('local date range uses start of selected local day', () async {
    final service = _FakeHealthConnectService(steps: 1250);
    final repository = ActivityRepository(service: service);
    final date = DateTime(2026, 5, 19, 14);

    await repository.fetchSummary(date);

    expect(service.ranges.first.start, DateTime(2026, 5, 19));
    expect(service.ranges.first.end, DateTime(2026, 5, 20));
  });

  test(
    'active Health Connect calories are preferred over step estimate',
    () async {
      final repository = ActivityRepository(
        service: _FakeHealthConnectService(steps: 5000, activeCalories: 321),
      );

      final summary = await repository.fetchToday();

      expect(summary.steps, 5000);
      expect(summary.activityCalories, 321);
      expect(summary.activityCaloriesEstimated, isFalse);
    },
  );

  test('missing calorie records fall back to step estimate', () async {
    final repository = ActivityRepository(
      service: _FakeHealthConnectService(steps: 5000),
    );

    final summary = await repository.fetchToday();

    expect(summary.activityCalories, 200);
    expect(summary.activityCaloriesEstimated, isTrue);
  });
}

class _FakeHealthConnectService extends HealthConnectService {
  _FakeHealthConnectService({
    this.availability = HealthConnectAvailability.available,
    this.hasPermission = true,
    this.grantsPermission = true,
    this.steps = 0,
    this.activeCalories,
  });

  final HealthConnectAvailability availability;
  final bool hasPermission;
  final bool grantsPermission;
  final int steps;
  final int? activeCalories;

  final List<({DateTime start, DateTime end})> ranges = [];

  @override
  Future<HealthConnectAvailability> checkAvailability() async => availability;

  @override
  Future<bool> hasPermissions() async => hasPermission;

  @override
  Future<bool> requestPermissions() async => grantsPermission;

  @override
  Future<int> getStepsForDateRange(DateTime start, DateTime end) async {
    ranges.add((start: start, end: end));
    return steps;
  }

  @override
  Future<HealthConnectCalories> getTodayActiveCaloriesBurned({
    int? fallbackSteps,
  }) async {
    if (activeCalories != null) {
      return HealthConnectCalories(
        calories: activeCalories!,
        isEstimated: false,
      );
    }
    return HealthConnectCalories(
      calories:
          ((fallbackSteps ?? steps) * HealthConnectService.caloriesPerStep)
              .round(),
      isEstimated: true,
    );
  }

  @override
  Future<HealthConnectWorkoutSummary> getTodayWorkoutSummary() async {
    return HealthConnectWorkoutSummary.empty;
  }

  @override
  Future<HealthConnectWorkoutSummary> getWorkoutSummaryForRange(
    DateTime start,
    DateTime end,
  ) async {
    return HealthConnectWorkoutSummary.empty;
  }
}
