import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/core/constants/app_constants.dart';
import 'package:snapcal/core/utils/date_utils.dart' as app_date;
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/providers/calorie_budget_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';

/// Meals saved to the real, encrypted Hive files on disk, then read back by
/// a fresh repository, the way they are after the app is closed and opened.

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async =>
      UserSettings.defaults().copyWith(dailyCalorieGoal: 2000);
}

String get _today => app_date.DateUtils.getTodayString();

Meal _meal(
  String id, {
  String? date,
  int calories = 300,
  int hour = 12,
  String mealType = 'Lunch',
}) {
  final day = app_date.DateUtils.parseDate(date ?? _today);
  return Meal(
    id: id,
    timestamp:
        DateTime(day.year, day.month, day.day, hour).millisecondsSinceEpoch,
    dateString: date ?? _today,
    foodName: 'Food $id',
    calories: calories,
    macros: Macros(protein: 20, carbs: 30, fat: 10),
    mealType: mealType,
  );
}

int _total(List<Meal> meals) => meals.fold(0, (sum, m) => sum + m.calories);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late MealRepository repo;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(MacrosAdapter());
  });

  Future<MealRepository> open() async {
    final opened = MealRepository.forTesting(
      FakeFirebaseFirestore(),
      MockFirebaseAuth(),
    );
    await opened.init();
    return opened;
  }

  /// Closes the files and opens them again with a new repository, as a
  /// restart does.
  Future<MealRepository> restart() async {
    repo.dispose();
    await Hive.close();
    return repo = await open();
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('meal_persistence_');
    Hive.init(directory.path);
    repo = await open();
  });

  tearDown(() async {
    repo.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'an added food is still there, with every detail, after a restart',
    () async {
      final scanned = _meal('scan', calories: 468).copyWith(
        macros: Macros(protein: 6, carbs: 58, fat: 24),
        portion: '150 g',
        scanSource: 'ai_scan',
        scanConfidence: 0.87,
        originalCalories: 468,
        weightG: 150.5,
        nutritionMatchId: 'fries_01',
        nutritionPer100g: {'calories': 312.0, 'protein': 3.4},
      );
      await repo.addMeal(scanned);

      await restart();
      final saved = repo.getMealsByDate(_today).single;
      expect(saved.foodName, 'Food scan');
      expect(saved.calories, 468);
      expect(saved.macros.protein, 6);
      expect(saved.macros.carbs, 58);
      expect(saved.macros.fat, 24);
      expect(saved.mealType, 'Lunch');
      expect(saved.portion, '150 g');
      expect(saved.scanConfidence, 0.87);
      expect(saved.weightG, 150.5);
      expect(saved.nutritionMatchId, 'fries_01');
      expect(saved.nutritionPer100g, {'calories': 312.0, 'protein': 3.4});
    },
  );

  test(
    'an edit replaces the food after a restart, never adding a copy',
    () async {
      await repo.addMeal(_meal('a', calories: 300));
      await repo.addMeal(_meal('b', calories: 200));
      await repo.updateMeal(
        repo.getMeal('a')!.copyWith(calories: 450, userCorrected: true),
      );

      await restart();
      final meals = repo.getMealsByDate(_today);
      expect(meals.map((m) => m.id), unorderedEquals(['a', 'b']));
      expect(repo.getMeal('a')!.calories, 450);
      expect(repo.getMeal('a')!.userCorrected, isTrue);
      expect(_total(meals), 650);
    },
  );

  test('a food moved to another day shows on that day only', () async {
    await repo.addMeal(_meal('a', date: '2026-02-28'));
    await repo.addMeal(_meal('b', date: '2026-02-28', calories: 100));
    await repo.updateMeal(
      repo.getMeal('a')!.copyWith(dateString: '2026-03-01'),
    );

    await restart();
    expect(repo.getMealsByDate('2026-02-28').map((m) => m.id), ['b']);
    expect(repo.getMealsByDate('2026-03-01').map((m) => m.id), ['a']);
  });

  test('a deleted food does not come back after a restart, and the day '
      'total drops by its calories', () async {
    await repo.addMeal(_meal('keep', calories: 1200));
    await repo.addMeal(_meal('gone', calories: 300));
    expect(_total(repo.getMealsByDate(_today)), 1500);

    await repo.deleteMeal('gone');

    await restart();
    expect(repo.getMeal('gone'), isNull);
    expect(repo.getMealsByDate(_today).map((m) => m.id), ['keep']);
    expect(_total(repo.getMealsByDate(_today)), 1200);
  });

  test(
    'deleting a day\'s last food leaves that day empty after a restart',
    () async {
      await repo.addMeal(_meal('only', date: '2026-01-15'));
      await repo.deleteMeal('only');

      await restart();
      expect(repo.getMealsByDate('2026-01-15'), isEmpty);
      expect(repo.getAllMeals(), isEmpty);
    },
  );

  test('deleting a food that is not there changes nothing', () async {
    await repo.addMeal(_meal('a'));
    await repo.deleteMeal('never-saved');
    expect(repo.getMealsByDate(_today).map((m) => m.id), ['a']);
  });

  test('saving the same food twice keeps one copy', () async {
    await repo.addMeal(_meal('a', calories: 300));
    await repo.addMeal(_meal('a', calories: 300));
    await repo.addMeals([_meal('a', calories: 300)]);

    await restart();
    expect(repo.getMealsByDate(_today).map((m) => m.id), ['a']);
    expect(_total(repo.getMealsByDate(_today)), 300);
  });

  test('a day lists its foods newest first and ignores other days', () async {
    await repo.addMeal(_meal('breakfast', hour: 8, calories: 400));
    await repo.addMeal(_meal('dinner', hour: 19, calories: 700));
    await repo.addMeal(_meal('lunch', hour: 13, calories: 600));
    await repo.addMeal(_meal('yesterday', date: '2020-05-05', calories: 999));

    final meals = repo.getMealsByDate(_today);
    expect(meals.map((m) => m.id), ['dinner', 'lunch', 'breakfast']);
    expect(_total(meals), 1700);
  });

  test('an install whose date index is missing rebuilds it on opening, '
      'so no history looks lost', () async {
    await repo.addMeal(_meal('a', date: '2025-12-31'));
    await repo.addMeal(_meal('b', date: '2026-01-01'));
    await repo.addMeal(_meal('c', date: '2026-01-01'));
    // Older versions kept meals without this index.
    await Hive.box<List<String>>(AppConstants.mealIndexBoxName).clear();

    await restart();
    expect(repo.getMealsByDate('2025-12-31').map((m) => m.id), ['a']);
    expect(
      repo.getMealsByDate('2026-01-01').map((m) => m.id),
      unorderedEquals(['b', 'c']),
    );
  });

  test('given 1,200 eaten of a 2,000 goal, adding a 300-calorie food shows '
      '1,500 eaten and 500 left, and survives a restart', () async {
    ProviderContainer container() => ProviderContainer(
      overrides: [
        mealRepositoryProvider.overrideWith((ref) async => repo),
        settingsProvider.overrideWith(_Settings.new),
        effectiveIsProProvider.overrideWithValue(false),
      ],
    );
    Future<CalorieBudget> budgetOf(ProviderContainer c) async {
      await c.read(settingsProvider.future);
      await c.read(todaysMealsProvider.future);
      return c.read(calorieBudgetProvider);
    }

    await repo.addMeal(_meal('breakfast', hour: 8, calories: 1200));
    final first = container();
    addTearDown(first.dispose);
    final sub = first.listen(todaysMealsProvider, (_, _) {});
    addTearDown(sub.close);
    var budget = await budgetOf(first);
    expect(budget.eaten, 1200);
    expect(budget.left, 800);

    await repo.addMeal(
      _meal('snack', hour: 16, calories: 300, mealType: 'Snack'),
    );
    await pumpEventQueue();
    budget = first.read(calorieBudgetProvider);
    expect(budget.eaten, 1500);
    expect(budget.left, 500);
    expect(
      first
          .read(todaysMealsProvider)
          .value!
          .singleWhere((m) => m.id == 'snack')
          .mealType,
      'Snack',
    );

    await restart();
    final second = container();
    addTearDown(second.dispose);
    budget = await budgetOf(second);
    expect(budget.eaten, 1500);
    expect(budget.left, 500);
  });

  test('one unreadable meal in the cloud does not stop the rest of the '
      'history reaching a new phone', () async {
    repo.dispose();
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'restore'),
      signedIn: true,
    );
    repo = MealRepository.forTesting(db, auth);
    await repo.init();
    await repo.syncFromFirestore();
    await Hive.box<List<String>>(
      AppConstants.mealIndexBoxName,
    ).delete('mealSyncCursor:restorefullHistoryV1');

    await db
        .doc('users/restore/meals/a-good')
        .set(_meal('a-good', date: '2024-06-01', calories: 500).toJson());
    // What the cloud rules let through: a name, calories and macros, but no
    // date or time -- as an older app version could have left it.
    await db.doc('users/restore/meals/b-broken').set({
      'id': 'b-broken',
      'foodName': 'Old entry',
      'calories': 250,
      'macros': {'protein': 1, 'carbs': 2, 'fat': 3},
    });
    await db
        .doc('users/restore/meals/c-good')
        .set(_meal('c-good', date: '2024-06-01', calories: 700).toJson());

    await repo.syncFromFirestore();
    expect(
      repo.getMealsByDate('2024-06-01').map((m) => m.id),
      unorderedEquals(['a-good', 'c-good']),
    );
    expect(repo.getMeal('b-broken'), isNull);
  });
}
