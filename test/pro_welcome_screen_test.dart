import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/paywall/paywall_screen.dart';
import 'package:snapcal/screens/paywall/pro_welcome_screen.dart';

void main() {
  Widget buildSubject({
    bool isRestore = false,
    VoidCallback? onContinue,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      builder:
          reduceMotion
              ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
              : null,
      home: ProWelcomeScreen(
        isRestore: isRestore,
        onContinue: onContinue ?? () {},
      ),
    );
  }

  // The intro runs about 2.5s. Stepping through it frame by frame, rather than
  // one long pump, lets the delayed animations actually start and finish, and
  // drains the haptic and confetti timers before the test ends.
  Future<void> playIntro(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tearDownScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a purchase is welcomed with the Pro benefits', (tester) async {
    await tester.pumpWidget(buildSubject());
    await playIntro(tester);

    expect(find.text("You're all set"), findsOneWidget);
    expect(find.text('Welcome to SnapCal Pro'), findsOneWidget);
    for (final benefit in [
      'Unlimited scans',
      'AI guidance',
      'Smart planner',
      'Weekly reports',
    ]) {
      expect(find.text(benefit), findsOneWidget, reason: benefit);
    }
    expect(find.text('Start exploring'), findsOneWidget);

    await tearDownScreen(tester);
  });

  testWidgets('a restore says Pro was restored, not newly bought', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(isRestore: true));
    await playIntro(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Pro restored'), findsOneWidget);
    expect(find.text('Welcome to SnapCal Pro'), findsNothing);

    await tearDownScreen(tester);
  });

  testWidgets('Start exploring continues into the app', (tester) async {
    var continued = 0;
    await tester.pumpWidget(buildSubject(onContinue: () => continued++));
    await playIntro(tester);

    await tester.tap(find.text('Start exploring'));
    expect(continued, 1);

    await tearDownScreen(tester);
  });

  testWidgets('back leads into the app, not back to the paywall', (
    tester,
  ) async {
    var continued = 0;
    await tester.pumpWidget(buildSubject(onContinue: () => continued++));
    await playIntro(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(continued, 1);
    expect(find.text('Welcome to SnapCal Pro'), findsOneWidget);

    await tearDownScreen(tester);
  });

  testWidgets('reduce motion shows the finished screen with no animation', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(reduceMotion: true));
    await tester.pump();

    expect(find.byType(Animate), findsNothing);
    expect(find.text('Welcome to SnapCal Pro'), findsOneWidget);
    expect(find.text('Start exploring'), findsOneWidget);

    await tearDownScreen(tester);
  });

  // Both of the paywall's success paths hand off with the same `go`. The
  // late-confirmation one is reachable without a store, so it stands in for
  // both: Pro arrives while the paywall is open, and the paywall must leave.
  // No purchase was started here, so it is an existing subscription being
  // recognised late -- welcomed back, not congratulated on a new purchase.
  testWidgets('the paywall hands off to the welcome screen when Pro arrives', (
    tester,
  ) async {
    final isPro = StateProvider<bool>((ref) => false);
    final container = ProviderContainer(
      overrides: [
        effectiveIsProProvider.overrideWith((ref) => ref.watch(isPro)),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(path: '/paywall', builder: (_, _) => const PaywallScreen()),
        GoRoute(
          path: '/pro-welcome',
          builder:
              (_, state) =>
                  Text('welcome restore=${(state.extra as Map?)?['restore']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          routerConfig: router,
        ),
      ),
    );
    router.push('/paywall');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PaywallScreen), findsOneWidget);

    container.read(isPro.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('welcome restore=true'), findsOneWidget);
    expect(find.byType(PaywallScreen), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 9));
  });

  // The smallest common phone at double text size, in the two longest
  // languages. It overflowed and pushed the button off screen before the
  // screen learned to scroll; it must now fit and keep the button reachable.
  for (final locale in const ['fr', 'ar']) {
    testWidgets('fits a small phone at 2x text in $locale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: const TextScaler.linear(2),
                ),
                child: child!,
              ),
          home: ProWelcomeScreen(onContinue: () {}),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final button = find.byType(FilledButton);
      await tester.ensureVisible(button);
      await tester.pump();
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(568));
    });
  }
}
