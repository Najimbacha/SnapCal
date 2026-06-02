import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/resilience/app_failure.dart';
import '../../core/resilience/timeout_policy.dart';
import 'gemini_service.dart'; // For NutritionResult

/// Service for looking up food by barcode via OpenFoodFacts API
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal() : _dio = Dio();

  final Dio _dio;

  /// Fetches product data from OpenFoodFacts
  Future<NutritionResult?> fetchProductByBarcode(String barcode) async {
    debugPrint("Looking up barcode: $barcode");
    final url = 'https://world.openfoodfacts.org/api/v2/product/$barcode.json';

    final response = await _dio.get(
      url,
      options: Options(
        connectTimeout: TimeoutPolicy.barcode,
        receiveTimeout: TimeoutPolicy.barcode,
      ),
    );

    if (response.statusCode != 200) return null;

    final data = response.data;
    if (data is! Map) {
      throw const AppFailure(
        type: AppFailureType.badResponse,
        message: 'Barcode service returned an unreadable response.',
      );
    }

    if (data['status'] != 1) return null;

    final product = data['product'];
    if (product is! Map) {
      throw const AppFailure(
        type: AppFailureType.badResponse,
        message: 'Barcode product payload is missing.',
      );
    }

    final nutriments =
        product['nutriments'] is Map ? product['nutriments'] as Map : {};

    final name = product['product_name']?.toString().trim();
    final portion = product['serving_size']?.toString().trim();

    return NutritionResult(
      foodName:
          name == null || name.isEmpty ? _l10n.barcode_unknown_product : name,
      portion:
          portion == null || portion.isEmpty
              ? _l10n.barcode_default_portion
              : portion,
      calories: _toInt(
        nutriments['energy-kcal_serving'] ??
            nutriments['energy-kcal_100g'] ??
            0,
      ),
      protein: _toInt(
        nutriments['proteins_serving'] ?? nutriments['proteins_100g'] ?? 0,
      ),
      carbs: _toInt(
        nutriments['carbohydrates_serving'] ??
            nutriments['carbohydrates_100g'] ??
            0,
      ),
      fat: _toInt(nutriments['fat_serving'] ?? nutriments['fat_100g'] ?? 0),
    );
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
