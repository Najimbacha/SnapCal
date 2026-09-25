import '../../l10n/generated/app_localizations.dart';
import 'onboarding_conversions.dart';
import 'onboarding_draft.dart';

/// Weights are kept in kg; these show them in whichever unit was picked.
double kgToDisplay(double kg, MeasurementSystem system) =>
    system == MeasurementSystem.imperial
        ? OnboardingConversions.kgToLb(kg)
        : kg;

double displayToKg(double value, MeasurementSystem system) =>
    system == MeasurementSystem.imperial
        ? OnboardingConversions.lbToKg(value)
        : value;

String weightUnitLabel(AppLocalizations l10n, MeasurementSystem system) =>
    system == MeasurementSystem.imperial
        ? l10n.settings_unit_lb
        : l10n.settings_unit_kg;

String formatWeight(
  AppLocalizations l10n,
  double kg,
  MeasurementSystem system, {
  int decimals = 1,
}) =>
    '${kgToDisplay(kg, system).toStringAsFixed(decimals)} '
    '${weightUnitLabel(l10n, system)}';

/// 69 inches as 5′9″.
String formatFeetInches(int inches) => '${inches ~/ 12}′${inches % 12}″';

/// The weight ruler's scale in [system]: 0.1 steps, a label every whole
/// unit.
({double min, double max}) weightRulerRange(MeasurementSystem system) =>
    system == MeasurementSystem.imperial
        ? (min: 66.0, max: 550.0)
        : (min: 30.0, max: 250.0);

/// The height ruler's scale: centimetres, or inches from 4′0″ to 7′6″.
({double min, double max}) heightRulerRange(MeasurementSystem system) =>
    system == MeasurementSystem.imperial
        ? (min: 48.0, max: 90.0)
        : (min: 120.0, max: 220.0);

/// A weight in [system], rounded to the ruler's 0.1 step.
double weightOnRuler(double kg, MeasurementSystem system) {
  final range = weightRulerRange(system);
  final shown = (kgToDisplay(kg, system) * 10).round() / 10;
  return shown.clamp(range.min, range.max).toDouble();
}

/// A height in [system], rounded to the ruler's whole-unit step.
double heightOnRuler(double cm, MeasurementSystem system) {
  final range = heightRulerRange(system);
  final shown =
      system == MeasurementSystem.imperial
          ? OnboardingConversions.cmToInch(cm).roundToDouble()
          : cm.roundToDouble();
  return shown.clamp(range.min, range.max).toDouble();
}
