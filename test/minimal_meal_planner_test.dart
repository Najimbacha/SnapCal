import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/planner/widgets/meal_card.dart';

void main() {
  testWidgets('minimal meal row shows essentials and expands details', (
    tester,
  ) async {
    final meal = _meal(
      id: 'breakfast',
      name: 'Greek yogurt bowl',
      type: 'Breakfast',
      ingredients: ['Greek yogurt', 'Blueberries'],
      rationale: 'High protein start.',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MealCard(meal: meal, onLogMeal: () {})),
      ),
    );

    expect(find.text('Greek yogurt bowl'), findsOneWidget);
    expect(find.text('420 kcal'), findsOneWidget);
    expect(find.text('PRO'), findsNothing);
    expect(find.text('32g'), findsNothing);

    await tester.tap(find.text('Greek yogurt bowl'));
    await tester.pumpAndSettle();

    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('32g'), findsOneWidget);
    expect(find.text('Greek yogurt, Blueberries'), findsOneWidget);
  });
}

Meal _meal({
  required String id,
  required String name,
  required String type,
  List<String>? ingredients,
  String? rationale,
}) {
  return Meal(
    id: id,
    timestamp: DateTime(2026, 5, 25, 8).millisecondsSinceEpoch,
    dateString: '2026-05-25',
    foodName: name,
    calories: 420,
    macros: Macros(protein: 32, carbs: 44, fat: 12),
    mealType: type,
    prepTimeMins: 10,
    ingredients: ingredients,
    aiRationale: rationale,
  );
}
