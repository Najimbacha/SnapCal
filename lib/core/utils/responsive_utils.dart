import 'package:flutter/material.dart';

/// Screen size categories for SnapCal
enum ScreenSize {
  small,    // Phones like Pixel 2, older small devices (< 380dp width)
  standard, // Modern mainstream phones (380-600dp width)
  tablet    // Large tablets and foldables (> 600dp width)
}

/// Utility for responsive calculations across the app
class Responsive {
  Responsive._();

  /// Detect the current screen size category
  static ScreenSize size(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 380) return ScreenSize.small;
    if (width > 600) return ScreenSize.tablet;
    return ScreenSize.standard;
  }

  /// Adaptive horizontal padding
  static double hPadding(BuildContext context) {
    final s = size(context);
    if (s == ScreenSize.small) return 16.0;
    if (s == ScreenSize.tablet) return 48.0;
    return 24.0;
  }

  /// Adaptive vertical padding
  static double vPadding(BuildContext context) {
    final s = size(context);
    if (s == ScreenSize.small) return 12.0;
    return 24.0;
  }

  /// Adaptive font scale factor
  static double fontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.85; // Slightly shrink for very narrow phones
    return 1.0;
  }

  /// Max width for content containers to ensure readability on large screens
  static double? maxWidth(BuildContext context) {
    if (size(context) == ScreenSize.tablet) return 600.0;
    return null;
  }

  /// Bottom nav bar height adjustment
  static double navBarHeight(BuildContext context) {
    if (size(context) == ScreenSize.small) return 72.0;
    return 80.0;
  }
}
