import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/activity_repository.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/metrics_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/home/activity_screen.dart';
import 'package:snapcal/screens/log/health_metric_detail_screen.dart';
import 'package:snapcal/screens/log/models/log_metric_models.dart';
import 'package:snapcal/screens/log/widgets/edit_meal_modal.dart';
import 'package:snapcal/screens/log/widgets/meal_list_tile.dart';
import 'package:snapcal/screens/settings/widgets/weight_entry_modal.dart';
import 'package:snapcal/widgets/motion/arriving_item.dart';
import 'package:snapcal/widgets/wazn_icons.dart';

Meal _salad({int calories = 520}) => Meal(
  id: 'salad',
  timestamp: DateTime(2026, 9, 26, 13, 5).millisecondsSinceEpoch,
  dateString: '2026-09-26',
  foodName: 'Chicken salad bowl',
  calories: calories,
  macros: Macros(protein: 42, carbs: 28, fat: 24),
  portion: '1 bowl',
  mealType: 'Lunch',
);

Widget _app(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _FakeWater extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 1600, goal: 2500);
}

class _FakeActivity extends Activity {
  @override
  Future<ActivitySummary> build() async => ActivitySummary(
    steps: 7842,
    activeCalories: 312,
    activeCaloriesEstimated: true,
    healthConnected: true,
  );
}

class _FakeMetrics extends BodyMetrics {
  final logged = <double>[];

  @override
  Future<List<BodyMetric>> build() async => [
    BodyMetric(id: 'w1', date: DateTime(2026, 9, 25), weight: 78.3),
  ];

  @override
  Future<void> logWeight(
    double weightKg, {
    DateTime? date,
    double? heightCm,
    double? bodyFat,
  }) async => logged.add(weightKg);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('editing a meal', () {
    Future<void> open(WidgetTester tester, {void Function(Meal)? onSave}) {
      _tallView(tester);
      return tester.pumpWidget(
        _app(
          EditMealModal(
            meal: _salad(),
            onSave: onSave ?? (_) {},
            onDelete: () {},
          ),
        ),
      );
    }

    String text(WidgetTester tester, int field) =>
        tester
            .widget<TextField>(find.byType(TextField).at(field))
            .controller!
            .text;

    testWidgets('the numbers count up as it opens', (tester) async {
      await open(tester);
      await tester.pump(const Duration(milliseconds: 600));
      final midway = int.parse(text(tester, 2));
      expect(midway, greaterThan(0));
      expect(midway, lessThan(520));
      await tester.pumpAndSettle();
      expect(text(tester, 2), '520');
      expect(text(tester, 3), '42');
      expect(text(tester, 5), '24');
    });

    testWidgets('touching a field puts the real numbers in at once', (
      tester,
    ) async {
      await open(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.showKeyboard(find.byType(TextField).at(0));
      await tester.pump();
      expect(text(tester, 2), '520');
      expect(text(tester, 4), '28');
    });

    testWidgets('a bar shows the split and follows the typing', (tester) async {
      await open(tester);
      await tester.pumpAndSettle();
      // 168 kcal protein, 112 carbs, 216 fat.
      expect(find.text('Protein 34%'), findsOneWidget);
      expect(find.text('Carbs 23%'), findsOneWidget);
      expect(find.text('Fat 44%'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(5), '0');
      await tester.pumpAndSettle();
      expect(find.text('Protein 60%'), findsOneWidget);
      expect(find.text('Fat 0%'), findsOneWidget);
    });

    testWidgets('the meal type pill glides to the choice', (tester) async {
      await open(tester);
      await tester.pumpAndSettle();
      AlignmentGeometry pill() =>
          tester
              .widget<AnimatedAlign>(
                find.byKey(const ValueKey('meal-type-pill')),
              )
              .alignment;
      expect(pill(), AlignmentDirectional(-1 + 2 / 3, 0));
      await tester.tap(find.text('Dinner'));
      await tester.pumpAndSettle();
      expect(pill(), AlignmentDirectional(-1 + 4 / 3, 0));
    });

    testWidgets('Save shows a tick before handing the meal over', (
      tester,
    ) async {
      Meal? saved;
      await open(tester, onSave: (meal) => saved = meal);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Entry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('edit-meal-saved')), findsOneWidget);
      expect(saved, isNull);
      await tester.pump(const Duration(milliseconds: 400));
      expect(saved?.calories, 520);
    });

    testWidgets('delete asks first, with a gentle pop', (tester) async {
      await open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Entry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Delete Meal Entry?'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Meal Entry?'), findsNothing);
    });
  });

  group('the Log row', () {
    Widget row(Meal meal) => _app(
      MealListTile(meal: meal, isPro: false, onTap: () {}, onDelete: () {}),
    );

    testWidgets('an edit rolls the calories and shows the change', (
      tester,
    ) async {
      await tester.pumpWidget(row(_salad()));
      expect(find.text('520 kcal'), findsOneWidget);
      await tester.pumpWidget(row(_salad(calories: 560)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('+40'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('560 kcal'), findsOneWidget);
      expect(find.text('+40'), findsNothing);
    });

    testWidgets('a meal deleted from its sheet slides out, then goes', (
      tester,
    ) async {
      var left = false;
      Widget item(bool leaving) => _app(
        Column(
          children: [
            ArrivingItem(
              arrived: false,
              leaving: leaving,
              onLeft: () => left = true,
              child: const SizedBox(height: 60, child: Text('meal')),
            ),
          ],
        ),
      );
      await tester.pumpWidget(item(false));
      await tester.pumpWidget(item(true));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getSize(find.byType(ArrivingItem)).height, lessThan(60));
      expect(left, isFalse);
      await tester.pumpAndSettle();
      expect(left, isTrue);
    });
  });

  group('Activity', () {
    testWidgets('the week grows in and a tap shows the day', (tester) async {
      tester.view.physicalSize = const Size(390, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final today = DateTime.now();
      final week = [
        for (var i = 0; i < 7; i++)
          DailySteps(
            date: today.subtract(Duration(days: 6 - i)),
            steps: const [6200, 8900, 10450, 11204, 10020, 10310, 7842][i],
          ),
      ];
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const ActivityScreen())],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityProvider.overrideWith(_FakeActivity.new),
            settingsProvider.overrideWith(_FakeSettings.new),
            effectiveIsProProvider.overrideWithValue(true),
            stepGoalProvider.overrideWith((ref) => Future.value(10000)),
            activityWeekProvider.overrideWith((ref) => Future.value(week)),
            stepStreakProvider.overrideWith((ref) => Future.value(4)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      double bar(int i) =>
          tester.getSize(find.byKey(ValueKey('week-bar-$i'))).height;

      // Step the clock, so the bars' timing is seen frame by frame.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final early = bar(3);
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(early, lessThan(bar(3) / 2));
      expect(find.text('4/7'), findsOneWidget);
      expect(find.text('11,204'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('week-bar-3')));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('week-bubble-3')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('health details', () {
    Future<void> open(WidgetTester tester) async {
      _tallView(tester);
      await tester.pumpWidget(
        _app(
          const HealthMetricDetailScreen(metric: LogMetricType.water),
          overrides: [
            settingsProvider.overrideWith(_FakeSettings.new),
            waterProvider.overrideWith(_FakeWater.new),
            activityProvider.overrideWith(_FakeActivity.new),
            effectiveIsProProvider.overrideWithValue(true),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('going back names the week being looked at', (tester) async {
      await open(tester);
      expect(find.text('This week'), findsOneWidget);

      await tester.tap(find.byIcon(WaznIcons.chevronLeft));
      await tester.pumpAndSettle();
      final range = metricRangeFor(
        LogMetricPeriod.week,
        shiftMetricAnchor(LogMetricPeriod.week, DateTime.now(), -1),
      );
      final day = DateFormat.MMMd('en');
      expect(
        find.text('${day.format(range.start)} – ${day.format(range.end)}'),
        findsOneWidget,
      );
      expect(find.text('This week'), findsNothing);

      await tester.tap(find.byIcon(WaznIcons.chevronRight));
      await tester.pumpAndSettle();
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('the period pill slides to the choice', (tester) async {
      await open(tester);
      AlignmentGeometry pill() =>
          tester
              .widget<AnimatedAlign>(
                find.byKey(const ValueKey('metric-period-pill')),
              )
              .alignment;
      expect(pill(), const AlignmentDirectional(-.5, 0));
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();
      expect(pill(), AlignmentDirectional.center);
      expect(find.text('This month'), findsOneWidget);
    });
  });

  group('logging weight', () {
    testWidgets('a mistake shakes, the change shows, Save ticks', (
      tester,
    ) async {
      _tallView(tester);
      final metrics = _FakeMetrics();
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const WeightEntryModal(),
                      ),
                  child: const Text('open'),
                ),
          ),
          overrides: [
            bodyMetricsProvider.overrideWith(() => metrics),
            settingsProvider.overrideWith(_FakeSettings.new),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      double shift() =>
          tester
              .widget<Transform>(
                find.byKey(const ValueKey('weight-field-shake')),
              )
              .transform
              .getTranslation()
              .x;

      await tester.enterText(find.byType(TextField).first, '779');
      await tester.tap(find.text('Save progress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(shift().abs(), greaterThan(1));
      await tester.pumpAndSettle();
      expect(find.text('Enter a value between 30 and 300'), findsOneWidget);
      expect(find.byKey(const ValueKey('weight-change-chip')), findsNothing);

      await tester.enterText(find.byType(TextField).first, '77.9');
      await tester.pumpAndSettle();
      expect(find.text('Enter a value between 30 and 300'), findsNothing);
      expect(find.text('−0.4 kg since Sep 25'), findsOneWidget);

      await tester.tap(find.text('Save progress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('weight-saved')), findsOneWidget);
      expect(metrics.logged, [closeTo(77.9, 1e-9)]);
      await tester.pumpAndSettle();
      expect(find.byType(WeightEntryModal), findsNothing);
    });
  });
}
