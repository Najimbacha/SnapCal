import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension on BuildContext to get theme-aware colors
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get surfaceLightColor =>
      isDarkMode ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight;

  // Text
  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;
  Color get textSecondaryColor =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textMutedColor =>
      isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  // Glass effects
  Color get glassBackgroundColor =>
      isDarkMode
          ? AppColors.darkGlassBackground
          : AppColors.lightGlassBackground;
  Color get glassBorderColor =>
      isDarkMode ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;

  // Gradients
  LinearGradient get premiumGradient =>
      isDarkMode
          ? AppColors.premiumDarkGradient
          : AppColors.premiumLightGradient;
}
