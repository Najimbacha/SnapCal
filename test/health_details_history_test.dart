import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/core/utils/date_utils.dart' as app_date;
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/log/health_metric_detail_screen.dart';
import 'package:snapcal/screens/log/models/log_metric_models.dart';

import 'helpers/metric_history_fakes.dart';

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _Water extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 1500, goal: 2500);
}

class _Activity extends Activity {
  @override
  Future<ActivitySummary> build() async => const ActivitySummary(
    steps: 7842,
    activeCalories: 312,
    healthConnected: true,
  );
}

/// The last [days] days, as the date strings the logs are keyed by.
Iterable<String> _pastDays(int days) sync* {
  final today = DateTime.now();
  for (var i = 0; i < days; i++) {
    yield app_date.DateUtils.getDateString(
      DateTime(today.year, today.month, today.day - i),
    );
  }
}

Meal _meal(String date, int calories, int protein) => Meal(
  id: '$date-$calories',
  timestamp: 0,
  dateString: date,
  foodName: 'Meal',
  calories: calories,
  macros: Macros(protein: protein, carbs: 40, fat: 10),
);

/// 7,000 steps for every calendar day the range touches.
Future<int> _sevenThousandADay(DateTime start, DateTime end) async {
  final days =
      DateTime(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime(start.year, start.month, start.day)).inDays;
  return 7000 * (days < 1 ? 1 : days);
}

Future<void> _open(
  WidgetTester tester,
  LogMetricType metric, {
  Map<String, List<Meal>> meals = const {},
  Map<String, int> water = const {},
  int stepGoal = 10000,
}) async {
  tester.view.physicalSize = const Size(420, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_Settings.new),
        waterProvider.overrideWith(_Water.new),
        activityProvider.overrideWith(_Activity.new),
        effectiveIsProProvider.overrideWithValue(true),
        ...metricHistoryOverrides(
          meals: meals,
          water: water,
          steps: _sevenThousandADay,
          stepGoal: stepGoal,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HealthMetricDetailScreen(metric: metric),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _average(WidgetTester tester) {
  final number = find.descendant(
    of: find.byKey(const ValueKey('metric-average')),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(number).data!;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('water shows what was drunk on each day, not zero', (
    tester,
  ) async {
    await _open(
      tester,
      LogMetricType.water,
      water: {for (final day in _pastDays(400)) day: 1500},
    );
    // Every day of the week so far had 1,500 ml, today included.
    expect(_average(tester), '1,500');
    expect(find.textContaining('1,500', findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calories and protein add up the meals of each day', (
    tester,
  ) async {
    final meals = {
      for (final day in _pastDays(400))
        day: [_meal(day, 500, 30), _meal(day, 700, 50)],
    };
    await _open(tester, LogMetricType.calories, meals: meals);
    expect(_average(tester), '1,200');

    await _open(tester, LogMetricType.protein, meals: meals);
    expect(_average(tester), '80');
  });

  testWidgets('steps are each day\'s own, measured against the step goal', (
    tester,
  ) async {
    await _open(tester, LogMetricType.steps, stepGoal: 8000);
    // It used to give today's 7,842 to every day.
    expect(_average(tester), '7,000');
    expect(find.text('8,000 goal'), findsOneWidget);
  });

  testWidgets('a year of steps is read month by month', (tester) async {
    final asked = <DateTime>[];
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_Settings.new),
          waterProvider.overrideWith(_Water.new),
          activityProvider.overrideWith(_Activity.new),
          effectiveIsProProvider.overrideWithValue(true),
          ...metricHistoryOverrides(
            steps: (start, end) async {
              asked.add(start);
              return 0;
            },
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HealthMetricDetailScreen(metric: LogMetricType.steps),
        ),
      ),
    );
    await tester.pumpAndSettle();
    asked.clear();
    await tester.tap(find.text('Y'));
    await tester.pumpAndSettle();
    // One question per month that has begun, never one per day.
    expect(asked.length, DateTime.now().month);
  });

  testWidgets('energy burned has no goal, so no verdict', (tester) async {
    await _open(tester, LogMetricType.energy);
    expect(find.text("You haven't hit your goal."), findsNothing);
    expect(find.text("You're on track."), findsNothing);
    expect(find.byKey(const ValueKey('metric-goal-fill')), findsNothing);
  });
}
