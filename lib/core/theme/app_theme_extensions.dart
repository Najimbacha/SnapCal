import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class SnapCalTheme extends ThemeExtension<SnapCalTheme> {
  final Color calories;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color water;
  final Color steps;
  final Color premiumGold;
  final LinearGradient premiumGradient;

  const SnapCalTheme({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.water,
    required this.steps,
    required this.premiumGold,
    required this.premiumGradient,
  });

  /// Semantic metric colors, tuned per brightness but always derived from the
  /// shared AppColors palette so charts and cards stay on one identity.
  static const light = SnapCalTheme(
    calories: AppColors.primaryDark, // Emerald
    protein: Color(0xFF5F7A52), // Deep sage
    carbs: Color(0xFF3D6F9F), // Deep slate blue
    fat: Color(0xFFB06F32), // Deep ochre
    water: Color(0xFF2563AE), // Deep water blue
    steps: AppColors.primaryDark,
    premiumGold: Color(0xFFC88A32),
    premiumGradient: LinearGradient(
      colors: [AppColors.emeraldDark, Color(0xFF0B6B4F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const dark = SnapCalTheme(
    calories: Color(0xFF34D399), // Mint emerald
    protein: Color(0xFFA3C293), // Light sage
    carbs: Color(0xFF7AB4E8), // Light slate blue
    fat: Color(0xFFE8B87A), // Light ochre
    water: AppColors.skyLight,
    steps: Color(0xFF34D399),
    premiumGold: Color(0xFFE7B766),
    premiumGradient: LinearGradient(
      colors: [Color(0xFF06251C), Color(0xFF047857)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  SnapCalTheme copyWith({
    Color? calories,
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? water,
    Color? steps,
    Color? premiumGold,
    LinearGradient? premiumGradient,
  }) {
    return SnapCalTheme(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      water: water ?? this.water,
      steps: steps ?? this.steps,
      premiumGold: premiumGold ?? this.premiumGold,
      premiumGradient: premiumGradient ?? this.premiumGradient,
    );
  }

  @override
  SnapCalTheme lerp(ThemeExtension<SnapCalTheme>? other, double t) {
    if (other is! SnapCalTheme) return this;
    return SnapCalTheme(
      calories: Color.lerp(calories, other.calories, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      water: Color.lerp(water, other.water, t)!,
      steps: Color.lerp(steps, other.steps, t)!,
      premiumGold: Color.lerp(premiumGold, other.premiumGold, t)!,
      premiumGradient: t < 0.5 ? premiumGradient : other.premiumGradient,
    );
  }
}

extension SnapCalThemeAccess on BuildContext {
  SnapCalTheme get snapcalTheme =>
      Theme.of(this).extension<SnapCalTheme>() ?? SnapCalTheme.light;
}
