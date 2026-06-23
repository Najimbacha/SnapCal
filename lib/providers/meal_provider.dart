import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/meal.dart';
import '../data/repositories/meal_repository.dart';
import '../core/services/app_lifecycle_service.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/services/gemini_service.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

part 'meal_provider.g.dart';

/// Stream provider for today's meals
@Riverpod(keepAlive: true)
Stream<List<Meal>> todaysMeals(TodaysMealsRef ref) async* {
  final repo = await ref.watch(mealRepositoryProvider.future);
  yield repo.getTodaysMeals();
  yield* repo.todaysMealsStream;
}

/// Current selected date for browsing
@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  String build() => app_date.DateUtils.getTodayString();

  void select(String date) => state = date;
  void goToPreviousDay() => state = app_date.DateUtils.getPreviousDay(state);
  void goToNextDay() => state = app_date.DateUtils.getNextDay(state);
  void goToToday() => state = app_date.DateUtils.getTodayString();
}

@Riverpod(keepAlive: true)
class MealLog extends _$MealLog {
  final Uuid _uuid = const Uuid();
  final Map<String, List<NutritionResult>> _analysisCache = {};
  int _lastMemoryPressureCount = 0;

  @override
  FutureOr<void> build() {
    AppLifecycleService().addListener(_handleLifecycleEvent);
    ref.onDispose(() => AppLifecycleService().removeListener(_handleLifecycleEvent));
  }

  void _handleLifecycleEvent() {
    final count = AppLifecycleService().memoryPressureCount;
    if (count == _lastMemoryPressureCount) return;
    _lastMemoryPressureCount = count;
    _analysisCache.clear();
  }

  String generateMealId() => _uuid.v4();

  Future<void> addMeal(Meal meal, {bool rebalancePlanner = true, String? mealDate}) async {
    final repo = await ref.read(mealRepositoryProvider.future);
    await repo.addMeal(meal);

    // Fire-and-forget streak update via settings
    unawaited(ref.read(settingsProvider.notifier).updateStreakOnMealLog(mealDate: mealDate));
  }

  Future<void> updateMeal(Meal meal) async {
    final repo = await ref.read(mealRepositoryProvider.future);
    await repo.updateMeal(meal);
  }

  Future<void> deleteMeal(String mealId) async {
    final repo = await ref.read(mealRepositoryProvider.future);
    await repo.deleteMeal(mealId);
  }

  void cacheAnalysis(String imageKey, List<NutritionResult> results) {
    if (_analysisCache.length >= 5) {
      _analysisCache.remove(_analysisCache.keys.first);
    }
    _analysisCache[imageKey] = results;
  }

  List<NutritionResult>? getCachedAnalysis(String imageKey) => _analysisCache[imageKey];
}
