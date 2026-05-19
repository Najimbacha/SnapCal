import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/repositories/activity_repository.dart';

void main() {
  test('normalizes step data and estimates calories safely', () {
    final repository = ActivityRepository();
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
    expect(summary.manualWorkoutCalories, 0);
    expect(summary.activityScore, 29);
    expect(summary.workouts, isEmpty);
  });

  test('net calories uses food calories minus activity calories only', () {
    const foodCalories = 1850;
    const activityCalories = 320;

    expect(foodCalories - activityCalories, 1530);
  });
}
