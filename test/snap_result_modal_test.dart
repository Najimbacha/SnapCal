import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

void main() {
  Future<void> setupTester(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildSubject({
    NutritionResult? result,
    List<NutritionResult>? results,
    void Function(String, int, int, int, int, String?)? onSave,
    void Function(List<NutritionResult>)? onSaveAll,
    bool isPro = false,
  }) {
    return ProviderScope(
      overrides: [
        effectiveIsProProvider.overrideWith((ref) => isPro),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ResultModal(
            result: result,
            results: results,
            onSave: onSave ?? (_, _, _, _, _, _) {},
            onSaveAll: onSaveAll,
            onCancel: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('single scan renders one food row with totals', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        isPro: true,
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

    expect(find.text('Rice', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('160', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('35g', skipOffstage: false), findsOneWidget);
    expect(find.text('4g', skipOffstage: false), findsOneWidget);
    expect(find.text('1g', skipOffstage: false), findsOneWidget);
    expect(find.text('100g ✓', skipOffstage: false), findsOneWidget);
  });

  testWidgets('multi scan renders all foods and summed totals', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        isPro: true,
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

    expect(find.text('Meal Review', skipOffstage: false), findsOneWidget);
    expect(find.text('Rice', skipOffstage: false), findsOneWidget);
    expect(find.text('Nuts', skipOffstage: false), findsOneWidget);
    expect(find.text('340', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('40g', skipOffstage: false), findsOneWidget);
    expect(find.text('10g', skipOffstage: false), findsOneWidget);
    expect(find.text('16g', skipOffstage: false), findsOneWidget);
  });

  testWidgets('editing a row updates summary macros', (tester) async {
    await setupTester(tester);
    await tester.pumpWidget(
      buildSubject(
        isPro: true,
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

    await tester.tap(find.text('Rice'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('150g'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('208'), findsAtLeastNWidgets(1));
    expect(find.text('46g'), findsOneWidget);
    expect(find.text('150g ✓'), findsOneWidget);
  });

  testWidgets('Add Item appends a placeholder row', (tester) async {
    await setupTester(tester);
    await tester.pumpWidget(
      buildSubject(
        isPro: true,
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

    final btnFinder = find.text('Add Item');
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Food item'), findsOneWidget);
    expect(find.text('160'), findsAtLeastNWidgets(1));
  });

  testWidgets('save button calls multi save callback for multiple rows', (
    tester,
  ) async {
    List<NutritionResult>? saved;
    await setupTester(tester);
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

    await tester.tap(find.textContaining('Add To Log'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved, hasLength(2));
    expect(saved!.first.foodName, 'Rice');
    expect(saved!.last.foodName, 'Nuts');
  });

  testWidgets('save button calls single save callback', (tester) async {
    String? savedName;
    int? savedCalories;

    await setupTester(tester);
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

    await tester.tap(find.textContaining('Add To Log'));
    await tester.pump();

    expect(savedName, 'Rice');
    expect(savedCalories, 160);
  });

  testWidgets('rapid double tap only saves once', (tester) async {
    var saveCount = 0;

    await setupTester(tester);
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

    await tester.tap(find.textContaining('Add To Log'));
    await tester.tap(find.textContaining('Add To Log'), warnIfMissed: false);
    await tester.pump();

    expect(saveCount, 1);
  });

  testWidgets('save button closes modal route', (tester) async {
    var saved = false;

    await setupTester(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectiveIsProProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      ),
    );

    await tester.tap(find.text('Open result'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Add To Log'), findsOneWidget);

    await tester.tap(find.textContaining('Add To Log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(saved, isTrue);
    expect(find.textContaining('Add To Log'), findsNothing);
  });
}
