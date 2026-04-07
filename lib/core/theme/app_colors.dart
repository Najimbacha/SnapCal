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
  static const Color protein = Color(0xFF7C9A6D);
  static const Color carbs = Color(0xFF4F8CC9);
  static const Color fat = Color(0xFFD18B47);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFBBF24);

  // Gradients for "Expressive" depth
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xffee3ae1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= DARK THEME OVERRIDES (Expressive Tones) =============
  static const Color darkBackground = Color(0xFF0F1713);
  static const Color darkSurface = Color(0xFF19221D);
  static const Color darkCard = Color(0xFF222C26);
  static const Color darkTextPrimary = Color(0xFFF1F5F3);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ============= LIGHT THEME OVERRIDES (Expressive Tones) =============
  static const Color lightBackground = Color(0xFFF8FAF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F171A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Premium Wellness Glow
  static const LinearGradient wellnessGlow = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
