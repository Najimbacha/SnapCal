import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/nutrition/plan_math.dart';

void main() {
  group('MacroSplit', () {
    test('kcal uses 4/4/9', () {
      const split = MacroSplit(protein: 100, carbs: 200, fat: 50);
      expect(split.kcal, 100 * 4 + 200 * 4 + 50 * 9);
    });

    test('shares sum to one and reflect energy, not grams', () {
      const split = MacroSplit(protein: 100, carbs: 100, fat: 100);
      final shares = split.shares;
      expect(shares.protein + shares.carbs + shares.fat, closeTo(1.0, 1e-9));
      // Equal grams are not equal energy: fat carries 9 kcal/g.
      expect(shares.fat, greaterThan(shares.protein));
      expect(shares.protein, closeTo(shares.carbs, 1e-9));
    });

    test('an empty split reports an even share rather than dividing by zero', () {
      const split = MacroSplit(protein: 0, carbs: 0, fat: 0);
      final shares = split.shares;
      expect(shares.protein, closeTo(1 / 3, 1e-9));
      expect(shares.carbs, closeTo(1 / 3, 1e-9));
      expect(shares.fat, closeTo(1 / 3, 1e-9));
    });
  });

  group('rebalanceToCalories', () {
    test('lands within tolerance of the target', () {
      const current = MacroSplit(protein: 150, carbs: 250, fat: 70);
      for (final target in [1200, 1500, 1800, 2000, 2350, 3000, 4200]) {
        final result = rebalanceToCalories(
          current: current,
          targetCalories: target,
        );
        expect(
          macrosAgreeWithCalories(result, target),
          isTrue,
          reason: 'target $target produced ${result.kcal} kcal ($result)',
        );
      }
    });

    test('preserves the shape of the split', () {
      // The user chose a high-protein ratio. Halving calories must not quietly
      // turn them into a balanced eater.
      const current = MacroSplit(protein: 200, carbs: 150, fat: 60);
      final before = current.shares;

      final result = rebalanceToCalories(current: current, targetCalories: 1500);
      final after = result.shares;

      expect(after.protein, closeTo(before.protein, 0.02));
      expect(after.carbs, closeTo(before.carbs, 0.02));
      expect(after.fat, closeTo(before.fat, 0.02));
    });

    test('scaling up and back down returns roughly where it started', () {
      const current = MacroSplit(protein: 150, carbs: 200, fat: 65);
      final up = rebalanceToCalories(current: current, targetCalories: 3000);
      final down = rebalanceToCalories(current: up, targetCalories: current.kcal);

      expect(down.protein, closeTo(current.protein, 2));
      expect(down.carbs, closeTo(current.carbs, 2));
      expect(down.fat, closeTo(current.fat, 2));
    });

    test('falls back to a default split when there is nothing to preserve', () {
      const empty = MacroSplit(protein: 0, carbs: 0, fat: 0);
      final result = rebalanceToCalories(current: empty, targetCalories: 2000);

      expect(result.kcal, greaterThan(0));
      expect(macrosAgreeWithCalories(result, 2000), isTrue);
      expect(result.shares.protein, closeTo(0.30, 0.03));
    });

    test('never produces a negative macro', () {
      // A fat-only split scaled far down is where naive arithmetic goes
      // negative on carbohydrate, because carbs absorb the rounding.
      const fatHeavy = MacroSplit(protein: 0, carbs: 0, fat: 300);
      final result = rebalanceToCalories(
        current: fatHeavy,
        targetCalories: 800,
      );
      expect(result.protein, greaterThanOrEqualTo(0));
      expect(result.carbs, greaterThanOrEqualTo(0));
      expect(result.fat, greaterThanOrEqualTo(0));
    });

    test('a lopsided split scaled high still hits the target', () {
      // Regression. The macro clamp used to be 800g for both typed and
      // computed values, so this case came back as 3232 kcal against a 5636
      // target — silently, with nothing in the result indicating a miss. Found
      // by a random sweep, not by hand: every value picked by a human was
      // moderate enough that the clamp never bound.
      const carbHeavy = MacroSplit(protein: 3, carbs: 498, fat: 0);
      final result = rebalanceToCalories(
        current: carbHeavy,
        targetCalories: 5636,
      );
      expect(macrosAgreeWithCalories(result, 5636), isTrue,
          reason: 'got ${result.kcal} kcal from $result');
    });

    test('holds across the whole allowed calorie range for lopsided splits', () {
      const splits = [
        MacroSplit(protein: 400, carbs: 10, fat: 5),
        MacroSplit(protein: 5, carbs: 600, fat: 5),
        MacroSplit(protein: 5, carbs: 5, fat: 300),
        MacroSplit(protein: 1, carbs: 1, fat: 1),
      ];
      for (final split in splits) {
        for (var target = PlanLimits.minCalories;
            target <= PlanLimits.maxCalories;
            target += 137) {
          final result = rebalanceToCalories(
            current: split,
            targetCalories: target,
          );
          expect(result.protein, greaterThanOrEqualTo(0));
          expect(result.carbs, greaterThanOrEqualTo(0));
          expect(result.fat, greaterThanOrEqualTo(0));
          expect(macrosAgreeWithCalories(result, target), isTrue,
              reason: '$split -> $target gave ${result.kcal}');
        }
      }
    });

    test('clamps a target outside the allowed range', () {
      const current = MacroSplit(protein: 150, carbs: 200, fat: 65);
      final tooLow = rebalanceToCalories(current: current, targetCalories: 1);
      final tooHigh = rebalanceToCalories(
        current: current,
        targetCalories: 99999,
      );
      expect(tooLow.kcal, greaterThanOrEqualTo(PlanLimits.minCalories - kMacroCalorieTolerance));
      expect(tooHigh.kcal, lessThanOrEqualTo(PlanLimits.maxCalories + kMacroCalorieTolerance));
    });
  });

  group('agreement', () {
    test('detects the drift the old UI could not show', () {
      // The exact bug: a 2000 kcal goal with macros left at a 2500 kcal split.
      const stale = MacroSplit(protein: 150, carbs: 300, fat: 78);
      expect(stale.kcal, greaterThan(2400));
      expect(macrosAgreeWithCalories(stale, 2000), isFalse);
      expect(macroCalorieDrift(stale, 2000), greaterThan(400));
    });

    test('treats rounding as agreement', () {
      final split = rebalanceToCalories(
        current: const MacroSplit(protein: 120, carbs: 210, fat: 60),
        targetCalories: 1850,
      );
      expect(macrosAgreeWithCalories(split, 1850), isTrue);
      expect(macroCalorieDrift(split, 1850).abs(), lessThanOrEqualTo(kMacroCalorieTolerance));
    });
  });

  group('validation', () {
    test('accepts realistic values', () {
      expect(validateCalories(1200).isValid, isTrue);
      expect(validateCalories(4500).isValid, isTrue);
      expect(validateAge(25).isValid, isTrue);
      expect(validateHeightCm(170).isValid, isTrue);
      expect(validateWeightKg(70.5).isValid, isTrue);
      expect(validateMacroGrams(0).isValid, isTrue);
    });

    test('rejects what the old dialog happily accepted', () {
      // The old check was `value > 0`.
      expect(validateCalories(1).isValid, isFalse);
      expect(validateAge(500).isValid, isFalse);
      expect(validateHeightCm(3).isValid, isFalse);
      expect(validateWeightKg(1).isValid, isFalse);
      expect(validateMacroGrams(5000).isValid, isFalse);
    });

    test('reports the bounds so the UI can explain itself', () {
      final result = validateCalories(1);
      expect(result.min, PlanLimits.minCalories);
      expect(result.max, PlanLimits.maxCalories);
    });
  });
}
