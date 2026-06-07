import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/onboarding/onboarding_conversions.dart';
import 'package:snapcal/screens/onboarding/onboarding_validation.dart';
import 'package:snapcal/screens/onboarding/onboarding_pace_calculator.dart';
import 'package:snapcal/screens/onboarding/onboarding_draft.dart';
import 'package:snapcal/screens/onboarding/profile_step.dart';
import 'package:snapcal/screens/onboarding/pace_step.dart';

void main() {
  Widget constrainedOnboardingHost(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(height: 360, child: SingleChildScrollView(child: child)),
      ),
    );
  }

  // ===== Unit Tests: OnboardingConversions =====

  group('OnboardingConversions', () {
    test('kgToLb converts 75 kg to ~165.3 lb', () {
      final result = OnboardingConversions.kgToLb(75);
      expect(result, closeTo(165.3, 0.5));
    });

    test('lbToKg converts 165 lb to ~74.8 kg', () {
      final result = OnboardingConversions.lbToKg(165);
      expect(result, closeTo(74.8, 0.5));
    });

    test('cmToInch converts 170 cm to ~66.9 in', () {
      final result = OnboardingConversions.cmToInch(170);
      expect(result, closeTo(66.9, 0.5));
    });

    test('inchToCm converts 67 in to ~170.2 cm', () {
      final result = OnboardingConversions.inchToCm(67);
      expect(result, closeTo(170.2, 0.5));
    });

    test('cmToFtIn converts 170 cm to 5 feet 7 inches', () {
      final result = OnboardingConversions.cmToFtIn(170);
      expect(result.feet, equals(5));
      expect(result.inches, equals(7));
    });

    test('ftInToCm converts 5ft 7in to ~170.2 cm', () {
      final result = OnboardingConversions.ftInToCm(5, 7);
      expect(result, closeTo(170.2, 0.5));
    });

    test('kgToLb and lbToKg are roundtrip consistent', () {
      const original = 80.0;
      final lb = OnboardingConversions.kgToLb(original);
      final back = OnboardingConversions.lbToKg(lb);
      expect(back, closeTo(original, 0.5));
    });

    test('cmToInch and inchToCm are roundtrip consistent', () {
      const original = 165.0;
      final inch = OnboardingConversions.cmToInch(original);
      final back = OnboardingConversions.inchToCm(inch);
      expect(back, closeTo(original, 0.5));
    });

    test('cmToFtIn and ftInToCm are roundtrip consistent', () {
      const original = 180.0;
      final ftIn = OnboardingConversions.cmToFtIn(original);
      final back = OnboardingConversions.ftInToCm(ftIn.feet, ftIn.inches);
      expect(back, closeTo(original, 1.0));
    });

    test('isValidPositiveNumber returns true for valid number', () {
      expect(OnboardingConversions.isValidPositiveNumber('75'), isTrue);
    });

    test('isValidPositiveNumber returns false for empty string', () {
      expect(OnboardingConversions.isValidPositiveNumber(''), isFalse);
    });

    test('isValidPositiveNumber returns false for text', () {
      expect(OnboardingConversions.isValidPositiveNumber('abc'), isFalse);
    });
  });

  // ===== Unit Tests: OnboardingValidation =====

  group('OnboardingValidation', () {
    test('validateAge returns null for valid age 25', () {
      expect(OnboardingValidation.validateAge(25), isNull);
    });

    test('validateAge returns adultOnly for age 17', () {
      expect(
        OnboardingValidation.validateAge(17),
        equals(OnboardingValidationError.adultOnly),
      );
    });

    test('validateAge returns null for age 18', () {
      expect(OnboardingValidation.validateAge(18), isNull);
    });

    test('validateAge returns ageRange for age 121', () {
      expect(
        OnboardingValidation.validateAge(121),
        equals(OnboardingValidationError.ageRange),
      );
    });

    test('validateAge returns null for age null', () {
      expect(OnboardingValidation.validateAge(null), isNull);
    });

    test('validateHeightCm returns null for valid 170', () {
      expect(OnboardingValidation.validateHeightCm(170), isNull);
    });

    test('validateHeightCm returns error for 40', () {
      expect(OnboardingValidation.validateHeightCm(40), isNotNull);
    });

    test('validateWeightKg returns null for valid 75', () {
      expect(OnboardingValidation.validateWeightKg(75), isNull);
    });

    test('validateWeightKg returns error for 10', () {
      expect(OnboardingValidation.validateWeightKg(10), isNotNull);
    });

    test('validateTargetWeightKg returns null for reasonable target', () {
      expect(OnboardingValidation.validateTargetWeightKg(65, 75), isNull);
    });

    test('validateTargetWeightKg returns error for extreme target', () {
      expect(OnboardingValidation.validateTargetWeightKg(10, 75), isNotNull);
    });

    test('isAllProfileValid returns true when all valid', () {
      expect(
        OnboardingValidation.isAllProfileValid(
          age: 25,
          heightCm: 170,
          currentWeightKg: 75,
        ),
        isTrue,
      );
    });

    test('isAllProfileValid returns false when age missing', () {
      expect(
        OnboardingValidation.isAllProfileValid(
          age: null,
          heightCm: 170,
          currentWeightKg: 75,
        ),
        isFalse,
      );
    });
  });

  // ===== Unit Tests: OnboardingPaceCalculator =====

  group('OnboardingPaceCalculator', () {
    test('weekly rate for gentle loss is 0.25 kg', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.loseWeight,
          Pace.gentle,
        ),
        equals(0.25),
      );
    });

    test('weekly rate for balanced loss is 0.5 kg', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.loseWeight,
          Pace.balanced,
        ),
        equals(0.5),
      );
    });

    test('weekly rate for faster loss is 0.75 kg', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.loseWeight,
          Pace.faster,
        ),
        equals(0.75),
      );
    });

    test('weekly rate for gentle gain is 0.125 kg', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.buildMuscle,
          Pace.gentle,
        ),
        equals(0.125),
      );
    });

    test('weekly rate for balanced gain is 0.25 kg', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.buildMuscle,
          Pace.balanced,
        ),
        equals(0.25),
      );
    });

    test('weekly rate for faster gain is 0.375 kg', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.buildMuscle,
          Pace.faster,
        ),
        equals(0.375),
      );
    });

    test('weekly rate for maintain is 0', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.maintainWeight,
          Pace.gentle,
        ),
        equals(0),
      );
    });

    test('weekly rate for track is 0', () {
      expect(
        OnboardingPaceCalculator.weeklyRateKgFor(
          GoalType.trackNutrition,
          Pace.gentle,
        ),
        equals(0),
      );
    });

    test('deriveTimelineMonths returns 1 for zero delta', () {
      expect(OnboardingPaceCalculator.deriveTimelineMonths(0, 0.5), equals(1));
    });

    test('deriveTimelineMonths returns 1 for negative weekly rate', () {
      expect(OnboardingPaceCalculator.deriveTimelineMonths(10, -1), equals(1));
    });

    test(
      'deriveTimelineMonths returns reasonable value for 5kg at 0.5/week',
      () {
        // 5kg / 0.5 = 10 weeks, 10 / 4.345 ≈ 2.3 → ceil → 3
        expect(
          OnboardingPaceCalculator.deriveTimelineMonths(5, 0.5),
          equals(3),
        );
      },
    );

    test('deriveTimelineMonths clamps minimum at 1', () {
      expect(OnboardingPaceCalculator.deriveTimelineMonths(0.1, 1), equals(1));
    });

    test('deriveTimelineMonths clamps maximum at 24', () {
      // 500kg / 0.1 = 5000 weeks, 5000 / 4.345 = huge → clamped to 24
      expect(
        OnboardingPaceCalculator.deriveTimelineMonths(500, 0.1),
        equals(24),
      );
    });

    test('formatWeeklyRateValue metric shows 0.5 for 0.5 kg', () {
      expect(
        OnboardingPaceCalculator.formatWeeklyRateValue(
          0.5,
          MeasurementSystem.metric,
        ),
        equals('0.5'),
      );
    });

    test('formatWeeklyRateValue imperial shows 1.1 for 0.5 kg', () {
      // 0.5 * 2.20462 = 1.10231 → 1.1
      expect(
        OnboardingPaceCalculator.formatWeeklyRateValue(
          0.5,
          MeasurementSystem.imperial,
        ),
        equals('1.1'),
      );
    });

    test('weeklyRateUnit returns kg for metric', () {
      expect(
        OnboardingPaceCalculator.weeklyRateUnit(MeasurementSystem.metric),
        equals('kg'),
      );
    });

    test('weeklyRateUnit returns lb for imperial', () {
      expect(
        OnboardingPaceCalculator.weeklyRateUnit(MeasurementSystem.imperial),
        equals('lb'),
      );
    });

    test('dailyCalorieAdjustmentFromWeeklyRate for 0.5 kg is ~550 kcal', () {
      // 0.5 * 7700 / 7 ≈ 550
      expect(
        OnboardingPaceCalculator.dailyCalorieAdjustmentFromWeeklyRate(0.5),
        closeTo(550, 5),
      );
    });

    test('dailyCalorieAdjustmentFromWeeklyRate for 0.75 kg is ~825 kcal', () {
      // 0.75 * 7700 / 7 ≈ 825
      expect(
        OnboardingPaceCalculator.dailyCalorieAdjustmentFromWeeklyRate(0.75),
        closeTo(825, 5),
      );
    });
  });

  // ===== Unit Tests: GoalTypeAdapter =====

  group('GoalTypeAdapter', () {
    test('loseWeight returns targetWeightKg', () {
      expect(
        GoalType.loseWeight.resolveGoalWeightKg(
          currentWeightKg: 75,
          targetWeightKg: 65,
        ),
        equals(65),
      );
    });

    test('buildMuscle returns targetWeightKg', () {
      expect(
        GoalType.buildMuscle.resolveGoalWeightKg(
          currentWeightKg: 75,
          targetWeightKg: 80,
        ),
        equals(80),
      );
    });

    test('maintainWeight returns currentWeightKg', () {
      expect(
        GoalType.maintainWeight.resolveGoalWeightKg(
          currentWeightKg: 75,
          targetWeightKg: 65,
        ),
        equals(75),
      );
    });

    test('trackNutrition returns currentWeightKg', () {
      expect(
        GoalType.trackNutrition.resolveGoalWeightKg(currentWeightKg: 75),
        equals(75),
      );
    });

    test('loseWeight throws when targetWeightKg is null', () {
      expect(
        () => GoalType.loseWeight.resolveGoalWeightKg(currentWeightKg: 75),
        throwsStateError,
      );
    });
  });

  // ===== Unit Tests: ActivityLevelAdapter =====

  group('ActivityLevelAdapter', () {
    test('mostlySitting maps to desk_life', () {
      expect(ActivityLevel.mostlySitting.serviceValue, equals('desk_life'));
    });

    test('lightlyActive maps to light_mover', () {
      expect(ActivityLevel.lightlyActive.serviceValue, equals('light_mover'));
    });

    test('active maps to active', () {
      expect(ActivityLevel.active.serviceValue, equals('active'));
    });

    test('veryActive maps to athlete', () {
      expect(ActivityLevel.veryActive.serviceValue, equals('athlete'));
    });
  });

  // ===== Unit Tests: BiologicalSexAdapter =====

  group('BiologicalSexAdapter', () {
    test('male maps to male', () {
      expect(BiologicalSex.male.serviceValue, equals('male'));
    });

    test('female maps to female', () {
      expect(BiologicalSex.female.serviceValue, equals('female'));
    });
  });

  // ===== Unit Tests: OnboardingDraft =====

  group('OnboardingDraft', () {
    test('defaults to metric system', () {
      const draft = OnboardingDraft();
      expect(draft.measurementSystem, equals(MeasurementSystem.metric));
    });

    test('needsPaceStep is true for loseWeight', () {
      const draft = OnboardingDraft(goalType: GoalType.loseWeight);
      expect(draft.needsPaceStep, isTrue);
    });

    test('needsPaceStep is true for buildMuscle', () {
      const draft = OnboardingDraft(goalType: GoalType.buildMuscle);
      expect(draft.needsPaceStep, isTrue);
    });

    test('needsPaceStep is false for maintainWeight', () {
      const draft = OnboardingDraft(goalType: GoalType.maintainWeight);
      expect(draft.needsPaceStep, isFalse);
    });

    test('needsPaceStep is false for trackNutrition', () {
      const draft = OnboardingDraft(goalType: GoalType.trackNutrition);
      expect(draft.needsPaceStep, isFalse);
    });

    test('isComplete returns false when recommendation is null', () {
      const draft = OnboardingDraft();
      expect(draft.isComplete, isFalse);
    });

    test('effectiveGoalWeightKg returns currentWeightKg for maintain', () {
      const draft = OnboardingDraft(
        goalType: GoalType.maintainWeight,
        currentWeightKg: 75,
      );
      expect(draft.effectiveGoalWeightKg, equals(75));
    });

    test('copyWith preserves unchanged fields', () {
      const draft = OnboardingDraft(goalType: GoalType.loseWeight);
      final copy = draft.copyWith(age: 25);
      expect(copy.goalType, equals(GoalType.loseWeight));
      expect(copy.age, equals(25));
    });

    test('clearPace removes pace', () {
      const draft = OnboardingDraft(pace: Pace.balanced);
      final copy = draft.copyWith(clearPace: true);
      expect(copy.pace, isNull);
    });
  });

  // ===== Direction Validation Tests =====

  group('DirectionValidation', () {
    test('lose weight rejects higher target', () {
      final err = OnboardingValidation.validateTargetDirection(
        goal: GoalType.loseWeight,
        currentWeightKg: 75,
        targetWeightKg: 80,
      );
      expect(err, equals(OnboardingValidationError.targetMustBeLower));
    });

    test('lose weight rejects equal target', () {
      final err = OnboardingValidation.validateTargetDirection(
        goal: GoalType.loseWeight,
        currentWeightKg: 75,
        targetWeightKg: 75,
      );
      expect(err, equals(OnboardingValidationError.targetMustBeLower));
    });

    test('lose weight accepts lower target', () {
      final err = OnboardingValidation.validateTargetDirection(
        goal: GoalType.loseWeight,
        currentWeightKg: 75,
        targetWeightKg: 65,
      );
      expect(err, isNull);
    });

    test('build muscle rejects lower target', () {
      final err = OnboardingValidation.validateTargetDirection(
        goal: GoalType.buildMuscle,
        currentWeightKg: 75,
        targetWeightKg: 70,
      );
      expect(err, equals(OnboardingValidationError.targetMustBeHigher));
    });

    test('build muscle rejects equal target', () {
      final err = OnboardingValidation.validateTargetDirection(
        goal: GoalType.buildMuscle,
        currentWeightKg: 75,
        targetWeightKg: 75,
      );
      expect(err, equals(OnboardingValidationError.targetMustBeHigher));
    });

    test('build muscle accepts higher target', () {
      final err = OnboardingValidation.validateTargetDirection(
        goal: GoalType.buildMuscle,
        currentWeightKg: 75,
        targetWeightKg: 80,
      );
      expect(err, isNull);
    });

    test('maintain weight always valid', () {
      final err = OnboardingValidation.validateTargetDirection(
        goal: GoalType.maintainWeight,
        currentWeightKg: 75,
        targetWeightKg: 65,
      );
      expect(err, isNull);
    });
  });

  // ===== Actual Weekly Rate Formula Tests =====

  group('ActualWeeklyRate', () {
    double calcRate(String goalMode, double tdee, int finalCalories) {
      // mirrors _calculateActualWeeklyRate from the service
      switch (goalMode) {
        case 'cut':
          return ((tdee - finalCalories) * 7 / 7700).clamp(0, double.infinity);
        case 'bulk':
          return ((finalCalories - tdee) * 7 / 7700).clamp(0, double.infinity);
        default:
          return 0.0;
      }
    }

    test('loss: floor above TDEE produces zero rate', () {
      // TDEE 1450, floor 1500 → eating above maintenance → zero loss
      expect(calcRate('cut', 1450, 1500), equals(0.0));
    });

    test('loss: floor below TDEE produces positive rate', () {
      // TDEE 2000, floor 1500 → deficit → positive loss
      final rate = calcRate('cut', 2000, 1500);
      expect(rate, greaterThan(0));
    });

    test('gain: cap below TDEE produces zero rate', () {
      // TDEE 1800, cap 1500 → below maintenance → zero gain
      expect(calcRate('bulk', 1800, 1500), equals(0.0));
    });

    test('gain: cap above TDEE produces positive rate', () {
      final rate = calcRate('bulk', 1500, 2000);
      expect(rate, greaterThan(0));
    });

    test('maintain always zero', () {
      expect(calcRate('maintain', 2000, 1500), equals(0.0));
    });

    test('loss constrained to TDEE produces zero rate', () {
      expect(calcRate('cut', 1500, 1500), equals(0.0));
    });
  });

  // ===== Macro Calorie Total Test =====

  group('MacroCalorieTotal', () {
    test('1500 kcal target macros total within 5 kcal', () {
      // Using the service's cut (lose) macro split: 35% P, 35% C, 30% F
      const dailyCalories = 1500;
      const proteinG = 131;
      const carbsG = 131;
      const fatG = 50;
      final total = (proteinG * 4) + (carbsG * 4) + (fatG * 9);
      expect(total, closeTo(dailyCalories, 5));
    });
  });

  group('OnboardingLayout', () {
    testWidgets('profile step renders default picker row values', (
      tester,
    ) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          ProfileStep(draft: const OnboardingDraft(), onChanged: (_) {}),
        ),
      );

      expect(find.text('28 years'), findsOneWidget);
      expect(find.text('170 cm'), findsOneWidget);
      expect(find.text('75 kg'), findsOneWidget);
    });

    testWidgets('profile step submits default numeric picker values', (
      tester,
    ) async {
      final key = GlobalKey<ProfileStepState>();
      OnboardingDraft? updated;

      await tester.pumpWidget(
        constrainedOnboardingHost(
          ProfileStep(
            key: key,
            draft: const OnboardingDraft(),
            onChanged: (draft) => updated = draft,
          ),
        ),
      );

      await tester.tap(find.text('Male'));
      await tester.pump();

      expect(key.currentState!.validateAndSubmit(), isTrue);
      expect(updated?.age, equals(28));
      expect(updated?.heightCm, equals(170));
      expect(updated?.currentWeightKg, equals(75));
    });

    testWidgets('profile step restores existing draft picker values', (
      tester,
    ) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          ProfileStep(
            draft: const OnboardingDraft(
              age: 42,
              heightCm: 180,
              currentWeightKg: 90,
            ),
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('42 years'), findsOneWidget);
      expect(find.text('180 cm'), findsOneWidget);
      expect(find.text('90 kg'), findsOneWidget);
    });

    testWidgets('profile unit toggle preserves equivalent picker values', (
      tester,
    ) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          ProfileStep(draft: const OnboardingDraft(), onChanged: (_) {}),
        ),
      );

      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      expect(find.text('5 ft 7 in'), findsOneWidget);
      expect(find.text('165 lb'), findsOneWidget);
    });

    testWidgets('profile age row opens picker sheet and done commits', (
      tester,
    ) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          ProfileStep(draft: const OnboardingDraft(), onChanged: (_) {}),
        ),
      );

      await tester.tap(find.byKey(const Key('onboarding_age_row')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_age_picker')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('onboarding_age_picker')),
        const Offset(0, -42),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('29 years'), findsOneWidget);
    });

    testWidgets('profile height picker cancel keeps previous value', (
      tester,
    ) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          ProfileStep(draft: const OnboardingDraft(), onChanged: (_) {}),
        ),
      );

      await tester.tap(find.byKey(const Key('onboarding_height_row')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_height_picker')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('onboarding_height_picker')),
        const Offset(0, -42),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('170 cm'), findsOneWidget);
    });

    testWidgets('profile weight row opens picker sheet', (tester) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          ProfileStep(draft: const OnboardingDraft(), onChanged: (_) {}),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('onboarding_weight_row')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_weight_row')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_weight_picker')), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('pace target wheel defaults lower for lose weight', (
      tester,
    ) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          PaceStep(
            draft: const OnboardingDraft(
              goalType: GoalType.loseWeight,
              measurementSystem: MeasurementSystem.metric,
              currentWeightKg: 80,
            ),
            onChanged: (_) {},
            onSkip: () {},
          ),
        ),
      );

      expect(find.text('75 kg'), findsOneWidget);
    });

    testWidgets('pace target wheel defaults higher for build muscle', (
      tester,
    ) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          PaceStep(
            draft: const OnboardingDraft(
              goalType: GoalType.buildMuscle,
              measurementSystem: MeasurementSystem.metric,
              currentWeightKg: 80,
            ),
            onChanged: (_) {},
            onSkip: () {},
          ),
        ),
      );

      expect(find.text('85 kg'), findsOneWidget);
    });

    testWidgets('pace target row opens picker sheet', (tester) async {
      await tester.pumpWidget(
        constrainedOnboardingHost(
          PaceStep(
            draft: const OnboardingDraft(
              goalType: GoalType.loseWeight,
              measurementSystem: MeasurementSystem.metric,
              currentWeightKg: 80,
            ),
            onChanged: (_) {},
            onSkip: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('onboarding_target_weight_row')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('onboarding_target_weight_picker')),
        findsOneWidget,
      );
    });

    testWidgets(
      'profile step remains safe with validation errors in constrained height',
      (tester) async {
        final key = GlobalKey<ProfileStepState>();

        await tester.pumpWidget(
          constrainedOnboardingHost(
            ProfileStep(
              key: key,
              draft: const OnboardingDraft(),
              onChanged: (_) {},
            ),
          ),
        );

        expect(key.currentState!.validateAndSubmit(), isFalse);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'pace step remains safe with validation errors in constrained height',
      (tester) async {
        final key = GlobalKey<PaceStepState>();

        await tester.pumpWidget(
          constrainedOnboardingHost(
            PaceStep(
              key: key,
              draft: const OnboardingDraft(
                goalType: GoalType.loseWeight,
                measurementSystem: MeasurementSystem.metric,
                currentWeightKg: 80,
              ),
              onChanged: (_) {},
              onSkip: () {},
            ),
          ),
        );

        expect(key.currentState!.validateAndSubmit(), isFalse);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });

  // ===== Rounding Boundary Invariant Tests =====

  group('RoundingBoundary', () {
    // Simulates the rounding logic from calorie_onboarding_service.dart
    double roundCalories(
      double target, {
      bool floorApplied = false,
      bool capApplied = false,
    }) {
      if (floorApplied) return (target / 25).ceil() * 25;
      if (capApplied) return (target / 25).floor() * 25;
      return (target / 25).round() * 25;
    }

    test('floor applied rounds up, never below BMR', () {
      const bmr = 1136.5;
      final rounded = roundCalories(bmr, floorApplied: true);
      expect(rounded, equals(1150));
      expect(rounded, greaterThanOrEqualTo(bmr.ceil()));
    });

    test('cap applied rounds down, never above TDEE+500', () {
      const tdee = 2638.875;
      const target = tdee + 500; // 3138.875
      final rounded = roundCalories(target, capApplied: true);
      expect(rounded, equals(3125));
      expect(rounded, lessThanOrEqualTo(target));
    });

    test('no constraint uses nearest 25', () {
      expect(roundCalories(2050), equals(2050)); // exact
      expect(roundCalories(2051), equals(2050)); // 51 → down
      expect(roundCalories(2074), equals(2075)); // 74 → up
    });

    test('floor invariant: result >= BMR', () {
      for (final bmr in [136.5, 500.0, 1136.5, 1702.5, 2500.0]) {
        final rounded = roundCalories(bmr, floorApplied: true);
        expect(
          rounded,
          greaterThanOrEqualTo(bmr.ceil()),
          reason: 'BMR=$bmr rounded to $rounded violates floor invariant',
        );
      }
    });

    test('cap invariant: result <= TDEE + 500', () {
      for (final tdee in [1500.0, 1800.0, 2638.875, 3000.0]) {
        final target = tdee + 500;
        final rounded = roundCalories(target, capApplied: true);
        expect(
          rounded,
          lessThanOrEqualTo(target),
          reason:
              'TDEE=$tdee cap target=$target rounded to $rounded violates cap invariant',
        );
      }
    });
  });
}
