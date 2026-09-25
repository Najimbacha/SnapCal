import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/screens/onboarding/onboarding_conversions.dart';

void main() {
  group('cmToFtIn', () {
    test('never reports twelve inches', () {
      // 182.5 cm is 71.85 in; rounding the remainder alone gave "5 ft 12 in".
      expect(OnboardingConversions.cmToFtIn(182.5), (feet: 6, inches: 0));
      expect(OnboardingConversions.cmToFtIn(182.88), (feet: 6, inches: 0));
      expect(OnboardingConversions.cmToFtIn(180), (feet: 5, inches: 11));
      expect(OnboardingConversions.cmToFtIn(152.4), (feet: 5, inches: 0));
    });

    test('round-trips through ftInToCm', () {
      for (var feet = 4; feet <= 7; feet++) {
        for (var inches = 0; inches < 12; inches++) {
          final cm = OnboardingConversions.ftInToCm(feet, inches);
          expect(
            OnboardingConversions.cmToFtIn(cm),
            (feet: feet, inches: inches),
          );
        }
      }
    });
  });

  test('isValidPositiveNumber accepts only finite positives', () {
    expect(OnboardingConversions.isValidPositiveNumber(' 72.5 '), isTrue);
    expect(OnboardingConversions.isValidPositiveNumber('0'), isFalse);
    expect(OnboardingConversions.isValidPositiveNumber('-5'), isFalse);
    expect(OnboardingConversions.isValidPositiveNumber('NaN'), isFalse);
    expect(OnboardingConversions.isValidPositiveNumber('Infinity'), isFalse);
    expect(OnboardingConversions.isValidPositiveNumber('abc'), isFalse);
  });
}
