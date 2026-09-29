import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/core/utils/date_utils.dart' as app_date;
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/meal_template.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/connectivity_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/template_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/log/log_screen.dart';

/// The Food Log's day total, as the user reads it, through deleting, undoing
/// and editing a meal.

String get _today => app_date.DateUtils.getTodayString();

Meal _meal(String id, String name, int calories, int hour, String type) {
  final now = DateTime.now();
  return Meal(
    id: id,
    timestamp:
        DateTime(now.year, now.month, now.day, hour).millisecondsSinceEpoch,
    dateString: _today,
    foodName: name,
    calories: calories,
    macros: Macros(protein: 20, carbs: 30, fat: 10),
    mealType: type,
    portion: '1 plate',
  );
}

/// The day's meals, kept in memory and announced on every change as the
/// real repository does.
class _Diary implements MealRepository {
  _Diary(List<Meal> meals) : _meals = {for (final m in meals) m.id: m};

  final Map<String, Meal> _meals;
  final changes = StreamController<List<Meal>>.broadcast();

  List<Meal> get _day =>
      _meals.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  void _announce() => changes.add(_day);

  @override
  List<Meal> getMealsByDate(String dateString) =>
      dateString == _today ? _day : const [];
  @override
  List<Meal> getAllMeals() => _day;
  @override
  Meal? getMeal(String id) => _meals[id];
  @override
  List<Meal> getTodaysMeals() => _day;

  void remove(String id) {
    _meals.remove(id);
    _announce();
  }

  void put(Meal meal) {
    _meals[meal.id] = meal;
    _announce();
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _MealLog extends MealLog {
  _MealLog(this.diary);

  final _Diary diary;
  final deleted = <String>[];
  final updated = <Meal>[];
  final added = <Meal>[];

  @override
  FutureOr<void> build() {}

  @override
  Future<void> addMeal(
    Meal meal, {
    bool rebalancePlanner = true,
    String? mealDate,
  }) async {
    added.add(meal);
    diary.put(meal);
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    deleted.add(mealId);
    diary.remove(mealId);
  }

  @override
  Future<void> updateMeal(Meal meal) async {
    updated.add(meal);
    diary.put(meal);
  }
}

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async =>
      UserSettings.defaults().copyWith(dailyCalorieGoal: 2000);
}

class _Activity extends Activity {
  @override
  Future<ActivitySummary> build() async => const ActivitySummary(steps: 0);
}

class _Water extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 0, goal: 2500);
}

class _Templates extends Templates {
  @override
  Future<List<MealTemplate>> build() async => const [];
}

Widget _host(_Diary diary, _MealLog log, {Locale locale = const Locale('en')}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LogScreen()),
      GoRoute(path: '/snap', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/reports', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/settings', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/log/metric/:type', builder: (_, _) => const SizedBox()),
    ],
  );
  return ProviderScope(
    overrides: [
      mealRepositoryProvider.overrideWith((ref) async => diary),
      todaysMealsProvider.overrideWith((ref) async* {
        yield diary.getTodaysMeals();
        yield* diary.changes.stream;
      }),
      mealLogProvider.overrideWith(() => log),
      settingsProvider.overrideWith(_Settings.new),
      effectiveIsProProvider.overrideWithValue(false),
      proAccessProvider.overrideWithValue(const ProAccess(ProStatus.free)),
      activityProvider.overrideWith(_Activity.new),
      stepGoalProvider.overrideWith((ref) async => 10000),
      waterProvider.overrideWith(_Water.new),
      templatesProvider.overrideWith(_Templates.new),
      waterRepositoryProvider.overrideWith(
        (ref) => Completer<WaterRepository>().future,
      ),
      connectivityProvider.overrideWith(
        (ref) => Stream.value([ConnectivityResult.wifi]),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

/// Lets the count-up animations and the toast run their course.
Future<void> _settle(WidgetTester tester, {int ms = 1200}) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late _Diary diary;
  late _MealLog log;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    diary = _Diary([
      _meal('b', 'Paratha and eggs', 1200, 8, 'Breakfast'),
      _meal('s', 'Mango lassi', 300, 16, 'Snack'),
    ]);
    log = _MealLog(diary);
  });
  tearDown(() => diary.changes.close());

  Finder total(String text) => find.descendant(
    of: find.byKey(const ValueKey('log-day-total')),
    matching: find.text(text),
  );

  Finder inDiary(String text) => find.descendant(
    of: find.byKey(const ValueKey('log-meal-diary')),
    matching: find.text(text),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(diary, log));
    await _settle(tester);
  }

  Future<void> swipeAway(WidgetTester tester, String id) async {
    await tester.drag(find.byKey(ValueKey(id)), const Offset(-600, 0));
    // Long enough for the row to go and the total to count, well inside
    // the four seconds the Undo message stays.
    await _settle(tester, ms: 1500);
  }

  testWidgets('1,500 eaten of a 2,000 goal reads 500 left', (tester) async {
    await open(tester);
    expect(total('1,500'), findsOneWidget);
    expect(total('500 left'), findsOneWidget);
  });

  testWidgets('a swiped meal leaves the list and the day total at once, '
      'and is deleted when the Undo message goes', (tester) async {
    await open(tester);
    await swipeAway(tester, 's');

    expect(inDiary('Mango lassi'), findsNothing);
    expect(log.deleted, isEmpty);
    expect(total('1,200'), findsOneWidget);
    expect(total('800 left'), findsOneWidget);

    await _settle(tester, ms: 6000);
    expect(log.deleted, ['s']);
    expect(total('1,200'), findsOneWidget);
    expect(total('800 left'), findsOneWidget);
  });

  testWidgets('Undo brings the meal and its calories back, deleting nothing', (
    tester,
  ) async {
    await open(tester);
    await swipeAway(tester, 's');
    await tester.tap(find.text('Undo'));
    await _settle(tester);

    expect(inDiary('Mango lassi'), findsOneWidget);
    expect(total('1,500'), findsOneWidget);
    expect(total('500 left'), findsOneWidget);
    await _settle(tester, ms: 6000);
    expect(log.deleted, isEmpty);
  });

  testWidgets('going over the goal says how far over', (tester) async {
    diary.put(_meal('d', 'Karahi', 850, 20, 'Dinner'));
    await open(tester);
    expect(total('2,350'), findsOneWidget);
    expect(total('350 over'), findsOneWidget);
  });

  testWidgets('editing a meal\'s calories saves the new figure and the day '
      'total follows', (tester) async {
    await open(tester);
    await tester.tap(inDiary('Mango lassi'));
    await _settle(tester, ms: 800);

    // Name, portion, calories, ...
    final calories = find.byType(TextField).at(2);
    await tester.enterText(calories, '450');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-meal-save')));
    await _settle(tester, ms: 2000);

    final saved = log.updated.single;
    expect(saved.id, 's');
    expect(saved.calories, 450);
    expect(saved.dateString, _today);
    expect(total('1,650'), findsOneWidget);
    expect(total('350 left'), findsOneWidget);
  });

  testWidgets('search, pick a food, change the serving and add it: the meal '
      'lands in the diary with the right figures and the total follows', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('quick-add-search')));
    await _settle(tester, ms: 800);
    await tester.enterText(
      find.byKey(const ValueKey('quick-food-search-field')),
      'biryani',
    );
    await tester.pump();
    await tester.tap(find.text('Chicken biryani').last);
    await _settle(tester, ms: 800);

    await tester.tap(find.text('2 servings'));
    await tester.pump();
    final add = find.byKey(const ValueKey('quick-food-add-button'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await _settle(tester, ms: 2000);

    // 195 kcal per 100 g, a 300 g serving, twice.
    final meal = log.added.single;
    expect(meal.foodName, 'Chicken biryani');
    expect(meal.calories, 1170);
    expect(meal.macros.protein, 48);
    expect(meal.macros.carbs, 168);
    expect(meal.macros.fat, 36);
    expect(meal.weightG, 600);
    expect(meal.dateString, _today);
    expect(meal.mealType, app_date.DateUtils.suggestedMealType());
    expect(meal.nutritionPer100g?['calories'], 195);

    expect(inDiary('Chicken biryani'), findsOneWidget);
    expect(total('2,670'), findsOneWidget);
    expect(total('670 over'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('the current meal with a four-figure total and its scan button '
        'fits a small phone with large text (${locale.languageCode})', (
      tester,
    ) async {
      final now = DateTime.now();
      diary.put(
        _meal(
          'big',
          'Family platter',
          1850,
          now.hour,
          app_date.DateUtils.suggestedMealType(now),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(320, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_host(diary, log, locale: locale));
      await _settle(tester);

      expect(find.byKey(const ValueKey('log-scan-current')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
