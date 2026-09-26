import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/data/services/health_connect_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/log/health_metric_detail_screen.dart';
import 'package:snapcal/screens/log/models/log_metric_models.dart';
import 'package:snapcal/widgets/motion/count_up_text.dart';
import 'package:snapcal/widgets/wazn_icons.dart';

/// Last week, Sunday to Saturday: every day in it is in the past.
MetricPeriodRange _lastWeek() => metricRangeFor(
  LogMetricPeriod.week,
  shiftMetricAnchor(LogMetricPeriod.week, DateTime.now(), -1),
);

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _FakeWater extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 900, goal: 2500);
}

class _FakeActivity extends Activity {
  @override
  Future<ActivitySummary> build() async => const ActivitySummary(
    steps: 4321,
    activeCalories: 150,
    healthConnected: true,
  );
}

class _FakeMeals implements MealRepository {
  _FakeMeals(this.byDate);
  final Map<String, List<Meal>> byDate;

  @override
  List<Meal> getMealsByDate(String dateString) =>
      byDate[dateString] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWaterLogs implements WaterRepository {
  _FakeWaterLogs(this.byDate);
  final Map<String, int> byDate;

  @override
  int getTotalWater(String dateString) => byDate[dateString] ?? 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHealth implements HealthConnectService {
  final ranges = <(DateTime, DateTime)>[];

  @override
  Future<int> getStepsForDateRange(DateTime start, DateTime end) async {
    ranges.add((start, end));
    return 7000;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Meal _meal(String date, {required int protein}) => Meal(
  id: 'meal-$date',
  timestamp: DateTime.parse(date).millisecondsSinceEpoch,
  dateString: date,
  foodName: 'Lentil soup',
  calories: 350,
  macros: Macros(protein: protein, carbs: 40, fat: 8),
  portion: '1 bowl',
  mealType: 'Lunch',
);

Future<void> _open(
  WidgetTester tester,
  LogMetricType metric, {
  Map<String, List<Meal>> meals = const {},
  Map<String, int> water = const {},
  _FakeHealth? health,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_FakeSettings.new),
        waterProvider.overrideWith(_FakeWater.new),
        activityProvider.overrideWith(_FakeActivity.new),
        effectiveIsProProvider.overrideWithValue(true),
        todaysMealsProvider.overrideWith((ref) => Stream.value(const [])),
        mealRepositoryProvider.overrideWith((ref) async => _FakeMeals(meals)),
        waterRepositoryProvider.overrideWith(
          (ref) async => _FakeWaterLogs(water),
        ),
        healthConnectServiceProvider.overrideWithValue(health ?? _FakeHealth()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HealthMetricDetailScreen(metric: metric)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _goBackAWeek(WidgetTester tester) async {
  await tester.tap(find.byIcon(WaznIcons.chevronLeft));
  await tester.pumpAndSettle();
}

int _average(WidgetTester tester) =>
    tester
        .widget<CountUpText>(find.byKey(const ValueKey('metric-average')))
        .value;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('water for a past week comes from its logs', (tester) async {
    final sunday = metricDateString(_lastWeek().start);
    await _open(tester, LogMetricType.water, water: {sunday: 1400});
    await _goBackAWeek(tester);
    expect(_average(tester), 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('protein for a past week sums that day\'s meals', (tester) async {
    final monday = metricDateString(
      DateTime(
        _lastWeek().start.year,
        _lastWeek().start.month,
        _lastWeek().start.day + 1,
      ),
    );
    await _open(
      tester,
      LogMetricType.protein,
      meals: {
        monday: [_meal(monday, protein: 49)],
      },
    );
    await _goBackAWeek(tester);
    expect(_average(tester), 7);
  });

  testWidgets('steps for a past week ask Health Connect for each day', (
    tester,
  ) async {
    final health = _FakeHealth();
    await _open(tester, LogMetricType.steps, health: health);
    health.ranges.clear();
    await _goBackAWeek(tester);

    expect(_average(tester), 7000);
    final week = _lastWeek();
    expect(health.ranges, hasLength(7));
    expect(health.ranges.first.$1, week.start);
    expect(
      health.ranges.first.$2,
      DateTime(week.start.year, week.start.month, week.start.day + 1),
    );
    // Not the live count for today, which is 4321.
    expect(_average(tester), isNot(4321));
  });

  testWidgets('a past week of water shows in Arabic too', (tester) async {
    final sunday = metricDateString(_lastWeek().start);
    await _open(
      tester,
      LogMetricType.water,
      water: {sunday: 2100},
      locale: const Locale('ar'),
    );
    // Right to left, "back" is the chevron on the right.
    await tester.tap(find.byIcon(WaznIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(_average(tester), 300);
    expect(tester.takeException(), isNull);
  });
}
