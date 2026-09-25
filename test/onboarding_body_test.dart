import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/screens/onboarding/onboarding_body.dart';
import 'package:snapcal/screens/onboarding/onboarding_draft.dart';

void main() {
  group('BMI', () {
    test('matches the textbook value', () {
      expect(bmiOf(weightKg: 70, heightCm: 175), closeTo(22.86, 0.01));
    });

    test('bands split at 18.5, 25 and 30', () {
      expect(bmiBandOf(18.4), BmiBand.below);
      expect(bmiBandOf(18.5), BmiBand.healthy);
      expect(bmiBandOf(24.9), BmiBand.healthy);
      expect(bmiBandOf(25), BmiBand.above);
      expect(bmiBandOf(30), BmiBand.wellAbove);
    });

    test('the healthy range scales with height squared', () {
      final range = healthyWeightRangeKg(170);
      expect(range.low, closeTo(53.47, 0.01));
      expect(range.high, closeTo(71.96, 0.01));
    });
  });

  group('target check', () {
    TargetCheck check(GoalType goal, double current, double target) =>
        checkTarget(
          goal: goal,
          currentKg: current,
          targetKg: target,
          heightCm: 170,
        );

    test('weight loss needs a lower target, muscle a higher one', () {
      expect(check(GoalType.loseWeight, 75, 75).issue, TargetIssue.mustBeLower);
      expect(check(GoalType.loseWeight, 75, 80).issue, TargetIssue.mustBeLower);
      expect(
        check(GoalType.buildMuscle, 75, 70).issue,
        TargetIssue.mustBeHigher,
      );
    });

    test('a target below the healthy range is blocked', () {
      // 53.47 kg is BMI 18.5 at 170 cm.
      expect(check(GoalType.loseWeight, 70, 53).issue, TargetIssue.belowHealthy);
      expect(check(GoalType.loseWeight, 70, 54).isOk, isTrue);
    });

    test('someone already below the range gets no weight-loss target', () {
      expect(
        check(GoalType.loseWeight, 52, 50).issue,
        TargetIssue.alreadyBelowHealthy,
      );
    });

    test('a target more than half the body weight away is refused', () {
      expect(check(GoalType.buildMuscle, 60, 130).issue, TargetIssue.tooFar);
    });

    test('notes: healthy, a first milestone, or fine for muscle', () {
      expect(check(GoalType.loseWeight, 75, 68).note, TargetNote.healthy);
      expect(check(GoalType.loseWeight, 100, 90).note, TargetNote.milestone);
      expect(
        check(GoalType.buildMuscle, 72, 76).note,
        TargetNote.aboveHealthyForMuscle,
      );
    });
  });

  group('default target', () {
    test('a few kilos down, or up for muscle', () {
      expect(
        defaultTargetKg(goal: GoalType.loseWeight, currentKg: 70, heightCm: 170),
        66,
      );
      expect(
        defaultTargetKg(goal: GoalType.buildMuscle, currentKg: 70, heightCm: 170),
        73,
      );
    });

    test('never below the healthy range', () {
      final guess = defaultTargetKg(
        goal: GoalType.loseWeight,
        currentKg: 56,
        heightCm: 170,
      );
      expect(guess, 54);
      expect(
        checkTarget(
          goal: GoalType.loseWeight,
          currentKg: 56,
          targetKg: guess,
          heightCm: 170,
        ).isOk,
        isTrue,
      );
    });

    test('a tenth of body weight for someone well above the range', () {
      expect(
        defaultTargetKg(goal: GoalType.loseWeight, currentKg: 110, heightCm: 170),
        closeTo(99, 0.001),
      );
    });
  });

  group('teen rules', () {
    test('under 18 is a minor', () {
      expect(isMinorAge(13), isTrue);
      expect(isMinorAge(17), isTrue);
      expect(isMinorAge(18), isFalse);
    });

    test('only weight loss is limited to the gentle pace', () {
      expect(gentlePaceOnly(age: 15, goal: GoalType.loseWeight), isTrue);
      expect(gentlePaceOnly(age: 15, goal: GoalType.buildMuscle), isFalse);
      expect(gentlePaceOnly(age: 18, goal: GoalType.loseWeight), isFalse);
    });
  });

  group('finish date', () {
    test('counts whole days at the weekly rate', () {
      expect(daysToTarget(currentKg: 75, targetKg: 70, weeklyRateKg: 0.5), 70);
      expect(daysToTarget(currentKg: 75, targetKg: 75, weeklyRateKg: 0.5), isNull);
      expect(daysToTarget(currentKg: 75, targetKg: 70, weeklyRateKg: 0), isNull);
    });

    test('adds calendar days, across a month end', () {
      expect(dateAfterDays(DateTime(2026, 1, 30), 3), DateTime(2026, 2, 2));
    });
  });
}
