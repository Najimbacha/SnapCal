import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/core/constants/app_constants.dart';
import 'package:snapcal/core/services/security_service.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(MacrosAdapter());
  });

  for (final failingBox in [
    AppConstants.mealsBoxName,
    AppConstants.mealIndexBoxName,
  ]) {
    test(
      'failure opening $failingBox preserves both files and allows retry',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'meal_preservation_',
        );
        Hive.init(directory.path);
        final key = await SecurityService().getEncryptionKey();
        final cipher = HiveAesCipher(key);
        final meal = Meal(
          id: 'saved-meal',
          timestamp: 1,
          dateString: '2026-09-28',
          foodName: 'Saved meal',
          calories: 432,
          macros: Macros.empty(),
        );
        final meals = await Hive.openBox<Meal>(
          AppConstants.mealsBoxName,
          encryptionCipher: cipher,
        );
        final index = await Hive.openBox<List<String>>(
          AppConstants.mealIndexBoxName,
          encryptionCipher: cipher,
        );
        await meals.put(meal.id, meal);
        await index.put(meal.dateString, [meal.id]);
        await meals.flush();
        await index.flush();
        final mealsFile = File(meals.path!);
        final indexFile = File(index.path!);
        final mealsBytes = await mealsFile.readAsBytes();
        final indexBytes = await indexFile.readAsBytes();
        await Hive.close();
        // A conflicting handle triggers a genuine Hive open failure while both
        // files contain valid saved data.
        final conflicting = await Hive.openBox<dynamic>(
          failingBox,
          encryptionCipher: cipher,
        );
        final repo = MealRepository.forTesting(
          FakeFirebaseFirestore(),
          MockFirebaseAuth(),
        );
        final emitted = <List<Meal>>[];
        final subscription = repo.todaysMealsStream.listen(emitted.add);
        try {
          await expectLater(repo.init(), throwsA(isA<HiveError>()));
          expect(await mealsFile.readAsBytes(), mealsBytes);
          expect(await indexFile.readAsBytes(), indexBytes);
          expect(emitted, isEmpty);
          await conflicting.close();
          await repo.init();
          expect(repo.getMeal(meal.id)?.calories, 432);
          expect(repo.getMealsByDate(meal.dateString).map((meal) => meal.id), [
            meal.id,
          ]);
        } finally {
          await subscription.cancel();
          repo.dispose();
          await Hive.close();
          await directory.delete(recursive: true);
        }
      },
    );
  }
}
