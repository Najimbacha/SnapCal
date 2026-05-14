import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildSubject({
    NutritionResult? result,
    List<NutritionResult>? results,
    void Function(String, int, int, int, int, String?)? onSave,
    void Function(List<NutritionResult>)? onSaveAll,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ResultModal(
          result: result,
          results: results,
          onSave: onSave ?? (_, _, _, _, _, _) {},
          onSaveAll: onSaveAll,
          onCancel: () {},
        ),
      ),
    );
  }

  testWidgets('single scan renders one food row with totals', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        result: NutritionResult(
          foodName: 'Rice',
          portion: '150.0g',
          calories: 160,
          protein: 4,
          carbs: 35,
          fat: 1,
        ),
      ),
    );

    expect(find.text('Rice'), findsAtLeastNWidgets(1));
    expect(find.text('160kcal'), findsOneWidget);
    expect(find.text('35g'), findsOneWidget);
    expect(find.text('4g'), findsOneWidget);
    expect(find.text('1g'), findsOneWidget);
    expect(find.text('160kcal / 150.0g'), findsOneWidget);
  });

  testWidgets('multi scan renders all foods and summed totals', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        results: [
          NutritionResult(
            foodName: 'Rice',
            portion: '150.0g',
            calories: 160,
            protein: 4,
            carbs: 35,
            fat: 1,
          ),
          NutritionResult(
            foodName: 'Nuts',
            portion: '30.0g',
            calories: 180,
            protein: 6,
            carbs: 5,
            fat: 15,
          ),
        ],
        onSaveAll: (_) {},
      ),
    );

    expect(find.text('Feast'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Nuts'), findsOneWidget);
    expect(find.text('340kcal'), findsOneWidget);
    expect(find.text('40g'), findsOneWidget);
    expect(find.text('10g'), findsOneWidget);
    expect(find.text('16g'), findsOneWidget);
  });

  testWidgets('editing a row updates summary macros', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        result: NutritionResult(
          foodName: 'Rice',
          portion: '150.0g',
          calories: 160,
          protein: 4,
          carbs: 35,
          fat: 1,
        ),
      ),
    );

    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '300');
    await tester.enterText(find.widgetWithText(TextField, 'Carbs'), '55');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('300kcal'), findsOneWidget);
    expect(find.text('55g'), findsOneWidget);
    expect(find.text('300kcal / 150.0g'), findsOneWidget);
  });

  testWidgets('More food appends manual item and updates totals', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        result: NutritionResult(
          foodName: 'Rice',
          portion: '150.0g',
          calories: 160,
          protein: 4,
          carbs: 35,
          fat: 1,
        ),
        onSaveAll: (_) {},
      ),
    );

    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Food'), 'Dates');
    await tester.enterText(find.widgetWithText(TextField, 'Portion'), '50.0g');
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '140');
    await tester.enterText(find.widgetWithText(TextField, 'Carbs'), '30');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Dates'), findsOneWidget);
    expect(find.text('300kcal'), findsOneWidget);
    expect(find.text('65g'), findsOneWidget);
    expect(find.text('140kcal / 50.0g'), findsOneWidget);
  });

  testWidgets('save button calls multi save callback for multiple rows', (
    tester,
  ) async {
    List<NutritionResult>? saved;
    await tester.pumpWidget(
      buildSubject(
        results: [
          NutritionResult(
            foodName: 'Rice',
            portion: '150.0g',
            calories: 160,
            protein: 4,
            carbs: 35,
            fat: 1,
          ),
          NutritionResult(
            foodName: 'Nuts',
            portion: '30.0g',
            calories: 180,
            protein: 6,
            carbs: 5,
            fat: 15,
          ),
        ],
        onSaveAll: (items) => saved = items,
      ),
    );

    await tester.tap(find.text('Log this meal'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved, hasLength(2));
    expect(saved!.first.foodName, 'Rice');
    expect(saved!.last.foodName, 'Nuts');
  });

  testWidgets('save button calls single save callback', (tester) async {
    String? savedName;
    int? savedCalories;

    await tester.pumpWidget(
      buildSubject(
        result: NutritionResult(
          foodName: 'Rice',
          portion: '150.0g',
          calories: 160,
          protein: 4,
          carbs: 35,
          fat: 1,
        ),
        onSave: (name, calories, protein, carbs, fat, portion) {
          savedName = name;
          savedCalories = calories;
        },
      ),
    );

    await tester.tap(find.text('Log this meal'));
    await tester.pump();

    expect(savedName, 'Rice');
    expect(savedCalories, 160);
  });

  testWidgets('rapid double tap only saves once', (tester) async {
    var saveCount = 0;

    await tester.pumpWidget(
      buildSubject(
        result: NutritionResult(
          foodName: 'Rice',
          portion: '150.0g',
          calories: 160,
          protein: 4,
          carbs: 35,
          fat: 1,
        ),
        onSave: (_, _, _, _, _, _) => saveCount++,
      ),
    );

    await tester.tap(find.text('Log this meal'));
    await tester.tap(find.text('Log this meal'), warnIfMissed: false);
    await tester.pump();

    expect(saveCount, 1);
  });

  testWidgets('save button closes modal route', (tester) async {
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => ResultModal(
                            result: NutritionResult(
                              foodName: 'Rice',
                              portion: '150.0g',
                              calories: 160,
                              protein: 4,
                              carbs: 35,
                              fat: 1,
                            ),
                            onSave: (_, _, _, _, _, _) => saved = true,
                            onCancel: () {},
                          ),
                    );
                  },
                  child: const Text('Open result'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open result'));
    await tester.pumpAndSettle();
    expect(find.text('Log this meal'), findsOneWidget);

    await tester.tap(find.text('Log this meal'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(find.text('Log this meal'), findsNothing);
  });
}
