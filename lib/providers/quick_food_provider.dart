import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/quick_food.dart';
import '../data/services/quick_food_preferences_service.dart';

final quickFoodPreferencesProvider =
    AsyncNotifierProvider<QuickFoodPreferencesNotifier, QuickFoodPreferences>(
      QuickFoodPreferencesNotifier.new,
    );

class QuickFoodPreferencesNotifier extends AsyncNotifier<QuickFoodPreferences> {
  final QuickFoodPreferencesService _service = QuickFoodPreferencesService();

  @override
  Future<QuickFoodPreferences> build() => _service.load();

  Future<void> setRegion(String region) async {
    final previous = state.valueOrNull ?? const QuickFoodPreferences();
    final valid = QuickFoodRegion.values.any((value) => value.id == region);
    if (!valid) return;
    final next = previous.copyWith(region: region);
    state = AsyncData(next);
    await _service.save(next);
  }

  Future<void> toggleFavorite(String nutritionId) async {
    final previous = state.valueOrNull ?? const QuickFoodPreferences();
    final favorites = {...previous.favoriteIds};
    if (!favorites.remove(nutritionId)) favorites.add(nutritionId);
    final next = previous.copyWith(favoriteIds: favorites);
    state = AsyncData(next);
    await _service.save(next);
  }
}
