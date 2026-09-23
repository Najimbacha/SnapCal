import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/first_meal_guide_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/achievements_provider.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/connectivity_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/home/home_screen.dart';

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async =>
      UserSettings.defaults().copyWith(onboardingComplete: true);
}

class _Achievements extends Achievements {
  @override
  Future<List<Achievement>> build() async => [];

  @override
  Future<void> refreshAchievements() async {}
}

class _Activity extends Activity {
  @override
  Future<ActivitySummary> build() async => const ActivitySummary();
}

class _Water extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 0, goal: 2500);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHome(WidgetTester tester, {double textScale = 1}) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/snap',
          builder: (_, _) => const Scaffold(body: Text('FOOD CAMERA')),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SizedBox.shrink()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_Settings.new),
          achievementsProvider.overrideWith(_Achievements.new),
          activityProvider.overrideWith(_Activity.new),
          waterProvider.overrideWith(_Water.new),
          stepGoalProvider.overrideWith((ref) async => 10000),
          proAccessProvider.overrideWithValue(const ProAccess(ProStatus.free)),
          todaysMealsProvider.overrideWith((ref) => Stream.value([])),
          connectivityProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('new user sees a simple overflow-safe guide and opens camera', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await FirstMealGuideService().schedule();

    await pumpHome(tester, textScale: 2);

    expect(find.text('Start with a meal photo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final scan = find.byKey(const ValueKey('first-meal-guide-scan'));
    await tester.ensureVisible(scan);
    await tester.pumpAndSettle();
    await tester.tap(scan);
    await tester.pumpAndSettle();

    expect(find.text('FOOD CAMERA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismissed guide stays dismissed', (tester) async {
    await FirstMealGuideService().schedule();
    await pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('first-meal-guide-dismiss')));
    await tester.pump();

    expect(find.text('Start with a meal photo'), findsNothing);
    expect(await FirstMealGuideService().isPending(), isFalse);
  });

  testWidgets('existing user without a pending flag is not interrupted', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Start with a meal photo'), findsNothing);
  });
}
