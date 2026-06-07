class OnboardingConversions {
  OnboardingConversions._();

  static double kgToLb(double kg) => kg * 2.20462;

  static double lbToKg(double lb) => lb / 2.20462;

  static double cmToInch(double cm) => cm / 2.54;

  static double inchToCm(double inch) => inch * 2.54;

  static ({int feet, int inches}) cmToFtIn(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return (feet: feet, inches: inches);
  }

  static double ftInToCm(int feet, int inches) {
    return ((feet * 12) + inches) * 2.54;
  }

  static bool isValidPositiveNumber(String text) {
    return double.tryParse(text.trim()) != null;
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
