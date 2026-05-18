import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/services/premium_gate_service.dart';

Future<PremiumGateService> _freshGate() async {
  SharedPreferences.setMockInitialValues({});
  final gate = PremiumGateService()..resetForTesting();
  await gate.init();
  return gate;
}

void main() {
  test('AHA prompts require a completed value action', () async {
    final gate = await _freshGate();

    expect(
      gate.canShowAhaPrompt(isPremium: false, hasCompletedValueAction: false),
      isFalse,
    );
    expect(
      gate.canShowAhaPrompt(isPremium: false, hasCompletedValueAction: true),
      isTrue,
    );
  });

  test('automatic modal prompts are capped at one per day', () async {
    final gate = await _freshGate();

    expect(
      gate.canShowAhaPrompt(isPremium: false, hasCompletedValueAction: true),
      isTrue,
    );
    await gate.recordPopupShown();

    expect(
      gate.canShowAhaPrompt(isPremium: false, hasCompletedValueAction: true),
      isFalse,
    );
  });

  test('CTA clicks suppress automatic modal prompts', () async {
    final gate = await _freshGate();

    await gate.recordCtaClicked('test');

    expect(
      gate.canShowAhaPrompt(isPremium: false, hasCompletedValueAction: true),
      isFalse,
    );
  });

  test('dismissed modal prompts are cooled down', () async {
    final gate = await _freshGate();

    await gate.recordPopupClosed();

    expect(
      gate.canShowAhaPrompt(isPremium: false, hasCompletedValueAction: true),
      isFalse,
    );
  });
}
