import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/core/theme/app_theme.dart';
import 'package:snapcal/data/services/calorie_onboarding_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/auth_state_provider.dart';
import 'package:snapcal/screens/onboarding/onboarding_flow_screen.dart';

/// The onboarding, walked from the welcome screen to the plan.
///
/// `SNAPCAL_CAPTURE_PREVIEWS=1 flutter test test/onboarding_design_test.dart`
/// writes each step to `build/onboarding-after/`. Without the flag it checks
/// that every step builds without overflowing -- in dark mode, in Arabic and
/// on a small phone -- and that the plan runs at the pace chosen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1';

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!capture) return;
    // The theme sets DM Sans through google_fonts, which cannot fetch it in a
    // test; each weight's family is given the nearest Segoe weight.
    const segoe = 'C:/Windows/Fonts';
    for (final (family, file) in [
      ('DMSans_regular', 'segoeui.ttf'),
      ('DMSans_500', 'segoeui.ttf'),
      ('DMSans_600', 'seguisb.ttf'),
      ('DMSans_700', 'segoeuib.ttf'),
      ('DMSans_800', 'segoeuib.ttf'),
      ('DMSans_900', 'seguibl.ttf'),
      ('DMSans', 'segoeui.ttf'),
    ]) {
      await (FontLoader(family)..addFont(
        Future.value(
          ByteData.sublistView(File('$segoe/$file').readAsBytesSync()),
        ),
      )).load();
    }
    await (FontLoader('packages/material_symbols_icons/MaterialSymbolsOutlined')
          ..addFont(
            rootBundle.load(
              'packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf',
            ),
          ))
        .load();
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
      rootBundle.load('packages/lucide_icons/assets/lucide.ttf'),
    )).load();
  });

  for (final (name, locale, dark, size) in [
    ('en', 'en', false, const Size(390, 844)),
    ('dark', 'en', true, const Size(390, 844)),
    ('ar', 'ar', false, const Size(390, 844)),
    ('small', 'en', false, const Size(320, 640)),
  ]) {
    testWidgets('onboarding walks through to a plan ($name)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final l10n = await AppLocalizations.delegate.load(Locale(locale));
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [isAnonymousProvider.overrideWithValue(true)],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder:
                (context, child) => RepaintBoundary(key: key, child: child!),
            home: const OnboardingFlowScreen(),
          ),
        ),
      );

      Future<void> settle([int ms = 1200]) async {
        for (var i = 0; i < ms ~/ 100; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> tapOn(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
      }

      Future<void> shot(String step) async {
        if (!capture) {
          expect(tester.takeException(), isNull, reason: '$name $step');
          return;
        }
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/onboarding-after/$name-$step.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      final next = find.byKey(const ValueKey('onboarding-continue'));

      await settle(2500);
      await shot('1-welcome');

      await tapOn(find.byKey(const ValueKey('onboarding-get-started')));
      await settle();
      await tapOn(find.text(l10n.onboarding_goal_lose));
      await settle(500);
      await shot('2-goal');

      await tapOn(next);
      await settle();
      await tapOn(find.text(l10n.onboarding_male));
      await settle(500);
      await shot('3-profile');

      await tapOn(next);
      await settle();
      await tapOn(find.text(l10n.onboarding_pace_balanced));
      await settle(500);
      await shot('4-pace');

      await tapOn(next);
      await settle();
      await tapOn(find.text(l10n.onboarding_activity_light));
      await settle(500);
      await shot('5-activity');

      await tapOn(next);
      await settle(2000);
      await shot('6-plan');

      expect(find.byKey(const ValueKey('onboarding-start-plan')), findsOneWidget);
      // The pace chosen on the pace step is the pace in the plan.
      if (locale == 'en') {
        expect(find.textContaining('0.5 kg/week'), findsWidgets);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await settle(2000);
    });
  }

  test('a plan runs at the pace the user chose', () {
    final plan = CalorieOnboardingService().computeBasePlan(
      OnboardingProfileInput(
        age: 28,
        gender: 'male',
        heightCm: 170,
        currentWeightKg: 75,
        goalWeightKg: 70,
        timelineMonths: 3,
        activityLevel: 'light_mover',
        weightUnit: 'kg',
        heightUnit: 'cm',
        selectedWeeklyRateKg: 0.5,
      ),
      languageCode: 'en',
    );
    expect(plan.weeklyRateKg, 0.5);
    expect(plan.paceAdjusted, isFalse);
  });
}
