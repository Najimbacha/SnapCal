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

class _FakeWater extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 1600, goal: 2500);
}

/// Routines kept in memory, recording what the Log asks of them.
class _Routines extends Templates {
  _Routines(this.start);

  final List<MealTemplate> start;
  final saved = <MealTemplate>[];
  final logged = <(String, String?, String?)>[];

  @override
  Future<List<MealTemplate>> build() async => [...start];

  @override
  Future<MealTemplate> saveTemplate({
    required String name,
    required String emoji,
    required List<Meal> meals,
    String? mealType,
  }) async {
    final t = MealTemplate(
      id: 'new-${saved.length}',
      name: name,
      emoji: emoji,
      items: [
        for (final m in meals)
          TemplateItem(
            foodName: m.foodName,
            calories: m.calories,
            protein: m.macros.protein,
            carbs: m.macros.carbs,
            fat: m.macros.fat,
          ),
      ],
      createdAt: 1,
      mealType: mealType,
    );
    saved.add(t);
    state = AsyncData([...state.valueOrNull ?? [], t]);
    return t;
  }

  @override
  Future<List<String>> logFromTemplate(
    MealTemplate template, {
    String? dateString,
    String? mealType,
  }) async {
    logged.add((template.id, dateString, mealType));
    return ['a', 'b'];
  }
}

MealTemplate _routine(String id, {String type = 'Breakfast'}) => MealTemplate(
  id: id,
  name: 'My usual breakfast',
  emoji: '🥣',
  items: [
    TemplateItem(
      foodName: 'Oat porridge',
      calories: 320,
      protein: 12,
      carbs: 50,
      fat: 8,
    ),
    TemplateItem(
      foodName: 'Flat white',
      calories: 95,
      protein: 5,
      carbs: 8,
      fat: 5,
    ),
  ],
  createdAt: 1,
  mealType: type,
);

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
      id: 'coffee',
      hour: 8,
      type: 'Breakfast',
      name: 'Flat white',
      calories: 95,
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

Widget _host(
  _Routines templates, {
  Locale locale = const Locale('en'),
  bool free = false,
}) {
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
      templatesProvider.overrideWith(() => templates),
      settingsProvider.overrideWith(() => _FakeSettings()),
      waterProvider.overrideWith(() => _FakeWater()),
      activityProvider.overrideWith(() => _FakeActivity()),
      proAccessProvider.overrideWithValue(
        ProAccess(free ? ProStatus.free : ProStatus.pro),
      ),
      effectiveIsProProvider.overrideWithValue(!free),
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

Future<void> _run(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a saved routine sits first in Quick add and logs in one tap '
      'into its own meal, with Undo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final routines = _Routines([_routine('r1', type: 'Dinner')]);
    await tester.pumpWidget(_host(routines));
    await _run(tester, 1500);

    final card = find.byKey(const ValueKey('routine-r1'));
    expect(card, findsOneWidget);
    // A pill in the Add food row, right after "Custom food".
    final custom = tester.getRect(
      find.byKey(const ValueKey('quick-add-custom')),
    );
    final pill = tester.getRect(card);
    expect(pill.top, closeTo(custom.top, 1));
    expect(pill.left, greaterThan(custom.right));
    expect(pill.height, 40);

    await tester.tap(card);
    await tester.pump();
    await _run(tester, 600);
    expect(routines.logged.single.$1, 'r1');
    expect(routines.logged.single.$2, _today());
    expect(routines.logged.single.$3, 'Dinner');
    expect(find.text('Routine logged'), findsOneWidget);
    expect(find.text('2 foods added to Dinner'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await _run(tester, 5000);
  });

  testWidgets('a meal can be saved as a routine, which then leads Quick add '
      'marked new', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final routines = _Routines([]);
    await tester.pumpWidget(_host(routines));
    await _run(tester, 1500);

    // Only a meal with two or more foods offers it.
    expect(find.byKey(const ValueKey('log-save-lunch')), findsNothing);
    final save = find.byKey(const ValueKey('log-save-breakfast'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await _run(tester, 800);
    // The sheet, titled like the link that opened it.
    expect(find.text('Save as a routine'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('routine-save')), findsOneWidget);
    expect(find.text('My usual breakfast'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('routine-save')));
    await tester.pump();
    await _run(tester, 1500);
    expect(routines.saved.single.name, 'My usual breakfast');
    expect(routines.saved.single.mealType, 'Breakfast');
    expect(find.text('Routine saved'), findsOneWidget);
    // Back up to Quick add, which the save button scrolled away from.
    await tester.drag(
      find.byKey(const ValueKey('food-log-scroll')),
      const Offset(0, 900),
    );
    await _run(tester, 600);
    expect(find.byKey(const ValueKey('routine-new-tag')), findsOneWidget);
    await _run(tester, 5000);
  });

  testWidgets('a free account with three routines is told about Pro instead', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final routines = _Routines([
      _routine('r1'),
      _routine('r2'),
      _routine('r3'),
    ]);
    await tester.pumpWidget(_host(routines, free: true));
    await _run(tester, 1500);

    final save = find.byKey(const ValueKey('log-save-breakfast'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await _run(tester, 800);
    expect(find.byKey(const ValueKey('routine-limit')), findsOneWidget);
    expect(find.text('You have 3 of 3 free routines'), findsOneWidget);
    expect(routines.saved, isEmpty);
  });
}
