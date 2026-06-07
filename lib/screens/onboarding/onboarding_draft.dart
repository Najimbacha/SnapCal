import 'package:flutter/foundation.dart';
import '../../data/services/calorie_onboarding_service.dart';

enum GoalType { loseWeight, maintainWeight, buildMuscle, trackNutrition }

enum MeasurementSystem { metric, imperial }

enum BiologicalSex { male, female }

enum Pace { gentle, balanced, faster }

enum ActivityLevel { mostlySitting, lightlyActive, active, veryActive }

extension GoalTypeAdapter on GoalType {
  double resolveGoalWeightKg({
    required double currentWeightKg,
    double? targetWeightKg,
  }) {
    switch (this) {
      case GoalType.loseWeight:
      case GoalType.buildMuscle:
        if (targetWeightKg == null) {
          throw StateError('Target weight is required for this goal.');
        }
        return targetWeightKg;
      case GoalType.maintainWeight:
      case GoalType.trackNutrition:
        return currentWeightKg;
    }
  }
}

extension ActivityLevelAdapter on ActivityLevel {
  String get serviceValue {
    switch (this) {
      case ActivityLevel.mostlySitting:
        return 'desk_life';
      case ActivityLevel.lightlyActive:
        return 'light_mover';
      case ActivityLevel.active:
        return 'active';
      case ActivityLevel.veryActive:
        return 'athlete';
    }
  }
}

extension BiologicalSexAdapter on BiologicalSex {
  String get serviceValue => this == BiologicalSex.male ? 'male' : 'female';
}

@immutable
class OnboardingDraft {
  final GoalType? goalType;
  final MeasurementSystem measurementSystem;
  final int? age;
  final BiologicalSex? sex;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final Pace? pace;
  final ActivityLevel? activityLevel;
  final OnboardingRecommendation? recommendation;

  const OnboardingDraft({
    this.goalType,
    this.measurementSystem = MeasurementSystem.metric,
    this.age,
    this.sex,
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
    this.pace,
    this.activityLevel,
    this.recommendation,
  });

  bool get hasValidRecommendation => recommendation != null;

  bool get needsPaceStep =>
      goalType == GoalType.loseWeight || goalType == GoalType.buildMuscle;

  bool get isComplete =>
      goalType != null &&
      age != null &&
      sex != null &&
      heightCm != null &&
      currentWeightKg != null &&
      (!needsPaceStep || (targetWeightKg != null && pace != null)) &&
      activityLevel != null &&
      hasValidRecommendation;

  double get effectiveGoalWeightKg {
    return goalType?.resolveGoalWeightKg(
          currentWeightKg: currentWeightKg ?? 0,
          targetWeightKg: targetWeightKg,
        ) ??
        (currentWeightKg ?? 0);
  }

  double get weightDeltaKg => effectiveGoalWeightKg - (currentWeightKg ?? 0);

  OnboardingDraft copyWith({
    GoalType? goalType,
    MeasurementSystem? measurementSystem,
    int? age,
    BiologicalSex? sex,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    Pace? pace,
    ActivityLevel? activityLevel,
    OnboardingRecommendation? recommendation,
    bool clearRecommendation = false,
    bool clearGoalType = false,
    bool clearAge = false,
    bool clearSex = false,
    bool clearHeightCm = false,
    bool clearCurrentWeightKg = false,
    bool clearTargetWeightKg = false,
    bool clearPace = false,
    bool clearActivityLevel = false,
  }) {
    return OnboardingDraft(
      goalType: clearGoalType ? null : (goalType ?? this.goalType),
      measurementSystem: measurementSystem ?? this.measurementSystem,
      age: clearAge ? null : (age ?? this.age),
      sex: clearSex ? null : (sex ?? this.sex),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      currentWeightKg:
          clearCurrentWeightKg
              ? null
              : (currentWeightKg ?? this.currentWeightKg),
      targetWeightKg:
          clearTargetWeightKg ? null : (targetWeightKg ?? this.targetWeightKg),
      pace: clearPace ? null : (pace ?? this.pace),
      activityLevel:
          clearActivityLevel ? null : (activityLevel ?? this.activityLevel),
      recommendation:
          clearRecommendation ? null : (recommendation ?? this.recommendation),
    );
  }
}
