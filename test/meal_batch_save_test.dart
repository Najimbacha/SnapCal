import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';

class _FailedRepository extends Fake implements MealRepository {
  List<Meal>? attempted;

  @override
  Future<void> addMeals(List<Meal> meals) async {
    attempted = meals;
    throw StateError('Disk write failed');
  }
}

class _Box<T> extends Fake implements Box<T> {
  final data = <dynamic, T>{};
  bool failWrites = false;
  int writes = 0;
  Completer<void>? gate;

  @override
  bool get isOpen => true;

  @override
  T? get(dynamic key, {T? defaultValue}) => data[key] ?? defaultValue;

  @override
  Iterable<T> get values => data.values;

  @override
  Future<void> putAll(Map<dynamic, T> values) async {
    writes++;
    if (gate != null) await gate!.future;
    if (failWrites) throw StateError('Disk write failed');
    data.addAll(values);
  }
}

Meal _meal(String id) => Meal(
  id: id,
  timestamp: 1,
  dateString: '2026-09-28',
  foodName: id,
  calories: 100,
  macros: Macros.empty(),
);

void main() {
  late _Box<Meal> meals;
  late _Box<List<String>> index;
  late MealRepository repo;

  setUp(() {
    meals = _Box<Meal>();
    index = _Box<List<String>>();
    repo = MealRepository.forTesting(
      FakeFirebaseFirestore(),
      MockFirebaseAuth(),
      mealsBox: meals,
      indexBox: index,
    );
  });
  tearDown(() => repo.dispose());

  test(
    'meal log submits one batch and propagates persistence failure',
    () async {
      final failed = _FailedRepository();
      final container = ProviderContainer(
        overrides: [mealRepositoryProvider.overrideWith((ref) async => failed)],
      );
      addTearDown(container.dispose);
      final batch = [_meal('a'), _meal('b')];
      await expectLater(
        container.read(mealLogProvider.notifier).addMeals(batch),
        throwsStateError,
      );
      expect(failed.attempted, same(batch));
    },
  );

  test(
    'a scan saves all foods in one meal write and waits for persistence',
    () async {
      meals.gate = Completer<void>();
      var completed = false;
      final save = repo
          .addMeals([_meal('a'), _meal('b')])
          .then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(meals.data, isEmpty);
      meals.gate!.complete();
      await save;
      expect(meals.writes, 1);
      expect(repo.getMealsByDate('2026-09-28').map((m) => m.id), ['a', 'b']);
    },
  );

  test(
    'index failure saves no foods and preserves existing index contents',
    () async {
      index.data['2026-09-28'] = ['existing'];
      index.failWrites = true;
      await expectLater(
        repo.addMeals([_meal('a'), _meal('b')]),
        throwsStateError,
      );
      expect(meals.data, isEmpty);
      expect(meals.writes, 0);
      expect(index.data['2026-09-28'], ['existing']);
    },
  );

  test(
    'meal write failure exposes no partial scan and retry has no duplicate ids',
    () async {
      meals.failWrites = true;
      await expectLater(
        repo.addMeals([_meal('a'), _meal('b')]),
        throwsStateError,
      );
      expect(repo.getMealsByDate('2026-09-28'), isEmpty);
      meals.failWrites = false;
      await repo.addMeals([_meal('a'), _meal('b')]);
      await repo.addMeals([_meal('a'), _meal('b')]);
      expect(index.data['2026-09-28'], ['a', 'b']);
      expect(meals.data.length, 2);
    },
  );

  test(
    'uninitialized storage fails instead of reporting a successful save',
    () async {
      final unavailable = MealRepository.forTesting(
        FakeFirebaseFirestore(),
        MockFirebaseAuth(),
      );
      addTearDown(unavailable.dispose);
      await expectLater(unavailable.addMeals([_meal('a')]), throwsStateError);
    },
  );
}
