import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import 'gemini_service.dart'; // For NutritionResult

/// Service for looking up food by barcode via OpenFoodFacts API
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal() : _dio = Dio();

  final Dio _dio;

  /// Fetches product data from OpenFoodFacts
  Future<NutritionResult?> fetchProductByBarcode(String barcode) async {
    try {
      debugPrint("Looking up barcode: $barcode");
      final url =
          'https://world.openfoodfacts.org/api/v2/product/$barcode.json';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 1) {
          final product = data['product'];

          // Helper to get nutrition per 100g or serving
          final nutriments = product['nutriments'] ?? {};

          return NutritionResult(
            foodName: product['product_name'] ?? _l10n.barcode_unknown_product,
            portion: product['serving_size'] ?? _l10n.barcode_default_portion,
            calories: _toInt(
              nutriments['energy-kcal_serving'] ??
                  nutriments['energy-kcal_100g'] ??
                  0,
            ),
            protein: _toInt(
              nutriments['proteins_serving'] ??
                  nutriments['proteins_100g'] ??
                  0,
            ),
            carbs: _toInt(
              nutriments['carbohydrates_serving'] ??
                  nutriments['carbohydrates_100g'] ??
                  0,
            ),
            fat: _toInt(
              nutriments['fat_serving'] ?? nutriments['fat_100g'] ?? 0,
            ),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint("Barcode lookup error: $e");
      return null;
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return double.tryParse(value)?.round() ?? 0;
    return 0;
  }

  AppLocalizations get _l10n {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode =
        AppLocalizations.supportedLocales.any(
              (supported) => supported.languageCode == locale.languageCode,
            )
            ? locale.languageCode
            : 'en';
    return lookupAppLocalizations(Locale(languageCode));
  }
}
