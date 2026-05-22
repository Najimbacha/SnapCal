import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

void main() {
  Future<void> setupTester(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider<SettingsProvider>.value(
          value: FakeSettingsProvider(isPro: isPro),
          child: ResultModal(
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

    expect(find.text('RICE', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('160', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('35g', skipOffstage: false), findsOneWidget);
    expect(find.text('4g', skipOffstage: false), findsOneWidget);
    expect(find.text('1g', skipOffstage: false), findsOneWidget);
    expect(find.text('150.0g', skipOffstage: false), findsOneWidget);
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

    expect(find.text('FEAST', skipOffstage: false), findsOneWidget);
    expect(find.text('RICE', skipOffstage: false), findsOneWidget);
    expect(find.text('NUTS', skipOffstage: false), findsOneWidget);
    expect(find.text('340', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text('40g', skipOffstage: false), findsOneWidget);
    expect(find.text('10g', skipOffstage: false), findsOneWidget);
    expect(find.text('16g', skipOffstage: false), findsOneWidget);
  });

  testWidgets('editing a row updates summary macros', (tester) async {
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
      ),
    );

    final rowFinder = find.text('RICE').last;
    await tester.tap(rowFinder);
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).at(2), '300');
    await tester.enterText(find.byType(TextField).at(3), '55');

    // Close keyboard/unfocus to restore view bounds before tapping Done
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('300'), findsAtLeastNWidgets(1));
    expect(find.text('55g'), findsOneWidget);
    expect(find.text('150.0g'), findsAtLeastNWidgets(1));
  });

  testWidgets('More food appends manual item and updates totals', (
    tester,
  ) async {
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
        onSaveAll: (_) {},
      ),
    );

    final btnFinder = find.text('ADD NEW ITEM');
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).at(0), 'Dates');
    await tester.enterText(find.byType(TextField).at(1), '50.0g');
    await tester.enterText(find.byType(TextField).at(2), '140');
    await tester.enterText(find.byType(TextField).at(3), '30');

    // Close keyboard/unfocus to restore view bounds before tapping Done
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('DATES'), findsOneWidget);
    expect(find.text('300'), findsAtLeastNWidgets(1));
    expect(find.text('65g'), findsOneWidget);
    expect(find.text('50.0g'), findsAtLeastNWidgets(1));
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
                          (context) =>
                              ChangeNotifierProvider<SettingsProvider>.value(
                                value: FakeSettingsProvider(),
                                child: ResultModal(
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

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  final bool _isPro;
  FakeSettingsProvider({bool isPro = false}) : _isPro = isPro;

  @override
  bool get isPro => _isPro;

  @override
  String get languageCode => 'en';

  @override
  UserSettings get settings => UserSettings.defaults();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
