import 'package:flutter/material.dart';

/// SnapCal Color Palette - Dual Theme Support
class AppColors {
  AppColors._();

  // ============= SHARED ACCENT COLORS (Same in both themes) =============

  // Primary Accent
  static const Color primary = Color(0xFF4ADE80);
  static const Color primaryDark = Color(0xFF22C55E);

  // Macro Colors
  static const Color protein = Color(0xFFA78BFA);
  static const Color carbs = Color(0xFF60A5FA);
  static const Color fat = Color(0xFFFB923C);

  // Status Colors
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFBBF24);

  // Gradient for primary button
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= DARK THEME COLORS =============
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceLight = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextMuted = Color(0xFF71717A);
  static const Color darkGlassBackground = Color(0x1AFFFFFF); // 10% white
  static const Color darkGlassBorder = Color(0x1FFFFFFF); // 12% white

  // ============= LIGHT THEME COLORS =============
  static const Color lightBackground = Color(0xFFF8FAFC); // Soft off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightTextMuted = Color(0xFF94A3B8); // Slate 400
  static const Color lightGlassBackground = Color(0x1A000000); // 10% black
  static const Color lightGlassBorder = Color(0x1F000000); // 12% black

  // Premium Dark Gradient (dark mode only, used in specific places)
  static const LinearGradient premiumDarkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Premium Light Gradient (light mode only)
  static const LinearGradient premiumLightGradient = LinearGradient(
    colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
