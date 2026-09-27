import 'package:flutter/material.dart';

/// The colours of Wazn's one text field: a white box on the warm page with
/// a thin warm edge (a near-black box and a dark edge in dark mode).
@immutable
class AppFieldColors {
  const AppFieldColors({
    required this.fill,
    required this.line,
    required this.text,
    required this.label,
    required this.hint,
    required this.unit,
  });

  final Color fill;
  final Color line;
  final Color text;
  final Color label;
  final Color hint;
  final Color unit;

  static const light = AppFieldColors(
    fill: Color(0xFFFFFFFF),
    line: Color(0xFFE3DFD6),
    text: Color(0xFF1C1917),
    label: Color(0xFF5F5A53),
    hint: Color(0xFFAAA49C),
    unit: Color(0xFF8A857F),
  );

  static const dark = AppFieldColors(
    fill: Color(0xFF1A1A17),
    line: Color(0xFF302E29),
    text: Color(0xFFF5F5F4),
    label: Color(0xFFB6B0A8),
    hint: Color(0xFF6F6A63),
    unit: Color(0xFF8F8A83),
  );

  static AppFieldColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Corner radius shared by every field.
const double appFieldRadius = 14;

/// The field style every [TextField] in the app starts from, so a field
/// nobody styled by hand still looks like the rest.
InputDecorationTheme appInputDecorationTheme(ColorScheme scheme) {
  final c =
      scheme.brightness == Brightness.dark
          ? AppFieldColors.dark
          : AppFieldColors.light;
  OutlineInputBorder edge(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(appFieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecorationTheme(
    filled: true,
    fillColor: c.fill,
    isDense: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    hintStyle: TextStyle(
      color: c.hint,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    // Labels live above the box (see AppTextField). A field that still
    // passes labelText keeps it as a hint-sized line instead of a label
    // floating over the edge.
    floatingLabelBehavior: FloatingLabelBehavior.never,
    labelStyle: TextStyle(color: c.hint, fontSize: 16),
    suffixStyle: TextStyle(
      color: c.unit,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    prefixIconColor: c.unit,
    suffixIconColor: c.unit,
    errorStyle: TextStyle(color: scheme.error, fontSize: 12.5, height: 1.3),
    border: edge(c.line),
    enabledBorder: edge(c.line),
    disabledBorder: edge(c.line.withValues(alpha: 0.5)),
    focusedBorder: edge(scheme.primary, 1.5),
    errorBorder: edge(scheme.error),
    focusedErrorBorder: edge(scheme.error, 1.5),
  );
}
