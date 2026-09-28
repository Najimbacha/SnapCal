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
    if (!isFoodBarcode(barcode)) return null;
    final url =
        'https://world.openfoodfacts.org/api/v2/product/${barcode.trim()}.json';

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

    return fromProduct(product, _l10n);
  }

  /// A food barcode: EAN-13, EAN-8, UPC-A or UPC-E -- digits only. Anything
  /// else (a QR code's web address, say) went straight into the lookup's
  /// address and came back as "product not found", or as a broken request.
  @visibleForTesting
  static bool isFoodBarcode(String code) =>
      RegExp(r'^\d{6,14}$').hasMatch(code.trim());

  /// The product as the result screen needs it: nutrition per 100 g and the
  /// weight of one serving, so the screen can show and scale it.
  ///
  /// It sent totals and a label instead. The screen read the weight from the
  /// label's first number, so "1 bar (40 g)" was a 1 g bar and adding 10 g
  /// multiplied the calories elevenfold; per-serving calories were mixed with
  /// per-100 g macros whenever a product listed only some per serving; a
  /// product listing energy only in kJ came out at 0 kcal; and a drink with
  /// no calories -- water, a diet soda -- could not be saved at all.
  @visibleForTesting
  static NutritionResult? fromProduct(Map product, AppLocalizations l10n) {
    final n = product['nutriments'] is Map ? product['nutriments'] as Map : {};
    double? num_(dynamic v) {
      if (v is num) return v.isFinite ? v.toDouble() : null;
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    double? kcal(String basis) {
      final direct = num_(n['energy-kcal_$basis']);
      if (direct != null) return direct;
      final kj = num_(n['energy-kj_$basis']) ?? num_(n['energy_$basis']);
      return kj == null ? null : kj / 4.184;
    }

    Map<String, double?> values(String basis) => {
      'calories': kcal(basis),
      'protein': num_(n['proteins_$basis']),
      'carbs': num_(n['carbohydrates_$basis']),
      'fat': num_(n['fat_$basis']),
    };

    final servingSize = product['serving_size']?.toString().trim();
    final servingG = num_(product['serving_quantity']);
    final hasServingWeight = servingG != null && servingG > 0;
    final per100 = values('100g');
    final perServing = values('serving');
    bool known(Map<String, double?> v) => v.values.any((x) => x != null);

    final Map<String, double?> base;
    final double weight;
    if (known(per100)) {
      base = per100;
      weight = hasServingWeight ? servingG : 100;
    } else if (known(perServing)) {
      // Only per serving: scaled to 100 g when the serving's weight is
      // known, otherwise one serving stands in as the unit.
      final w = hasServingWeight ? servingG : 100.0;
      base = {
        for (final e in perServing.entries)
          e.key: e.value == null ? null : e.value! * 100 / w,
      };
      weight = w;
    } else {
      return NutritionResult(
        foodName: _name(product, l10n),
        portion:
            servingSize?.isNotEmpty == true
                ? servingSize!
                : l10n.barcode_default_portion,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        matched: false,
      );
    }

    final per100g = {for (final e in base.entries) e.key: e.value ?? 0.0};
    int at(String key) => (per100g[key]! * weight / 100).round();
    return NutritionResult(
      foodName: _name(product, l10n),
      portion:
          hasServingWeight && servingSize?.isNotEmpty == true
              ? servingSize!
              : '${weight.round()} g',
      calories: at('calories'),
      protein: at('protein'),
      carbs: at('carbs'),
      fat: at('fat'),
      weightG: weight,
      matched: true,
      nutritionPer100g: per100g,
    );
  }

  static String _name(Map product, AppLocalizations l10n) {
    final name = product['product_name']?.toString().trim();
    return name == null || name.isEmpty ? l10n.barcode_unknown_product : name;
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
