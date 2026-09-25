import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/metrics_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/reports/reports_screen.dart';

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _Metrics extends BodyMetrics {
  @override
  Future<List<BodyMetric>> build() async {
    final now = DateTime.now();
    return [
      for (var i = 0; i < 5; i++)
        BodyMetric(
          date: DateTime(now.year, now.month, now.day - 4 + i),
          weight: 73.0 - i * .15,
        ),
    ];
  }
}

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  late MealRepository repo;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    Hive.init((await Directory.systemTemp.createTemp('snapcal_stats_')).path);
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(MacrosAdapter());
    repo = MealRepository.forTesting(
      FakeFirebaseFirestore(),
      MockFirebaseAuth(mockUser: MockUser(uid: 'stats'), signedIn: true),
    );
    await repo.init();
    final now = DateTime.now();
    const week = [1720, 1980, 2140, 1650, 1910, 1860, 1220];
    for (var i = 0; i < week.length; i++) {
      final date = DateTime(now.year, now.month, now.day - 6 + i, 12);
      await repo.addMeal(
        Meal(
          id: 'meal$i',
          timestamp: date.millisecondsSinceEpoch,
          dateString: _day(date),
          foodName: 'Lunch $i',
          calories: week[i],
          macros: Macros(protein: 100, carbs: 200, fat: 60),
        ),
      );
    }
  });
  tearDownAll(Hive.close);

  Widget host({required bool pro, bool reduce = false}) => ProviderScope(
    overrides: [
      settingsProvider.overrideWith(_Settings.new),
      bodyMetricsProvider.overrideWith(_Metrics.new),
      mealRepositoryProvider.overrideWith((ref) async => repo),
      todaysMealsProvider.overrideWith((ref) => Stream.value(const [])),
      proAccessProvider.overrideWithValue(
        ProAccess(pro ? ProStatus.pro : ProStatus.free),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: child!,
          ),
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const ReportsScreen())],
      ),
    ),
  );

  testWidgets('Stats opens, rolls its average in and settles', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(pro: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Mid-roll the average is drawn digit by digit.
    expect(find.text('1,783'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('1,783'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-bar-6')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a bar shows its day, tapping again lets go', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(pro: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stats-bar-2')));
    await tester.pumpAndSettle();
    expect(find.text('2,140 kcal'), findsOneWidget);
    expect(find.textContaining('140 over your target'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('stats-bar-2')));
    await tester.pumpAndSettle();
    expect(find.text('2,140 kcal'), findsNothing);
  });

  testWidgets('switching to 30 days grows a new set of bars', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(pro: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-bar-29')), findsNothing);

    // A day picked in one range is let go when the range changes.
    await tester.tap(find.byKey(const ValueKey('stats-bar-2')));
    await tester.pumpAndSettle();
    expect(find.text('2,140 kcal'), findsOneWidget);

    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-bar-29')), findsOneWidget);
    expect(find.text('2,140 kcal'), findsNothing);
    expect(find.text('0 kcal'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with reduced motion everything is in place at once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(pro: true, reduce: true));
    // A few frames for the data to load -- far less than any animation.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.text('1,783'), findsOneWidget);
  });
}
