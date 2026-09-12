import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/data/models/user_settings.dart';
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
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _Achievements extends Achievements {
  @override
  Future<List<Achievement>> build() async => [];
  @override
  Future<void> refreshAchievements() async {}
}

class _Activity extends Activity {
  @override
  Future<ActivitySummary> build() async => const ActivitySummary(steps: 6842);
}

class _Water extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 1600, goal: 2500);
}

void main() {
  for (final destination in ['/assistant', '/planner']) {
    for (final status in ProStatus.values) {
      testWidgets('Home opens $destination for $status at large text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
            GoRoute(
              path: destination,
              builder: (_, _) => const Scaffold(body: Text('Feature opened')),
            ),
            GoRoute(
              path: '/paywall',
              builder: (_, _) => const Text('Unexpected paywall'),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(_Settings.new),
              achievementsProvider.overrideWith(_Achievements.new),
              activityProvider.overrideWith(_Activity.new),
              waterProvider.overrideWith(_Water.new),
              stepGoalProvider.overrideWith((ref) async => 10000),
              proAccessProvider.overrideWithValue(ProAccess(status)),
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
                    ).copyWith(textScaler: TextScaler.linear(2)),
                    child: child!,
                  ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
        final target = find.text(
          destination == '/assistant' ? 'AI Coach' : 'Meal Planner',
        );
        await tester.scrollUntilVisible(target, 250);
        await tester.pump();
        await Scrollable.ensureVisible(tester.element(target), alignment: 0.1);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.text('Feature opened'), findsOneWidget);
        expect(find.text('Unexpected paywall'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      });
    }
  }
}
