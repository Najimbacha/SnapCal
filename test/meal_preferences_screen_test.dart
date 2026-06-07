import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/widgets/app_icon.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/core/state/async_ui_state.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/planner_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/planner/meal_preferences_screen.dart';

void main() {
  test(
    'legacy halal and gluten-free diet values migrate into requirements',
    () {
      final halalSettings = UserSettings.defaults().copyWith(
        dietaryRestriction: 'halal',
      );

      expect(SettingsProvider.normalizePlannerDietStyle('halal'), 'none');
      expect(
        SettingsProvider.migrateDietaryRequirements(halalSettings),
        contains('halal'),
      );

      final glutenSettings = UserSettings.defaults().copyWith(
        dietaryRestriction: 'gluten-free',
      );

      expect(SettingsProvider.normalizePlannerDietStyle('gluten_free'), 'none');
      expect(
        SettingsProvider.migrateDietaryRequirements(glutenSettings),
        contains('gluten_free'),
      );
    },
  );

  testWidgets('meal preferences render compact setup without old sections', (
    tester,
  ) async {
    final settings = FakeSettingsProvider();
    final planner = FakePlannerProvider();

    await tester.pumpWidget(_app(settings: settings, planner: planner));

    expect(find.text('Create your meal plan'), findsOneWidget);
    expect(find.text('Based on your goal'), findsOneWidget);
    expect(find.textContaining('2,000 kcal/day'), findsOneWidget);
    expect(find.text('Meals per day'), findsOneWidget);
    expect(find.text('Diet style'), findsOneWidget);
    expect(find.text('Requirements'), findsOneWidget);
    expect(find.text('More preferences'), findsOneWidget);
    expect(find.text('Create my plan'), findsOneWidget);

    expect(find.text('PLAN STYLE'), findsNothing);
    expect(find.text('Plan Style'), findsNothing);
    expect(find.text('Cuisine style'), findsNothing);
    expect(find.textContaining('AI-generated'), findsNothing);
    expect(find.textContaining('Lose weight'), findsOneWidget); // summary only
  });

  testWidgets('stepper clamps and requirements can be multi-selected', (
    tester,
  ) async {
    final settings = FakeSettingsProvider();
    final planner = FakePlannerProvider();

    await tester.pumpWidget(_app(settings: settings, planner: planner));

    await tester.tap(find.byIcon(AppSymbols.minus).hitTestable());
    await tester.pump();
    expect(find.text('2 meals'), findsOneWidget);

    await tester.ensureVisible(find.text('Halal'));
    await tester.pump();
    await tester.tap(find.text('Halal'));
    await tester.tap(find.text('Gluten-free'));
    await tester.ensureVisible(find.text('Create my plan'));
    await tester.pump();
    await tester.tap(find.text('Create my plan'));
    await tester.pump();

    expect(settings.savedRequirements, containsAll(['halal', 'gluten_free']));
    expect(settings.savedDietStyle, 'none');
  });

  testWidgets('bottom sheet discards unsaved edits and stages saved edits', (
    tester,
  ) async {
    final settings = FakeSettingsProvider();
    final planner = FakePlannerProvider();

    await tester.pumpWidget(_app(settings: settings, planner: planner));

    await tester.ensureVisible(find.text('More preferences'));
    await tester.pump();
    await tester.tap(find.text('More preferences'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'peanuts');
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('More preferences'));
    await tester.pump();
    await tester.tap(find.text('More preferences'));
    await tester.pumpAndSettle();
    expect(find.text('peanuts'), findsNothing);
    await tester.enterText(find.byType(TextField), 'mushrooms');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(settings.savedExcludedFoodsNotes, isNull);
    await tester.ensureVisible(find.text('Create my plan'));
    await tester.pump();
    await tester.tap(find.text('Create my plan'));
    await tester.pump();

    expect(settings.savedExcludedFoodsNotes, 'mushrooms');
  });

  testWidgets('CTA prevents duplicate starts and preserves draft on failure', (
    tester,
  ) async {
    final settings = FakeSettingsProvider();
    final planner = FakePlannerProvider();
    var starts = 0;

    await tester.pumpWidget(
      _app(
        settings: settings,
        planner: planner,
        onGenerate: () async {
          starts += 1;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return false;
        },
      ),
    );

    await tester.ensureVisible(find.text('Halal'));
    await tester.pump();
    await tester.tap(find.text('Halal'));
    await tester.ensureVisible(find.text('Create my plan'));
    await tester.pump();
    await tester.tap(find.text('Create my plan'));
    await tester.tap(find.text('Create my plan'), warnIfMissed: false);
    await tester.pump();
    expect(starts, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 30));
    expect(
      find.text('Could not start your plan. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Halal'), findsOneWidget);
    expect(settings.savedRequirements, contains('halal'));
  });
}

Widget _app({
  required FakeSettingsProvider settings,
  required FakePlannerProvider planner,
  Future<bool> Function()? onGenerate,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<PlannerProvider>.value(value: planner),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MealPreferencesScreen(onGenerate: onGenerate ?? () async => true),
    ),
  );
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  int savedMealsPerDay = 3;
  String? savedDietStyle;
  Set<String> savedRequirements = {};
  String? savedCuisine;
  String? savedExcludedFoodsNotes;

  @override
  int get mealsPerDay => 3;

  @override
  String get plannerDietStyle => 'none';

  @override
  Set<String> get dietaryRequirements => const {};

  @override
  String get cuisinePreference => 'international';

  @override
  String? get excludedFoodsNotes => null;

  @override
  String get goalMode => 'cut';

  @override
  int get dailyCalorieGoal => 2000;

  @override
  int get dailyProteinGoal => 140;

  @override
  int get dailyCarbGoal => 180;

  @override
  int get dailyFatGoal => 55;

  @override
  UserSettings get settings => UserSettings.defaults().copyWith(
    dailyCalorieGoal: dailyCalorieGoal,
    dailyProteinGoal: dailyProteinGoal,
    dailyCarbGoal: dailyCarbGoal,
    dailyFatGoal: dailyFatGoal,
    goalMode: goalMode,
  );

  @override
  Future<void> updatePlannerPreferences({
    int? mealsPerDay,
    String? dietaryRestriction,
    Set<String>? dietaryRequirements,
    String? cuisinePreference,
    String? excludedFoodsNotes,
  }) async {
    savedMealsPerDay = mealsPerDay ?? savedMealsPerDay;
    savedDietStyle = dietaryRestriction;
    savedRequirements = {...?dietaryRequirements};
    savedCuisine = cuisinePreference;
    savedExcludedFoodsNotes =
        excludedFoodsNotes == null || excludedFoodsNotes.trim().isEmpty
            ? null
            : excludedFoodsNotes.trim();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlannerProvider extends ChangeNotifier implements PlannerProvider {
  String savedPrep = 'balanced';
  String savedBudget = 'standard';

  @override
  String get prepTimePreference => savedPrep;

  @override
  String get budgetPreference => savedBudget;

  @override
  bool get isGenerating => false;

  @override
  AsyncUiState get uiState => const AsyncUiState.empty();

  @override
  void setPlanningPreferences({
    required String prepTimePreference,
    required String budgetPreference,
  }) {
    savedPrep = prepTimePreference;
    savedBudget = budgetPreference;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
