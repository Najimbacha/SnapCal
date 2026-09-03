import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/auth_state_provider.dart';
import 'package:snapcal/providers/promo_offer_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/settings/about_screen.dart';
import 'package:snapcal/screens/settings/settings_screen.dart';
import 'package:snapcal/screens/settings/widgets/settings_kit.dart';

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _FakeActivity extends Activity {
  @override
  Future<ActivitySummary> build() async => ActivitySummary();
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isAnonymous => false;

  @override
  String? get displayName => 'Najim';

  @override
  String? get email => 'najim@example.com';

  @override
  String? get photoURL => null;

  @override
  String get uid => 'uid-1';
}

Widget _host({
  required Widget child,
  List<Override> overrides = const [],
  GoRouter? router,
}) {
  final effectiveRouter =
      router ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => child),
          GoRoute(
            path: '/settings/about',
            builder: (_, _) => const AboutScreen(),
          ),
        ],
      );
  return ProviderScope(
    overrides:
        overrides +
        [
          settingsProvider.overrideWith(() => _FakeSettings()),
          activityProvider.overrideWith(() => _FakeActivity()),
          // Without this the real provider runs, gets null back from an
          // unconfigured RevenueCat, and schedules a 20-second retry timer
          // that outlives the widget tree — which the test binding reports as
          // "a Timer is still pending", failing tests that never touched the
          // promo pill.
          promoOfferProvider.overrideWith((ref) async => null),
        ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: effectiveRouter,
    ),
  );
}

void main() {
  testWidgets('guest root hides sign-out zone and shows upgrade card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // SettingsSection uppercases its title, so these are the l10n values
    // settings_core_config / settings_data_security / settings_information as
    // they render. They were renamed when Settings was split into sub-screens
    // and this expectation kept the old copy.
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('YOUR DATA'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('Sign Out'), findsNothing);
    expect(find.text('SnapCal Pro'), findsOneWidget);
  });

  testWidgets('member root shows live values and the destructive zone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
        ],
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Najim'), findsOneWidget);
    expect(find.textContaining('kcal'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('about row routes to the about screen with social links', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SettingsScreen(showBack: false),
        ),
        GoRoute(
          path: '/settings/about',
          builder: (_, _) => const AboutScreen(),
        ),
      ],
    );

    await tester.pumpWidget(_host(router: router, child: const SizedBox()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.textContaining('snapcalories@gmail'), findsNothing);
    expect(find.text('Tips, recipes & community'), findsOneWidget);
  });

  testWidgets('number dialog disables confirm until input is valid', (
    tester,
  ) async {
    final saved = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed:
                        () => showSettingsNumberDialog(
                          context,
                          title: 'Daily Calories',
                          currentValue: 2000,
                          unit: 'kcal',
                          onSave: (v) async => saved.add(v),
                        ),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '2500');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(saved, [2500]);
  });
}
