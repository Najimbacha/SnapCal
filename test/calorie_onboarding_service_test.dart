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
