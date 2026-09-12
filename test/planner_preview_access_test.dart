import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/data/models/grocery_item.dart';
import 'package:snapcal/data/models/meal_plan.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/connectivity_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/planner_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/planner/meal_planner_screen.dart';
import 'package:snapcal/screens/planner/meal_planner_widgets.dart';

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _PreviewPlanner extends ChangeNotifier implements PlannerProvider {
  @override
  List<GroceryItem> get groceryList => [];
  @override
  bool get canRegenerate => false;
  @override
  bool get isGenerating => false;
  @override
  bool get isRegenerating => false;
  @override
  String? get fallbackNotice => null;
  @override
  String? get rebalanceNotice => null;
  @override
  String? get error => null;
  @override
  MealPlan? get currentPlan => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final locale in ['en', 'ar', 'es', 'fr']) {
    for (final size in [const Size(320, 568), const Size(640, 360)]) {
      testWidgets('planner sample stays usable $locale $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const MealPlannerScreen()),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(_Settings.new),
              plannerNotifierProvider.overrideWith((ref) => _PreviewPlanner()),
              proAccessProvider.overrideWithValue(
                const ProAccess(ProStatus.free),
              ),
              todaysMealsProvider.overrideWith((ref) => Stream.value([])),
              mealRepositoryProvider.overrideWith(
                (ref) => Completer<MealRepository>().future,
              ),
              connectivityProvider.overrideWith(
                (ref) => Stream.value([ConnectivityResult.wifi]),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder:
                  (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(2),
                      padding: const EdgeInsets.only(bottom: 34),
                    ),
                    child: child!,
                  ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PlannerLockedWeekCard), findsNothing);
        expect(find.byType(PlannerTabs), findsNothing);
        expect(find.byType(FilledButton), findsOneWidget);
        for (
          var i = 0;
          i < 20 && find.byType(PlannerMealRow).evaluate().isEmpty;
          i++
        ) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -150),
          );
          await tester.pump();
        }
        await Scrollable.ensureVisible(
          tester.element(find.byType(PlannerMealRow).first),
          alignment: 0.1,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(PlannerMealRow).first);
        await tester.pumpAndSettle();
        expect(find.byType(PlannerMealDetailScreen), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
