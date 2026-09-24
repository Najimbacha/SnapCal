import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/quick_food.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/log/widgets/quick_add_foods.dart';

Meal _meal(String id, {String name = 'Chicken biryani'}) => Meal(
  id: id,
  timestamp: DateTime(2026, 9, 24, 13).millisecondsSinceEpoch,
  dateString: '2026-09-24',
  foodName: name,
  calories: 585,
  macros: Macros(protein: 24, carbs: 84, fat: 18),
  mealType: 'Lunch',
  portion: '300 g',
);

Widget _host({
  Locale locale = const Locale('en'),
  List<Meal> meals = const [],
  TextScaler textScaler = TextScaler.noScaling,
  ThemeMode themeMode = ThemeMode.light,
  required Future<Meal> Function(QuickFood, double) onAdd,
  required Future<Meal> Function(Meal) onRepeat,
  required Future<void> Function(String) onUndo,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: textScaler),
          child: child!,
        );
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: QuickAddFoods(
            meals: meals,
            mealType: 'Lunch',
            cuisinePreference: 'south asian',
            onAddCatalogFood: onAdd,
            onRepeatMeal: onRepeat,
            onUndo: onUndo,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Quick Add and its browser fit a narrow Arabic phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(
        locale: const Locale('ar'),
        textScaler: const TextScaler.linear(1.3),
        themeMode: ThemeMode.dark,
        onAdd: (food, grams) async => _meal('new', name: food.name),
        onRepeat: (meal) async => _meal('repeat', name: meal.foodName),
        onUndo: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quick-add-foods')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('quick-add-see-all')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quick-food-search-field')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('quick-food-search-field')),
      'biryani',
    );
    await tester.pump();
    expect(find.text('برياني دجاج'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a recent food repeats immediately and can be undone', (
    tester,
  ) async {
    var repeated = 0;
    String? undone;
    final recent = _meal('old');
    await tester.pumpWidget(
      _host(
        meals: [recent],
        onAdd: (food, grams) async => _meal('catalog', name: food.name),
        onRepeat: (meal) async {
          repeated++;
          return _meal('repeated', name: meal.foodName);
        },
        onUndo: (id) async => undone = id,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quick-food-old')));
    await tester.pumpAndSettle();
    expect(repeated, 1);
    expect(find.text('Chicken biryani added'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 'repeated');
  });

  testWidgets('food region can be changed without location permission', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(
        textScaler: const TextScaler.linear(1.3),
        onAdd: (food, grams) async => _meal('catalog', name: food.name),
        onRepeat: (meal) async => _meal('repeat', name: meal.foodName),
        onUndo: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quick-add-see-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-food-region-button')));
    await tester.pumpAndSettle();
    expect(find.text('Food region'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Pakistan'));
    await tester.pumpAndSettle();
    expect(find.text('Food region: Pakistan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog food opens a scroll-safe serving picker', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(
        textScaler: const TextScaler.linear(1.3),
        themeMode: ThemeMode.dark,
        onAdd: (food, grams) async => _meal('catalog', name: food.name),
        onRepeat: (meal) async => _meal('repeat', name: meal.foodName),
        onUndo: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quick-add-see-all')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('quick-food-search-field')),
      'biryani',
    );
    await tester.pump();
    await tester.tap(find.text('Chicken biryani'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-food-add-button')), findsOneWidget);
    expect(find.text('1 serving'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('quick-food-add-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-food-add-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-food-search-field')), findsNothing);
    expect(find.text('Chicken biryani added'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
