import 'package:flutter/material.dart';

/// SnapCal Color Palette - Dark Theme Only
class AppColors {
  AppColors._();

  // Base Colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2A2A2A);

  // Primary Accent
  static const Color primary = Color(0xFF4ADE80);
  static const Color primaryDark = Color(0xFF22C55E);

  // Macro Colors
  static const Color protein = Color(0xFFA78BFA);
  static const Color carbs = Color(0xFF60A5FA);
  static const Color fat = Color(0xFFFB923C);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

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

  // Glass effect color
  static const Color glassBackground = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% white

  // Premium Dark Gradient
  static const LinearGradient premiumDarkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Slate/Dark Blue tone
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
