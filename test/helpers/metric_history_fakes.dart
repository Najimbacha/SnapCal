import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';

/// Meals by date string, standing in for the on-device meal log.
class FakeMealLog implements MealRepository {
  FakeMealLog([this.byDate = const {}]);

  final Map<String, List<Meal>> byDate;

  @override
  List<Meal> getMealsByDate(String dateString) =>
      byDate[dateString] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Millilitres by date string, standing in for the on-device water log.
class FakeWaterLog implements WaterRepository {
  FakeWaterLog([this.byDate = const {}]);

  final Map<String, int> byDate;

  @override
  int getTotalWater(String dateString) => byDate[dateString] ?? 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What the health details page reads its history from, without Hive or
/// Health Connect. [steps] answers each range the page asks about.
List<Override> metricHistoryOverrides({
  Map<String, List<Meal>> meals = const {},
  Map<String, int> water = const {},
  Future<int> Function(DateTime start, DateTime end)? steps,
  int stepGoal = 10000,
}) => [
  mealRepositoryProvider.overrideWith((ref) async => FakeMealLog(meals)),
  waterRepositoryProvider.overrideWith((ref) async => FakeWaterLog(water)),
  todaysMealsProvider.overrideWith((ref) => Stream.value(const <Meal>[])),
  stepGoalProvider.overrideWith((ref) async => stepGoal),
  metricStepsLoaderProvider.overrideWithValue(steps ?? (_, _) async => 0),
];
