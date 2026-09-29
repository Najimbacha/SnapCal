import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/network/api_client.dart';
import '../../core/resilience/app_failure.dart';
import '../../core/services/config_service.dart';
import '../../core/resilience/timeout_policy.dart';
import 'gemini_service.dart'; // For NutritionResult

/// Service for looking up food by barcode via OpenFoodFacts API
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal() : _dio = Dio();

  /// A plain client for the public database. It must never carry our sign-in,
  /// so our own server is called through ApiClient instead.
  final Dio _dio;

  /// OpenFoodFacts asks apps to name themselves; anonymous callers can be
  /// slowed or blocked.
  @visibleForTesting
  static const userAgent = 'Wazn-Android/1.0';

  /// Fetches product data from OpenFoodFacts
  Future<NutritionResult?> fetchProductByBarcode(String barcode) async {
    debugPrint("Looking up barcode: $barcode");
    final codes = lookupCodes(barcode);
    for (final code in codes) {
      final result = await _fetchOne(code);
      if (result != null) return result;
    }
    if (codes.isEmpty) return null;
    return _fetchFromUsda(codes);
  }

  /// A second, free database (USDA branded foods) for what the first does not
  /// know. It runs on our server, which holds the key. It is a bonus: any
  /// failure here just means "not found".
  Future<NutritionResult?> _fetchFromUsda(List<String> codes) async {
    final code = codes.firstWhere(
      (c) => c.length == 12 || c.length == 13,
      orElse: () => codes.first,
    );
    try {
      final response = await ApiClient.dio.get(
        '${ConfigService().backendProxyUrl}/api/barcode/$code',
        options: Options(
          receiveTimeout: TimeoutPolicy.barcodeFallback,
          sendTimeout: TimeoutPolicy.barcodeFallback,
        ),
      );
      final data = response.data;
      final product = data is Map ? data['product'] : null;
      if (product is! Map) return null;
      return fromUsda(product, _l10n);
    } catch (e) {
      debugPrint('USDA barcode lookup unavailable: $e');
      return null;
    }
  }

  /// A product from our server's USDA lookup, shaped like an OpenFoodFacts
  /// one so it is read by the same, tested code.
  @visibleForTesting
  static NutritionResult? fromUsda(Map product, AppLocalizations l10n) {
    final per100 = product['per100g'];
    if (per100 is! Map) return null;
    final name = product['name']?.toString().trim() ?? '';
    final brand = product['brand']?.toString().trim() ?? '';
    return fromProduct({
      'product_name':
          name.isEmpty
              ? ''
              : (brand.isEmpty || name.toLowerCase().contains(brand.toLowerCase())
                  ? name
                  : '$name ($brand)'),
      'serving_size': product['servingText'],
      'serving_quantity': product['servingSize'],
      'nutriments': {
        'energy-kcal_100g': per100['calories'],
        'proteins_100g': per100['protein'],
        'carbohydrates_100g': per100['carbs'],
        'fat_100g': per100['fat'],
      },
    }, l10n);
  }

  Future<NutritionResult?> _fetchOne(String code) async {
    final url = 'https://world.openfoodfacts.org/api/v2/product/$code.json';

    final Response response;
    try {
      response = await _dio.get(
        url,
        options: Options(
          headers: const {'User-Agent': userAgent},
          connectTimeout: TimeoutPolicy.barcode,
          receiveTimeout: TimeoutPolicy.barcode,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }

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

  /// The same product can be printed in several forms: a 12-digit UPC-A is an
  /// EAN-13 with a leading 0, a UPC-E is a squeezed UPC-A, and a 14-digit
  /// case code wraps the 13-digit one. The database knows the plain forms, so
  /// each is tried in turn.
  @visibleForTesting
  static List<String> lookupCodes(String raw) {
    if (!isFoodBarcode(raw)) return const [];
    final code = raw.trim();
    final codes = <String>[code];
    void add(String c) {
      if (!codes.contains(c)) codes.add(c);
    }

    if (code.length == 8 && (code[0] == '0' || code[0] == '1')) {
      final upcA = _expandUpcE(code);
      add(upcA);
      add('0$upcA');
    } else if (code.length == 12) {
      add('0$code');
    } else if (code.length == 14) {
      final body = code.substring(1, 13);
      add('$body${_ean13Check(body)}');
    }
    return codes;
  }

  static String _expandUpcE(String upcE) {
    final d = upcE.split('');
    final String body;
    switch (d[6]) {
      case '0' || '1' || '2':
        body = '${d[0]}${d[1]}${d[2]}${d[6]}0000${d[3]}${d[4]}${d[5]}';
      case '3':
        body = '${d[0]}${d[1]}${d[2]}${d[3]}00000${d[4]}${d[5]}';
      case '4':
        body = '${d[0]}${d[1]}${d[2]}${d[3]}${d[4]}00000${d[5]}';
      default:
        body = '${d[0]}${d[1]}${d[2]}${d[3]}${d[4]}${d[5]}0000${d[6]}';
    }
    return '$body${d[7]}';
  }

  static int _ean13Check(String twelveDigits) {
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(twelveDigits[i]) * (i.isEven ? 1 : 3);
    }
    return (10 - sum % 10) % 10;
  }

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
