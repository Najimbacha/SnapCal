import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:snapcal/widgets/premium_prompt_card.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/activity_repository.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/home/activity_screen.dart';

/// Renders the activity screen the way `assistant_redesign_test` renders the
/// coach.
///
/// `SNAPCAL_CAPTURE_PREVIEWS=1 flutter test test/activity_design_test.dart`
/// writes PNGs to `build/activity-previews/`. Without the flag it is a smoke
/// test: the screen builds for a Pro user, a free user and someone who has
/// not connected Health Connect, in both themes, both directions and on a
/// small phone, without throwing or overflowing.
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
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
      rootBundle.load('packages/lucide_icons/assets/lucide.ttf'),
    )).load();
  });

  final week = <DailySteps>[
    DailySteps(date: DateTime(2026, 9, 6), steps: 11240),
    DailySteps(date: DateTime(2026, 9, 7), steps: 6120),
    DailySteps(date: DateTime(2026, 9, 8), steps: 9870),
    DailySteps(date: DateTime(2026, 9, 9), steps: 13410),
    DailySteps(date: DateTime(2026, 9, 10), steps: 4380),
    DailySteps(date: DateTime(2026, 9, 11), steps: 10250),
    DailySteps(date: DateTime.now(), steps: 6842),
  ];

  for (final scenario in [
    ('pro-light', true, true, 390.0, 1700.0, 1.0, 'en', false),
    ('pro-dark', true, true, 390.0, 1700.0, 1.0, 'en', true),
    ('free-light', false, true, 390.0, 1200.0, 1.0, 'en', false),
    ('not-connected', false, false, 390.0, 900.0, 1.0, 'en', false),
    ('arabic-pro', true, true, 390.0, 1700.0, 1.0, 'ar', false),
    ('small-pro', true, true, 320.0, 1700.0, 1.0, 'en', false),
  ]) {
    final (name, isPro, connected, width, height, scale, locale, dark) =
        scenario;

    testWidgets('activity $name', (tester) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityProvider.overrideWith(
              () => _FakeActivity(
                ActivitySummary(
                  steps: connected ? 6842 : 0,
                  activeCalories: connected ? 312 : 0,
                  activeCaloriesEstimated: false,
                  healthConnected: connected,
                  workouts:
                      connected
                          ? const [
                            Workout(
                              name: 'Walking',
                              calories: 148,
                              duration: Duration(minutes: 32),
                            ),
                          ]
                          : const [],
                ),
              ),
            ),
            settingsProvider.overrideWith(() => _FakeSettings()),
            effectiveIsProProvider.overrideWithValue(isPro),
            stepGoalProvider.overrideWith((ref) => Future.value(10000)),
            activityWeekProvider.overrideWith(
              (ref) => Future.value(connected ? week : const <DailySteps>[]),
            ),
            stepStreakProvider.overrideWith((ref) => Future.value(4)),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              // AppPageScaffold asks the router whether it can pop.
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const ActivityScreen(),
                ),
              ],
            ),
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
              // The ring's own text sets no family and inherits this one.
              fontFamily: capture ? 'DMSans_regular' : null,
            ),
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: RepaintBoundary(key: key, child: child!),
                ),
          ),
        ),
      );

      // The ring animates in; step past it rather than settling, so a
      // repeating animation could never hang the test.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Capture mode forbids google_fonts from fetching DM Sans and it
      // complains, once, as an unhandled error; the families come from Segoe
      // instead and the render is unaffected. A normal run loads no fonts and
      // must be clean -- that is the run CI sees.
      if (!capture) expect(tester.takeException(), isNull);
      expect(find.byType(PremiumPromptCard), findsNothing);

      if (locale == 'en' && connected) {
        expect(find.text('6842'), findsOneWidget);
        expect(find.textContaining('10,000'), findsWidgets);
      }

      if (capture) {
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/activity-previews/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}

class _FakeActivity extends Activity {
  _FakeActivity(this._summary);

  final ActivitySummary _summary;

  @override
  Future<ActivitySummary> build() async => _summary;
}

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}
