import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/barcode_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('only food barcodes are looked up', () {
    expect(BarcodeService.isFoodBarcode('5449000000996'), isTrue);
    expect(BarcodeService.isFoodBarcode('96385074'), isTrue);
    expect(BarcodeService.isFoodBarcode('https://example.com/p/1'), isFalse);
    expect(BarcodeService.isFoodBarcode('../../admin'), isFalse);
  });

  test('every printed form of a barcode is tried', () {
    expect(BarcodeService.lookupCodes('5449000000996'), ['5449000000996']);
    expect(BarcodeService.lookupCodes('042100005264'), [
      '042100005264',
      '0042100005264',
    ]);
    expect(BarcodeService.lookupCodes('04252614'), [
      '04252614',
      '042100005264',
      '0042100005264',
    ]);
    expect(BarcodeService.lookupCodes('15449000000993'), [
      '15449000000993',
      '5449000000996',
    ]);
    expect(BarcodeService.lookupCodes('https://example.com'), isEmpty);
  });

  test('a USDA product from our server reads like any other product', () {
    final r =
        BarcodeService.fromUsda({
          'name': 'Oat Bar',
          'brand': 'Acme Foods',
          'servingSize': 40,
          'servingText': '1 bar',
          'per100g': {'calories': 400, 'protein': 10, 'carbs': 60, 'fat': 12},
        }, l10n)!;
    expect(r.foodName, 'Oat Bar (Acme Foods)');
    expect(r.weightG, 40);
    expect(r.calories, 160);
    expect(r.protein, 4);
    expect(r.portion, '1 bar');
    expect(r.matched, isTrue);
    expect(BarcodeService.fromUsda({'name': 'x'}, l10n), isNull);
  });

  test('a serving is its real weight, not the first number on the label', () {
    final r =
        BarcodeService.fromProduct({
          'product_name': 'Oat bar',
          'serving_size': '1 bar (40 g)',
          'serving_quantity': 40,
          'nutriments': {
            'energy-kcal_100g': 400,
            'proteins_100g': 10,
            'carbohydrates_100g': 60,
            'fat_100g': 12,
          },
        }, l10n)!;
    expect(r.weightG, 40);
    expect(r.calories, 160);
    expect(r.protein, 4);
    expect(r.portion, '1 bar (40 g)');
    expect(r.nutritionPer100g!['calories'], 400);
  });

  test('a diet drink with no calories can be logged', () {
    final r =
        BarcodeService.fromProduct({
          'product_name': 'Cola zero',
          'serving_quantity': '330',
          'serving_size': '330 ml',
          'nutriments': {
            'energy-kcal_100g': 0,
            'proteins_100g': 0,
            'carbohydrates_100g': 0,
            'fat_100g': 0,
          },
        }, l10n)!;
    expect(r.calories, 0);
    expect(r.matched, isTrue);
    expect(r.nutritionPer100g, isNotNull);
  });

  test('energy given only in kJ still counts', () {
    final r =
        BarcodeService.fromProduct({
          'product_name': 'Crackers',
          'nutriments': {'energy_100g': 1841},
        }, l10n)!;
    expect(r.calories, 440);
    expect(r.weightG, 100);
    expect(r.portion, '100 g');
  });

  test('per-serving figures are not mixed with per-100 g ones', () {
    final r =
        BarcodeService.fromProduct({
          'product_name': 'Yogurt',
          'serving_quantity': 125,
          'nutriments': {
            'energy-kcal_100g': 80,
            'energy-kcal_serving': 100,
            'proteins_100g': 8,
          },
        }, l10n)!;
    // All from the per-100 g table, scaled to the 125 g pot.
    expect(r.calories, 100);
    expect(r.protein, 10);
  });

  test('a product with no nutrition is not presented as zero', () {
    final r = BarcodeService.fromProduct({'product_name': 'Mystery'}, l10n)!;
    expect(r.matched, isFalse);
    expect(r.nutritionPer100g, isNull);
  });
}
