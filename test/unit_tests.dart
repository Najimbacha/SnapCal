import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/core/constants/app_constants.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/data/repositories/settings_repository.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

// Mock PathProvider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MealRepository mealRepository;
  late SettingsRepository settingsRepository;

  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    Hive.registerAdapter(MacrosAdapter());
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('SettingsProvider & Paywall Logic', () {
    late SettingsProvider provider;

    setUp(() async {
      settingsRepository = SettingsRepository();
      await settingsRepository.init();
      // Reset settings
      final box = await Hive.openBox<UserSettings>(
        AppConstants.settingsBoxName,
      );
      await box.clear();

      provider = SettingsProvider(settingsRepository);
    });

    test('Should enforce free tier limit', () {
      expect(provider.isPro, false);

      // Limit is 3
      expect(provider.canAddMeal(0), true);
      expect(provider.canAddMeal(1), true);
      expect(provider.canAddMeal(2), true);
      expect(provider.canAddMeal(3), false); // Limit reached
    });

    test('Should allow unlimited meals for Pro users', () async {
      await provider.upgradeToPro();
      expect(provider.isPro, true);

      expect(provider.canAddMeal(3), true);
      expect(provider.canAddMeal(10), true);
    });
  });

  group('MealProvider & Persistence', () {
    late MealProvider provider;

    setUp(() async {
      mealRepository = MealRepository();
      await mealRepository.init();
      // Clear meals
      final box = await Hive.openBox<Meal>(AppConstants.mealsBoxName);
      await box.clear();

      provider = MealProvider(mealRepository);
    });

    test('Should add and persist meal', () async {
      expect(provider.todaysMeals.isEmpty, true);

      await provider.addMeal(
        foodName: 'Test Burger',
        calories: 500,
        protein: 30,
        carbs: 40,
        fat: 20,
      );

      expect(provider.todaysMeals.length, 1);
      expect(provider.todaysMeals.first.foodName, 'Test Burger');
      expect(provider.todaysTotalCalories, 500);

      // Verify persistence by creating new repository instance
      final newRepo = MealRepository();
      await newRepo.init();
      final savedMeals = newRepo.getAllMeals();
      expect(savedMeals.length, 1);
      expect(savedMeals.first.foodName, 'Test Burger');
    });

    test('Should delete meal', () async {
      await provider.addMeal(
        foodName: 'To Delete',
        calories: 100,
        protein: 10,
        carbs: 10,
        fat: 10,
      );

      final mealId = provider.todaysMeals.first.id;
      await provider.deleteMeal(mealId);

      expect(provider.todaysMeals.isEmpty, true);
    });
  });
}
