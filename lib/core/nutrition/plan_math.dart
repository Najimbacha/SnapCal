/// The arithmetic that keeps a nutrition plan internally consistent.
///
/// Why this exists
/// ---------------
/// Calories and macros were two independent settings that described one plan.
/// `updateCalorieGoal` wrote only `dailyCalorieGoal`; the macro setters wrote
/// only their own field. Nothing reconciled them, so a user could sit at a
/// 2000 kcal goal with macros summing to 2500 kcal — and the "macro / calorie
/// split" card computed its percentages from the macros alone, so it drew a
/// tidy, confident bar that contradicted the number two rows above it. It had
/// no way to show the mismatch because it never saw the calorie goal.
///
/// Everything here is pure: no Flutter, no I/O, no providers. That is
/// deliberate — this is the part worth testing, and `flutter test` can cover
/// it completely.
library;

import 'dart:math' as math;

/// Energy per gram. Alcohol is deliberately absent: the app does not track it,
/// and pretending otherwise would make the totals lie.
const int kcalPerGramProtein = 4;
const int kcalPerGramCarb = 4;
const int kcalPerGramFat = 9;

/// Bounds for user-entered values.
///
/// These are guard rails against typos and fat fingers, not medical advice.
/// They are deliberately wide: a 1200 kcal cut and a 4500 kcal bulk are both
/// legitimate, and an app that refuses them is wrong more often than the user
/// is. What they stop is 1 kcal, age 500, and a height of 3.
class PlanLimits {
  const PlanLimits._();

  static const int minCalories = 800;
  static const int maxCalories = 6000;

  /// Ceiling for a macro the user types directly. 800g of anything is well
  /// past any real diet and catches a stray digit.
  static const int minMacroGrams = 0;
  static const int maxMacroGrams = 800;

  /// Ceiling for a macro the app computes. Higher than the typing limit on
  /// purpose: at [maxCalories] an all-carbohydrate plan needs 1500g, and a
  /// clamp that binds during rebalancing does not fail loudly — it returns a
  /// split that quietly misses the target. A random sweep found a carb-heavy
  /// profile scaled to 5636 kcal coming back as 3232 kcal, with nothing in the
  /// result saying so. This bound is chosen so it can never bind for any
  /// calorie value the app allows.
  static const int maxComputedMacroGrams = 1500;

  static const int minAge = 13;
  static const int maxAge = 100;

  static const double minHeightCm = 100;
  static const double maxHeightCm = 250;

  static const double minWeightKg = 30;
  static const double maxWeightKg = 300;
}

/// A protein/carb/fat split, in grams.
class MacroSplit {
  const MacroSplit({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int protein;
  final int carbs;
  final int fat;

  /// What these grams actually add up to.
  int get kcal =>
      protein * kcalPerGramProtein +
      carbs * kcalPerGramCarb +
      fat * kcalPerGramFat;

  /// Share of energy from each macro, as fractions summing to 1. Returns an
  /// even split when there is no energy to divide, so a chart drawn from this
  /// never has to handle division by zero itself.
  ({double protein, double carbs, double fat}) get shares {
    final total = kcal;
    if (total <= 0) {
      return (protein: 1 / 3, carbs: 1 / 3, fat: 1 / 3);
    }
    return (
      protein: protein * kcalPerGramProtein / total,
      carbs: carbs * kcalPerGramCarb / total,
      fat: fat * kcalPerGramFat / total,
    );
  }

  MacroSplit copyWith({int? protein, int? carbs, int? fat}) => MacroSplit(
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
  );

  @override
  String toString() => 'MacroSplit(p:$protein, c:$carbs, f:$fat, ${kcal}kcal)';

  @override
  bool operator ==(Object other) =>
      other is MacroSplit &&
      other.protein == protein &&
      other.carbs == carbs &&
      other.fat == fat;

  @override
  int get hashCode => Object.hash(protein, carbs, fat);
}

/// How far macros may drift from the calorie goal before the UI should say so.
///
/// Grams are whole numbers and carbohydrate moves in steps of 4 kcal, so an
/// exact match is not always reachable. Anything inside this window is
/// rounding, not disagreement.
const int kMacroCalorieTolerance = 12;

/// A sensible starting split when there is nothing to preserve: 30% protein,
/// 40% carbohydrate, 30% fat. Used only when existing macros carry no
/// information — a fresh profile, or all three sitting at zero.
const _defaultProteinShare = 0.30;
const _defaultCarbShare = 0.40;

/// Scales [current] to hit [targetCalories] while holding its shape.
///
/// The user's ratio is the thing worth preserving: someone eating 40% protein
/// chose that, and a calorie change should not quietly turn them into a
/// balanced eater. So every macro moves by the same factor.
///
/// Rounding is absorbed by carbohydrate, which is the macro people are least
/// attached to at the gram level, and only after protein and fat have been
/// rounded normally. Where the remainder is not divisible by 4 kcal a residue
/// of up to 3 kcal survives; [kMacroCalorieTolerance] is what treats that as
/// agreement rather than error.
MacroSplit rebalanceToCalories({
  required MacroSplit current,
  required int targetCalories,
}) {
  final target = targetCalories.clamp(
    PlanLimits.minCalories,
    PlanLimits.maxCalories,
  );

  final currentKcal = current.kcal;

  if (currentKcal <= 0) {
    return splitForCalories(target);
  }

  final factor = target / currentKcal;

  var protein = (current.protein * factor).round();
  var fat = (current.fat * factor).round();
  var carbs = (current.carbs * factor).round();

  protein = protein.clamp(
    PlanLimits.minMacroGrams,
    PlanLimits.maxComputedMacroGrams,
  );
  fat = fat.clamp(PlanLimits.minMacroGrams, PlanLimits.maxComputedMacroGrams);

  // Absorb whatever the rounding left over into carbohydrate.
  final withoutCarbs = protein * kcalPerGramProtein + fat * kcalPerGramFat;
  carbs = ((target - withoutCarbs) / kcalPerGramCarb).round();
  carbs = carbs.clamp(
    PlanLimits.minMacroGrams,
    PlanLimits.maxComputedMacroGrams,
  );

  return MacroSplit(protein: protein, carbs: carbs, fat: fat);
}

/// A default split for [calories], used when there is no existing shape to
/// preserve.
MacroSplit splitForCalories(int calories) {
  final target = calories.clamp(
    PlanLimits.minCalories,
    PlanLimits.maxCalories,
  );

  final protein = (target * _defaultProteinShare / kcalPerGramProtein).round();
  final fat =
      (target * (1 - _defaultProteinShare - _defaultCarbShare) /
              kcalPerGramFat)
          .round();
  final carbs =
      ((target - protein * kcalPerGramProtein - fat * kcalPerGramFat) /
              kcalPerGramCarb)
          .round();

  return MacroSplit(
    protein: math.max(0, protein),
    carbs: math.max(0, carbs),
    fat: math.max(0, fat),
  );
}

/// Whether [split] and [calories] describe the same plan.
bool macrosAgreeWithCalories(MacroSplit split, int calories) =>
    (split.kcal - calories).abs() <= kMacroCalorieTolerance;

/// Signed difference between what the macros hold and the calorie goal.
/// Positive means the macros exceed the goal.
int macroCalorieDrift(MacroSplit split, int calories) => split.kcal - calories;

/// Outcome of validating a user-entered number.
class PlanValidation {
  const PlanValidation.ok() : min = null, max = null, isValid = true;
  const PlanValidation.outOfRange({required this.min, required this.max})
    : isValid = false;

  final bool isValid;
  final num? min;
  final num? max;
}

PlanValidation validateCalories(int value) =>
    value >= PlanLimits.minCalories && value <= PlanLimits.maxCalories
        ? const PlanValidation.ok()
        : const PlanValidation.outOfRange(
          min: PlanLimits.minCalories,
          max: PlanLimits.maxCalories,
        );

PlanValidation validateMacroGrams(int value) =>
    value >= PlanLimits.minMacroGrams && value <= PlanLimits.maxMacroGrams
        ? const PlanValidation.ok()
        : const PlanValidation.outOfRange(
          min: PlanLimits.minMacroGrams,
          max: PlanLimits.maxMacroGrams,
        );

PlanValidation validateAge(int value) =>
    value >= PlanLimits.minAge && value <= PlanLimits.maxAge
        ? const PlanValidation.ok()
        : const PlanValidation.outOfRange(
          min: PlanLimits.minAge,
          max: PlanLimits.maxAge,
        );

PlanValidation validateHeightCm(double value) =>
    value >= PlanLimits.minHeightCm && value <= PlanLimits.maxHeightCm
        ? const PlanValidation.ok()
        : const PlanValidation.outOfRange(
          min: PlanLimits.minHeightCm,
          max: PlanLimits.maxHeightCm,
        );

PlanValidation validateWeightKg(double value) =>
    value >= PlanLimits.minWeightKg && value <= PlanLimits.maxWeightKg
        ? const PlanValidation.ok()
        : const PlanValidation.outOfRange(
          min: PlanLimits.minWeightKg,
          max: PlanLimits.maxWeightKg,
        );
