import '../data/services/app_review_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/meal.dart';
import '../core/services/app_lifecycle_service.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/services/gemini_service.dart';
import '../data/services/promotional_paywall_service.dart';
import 'planner_provider.dart';
import 'repository_providers.dart';
import 'current_day_provider.dart';
import 'settings_provider.dart';

part 'meal_provider.g.dart';

/// Stream provider for today's meals
///
/// Rebuilt when the day changes: the repository only emits on writes, so
/// without this Home stayed on yesterday's meals until something was logged.
@Riverpod(keepAlive: true)
Stream<List<Meal>> todaysMeals(TodaysMealsRef ref) async* {
  ref.watch(currentDayProvider);
  final repo = await ref.watch(mealRepositoryProvider.future);
  yield repo.getTodaysMeals();
  yield* repo.todaysMealsStream;
}

/// Current selected date for browsing
@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  String build() {
    // A diary left on today moves on with the day; one the user took back to
    // an earlier date stays there.
    ref.listen(currentDayProvider, (previous, next) {
      if (previous != null && state == previous) state = next;
    });
    return ref.read(currentDayProvider);
  }

  void select(String date) => state = date;
  void goToPreviousDay() => state = app_date.DateUtils.getPreviousDay(state);
  void goToNextDay() => state = app_date.DateUtils.getNextDay(state);
  void goToToday() => state = ref.read(currentDayProvider);
}

@Riverpod(keepAlive: true)
class MealLog extends _$MealLog {
  final Uuid _uuid = const Uuid();
  final Map<String, List<NutritionResult>> _analysisCache = {};
  int _lastMemoryPressureCount = 0;

  @override
  FutureOr<void> build() {
    AppLifecycleService().addListener(_handleLifecycleEvent);
    ref.onDispose(
      () => AppLifecycleService().removeListener(_handleLifecycleEvent),
    );
  }

  void _handleLifecycleEvent() {
    final count = AppLifecycleService().memoryPressureCount;
    if (count == _lastMemoryPressureCount) return;
    _lastMemoryPressureCount = count;
    _analysisCache.clear();
  }

  String generateMealId() => _uuid.v4();

  Future<void> addMeal(
    Meal meal, {
    bool rebalancePlanner = true,
    String? mealDate,
  }) async {
    final repo = await ref.read(mealRepositoryProvider.future);
    await repo.addMeal(meal);

    // Fire-and-forget streak update via settings
    unawaited(
      ref
          .read(settingsProvider.notifier)
          .updateStreakOnMealLog(mealDate: mealDate),
    );

    // Feeds the promotional paywall's eligibility rules (3 logged meals across
    // 2 distinct days). Nothing called this before, so the counter never moved
    // and the paywall could never become eligible.
    unawaited(
      PromotionalPaywallService.instance().recordSuccessfulMealScanOrLog(),
    );

    // And the review prompt's (5 logged meals across 3 days). The service
    // was complete but nothing fed it, so it could never ask.
    unawaited(AppReviewService.instance().recordSuccessfulMealScanOrLog());

    // After an off-plan meal, the rest of that day's planned meals are
    // resized to what the day has left. The planner could do this all
    // along; nothing asked it to.
    unawaited(
      _rebalancePlanAfter(meal, repo.getMealsByDate(meal.dateString)),
    );
  }

  Future<void> _rebalancePlanAfter(Meal meal, List<Meal> mealsForDate) async {
    try {
      if (!ref.read(proAccessProvider).isPro) return;
      await ref
          .read(plannerNotifierProvider)
          .rebalanceAfterMealLog(
            loggedMeal: meal,
            loggedMealsForDate: mealsForDate,
          );
    } catch (e) {
      debugPrint('Planner rebalance skipped: $e');
    }
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

  List<NutritionResult>? getCachedAnalysis(String imageKey) =>
      _analysisCache[imageKey];
}
