import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/home/widgets/home_nutrition_dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1';
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader('Preview')..addFont(
      Future.value(
        ByteData.sublistView(
          File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
        ),
      ),
    )).load();
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
      rootBundle.load('packages/lucide_icons/assets/lucide.ttf'),
    )).load();
  });
  for (final scenario in [
    ('free', false, 390.0, 1.0, 'en', true),
    ('pro', true, 390.0, 1.0, 'en', true),
    ('narrow', true, 320.0, 1.0, 'en', true),
    ('large-text', false, 320.0, 1.8, 'en', true),
    ('arabic', true, 320.0, 1.5, 'ar', true),
    ('light', false, 390.0, 1.0, 'en', false),
  ]) {
    testWidgets('Home dashboard ${scenario.$1}', (tester) async {
      tester.view.physicalSize = Size(scenario.$3, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      var upgrades = 0, water = 0, activity = 0, planner = 0, coach = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(scenario.$5),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            brightness: scenario.$6 ? Brightness.dark : Brightness.light,
            fontFamily: capture ? 'Preview' : null,
            scaffoldBackgroundColor: scenario.$6 ? Colors.black : Colors.white,
          ),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scenario.$4)),
                child: child!,
              ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: scenario.$6 ? Colors.black : Colors.white,
                  child: Column(
                    children: [
                      HomeMacroSection(
                        macros: Macros(protein: 127, carbs: 431, fat: 187),
                        proteinGoal: 140,
                        carbGoal: 260,
                        fatGoal: 70,
                        isPro: scenario.$2,
                        hasMeals: true,
                        onUpgrade: () => upgrades++,
                      ),
                      HomeWellnessSection(
                        waterTotal: 1400,
                        waterGoal: 2500,
                        steps: 6842,
                        stepGoal: 10000,
                        burnedCalories: 312,
                        caloriesEstimated: false,
                        onWaterTap: () => water++,
                        onActivityTap: () => activity++,
                      ),
                      HomeToolsSection(
                        isPro: scenario.$2,
                        onPlannerTap: () => planner++,
                        onCoachTap: () => coach++,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (scenario.$5 == 'en') {
        expect(find.text(scenario.$2 ? '127 / 140g' : '13%'), findsOneWidget);
        if (!scenario.$2) {
          await tester.tap(
            find.text('See grams, daily goals & what to eat next'),
          );
          expect(upgrades, 1);
        }
        for (final title in [
          'Hydration',
          'Activity',
          'Meal Planner',
          'AI Coach',
        ]) {
          await tester.ensureVisible(find.text(title));
          await tester.tap(find.text(title));
        }
        expect([water, activity, planner, coach], [1, 1, 1, 1]);
      }
      await tester.pumpAndSettle();
      if (capture) {
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/home-previews/${scenario.$1}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
  testWidgets('No food hides macros; zero targets remain finite', (
    tester,
  ) async {
    Future<void> render(bool hasMeals) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeMacroSection(
            macros: Macros.empty(),
            proteinGoal: 0,
            carbGoal: 0,
            fatGoal: 0,
            isPro: true,
            hasMeals: hasMeals,
            onUpgrade: () {},
          ),
        ),
      ),
    );
    await render(false);
    expect(find.text('Protein'), findsNothing);
    await render(true);
    expect(find.text('0 / —g'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
