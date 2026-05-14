import 'package:flutter/material.dart';

/// SnapCal Color Palette - Material 3 Expressive
class AppColors {
  AppColors._();

  // ============= M3 SEED COLORS =============
  static const Color seed = Color(0xFF10B981); // Emerald Seed
  static const Color secondarySeed = Color(0xFF3B82F6); // Blue for variety
  static const Color tertiarySeed = Color(0xFFF59E0B); // Amber for flair

  // ============= SHARED ACCENT COLORS =============
  static const Color primary = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF6EE7B7);
  static const Color emeraldDark = Color(0xFF065F46);
  static const Color protein = Color(0xFF7C9A6D);
  static const Color carbs = Color(0xFF4F8CC9);
  static const Color fat = Color(0xFFD18B47);
  static const Color violet = Color(0xFF7C6FD6); // Muted, warmer — harmonizes with emerald
  static const Color sky = Color(0xFF0D9BD8); // Slightly warmer
  static const Color amber = Color(0xFFF59E0B);

  // Status Colors
  static const Color success = Color(0xFF22C997); // Brighter, shifted toward cyan — distinct from primary
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFBBF24);

  // Gradients for "Expressive" depth
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0D9BD8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0D9BD8), Color(0xFF7C6FD6)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= DARK THEME OVERRIDES (Expressive Tones) =============
  static const Color darkBackground = Color(0xFF09090B); // Deep zinc/charcoal (Apple-esque)
  static const Color darkSurface = Color(0xFF111113); // Subtle elevation
  static const Color darkCard = Color(0xFF161618); // Elevated card
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA); // Neutral zinc grey

  // ============= LIGHT THEME OVERRIDES (Expressive Tones) =============
  static const Color lightBackground = Color(0xFFF8F9FA); // Ultra-subtle pristine off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE5E7EB); // Neutral gray border
  static const Color lightTextPrimary = Color(0xFF0C1714);
  static const Color lightTextSecondary = Color(0xFF5B6D7E);

  // Premium Wellness Glow
  static const LinearGradient wellnessGlow = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
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
