import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/data/repositories/activity_repository.dart';
import 'package:snapcal/data/services/health_connect_service.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('snapcal_activity_week_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('a week of steps is seven days, oldest first, one query each', () async {
    final service = _FakeService(steps: 4200);
    final repository = ActivityRepository(service: service);

    final week = await repository.weeklySteps(
      today: DateTime(2026, 9, 12, 14, 30),
    );

    expect(week.length, 7);
    expect(week.first.date, DateTime(2026, 9, 6));
    expect(week.last.date, DateTime(2026, 9, 12));
    expect(week.every((day) => day.steps == 4200), isTrue);
    // One query per day, and no more: the old chart path would have run the
    // streak scan seven times over.
    expect(service.ranges.length, 7);
    // A past day runs to midnight; today stops at now.
    expect(service.ranges.first.end, DateTime(2026, 9, 7));
    expect(service.ranges.last.end, DateTime(2026, 9, 12, 14, 30));
  });

  test('the streak scan is bounded', () async {
    final service = _FakeService(steps: 99999);
    final repository = ActivityRepository(service: service);

    final streak = await repository.getStepStreak();

    expect(streak, ActivityRepository.maxStreakDays);
    expect(service.ranges.length, ActivityRepository.maxStreakDays);
  });

  test('a day below the goal ends the streak', () async {
    final service = _FakeService(steps: 10);
    final repository = ActivityRepository(service: service);

    expect(await repository.getStepStreak(), 0);
  });
}

class _FakeService extends HealthConnectService {
  _FakeService({required this.steps});

  final int steps;
  final List<({DateTime start, DateTime end})> ranges = [];

  @override
  Future<HealthConnectAvailability> checkAvailability() async =>
      HealthConnectAvailability.available;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<int> getStepsForDateRange(DateTime start, DateTime end) async {
    ranges.add((start: start, end: end));
    return steps;
  }
}
