import 'package:flutter/material.dart';

import 'app_field_theme.dart';
import 'app_typography.dart';

/// The colours of Wazn's buttons that the colour scheme doesn't hold: the
/// warm grey of a button that isn't ready yet, and the quiet grey of a
/// Cancel.
@immutable
class AppButtonColors {
  const AppButtonColors({
    required this.off,
    required this.offText,
    required this.quiet,
  });

  final Color off;
  final Color offText;
  final Color quiet;

  static const light = AppButtonColors(
    off: Color(0xFFE9E6DF),
    offText: Color(0xFFA29D95),
    quiet: Color(0xFF5F5A53),
  );

  static const dark = AppButtonColors(
    off: Color(0xFF23221F),
    offText: Color(0xFF6F6A63),
    quiet: Color(0xFFB6B0A8),
  );

  static AppButtonColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static AppButtonColors forScheme(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark ? dark : light;
}

/// Height and corner radius of every full-size button; the corners match
/// the text fields.
const double appMinimumTapTarget = 48;
const double appButtonHeight = 52;
const double appButtonRadius = appFieldRadius;
const double appActionIconSize = 20;

TextStyle get _label => AppTypography.labelLarge.copyWith(
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

RoundedRectangleBorder get _shape => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(appButtonRadius),
);

/// The main button: the app's green with white text (mint with dark text
/// in dark mode), and warm grey while it can't be pressed yet.
ButtonStyle appPrimaryButtonStyle(ColorScheme scheme) {
  final c = AppButtonColors.forScheme(scheme);
  return FilledButton.styleFrom(
    backgroundColor: scheme.primary,
    foregroundColor: scheme.onPrimary,
    disabledBackgroundColor: c.off,
    disabledForegroundColor: c.offText,
    elevation: 0,
    minimumSize: const Size(64, appButtonHeight),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    textStyle: _label,
    shape: _shape,
    animationDuration: const Duration(milliseconds: 150),
  );
}

/// A second choice: the field's white box and edge, with green text.
ButtonStyle appSecondaryButtonStyle(ColorScheme scheme) {
  final f =
      scheme.brightness == Brightness.dark
          ? AppFieldColors.dark
          : AppFieldColors.light;
  final c = AppButtonColors.forScheme(scheme);
  return OutlinedButton.styleFrom(
    backgroundColor: f.fill,
    foregroundColor: scheme.primary,
    disabledForegroundColor: c.offText,
    side: BorderSide(color: f.line),
    elevation: 0,
    minimumSize: const Size(64, appButtonHeight),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    textStyle: _label,
    shape: _shape,
    animationDuration: const Duration(milliseconds: 150),
  );
}

/// Links and small actions: plain green text, still easy to tap.
ButtonStyle appTextButtonStyle(ColorScheme scheme) {
  final c = AppButtonColors.forScheme(scheme);
  return TextButton.styleFrom(
    foregroundColor: scheme.primary,
    disabledForegroundColor: c.offText,
    minimumSize: const Size.square(appMinimumTapTarget),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    textStyle: _label.copyWith(fontSize: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

/// Button styles every button in the app starts from.
FilledButtonThemeData appFilledButtonTheme(ColorScheme scheme) =>
    FilledButtonThemeData(style: appPrimaryButtonStyle(scheme));

ElevatedButtonThemeData appElevatedButtonTheme(ColorScheme scheme) =>
    ElevatedButtonThemeData(style: appPrimaryButtonStyle(scheme));

OutlinedButtonThemeData appOutlinedButtonTheme(ColorScheme scheme) =>
    OutlinedButtonThemeData(style: appSecondaryButtonStyle(scheme));

TextButtonThemeData appTextButtonTheme(ColorScheme scheme) =>
    TextButtonThemeData(style: appTextButtonStyle(scheme));

/// Compact visual icons inside a full Android/iOS-safe touch target.
IconButtonThemeData appIconButtonTheme(ColorScheme scheme) =>
    IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurface,
        iconSize: appActionIconSize,
        minimumSize: const Size.square(appMinimumTapTarget),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
