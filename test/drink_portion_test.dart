import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/utils/drink_portion.dart';
import 'package:snapcal/data/services/gemini_service.dart';

void main() {
  test('common thin drinks support approximate volume', () {
    for (final name in [
      'Diet Pepsi',
      'diet cola',
      'Lemon Mint Drink',
      'sparkling water',
      'orange juice',
      'Coca-Cola Zero',
      'iced tea',
    ]) {
      expect(usesApproximateDrinkVolume(name), isTrue, reason: name);
    }
  });
  test('dense drinks, sauces and foods retain grams', () {
    for (final name in [
      'Mango smoothie',
      'milkshake',
      'milk',
      'Rice',
      'watermelon',
      'coffee cake',
      'tea biscuits',
      'cola chicken',
      'tomato sauce',
      'coconut cream',
      'fruit yogurt',
      'protein powder',
    ]) {
      expect(usesApproximateDrinkVolume(name), isFalse, reason: name);
    }
  });
  test('stable English name is preserved for translated scan results', () {
    final result = NutritionResult.fromJson({
      'food_name': 'بيبسي دايت',
      'match_key': 'diet cola',
      'weight_g': 330,
    });
    expect(result.foodName, 'بيبسي دايت');
    expect(result.matchKey, 'diet cola');
  });
}
