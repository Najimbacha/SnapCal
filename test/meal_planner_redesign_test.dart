import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/grocery_item.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/planner/meal_planner_setup.dart';
import 'package:snapcal/screens/planner/meal_planner_widgets.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Meal _meal() {
  return Meal(
    id: 'lunch',
    timestamp: DateTime(2026, 9, 8, 13).millisecondsSinceEpoch,
    dateString: '2026-09-08',
    foodName: 'Grilled chicken rice bowl',
    calories: 610,
    macros: Macros(protein: 46, carbs: 64, fat: 18),
    mealType: 'Lunch',
    prepTimeMins: 25,
    portion: '1 serving',
    ingredients: const ['Chicken breast', 'Rice', 'Tomatoes', 'Avocado'],
  );
}

void main() {
  testWidgets('planner setup follows the approved two-step flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    PlannerSetupResult? result;
    await tester.pumpWidget(
      _host(
        MealPlannerSetup(
          settings: UserSettings.defaults(),
          initialPrepTime: 'balanced',
          initialBudget: 'standard',
          editingExistingPlan: false,
          onClose: () {},
          onGenerate: (value) async => result = value,
        ),
      ),
    );

    expect(find.text('Build your week'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Daily goal'), findsOneWidget);
    expect(find.text('Cooking time'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('planner-setup-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Choose cuisines'), findsOneWidget);
    expect(find.text('Shopping style'), findsOneWidget);
    expect(find.text('Use pantry staples'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('planner-generate-plan')));
    await tester.pump();
    expect(result, isNotNull);
    expect(result!.mealsPerDay, 3);
  });

  testWidgets('planner setup remains usable on a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(
        MealPlannerSetup(
          settings: UserSettings.defaults(),
          initialPrepTime: 'balanced',
          initialBudget: 'standard',
          editingExistingPlan: false,
          onClose: () {},
          onGenerate: (_) async {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('planner-setup-continue')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('meal detail shows nutrition ingredients and actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Meal? logged;
    await tester.pumpWidget(
      _host(
        PlannerMealDetailScreen(
          meal: _meal(),
          isPro: true,
          onLog: (meal) async => logged = meal,
          onSwap: () {},
        ),
      ),
    );

    expect(find.text('Grilled chicken rice bowl'), findsOneWidget);
    expect(find.text('610'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('Log meal'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('Preparation'), findsOneWidget);

    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(logged?.calories, 610);
  });

  testWidgets('grocery view groups items and filters checked rows', (
    tester,
  ) async {
    final items = [
      GroceryItem(name: 'Tomatoes', amount: '6', category: 'Produce'),
      GroceryItem(
        name: 'Chicken breast',
        amount: '1 kg',
        category: 'Protein',
        isChecked: true,
      ),
    ];
    var filter = 0;
    await tester.pumpWidget(
      _host(
        Scaffold(
          body: GroceryPlannerView(
            items: items,
            groupedItems: {
              'Produce': [items[0]],
              'Protein': [items[1]],
            },
            selectedFilter: filter,
            shoppingMode: false,
            onFilterChanged: (value) => filter = value,
            onToggle: (_) async {},
            onClearChecked: () async {},
            onShoppingMode: () {},
            onShare: () {},
          ),
        ),
      ),
    );

    expect(find.text('Grocery List'), findsOneWidget);
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Needed'));
    await tester.pump();
    expect(filter, 1);
  });

  testWidgets('meal row stays compact on a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              PlannerMealRow(
                meal: _meal(),
                isNext: true,
                isLogged: false,
                interactive: true,
                onOpen: () {},
                onLog: () {},
                onSwap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(PlannerMealRow));
    expect(size.height, lessThanOrEqualTo(104));
    expect(tester.takeException(), isNull);
  });
}
