import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/auth/auth_screen.dart';
import 'package:snapcal/screens/splash/splash_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app(Widget home, {bool reduceMotion = false}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
    home: home,
  );

  group('loading screen', () {
    double opacityOf(WidgetTester tester, String text) =>
        tester
            .widget<Opacity>(
              find.ancestor(
                of: find.text(text),
                matching: find.byType(Opacity),
              ),
            )
            .opacity;

    testWidgets('shows the Wazn name, not the old letter', (tester) async {
      await tester.pumpWidget(app(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      // The name is still to come while the icon draws.
      expect(opacityOf(tester, 'W'), 0);
      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'W'), 1);
      expect(opacityOf(tester, 'n'), 1);
      expect(find.bySemanticsLabel('Wazn'), findsOneWidget);
      expect(find.text('Calorie tracker'), findsOneWidget);
      expect(find.text('S'), findsNothing);
    });

    testWidgets('is complete at once with reduced motion', (tester) async {
      await tester.pumpWidget(app(const SplashScreen(), reduceMotion: true));
      await tester.pump();
      expect(opacityOf(tester, 'W'), 1);
      expect(opacityOf(tester, 'Calorie tracker'), 1);
    });
  });

  group('sign-in', () {
    Future<void> openEmailForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(child: app(const AuthScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.tap(find.text('Continue with email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
    }

    testWidgets('the title changes and rises for the email form', (
      tester,
    ) async {
      await openEmailForm(tester);
      expect(find.bySemanticsLabel('Welcome back'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing details give the form a shake', (tester) async {
      await openEmailForm(tester);
      double shift() =>
          tester
              .widget<Transform>(find.byKey(const ValueKey('auth-form-shake')))
              .transform
              .getTranslation()
              .x;

      await tester.tap(find.text('Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(shift().abs(), greaterThan(1));
      await tester.pumpAndSettle();
      expect(shift(), closeTo(0, 1e-6));
    });
  });
}
