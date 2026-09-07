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

Widget _host({Locale locale = const Locale('en')}) {
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
    expect(find.text('Daily balance'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Avocado toast and eggs'), findsOneWidget);
    expect(find.text('Chicken rice bowl'), findsOneWidget);
    expect(find.text('Greek yogurt and berries'), findsOneWidget);
    // The floating scan/pencil dock is gone -- it hovered over the meal rows
    // and covered "Add Dinner". Scanning is the camera button in the nav bar
    // and adding by hand is the action on the Meals heading, both of which
    // were already there.
    expect(find.byKey(const ValueKey('log-scan-meal')), findsNothing);
    expect(find.byKey(const ValueKey('log-add-manually')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('food-log-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily health'), findsOneWidget);
    expect(find.text('6,842'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('food log does not overflow on a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('daily-balance-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('log-add-manually')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manual meal sheet stays above the log and shows its save action',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('log-add-manually')));
      await tester.pumpAndSettle();

      expect(find.text('Log New Meal'), findsOneWidget);
      expect(find.text('Food Name'), findsOneWidget);
      expect(find.text('Portion Description'), findsOneWidget);
      expect(find.text('Save Entry'), findsOneWidget);
      expect(find.text('Breakfast'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('food log remains stable in Arabic', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(locale: const Locale('ar')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('daily-balance-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('log-scan-meal')), findsNothing);
    expect(find.byKey(const ValueKey('log-add-manually')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
