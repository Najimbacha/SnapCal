import 'dart:math' as math;

import 'meal.dart';

/// A food that can be added without running an AI scan.
///
/// Nutrition is stored per 100 g so every serving is calculated in exactly
/// the same way as a scanned meal. [nutritionId] points at the matching row in
/// the backend catalogue, which keeps Quick Add and scan corrections aligned.
class QuickFood {
  const QuickFood({
    required this.nutritionId,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.defaultServingG,
    required this.regions,
    this.countries = const {},
    this.mealTypes = const {'Lunch', 'Dinner'},
    this.localizedNames = const {},
    this.aliases = const [],
  });

  final String nutritionId;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double defaultServingG;
  final Set<String> regions;
  final Set<String> countries;
  final Set<String> mealTypes;
  final Map<String, String> localizedNames;
  final List<String> aliases;

  String displayName(String languageCode) =>
      localizedNames[languageCode]?.trim().isNotEmpty == true
          ? localizedNames[languageCode]!
          : name;

  int caloriesFor(double grams) =>
      math.max(0, (caloriesPer100g * grams / 100).round());

  Macros macrosFor(double grams) => Macros(
    protein: math.max(0, (proteinPer100g * grams / 100).round()),
    carbs: math.max(0, (carbsPer100g * grams / 100).round()),
    fat: math.max(0, (fatPer100g * grams / 100).round()),
  );

  Map<String, dynamic> get nutritionPer100g => {
    'calories': caloriesPer100g,
    'protein': proteinPer100g,
    'carbs': carbsPer100g,
    'fat': fatPer100g,
  };

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      name,
      ...localizedNames.values,
      ...aliases,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

class QuickFoodPreferences {
  const QuickFoodPreferences({
    this.region = 'automatic',
    this.favoriteIds = const {},
  });

  final String region;
  final Set<String> favoriteIds;

  QuickFoodPreferences copyWith({String? region, Set<String>? favoriteIds}) {
    return QuickFoodPreferences(
      region: region ?? this.region,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

class QuickFoodRegion {
  const QuickFoodRegion(this.id, this.catalogRegion);

  final String id;
  final String catalogRegion;

  static const values = <QuickFoodRegion>[
    QuickFoodRegion('automatic', 'automatic'),
    QuickFoodRegion('pakistan', 'south_asian'),
    QuickFoodRegion('south_asian', 'south_asian'),
    QuickFoodRegion('middle_eastern', 'middle_eastern'),
    QuickFoodRegion('gulf', 'middle_eastern'),
    QuickFoodRegion('east_asian', 'east_asian'),
    QuickFoodRegion('korean', 'east_asian'),
    QuickFoodRegion('american', 'american'),
    QuickFoodRegion('mediterranean', 'mediterranean'),
    QuickFoodRegion('international', 'international'),
  ];

  static QuickFoodRegion byId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => values.first);
}
