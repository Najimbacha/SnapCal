/// BMI, the healthy weight range and the target-weight rules the onboarding
/// screens show. Pure, like `plan_math.dart`, so it is tested without a
/// widget.
library;

import 'onboarding_draft.dart';
import 'onboarding_validation.dart';

/// The adult healthy BMI band.
const double kHealthyBmiLow = 18.5;
const double kHealthyBmiHigh = 24.9;

double bmiOf({required double weightKg, required double heightCm}) {
  final m = heightCm / 100;
  return weightKg / (m * m);
}

/// The weights, in kg, that put an adult of [heightCm] inside the healthy
/// band.
({double low, double high}) healthyWeightRangeKg(double heightCm) {
  final m2 = (heightCm / 100) * (heightCm / 100);
  return (low: kHealthyBmiLow * m2, high: kHealthyBmiHigh * m2);
}

enum BmiBand { below, healthy, above, wellAbove }

BmiBand bmiBandOf(double bmi) {
  if (bmi < kHealthyBmiLow) return BmiBand.below;
  if (bmi < 25) return BmiBand.healthy;
  if (bmi < 30) return BmiBand.above;
  return BmiBand.wellAbove;
}

bool isMinorAge(int age) => age < kAdultAge;

/// Under 18, a weight-loss plan runs at the gentle pace only.
bool gentlePaceOnly({required int age, required GoalType? goal}) =>
    isMinorAge(age) && goal == GoalType.loseWeight;

/// Why a target can't be used.
enum TargetIssue {
  mustBeLower,
  mustBeHigher,
  tooFar,

  /// Already below the healthy range: no weight-loss target is allowed.
  alreadyBelowHealthy,

  /// Below the healthy range for this height. Blocked, following the
  /// standard recommendation.
  belowHealthy,
}

/// What to say about a target that can be used.
enum TargetNote { healthy, milestone, aboveHealthyForMuscle }

class TargetCheck {
  const TargetCheck.issue(TargetIssue this.issue) : note = null;
  const TargetCheck.ok(TargetNote this.note) : issue = null;

  final TargetIssue? issue;
  final TargetNote? note;

  bool get isOk => issue == null;
}

TargetCheck checkTarget({
  required GoalType goal,
  required double currentKg,
  required double targetKg,
  required double heightCm,
}) {
  // A hair of tolerance, so a ruler that lands on the current weight
  // doesn't count as a direction.
  const epsilon = 0.05;
  if (goal == GoalType.loseWeight && targetKg >= currentKg - epsilon) {
    return const TargetCheck.issue(TargetIssue.mustBeLower);
  }
  if (goal == GoalType.buildMuscle && targetKg <= currentKg + epsilon) {
    return const TargetCheck.issue(TargetIssue.mustBeHigher);
  }
  final ratio = targetKg / currentKg;
  if (ratio < 0.5 || ratio > 2) {
    return const TargetCheck.issue(TargetIssue.tooFar);
  }
  final currentBmi = bmiOf(weightKg: currentKg, heightCm: heightCm);
  final targetBmi = bmiOf(weightKg: targetKg, heightCm: heightCm);
  if (goal == GoalType.loseWeight && currentBmi < kHealthyBmiLow) {
    return const TargetCheck.issue(TargetIssue.alreadyBelowHealthy);
  }
  if (targetBmi < kHealthyBmiLow) {
    return const TargetCheck.issue(TargetIssue.belowHealthy);
  }
  if (goal == GoalType.loseWeight && targetBmi >= 25) {
    return const TargetCheck.ok(TargetNote.milestone);
  }
  if (goal == GoalType.buildMuscle && targetBmi >= 25) {
    return const TargetCheck.ok(TargetNote.aboveHealthyForMuscle);
  }
  return const TargetCheck.ok(TargetNote.healthy);
}

/// A first guess at the target: a few kilos away, never below the healthy
/// range, and a tenth of body weight for someone well above it.
double defaultTargetKg({
  required GoalType goal,
  required double currentKg,
  required double heightCm,
}) {
  if (goal == GoalType.buildMuscle) return currentKg + 3;
  final range = healthyWeightRangeKg(heightCm);
  final guess =
      currentKg > range.high + 2
          ? (currentKg * 0.9 > range.high ? currentKg * 0.9 : range.high)
          : currentKg - 4;
  final floor = range.low.ceilToDouble();
  if (guess < floor) return floor < currentKg ? floor : currentKg;
  return guess;
}

/// Days from today to [targetKg] at [weeklyRateKg], or null when there is no
/// movement to count.
int? daysToTarget({
  required double currentKg,
  required double targetKg,
  required double weeklyRateKg,
}) {
  if (weeklyRateKg <= 0) return null;
  final delta = (targetKg - currentKg).abs();
  if (delta < 0.001) return null;
  return (delta / weeklyRateKg * 7).ceil();
}

/// [days] calendar days from [from], counted on the calendar rather than as
/// 24-hour spans (see `DateUtils.addDays`).
DateTime dateAfterDays(DateTime from, int days) =>
    DateTime(from.year, from.month, from.day + days);
