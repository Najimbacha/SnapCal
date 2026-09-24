import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/models/quick_food.dart';
import 'package:snapcal/data/quick_food_catalog.dart';
import 'package:snapcal/data/services/quick_food_preferences_service.dart';

void main() {
  test('device countries resolve to a useful regional catalogue', () {
    expect(QuickFoodCatalog.automaticRegion('PK'), 'south_asian');
    expect(QuickFoodCatalog.automaticRegion('SA'), 'middle_eastern');
    expect(QuickFoodCatalog.automaticRegion('KR'), 'east_asian');
    expect(QuickFoodCatalog.automaticRegion('US'), 'american');
    expect(QuickFoodCatalog.automaticRegion('ZZ'), 'international');
  });

  test('Pakistan preference ranks local food ahead of unrelated food', () {
    final ranked = QuickFoodCatalog.ranked(
      regionPreference: 'pakistan',
      cuisinePreference: 'international',
      mealType: 'Lunch',
      countryCode: 'PK',
    );
    final biryani = ranked.indexWhere((food) => food.name == 'Chicken biryani');
    final burger = ranked.indexWhere((food) => food.name == 'Hamburger');
    expect(biryani, isNonNegative);
    expect(burger, isNonNegative);
    expect(biryani, lessThan(burger));
  });

  test('an explicit Pakistan preference overrides a Saudi device region', () {
    final ranked = QuickFoodCatalog.ranked(
      regionPreference: 'pakistan',
      cuisinePreference: 'international',
      mealType: 'Lunch',
      countryCode: 'SA',
    );
    final biryani = ranked.indexWhere((food) => food.name == 'Chicken biryani');
    final kabsa = ranked.indexWhere((food) => food.name == 'Chicken kabsa');
    expect(biryani, lessThan(kabsa));
  });

  test('catalog IDs are unique and serving nutrition scales safely', () {
    final ids = QuickFoodCatalog.foods.map((food) => food.nutritionId).toSet();
    expect(ids, hasLength(QuickFoodCatalog.foods.length));
    final biryani = QuickFoodCatalog.byId('FDB_000533')!;
    expect(biryani.caloriesFor(300), 585);
    expect(biryani.macrosFor(300).protein, 24);
    expect(biryani.caloriesFor(-10), 0);
  });

  test('food preference service rejects an unknown saved region', () async {
    SharedPreferences.setMockInitialValues({
      QuickFoodPreferencesService.regionKey: 'not-a-real-region',
      QuickFoodPreferencesService.favoritesKey: ['FDB_000533'],
    });
    final preferences = await QuickFoodPreferencesService().load();
    expect(preferences.region, 'automatic');
    expect(preferences.favoriteIds, {'FDB_000533'});

    await QuickFoodPreferencesService().save(
      const QuickFoodPreferences(
        region: 'pakistan',
        favoriteIds: {'FDB_000533', 'FDB_000534'},
      ),
    );
    final saved = await QuickFoodPreferencesService().load();
    expect(saved.region, 'pakistan');
    expect(saved.favoriteIds, {'FDB_000533', 'FDB_000534'});
  });
}
