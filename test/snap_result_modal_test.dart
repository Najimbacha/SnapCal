import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  testWidgets('single scan renders food with weight and kcal', (tester) async {
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
    expect(find.textContaining('5/10', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('35 g', skipOffstage: false), findsOneWidget);
  });

  testWidgets('multi scan renders all foods with summed totals', (tester) async {
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

    expect(find.text('Rice', skipOffstage: false), findsOneWidget);
    expect(find.text('Nuts', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Tap an item to adjust its portion', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('v2 enriched scan shows confidence badge for high confidence', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        isPro: true,
        result: NutritionResult(
          foodName: 'Chicken Breast',
          portion: '180g',
          calories: 297,
          protein: 56,
          carbs: 0,
          fat: 6,
          weightG: 180,
          confidence: 0.96,
          nutritionMatchId: 'FDB_000241',
          matched: true,
          nutritionPer100g: {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6},
          nutritionActual: {'calories': 297, 'protein': 56, 'carbs': 0, 'fat': 6.5},
        ),
      ),
    );

    expect(find.text('Chicken Breast', skipOffstage: false), findsAtLeastNWidgets(1));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('297', skipOffstage: false), findsAtLeastNWidgets(1));
    // The weight is shown on the collapsed row and again in the expanded
    // portion editor; both stay in the tree for the size transition.
    expect(find.text('180 g', skipOffstage: false), findsAtLeastNWidgets(1));
  });

  testWidgets('unmatched food shows rescue chip instead of junk insight', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        isPro: true,
        result: NutritionResult(
          foodName: 'Unknown Sauce',
          portion: '~10g',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          weightG: 10,
          confidence: 0.45,
          matched: false,
          nutritionPer100g: null,
          nutritionActual: null,
        ),
      ),
    );

    expect(find.text('Unknown Sauce', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('Not in database', skipOffstage: false), findsOneWidget);
    expect(find.text('Not matched \u00b7 tap to fix', skipOffstage: false), findsOneWidget);
    expect(find.text('Nutrition unavailable', skipOffstage: false), findsNothing);
  });

  testWidgets('thousands separator and share context render for multi scan', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        isPro: true,
        results: [
          NutritionResult(
            foodName: 'Rice',
            portion: '600g',
            calories: 600,
            protein: 12,
            carbs: 130,
            fat: 2,
          ),
          NutritionResult(
            foodName: 'Nuts',
            portion: '100g',
            calories: 513,
            protein: 20,
            carbs: 17,
            fat: 44,
          ),
        ],
        onSaveAll: (_) {},
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1,113', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('54%', skipOffstage: false), findsOneWidget);
    expect(find.text('46%', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Add to log'), findsOneWidget);
  });

  testWidgets('Add Item button adds a placeholder row', (tester) async {
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

    await tester.tap(find.textContaining('Add to log'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(savedName, 'Rice');
    expect(savedCalories, greaterThan(0));
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

    await tester.tap(find.textContaining('Add to log'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(saved, isNotNull);
    expect(saved, hasLength(2));
    expect(saved!.first.foodName, 'Rice');
    expect(saved!.last.foodName, 'Nuts');
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

    await tester.tap(find.textContaining('Add to log'));
    await tester.tap(find.textContaining('Add to log'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

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
    expect(find.textContaining('Add to log'), findsOneWidget);

    await tester.tap(find.textContaining('Add to log'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(saved, isTrue);
    expect(find.textContaining('Add to log'), findsNothing);
  });

  testWidgets('free user sees macro grams, never a blurred value', (tester) async {
    await setupTester(tester);
    await tester.pumpWidget(
      buildSubject(
        isPro: false,
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

    // free_macros_enabled defaults to true: macro grams are part of the answer
    // a scan produces, so the free tier is capped by scan count alone.
    expect(find.text('4 g', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('35 g', skipOffstage: false), findsAtLeastNWidgets(1));

    // The upsell now sells the coaching layer, not the macros themselves.
    expect(
      find.text('Unlock deeper insights', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.lock, skipOffstage: false), findsNothing);
  });

  testWidgets('free user sees remaining scan count on the save bar', (
    tester,
  ) async {
    await setupTester(tester);
    await tester.pumpWidget(
      buildSubject(
        isPro: false,
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

    expect(
      find.textContaining('scans left today', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('collapsed row shows a static weight and only expands', (
    tester,
  ) async {
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

    // Steppers live in the expanded state now, so a near-miss on the row can
    // no longer change the weight instead of opening the card. The collapsed
    // header row itself must contain no stepper controls.
    expect(find.text('150 g'), findsAtLeastNWidgets(1));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('card-header')),
        matching: find.byIcon(LucideIcons.plus),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();

    expect(find.text('Portion Size'), findsOneWidget);
    expect(find.byIcon(LucideIcons.plus), findsAtLeastNWidgets(1));
  });

  testWidgets('expanded stepper adjusts the weight', (tester) async {
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

    // The header also shows the food title; the row inside the list is what
    // expands the card.
    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await tester.pump();

    expect(find.text('180 g'), findsAtLeastNWidgets(1));
  });

  testWidgets('delete shows snackbar with undo restoring item', (tester) async {
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

    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();
    expect(find.text('Portion Size'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('card-delete')));
    await tester.pump();

    expect(find.textContaining('Removed'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Restored: the row is back alongside the header title.
    expect(find.text('Rice'), findsAtLeastNWidgets(2));
  });

  testWidgets('back prompts discard confirmation when content exists', (tester) async {
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

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pump();

    expect(find.text('Discard scan?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pump();

    expect(find.text('Discard scan?'), findsNothing);
    expect(find.textContaining('Add to log'), findsOneWidget);
  });
}
