import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/home/widgets/home_nutrition_dashboard.dart';
import 'package:snapcal/screens/planner/meal_planner_widgets.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(640, 360),
  ]) {
    for (final locale in ['en', 'ar', 'es', 'fr']) {
      for (final scale in [1.0, 1.5, 2.0]) {
        for (final dark in [false, true]) {
          testWidgets('feature access $size $locale $scale dark=$dark', (
            tester,
          ) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var coach = 0, planner = 0, upgrade = 0;
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                builder:
                    (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                        padding: const EdgeInsets.only(bottom: 34),
                      ),
                      child: child!,
                    ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        HomeMacroSection(
                          hasMeals: true,
                          isPro: false,
                          macros: Macros(protein: 40, carbs: 60, fat: 20),
                          proteinGoal: 100,
                          carbGoal: 200,
                          fatGoal: 60,
                          onUpgrade: () => upgrade++,
                        ),
                        HomeToolsSection(
                          isPro: false,
                          onCoachTap: () => coach++,
                          onPlannerTap: () => planner++,
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: PlannerBottomActions(
                    isPro: false,
                    onAdjust: () {},
                    onGrocery: () => upgrade++,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final context = tester.element(find.byType(HomeToolsSection));
            final l = AppLocalizations.of(context)!;
            for (final title in [l.assistant_title, l.planner_title]) {
              // Find the feature by its localized text, then verify it remains reachable.
              final target = find.text(title);
              expect(target, findsOneWidget);
              await tester.ensureVisible(target);
              await tester.tap(target);
            }
            await tester.tap(find.byType(FilledButton));
            expect(upgrade, 1); // Only the deliberate weekly-plan CTA sells.
            expect(planner, 1);
            expect(tester.takeException(), isNull);
            expect(coach, 1);
          });
        }
      }
    }
  }
}
