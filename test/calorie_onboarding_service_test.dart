import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/calorie_onboarding_service.dart';

void main() {
  group('CalorieOnboardingService', () {
    const baseInput = OnboardingProfileInput(
      age: 28,
      gender: 'female',
      heightCm: 165,
      currentWeightKg: 78,
      goalWeightKg: 65,
      timelineMonths: 4,
      activityLevel: 'desk_life',
      weightUnit: 'kg',
      heightUnit: 'cm',
    );

    test('applies calorie floor for women', () async {
      final service = CalorieOnboardingService(
        aiBuilder: (p0, p1, p2, p3) async => null,
      );

      const input = OnboardingProfileInput(
        age: 32,
        gender: 'female',
        heightCm: 150,
        currentWeightKg: 52,
        goalWeightKg: 42,
        timelineMonths: 1,
        activityLevel: 'desk_life',
        weightUnit: 'kg',
        heightUnit: 'cm',
      );

      final result = await service.buildRecommendation(input);

      expect(result.dailyCalories, greaterThanOrEqualTo(1200));
      expect(result.safetyNote, isNotEmpty);
    });

    test('caps aggressive loss pace to about one kilogram per week', () async {
      final service = CalorieOnboardingService(
        aiBuilder: (p0, p1, p2, p3) async => null,
      );

      final result = await service.buildRecommendation(baseInput);

      expect(result.goalMode, 'cut');
      expect(result.paceAdjusted, isTrue);
      expect(result.weeklyRateKg, lessThanOrEqualTo(1.01));
      expect(result.safetyNote, isNotEmpty);
    });

    // Wazn is for 13 and over. Under 18 a weight-loss plan is held to the
    // gentle pace whatever was asked for, and counts as a minor's.
    test('holds a minor to the gentle pace', () {
      final plan = CalorieOnboardingService().computeBasePlan(
        const OnboardingProfileInput(
          age: 15,
          gender: 'male',
          heightCm: 172,
          currentWeightKg: 80,
          goalWeightKg: 70,
          timelineMonths: 3,
          activityLevel: 'active',
          weightUnit: 'kg',
          heightUnit: 'cm',
          selectedWeeklyRateKg: 0.75,
        ),
      );
      expect(plan.isMinor, isTrue);
      expect(plan.paceAdjusted, isTrue);
      expect(plan.weeklyRateKg, lessThanOrEqualTo(kMinorMaxWeeklyLossKg + 0.02));
    });

    test('leaves a minor already at the gentle pace alone', () {
      final plan = CalorieOnboardingService().computeBasePlan(
        const OnboardingProfileInput(
          age: 17,
          gender: 'female',
          heightCm: 165,
          currentWeightKg: 70,
          goalWeightKg: 64,
          timelineMonths: 6,
          activityLevel: 'light_mover',
          weightUnit: 'kg',
          heightUnit: 'cm',
          selectedWeeklyRateKg: 0.25,
        ),
      );
      expect(plan.isMinor, isTrue);
      expect(plan.paceAdjusted, isFalse);
      expect(plan.weeklyRateKg, 0.25);
    });

    test('an 18-year-old is not a minor', () {
      final plan = CalorieOnboardingService().computeBasePlan(
        baseInput.copyWithAge(18),
      );
      expect(plan.isMinor, isFalse);
    });

    test('caps bulk surplus at five hundred calories', () async {
      final service = CalorieOnboardingService(
        aiBuilder: (p0, p1, p2, p3) async => null,
      );

      const input = OnboardingProfileInput(
        age: 24,
        gender: 'male',
        heightCm: 182,
        currentWeightKg: 68,
        goalWeightKg: 85,
        timelineMonths: 1,
        activityLevel: 'active',
        weightUnit: 'kg',
        heightUnit: 'cm',
      );

      final result = await service.buildRecommendation(input);

      expect(result.goalMode, 'bulk');
      expect(result.dailyCalories - result.tdee, lessThanOrEqualTo(525));
      expect(result.paceAdjusted, isTrue);
    });

    test('uses AI copy when the builder returns content', () async {
      final service = CalorieOnboardingService(
        aiBuilder:
            (_, calories, mode, weeklyRate) async => {
              'insight': 'Target $calories kcal fits a $mode plan.',
              'tip':
                  'Weekly rate ${weeklyRate.toStringAsFixed(1)} kg stays manageable.',
            },
      );

      final result = await service.buildRecommendation(baseInput);

      expect(result.usedFallback, isFalse);
      expect(result.insight, contains('Target'));
      expect(result.tip, contains('Weekly rate'));
    });

    test('falls back when AI times out', () async {
      final service = CalorieOnboardingService(
        aiBuilder: (p0, p1, p2, p3) async {
          await Future<void>.delayed(const Duration(seconds: 5));
          return {'insight': 'late', 'tip': 'late'};
        },
      );

      final result = await service.buildRecommendation(baseInput);

      expect(result.usedFallback, isTrue);
      expect(result.insight, isNotEmpty);
      expect(result.tip, isNotEmpty);
    });
  });
}

extension on OnboardingProfileInput {
  OnboardingProfileInput copyWithAge(int age) => OnboardingProfileInput(
    age: age,
    gender: gender,
    heightCm: heightCm,
    currentWeightKg: currentWeightKg,
    goalWeightKg: goalWeightKg,
    timelineMonths: timelineMonths,
    activityLevel: activityLevel,
    weightUnit: weightUnit,
    heightUnit: heightUnit,
    selectedWeeklyRateKg: selectedWeeklyRateKg,
  );
}
