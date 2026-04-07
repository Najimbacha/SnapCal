import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension on BuildContext to get theme-aware colors
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get surfaceContainerColor => Theme.of(this).colorScheme.surfaceContainer;
  Color get cardColor => Theme.of(this).colorScheme.surfaceContainerLowest;
  Color get cardSoftColor => Theme.of(this).colorScheme.surfaceContainerHigh;
  
  Color get dividerColor => Theme.of(this).dividerColor;
  
  Color get overlayColor =>
      isDarkMode
          ? Colors.black.withValues(alpha: 0.32)
          : Colors.white.withValues(alpha: 0.72);

  // Text
  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;
  Color get textSecondaryColor => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get textMutedColor => Theme.of(this).colorScheme.outline;

  // Glass effects (Expressive M3 often uses tonal elevations instead of raw glass)
  Color get glassBackgroundColor => Theme.of(this).colorScheme.surfaceContainerHigh.withValues(alpha: 0.4);
  Color get glassBorderColor => Theme.of(this).colorScheme.outlineVariant;

  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Gradients
  LinearGradient get primaryGradient => AppColors.primaryGradient;
}
