import 'package:flutter/material.dart';

/// SnapCal Color Palette - Google Gemini & Material 3 Expressive Gradient Theme
class AppColors {
  AppColors._();

  // ============= M3 SEED COLORS =============
  static const Color seed = Color(0xFF4F46E5); // Indigo Seed
  static const Color secondarySeed = Color(0xFF3B82F6); // Google Blue
  static const Color tertiarySeed = Color(0xFFEC4899); // Gemini Fuchsia/Pink

  // ============= SHARED ACCENT COLORS =============
  static const Color primary = Color(0xFF4F46E5); // Indigo Accent
  static const Color emeraldLight = Color(0xFF818CF8); // Soft Light Indigo
  static const Color emeraldDark = Color(0xFF312E81); // Deep Dark Indigo
  static const Color protein = Color(0xFF7C9A6D);
  static const Color carbs = Color(0xFF4F8CC9);
  static const Color fat = Color(0xFFD18B47);
  static const Color violet = Color(0xFF8B5CF6); // Vibrant Violet
  static const Color sky = Color(0xFF3B82F6); // Google Blue/Sky
  static const Color amber = Color(0xFFF59E0B); // Google Orange/Amber

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Gradients for "Expressive" depth - Google Gemini style
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF3B82F6), // Google Blue
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink/Magenta
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [
      Color(0xFF3B82F6), // Google Blue
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFFF59E0B), // Amber
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= DARK THEME OVERRIDES (Expressive Tones) =============
  static const Color darkBackground = Color(0xFF080B16); // Deep space navy/slate
  static const Color darkSurface = Color(0xFF0F1326); // Slightly lighter navy/slate
  static const Color darkCard = Color(0xFF161B36); // Card color
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA); // Neutral zinc grey

  // ============= LIGHT THEME OVERRIDES (Expressive Tones) =============
  static const Color lightBackground = Color(0xFFF4F6FB); // Cool light grey/blue
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Premium Wellness Glow
  static const LinearGradient wellnessGlow = LinearGradient(
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= MACRO GRADIENT FILLS =============
  static const LinearGradient proteinGradient = LinearGradient(
    colors: [Color(0xFF7C9A6D), Color(0xFFA3C293)],
  );
  static const LinearGradient carbsGradient = LinearGradient(
    colors: [Color(0xFF4F8CC9), Color(0xFF7AB4E8)],
  );
  static const LinearGradient fatGradient = LinearGradient(
    colors: [Color(0xFFD18B47), Color(0xFFE8B87A)],
  );
}
