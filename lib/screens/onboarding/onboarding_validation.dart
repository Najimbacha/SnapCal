import 'onboarding_draft.dart';

enum OnboardingValidationError {
  ageRange,
  heightRange,
  weightRange,
  targetRange,
  adultOnly,
  targetMustBeLower,
  targetMustBeHigher,
  targetExtreme,
}

class OnboardingValidation {
  OnboardingValidation._();

  static OnboardingValidationError? validateAge(int? age) {
    if (age == null) return null;
    if (age < 18) return OnboardingValidationError.adultOnly;
    if (age > 120) return OnboardingValidationError.ageRange;
    return null;
  }

  static OnboardingValidationError? validateHeightCm(double? heightCm) {
    if (heightCm == null) return null;
    if (heightCm < 50 || heightCm > 300) {
      return OnboardingValidationError.heightRange;
    }
    return null;
  }

  static OnboardingValidationError? validateWeightKg(double? weightKg) {
    if (weightKg == null) return null;
    if (weightKg < 20 || weightKg > 500) {
      return OnboardingValidationError.weightRange;
    }
    return null;
  }

  static OnboardingValidationError? validateTargetWeightKg(
    double? targetKg,
    double currentKg,
  ) {
    if (targetKg == null) return null;
    if (targetKg < 20 || targetKg > 500) {
      return OnboardingValidationError.targetRange;
    }
    final ratio = targetKg / currentKg;
    if (ratio < 0.5 || ratio > 2.0) {
      return OnboardingValidationError.targetExtreme;
    }
    return null;
  }

  static OnboardingValidationError? validateTargetDirection({
    required GoalType goal,
    required double currentWeightKg,
    required double targetWeightKg,
  }) {
    switch (goal) {
      case GoalType.loseWeight:
        if (targetWeightKg >= currentWeightKg) {
          return OnboardingValidationError.targetMustBeLower;
        }
      case GoalType.buildMuscle:
        if (targetWeightKg <= currentWeightKg) {
          return OnboardingValidationError.targetMustBeHigher;
        }
      case GoalType.maintainWeight:
      case GoalType.trackNutrition:
    }
    return null;
  }

  static bool isAllProfileValid({
    required int? age,
    required double? heightCm,
    required double? currentWeightKg,
  }) {
    return age != null &&
        heightCm != null &&
        currentWeightKg != null &&
        validateAge(age) == null &&
        validateHeightCm(heightCm) == null &&
        validateWeightKg(currentWeightKg) == null;
  }
}
