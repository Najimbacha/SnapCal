import 'package:flutter/material.dart';

/// SnapCal Design System — Brand Colors
///
/// One unified visual identity: premium emerald green as the single brand
/// color, warm neutral surfaces, and semantic supporting colors only.
/// Every screen must draw its accents from this file (or ThemeData) —
/// never from inline hex literals.
class AppColors {
  AppColors._();

  // ============= BRAND — SNAPCAL EMERALD =============
  /// Seed for Material 3 ColorScheme generation (both themes).
  static const Color seed = Color(0xFF059669); // Emerald 600

  /// Vivid brand emerald. Reads well on dark surfaces; use via
  /// Theme.colorScheme.primary when a brightness-adaptive tone is needed.
  static const Color primary = Color(0xFF10B981); // Emerald 500

  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color emeraldLight = Color(0xFF6EE7B7); // Emerald 300
  static const Color emeraldDark = Color(0xFF064E3B); // Emerald 900

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF34D399), // Mint
      Color(0xFF059669), // Emerald
      Color(0xFF047857), // Deep emerald
    ],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft ambient glow for wellness surfaces.
  static const LinearGradient wellnessGlow = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= SEEDS (M3 tonal support roles) =============
  static const Color secondarySeed = Color(0xFF0F766E); // Teal
  static const Color tertiarySeed = Color(0xFFC88A32); // Warm gold

  // ============= SEMANTIC STATUS =============
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  // ============= MACROS (semantic, shared everywhere) =============
  static const Color protein = Color(0xFF7C9A6D); // Sage
  static const Color carbs = Color(0xFF4F8CC9); // Slate blue
  static const Color fat = Color(0xFFD18B47); // Amber ochre

  static const LinearGradient proteinGradient = LinearGradient(
    colors: [Color(0xFF7C9A6D), Color(0xFFA3C293)],
  );
  static const LinearGradient carbsGradient = LinearGradient(
    colors: [Color(0xFF4F8CC9), Color(0xFF7AB4E8)],
  );
  static const LinearGradient fatGradient = LinearGradient(
    colors: [Color(0xFFD18B47), Color(0xFFE8B87A)],
  );

  // ============= FUNCTIONAL MODULE ACCENTS =============
  /// Water/hydration keeps blue — it is a functional color, not decoration.
  static const Color sky = Color(0xFF3B82F6);
  static const Color skyLight = Color(0xFF60A5FA);
  static const Color vividBlue = Color(0xFF3B82F6);

  /// Premium/subscription identity (paywall, upsell) — deliberately distinct
  /// from the daily-use brand palette.
  static const Color secondary = Color(0xFF8B5CF6); // Violet
  static const Color violet = Color(0xFF8B5CF6);
  static const Color premiumGold = Color(0xFFC88A32);

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [
      Color(0xFF10B981), // Emerald
      Color(0xFF0F766E), // Teal
      Color(0xFFC88A32), // Gold
    ],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= NEUTRALS & SURFACES =============
  static const Color background = Color(0xFFF7F7F4); // Warm off-white
  static const Color neutralCoolSurface = Color(0xFFF7F7F4);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF16181D);
  static const Color textSecondary = Color(0xFF77776F);

  static const Color green = Color(0xFF3B6D11);
  static const Color greenLight = Color(0xFFE0F0D0);
  static const Color amber = Color(0xFFBA7517);
  static const Color amberLight = Color(0xFFFFF3E0);
  static const Color blue = Color(0xFF185FA5);
  static const Color blueLight = Color(0xFFE6F1FB);

  // Planner slot tints (emerald-washed neutrals)
  static const Color plannerBorder = Color(0xFFCFE9DC);
  static const Color slotNextBg = Color(0xFFEAF6F0);
  static const Color slotDoneBg = Color(0xFFF5FAF7);
  static const Color slotUpcomingBg = Color(0xFFF7F7F4);
  static const Color primaryContainer = Color(0xFFD7F0E4);

  // ============= DARK THEME OVERRIDES =============
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF000000);
  static const Color darkCard = Color(0xFF111111);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // ============= LIGHT THEME OVERRIDES =============
  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFAFAF8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE6E6E0);
  static const Color lightTextPrimary = Color(0xFF16181D);
  static const Color lightTextSecondary = Color(0xFF56565A);

  // ============= FEATURE ACCENTS (single source of truth) =============
  static const Color homeCoachAccent = Color(0xFF10B981);
  static const Color calories = Color(0xFF10B981);
  static const Color homePlannerAccent = Color(0xFF10B981);
  static const Color homePremiumBackground = Color(0xFF0E211A);

  // ============= WARM THEME COLORS =============
  static const Color warmDarkSurface = Color(0xFF1C1B1F);
  static const Color minimalBg = Color(0xFFFEFCF7);
  static const Color warmInk = Color(0xFF1C1917);

  // ============= DEEP INK (near-black neutrals) =============
  static const Color neutralDarkDeep = Color(0xFF141519);
  static const Color neutralDarkDeepAlt = Color(0xFF23252B);

  // ============= LEGACY / FOOD CARD COLORS =============
  static const Color legacyDeepForest = Color(0xFF1B4332);
  static const Color legacyGreenText = Color(0xFF40916C);
  static const Color oliveAccent = Color(0xFF7C9A6D);
  static const Color blueAccent = Color(0xFF4F8CC9);
  static const Color warmOrange = Color(0xFFD18B47);
}
