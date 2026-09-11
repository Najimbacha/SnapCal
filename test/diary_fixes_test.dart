import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/current_day_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/log/widgets/edit_meal_modal.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

void main() {
  group('a new day', () {
    late DateTime now;
    late ProviderContainer container;

    setUp(() {
      now = DateTime(2026, 9, 11, 23, 59);
      CurrentDayNotifier.clock = () => now;
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      CurrentDayNotifier.clock = DateTime.now;
    });

    test('moves the app on, and a diary left on today with it', () {
      expect(container.read(currentDayProvider), '2026-09-11');
      expect(container.read(selectedDateProvider), '2026-09-11');

      now = DateTime(2026, 9, 12, 0, 1);
      container.read(currentDayProvider.notifier).refresh();

      expect(container.read(currentDayProvider), '2026-09-12');
      expect(container.read(selectedDateProvider), '2026-09-12');
    });

    test('leaves a diary the user took back to an earlier day', () {
      container.read(selectedDateProvider.notifier).select('2026-09-05');

      now = DateTime(2026, 9, 12, 0, 1);
      container.read(currentDayProvider.notifier).refresh();

      expect(container.read(selectedDateProvider), '2026-09-05');
    });
  });

  group('the meal form', () {
    late AppLocalizations l10n;
    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    Future<void> pumpForm(
      WidgetTester tester, {
      required Meal meal,
      bool isNew = false,
      required void Function(Meal) onSave,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EditMealModal(
              meal: meal,
              isNew: isNew,
              onSave: onSave,
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    // Name, portion, calories, protein, carbs, fat.
    Finder field(int index) => find.byType(TextField).at(index);
    bool canSave(WidgetTester tester) =>
        tester
            .widget<ElevatedButton>(
              find.byWidgetPredicate((w) => w is ElevatedButton),
            )
            .onPressed !=
        null;

    Meal meal({
      int calories = 300,
      Map<String, dynamic>? per100g,
      String? matchId,
      double? weightG,
    }) => Meal(
      id: 'm1',
      timestamp: 0,
      dateString: '2026-09-12',
      foodName: 'Rice',
      calories: calories,
      macros: Macros(protein: 6, carbs: 66, fat: 1),
      nutritionPer100g: per100g,
      nutritionMatchId: matchId,
      weightG: weightG,
      originalCalories: calories,
    );

    testWidgets('logs a zero-calorie drink', (tester) async {
      Meal? saved;
      await pumpForm(
        tester,
        meal: Meal(
          id: 'new',
          timestamp: 0,
          dateString: '2026-09-12',
          foodName: '',
          calories: 0,
          macros: Macros.empty(),
          portion: '',
        ),
        isNew: true,
        onSave: (m) => saved = m,
      );
      expect(canSave(tester), isFalse);

      await tester.enterText(field(0), 'Black coffee');
      await tester.enterText(field(2), '0');
      await tester.pump();
      expect(canSave(tester), isTrue);

      await tester.tap(find.text(l10n.log_save_entry));
      await tester.pump();
      expect(saved?.foodName, 'Black coffee');
      expect(saved?.calories, 0);
    });

    testWidgets('will not save an edit with the calories cleared', (
      tester,
    ) async {
      await pumpForm(tester, meal: meal(), onSave: (_) {});
      expect(canSave(tester), isTrue);

      await tester.enterText(field(2), '');
      await tester.pump();
      expect(canSave(tester), isFalse);
    });

    testWidgets('a corrected scan stops carrying the scan\'s numbers', (
      tester,
    ) async {
      Meal? saved;
      await pumpForm(
        tester,
        meal: meal(
          per100g: const {
            'calories': 150,
            'protein': 3,
            'carbs': 33,
            'fat': 0.5,
          },
          matchId: 'usda:rice',
          weightG: 200,
        ),
        onSave: (m) => saved = m,
      );

      await tester.enterText(field(2), '250');
      await tester.pump();
      await tester.tap(find.text(l10n.log_save_entry));
      await tester.pump();

      expect(saved?.calories, 250);
      expect(saved?.userCorrected, isTrue);
      expect(saved?.nutritionPer100g, isNull);
      expect(saved?.nutritionMatchId, isNull);
      expect(saved?.weightG, 200);
      expect(saved?.originalCalories, 300);
    });

    testWidgets('renaming alone keeps the scan\'s numbers', (tester) async {
      Meal? saved;
      await pumpForm(
        tester,
        meal: meal(per100g: const {'calories': 150}, matchId: 'usda:rice'),
        onSave: (m) => saved = m,
      );

      await tester.enterText(field(0), 'Basmati rice');
      await tester.pump();
      await tester.tap(find.text(l10n.log_save_entry));
      await tester.pump();

      expect(saved?.foodName, 'Basmati rice');
      expect(saved?.userCorrected, isFalse);
      expect(saved?.nutritionPer100g, isNotNull);
      expect(saved?.nutritionMatchId, 'usda:rice');
    });
  });

  testWidgets('a scanned glass of water can be saved at zero calories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<NutritionResult>? saved;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [effectiveIsProProvider.overrideWith((ref) => true)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ResultModal(
              result: NutritionResult(
                foodName: 'Water',
                portion: '250g',
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                weightG: 250,
                nutritionPer100g: const {
                  'calories': 0,
                  'protein': 0,
                  'carbs': 0,
                  'fat': 0,
                },
              ),
              onSave: (_, _, _, _, _, _) {},
              onSaveAll: (items) => saved = items,
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('result-save-button')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved!.single.foodName, 'Water');
    expect(saved!.single.calories, 0);
  });
}
