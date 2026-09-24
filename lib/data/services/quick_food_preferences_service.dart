import 'package:shared_preferences/shared_preferences.dart';

import '../models/quick_food.dart';

/// Local preferences for the instant food picker.
///
/// These values do not contain meal history or health data. They are cleared
/// with the rest of the signed-in session so one account cannot inherit
/// another account's region or favorites on a shared phone.
class QuickFoodPreferencesService {
  static const regionKey = 'quick_food_region';
  static const favoritesKey = 'quick_food_favorites';

  Future<QuickFoodPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRegion = prefs.getString(regionKey) ?? 'automatic';
    final validRegion = QuickFoodRegion.values.any(
      (region) => region.id == savedRegion,
    );
    return QuickFoodPreferences(
      region: validRegion ? savedRegion : 'automatic',
      favoriteIds:
          (prefs.getStringList(favoritesKey) ?? const <String>[]).toSet(),
    );
  }

  Future<void> save(QuickFoodPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(regionKey, preferences.region);
    final ids = preferences.favoriteIds.toList()..sort();
    await prefs.setStringList(favoritesKey, ids);
  }
}
