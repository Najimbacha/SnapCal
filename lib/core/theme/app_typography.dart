import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SnapCal Typography - Expressive Material 3
class AppTypography {
  AppTypography._();

  static TextStyle get _font => GoogleFonts.plusJakartaSans();

  // Display - For large calorie numbers
  static TextStyle get displayLarge => _font.copyWith(
    fontSize: 57,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
  );

  static TextStyle get displayMedium => _font.copyWith(
    fontSize: 45,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
  );

  static TextStyle get displaySmall => _font.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w800,
  );

  // Headlines - For section titles
  static TextStyle get headlineLarge => _font.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => _font.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get headlineSmall => _font.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  // Titles - For cards and list items
  static TextStyle get titleLarge => _font.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleMedium => _font.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleSmall => _font.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Body - For general text
  static TextStyle get bodyLarge => _font.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _font.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static TextStyle get bodySmall => _font.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Labels - For small UI elements
  static TextStyle get labelLarge => _font.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get labelMedium => _font.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get labelSmall => _font.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  
  // Legacy aliases to avoid breaking existing code immediately
  static TextStyle get heading1 => headlineLarge;
  static TextStyle get heading2 => headlineMedium;
  static TextStyle get heading3 => headlineSmall;
  static TextStyle get button => labelLarge;
}
