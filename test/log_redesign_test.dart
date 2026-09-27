import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/connectivity_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/log/log_screen.dart';
import 'package:snapcal/data/models/meal_template.dart';
import 'package:snapcal/providers/template_provider.dart';

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _FakeActivity extends Activity {
  @override
  Future<ActivitySummary> build() async => const ActivitySummary(steps: 6842);
}

/// No saved routines; the real store lives in Hive.
class _FakeTemplates extends Templates {
  @override
  Future<List<MealTemplate>> build() async => const [];
}

/// Records meals instead of writing them to Hive.
class _FakeMealLog extends MealLog {
  final added = <Meal>[];

  @override
  FutureOr<void> build() {}

  @override
  Future<void> addMeal(
    Meal meal, {
    bool rebalancePlanner = true,
    String? mealDate,
  }) async => added.add(meal);

  @override
  Future<void> deleteMeal(String mealId) async {}
}

class _FakeWater extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 1600, goal: 2500);
}

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

List<Meal> _meals() {
  final now = DateTime.now();
  Meal meal({
    required String id,
    required int hour,
    required String type,
    required String name,
    required int calories,
  }) {
    return Meal(
      id: id,
      timestamp:
          DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            10,
          ).millisecondsSinceEpoch,
      dateString: _today(),
      foodName: name,
      calories: calories,
      macros: Macros(protein: 30, carbs: 40, fat: 15),
      mealType: type,
      portion: '1 bowl',
    );
  }

  return [
    meal(
      id: 'breakfast',
      hour: 8,
      type: 'Breakfast',
      name: 'Avocado toast and eggs',
      calories: 420,
    ),
    meal(
      id: 'lunch',
      hour: 13,
      type: 'Lunch',
      name: 'Chicken rice bowl',
      calories: 610,
    ),
    meal(
      id: 'snack',
      hour: 16,
      type: 'Snack',
      name: 'Greek yogurt and berries',
      calories: 190,
    ),
  ];
}

Widget _host({Locale locale = const Locale('en'), _FakeMealLog? mealLog}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LogScreen()),
      GoRoute(path: '/reports', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/settings', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/snap', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/log/metric/:type', builder: (_, _) => const SizedBox()),
    ],
  );

  return ProviderScope(
    overrides: [
      templatesProvider.overrideWith(_FakeTemplates.new),
      mealLogProvider.overrideWith(() => mealLog ?? _FakeMealLog()),
      settingsProvider.overrideWith(() => _FakeSettings()),
      waterProvider.overrideWith(() => _FakeWater()),
      activityProvider.overrideWith(() => _FakeActivity()),
      proAccessProvider.overrideWithValue(const ProAccess(ProStatus.pro)),
      todaysMealsProvider.overrideWith((ref) => Stream.value(_meals())),
      mealRepositoryProvider.overrideWith(
        (ref) => Completer<MealRepository>().future,
      ),
      waterRepositoryProvider.overrideWith(
        (ref) => Completer<WaterRepository>().future,
      ),
      connectivityProvider.overrideWith(
        (ref) => Stream.value([ConnectivityResult.wifi]),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('food log keeps the approved hierarchy on a phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Food Log'), findsOneWidget);
    expect(find.text('Daily balance'), findsNothing);
    expect(find.text('MEALS'), findsOneWidget);
    // Meals are one card in eating order, each meal with a single plus.
    expect(find.byKey(const ValueKey('log-day-total')), findsOneWidget);
    expect(find.byKey(const ValueKey('log-meal-diary')), findsOneWidget);
    final mealOrder =
        [
              'log-add-breakfast',
              'log-add-lunch',
              'log-add-dinner',
              'log-add-snack',
            ]
            .map((key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy)
            .toList();
    expect(mealOrder, orderedEquals([...mealOrder]..sort()));
    expect(find.textContaining('Add Breakfast'), findsNothing);
    // Add food sits above the meals: a big search bar, then pills that
    // repeat frequently logged names.
    expect(find.byKey(const ValueKey('quick-add-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-add-custom')), findsOneWidget);
    expect(find.text('Avocado toast and eggs'), findsWidgets);
    expect(find.text('Chicken rice bowl'), findsWidgets);
    expect(find.text('Greek yogurt and berries'), findsWidgets);
    // No floating scan dock, and no separate "Add manually": a food of
    // your own is the Custom food pill or a meal's plus.
    expect(find.byKey(const ValueKey('log-scan-meal')), findsNothing);
    expect(find.byKey(const ValueKey('log-add-manually')), findsNothing);
    // Every meal here has one food, so none offers "Save as routine".
    expect(find.text('Save as routine'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('food-log-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    // Water, steps and the Pro protein line share one card.
    expect(find.text('Daily health'), findsNothing);
    final health = find.byKey(const ValueKey('log-health-card'));
    expect(
      find.descendant(of: health, matching: find.text('6,842')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: health, matching: find.text('PRO')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('food log does not overflow on a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('daily-balance-card')), findsNothing);
    expect(find.byKey(const ValueKey('quick-add-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each meal plus opens the short own-food form for that meal, '
      'which needs only a name and calories', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final mealLog = _FakeMealLog();

    await tester.pumpWidget(_host(mealLog: mealLog));
    await tester.pump(const Duration(milliseconds: 500));
    final plus = find.byKey(const ValueKey('log-add-dinner'));
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pumpAndSettle();

    expect(find.text('Your own food'), findsOneWidget);
    expect(find.text('Add to Dinner'), findsOneWidget);
    // Protein, carbs and fat wait behind a link.
    expect(find.text('Protein, carbs and fat (optional)'), findsOneWidget);
    final add = find.byKey(const ValueKey('custom-food-add'));
    expect(tester.widget<FilledButton>(add).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('custom-food-name')),
      'chickpea curry',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-kcal')),
      '450',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
    await tester.tap(add);
    await tester.pumpAndSettle();

    final meal = mealLog.added.single;
    expect(meal.foodName, 'Chickpea curry');
    expect(meal.calories, 450);
    expect(meal.mealType, 'Dinner');
    expect(meal.dateString, _today());
    expect(find.text('Chickpea curry added'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a search that finds nothing offers to add it yourself, '
      'keeping what was typed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final mealLog = _FakeMealLog();

    await tester.pumpWidget(_host(mealLog: mealLog));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('quick-add-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('quick-food-search-field')),
      'zzqx stew',
    );
    await tester.pump();
    expect(
      find.text('No matches in your foods or the food list.'),
      findsOneWidget,
    );
    expect(find.text('Add “zzqx stew” yourself'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quick-food-add-own')));
    await tester.pumpAndSettle();
    expect(find.text('Your own food'), findsOneWidget);
    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('custom-food-name')),
    );
    expect(name.controller!.text, 'zzqx stew');
    expect(tester.takeException(), isNull);
  });

  testWidgets('food log remains stable in Arabic', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(locale: const Locale('ar')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('daily-balance-card')), findsNothing);
    expect(find.byKey(const ValueKey('log-scan-meal')), findsNothing);
    expect(find.byKey(const ValueKey('quick-add-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
