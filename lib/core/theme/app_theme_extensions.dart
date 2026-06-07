import 'package:flutter/material.dart';

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

  static const light = SnapCalTheme(
    calories: Color(0xFFE56B38),
    protein: Color(0xFF256D63),
    carbs: Color(0xFFC88A32),
    fat: Color(0xFF8C67B8),
    water: Color(0xFF3185C6),
    steps: Color(0xFF087F5B),
    premiumGold: Color(0xFFC88A32),
    premiumGradient: LinearGradient(
      colors: [Color(0xFF087F5B), Color(0xFF21A574)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const dark = SnapCalTheme(
    calories: Color(0xFFE56B38),
    protein: Color(0xFF79D6C6),
    carbs: Color(0xFFE7B766),
    fat: Color(0xFFBDA1DE),
    water: Color(0xFF79B7EE),
    steps: Color(0xFF56D6A5),
    premiumGold: Color(0xFFE7B766),
    premiumGradient: LinearGradient(
      colors: [Color(0xFF103E31), Color(0xFF087F5B)],
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
