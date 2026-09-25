class OnboardingConversions {
  OnboardingConversions._();

  static double kgToLb(double kg) => kg * 2.20462;

  static double lbToKg(double lb) => lb / 2.20462;

  static double cmToInch(double cm) => cm / 2.54;

  static double inchToCm(double inch) => inch * 2.54;

  /// Rounded to the nearest whole inch before splitting, so 182.5 cm is
  /// 6 ft 0 in and not "5 ft 12 in" -- rounding the remainder on its own
  /// could reach 12.
  static ({int feet, int inches}) cmToFtIn(double cm) {
    final totalInches = (cm / 2.54).round();
    return (feet: totalInches ~/ 12, inches: totalInches % 12);
  }

  static double ftInToCm(int feet, int inches) {
    return ((feet * 12) + inches) * 2.54;
  }

  static bool isValidPositiveNumber(String text) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite && value > 0;
  }

  static String formatWeightKgForDisplay(double kg) {
    final rounded = kg.round();
    return rounded.toString();
  }

  static String formatHeightCmForDisplay(double cm) {
    final rounded = cm.round();
    return rounded.toString();
  }
}
