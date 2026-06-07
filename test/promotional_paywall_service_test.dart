import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/services/app_prompt_session_coordinator.dart';
import 'package:snapcal/data/services/promotional_paywall_service.dart';

class _FakePromoGateway implements PromotionalPaywallSubscriptionGateway {
  _FakePromoGateway({
    this.isPremium = false,
    this.hasOfferings = true,
    this.purchaseInFlight = false,
  });

  final bool isPremium;
  final bool hasOfferings;
  @override
  final bool purchaseInFlight;

  @override
  Future<bool> hasActivePremiumEntitlement() async => isPremium;

  @override
  Future<bool> hasValidCurrentOffering() async => hasOfferings;
}

Future<PromotionalPaywallService> _service({
  required _FakePromoGateway gateway,
  DateTime? now,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final session = AppPromptSessionCoordinator()..resetForTesting();
  final service = PromotionalPaywallService(
    preferences: prefs,
    subscriptionGateway: gateway,
    session: session,
    clock: () => now ?? DateTime(2026, 6, 3, 12),
  );
  await service.init();
  return service;
}

Map<String, Object> _eligibleState({
  int appOpenCount = 4,
  int mealLogCount = 3,
  int totalDisplayCount = 0,
  String? lastShownAt,
  List<String> days = const ['2026-06-01', '2026-06-02'],
}) {
  return <String, Object>{
    'promo_paywall_app_open_count': appOpenCount - 1,
    'promo_paywall_distinct_usage_days': days,
    'promo_paywall_successful_meal_log_count': mealLogCount,
    'promo_paywall_total_display_count': totalDisplayCount,
    if (lastShownAt != null) 'promo_paywall_last_shown_at': lastShownAt,
  };
}

Future<bool> _canShow(PromotionalPaywallService service) {
  return service.canShowPromotionalPaywall(
    isPremium: false,
    onboardingComplete: true,
    homeLoaded: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Premium user never sees promotional paywall', () async {
    SharedPreferences.setMockInitialValues(_eligibleState());
    final service = await _service(gateway: _FakePromoGateway(isPremium: true));

    expect(
      await service.canShowPromotionalPaywall(
        isPremium: true,
        onboardingComplete: true,
        homeLoaded: true,
      ),
      isFalse,
    );
  });

  test('new user on first launch never sees promotional paywall', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = await _service(gateway: _FakePromoGateway());

    expect(await _canShow(service), isFalse);
  });

  test('free user with fewer than 4 app opens is not eligible', () async {
    SharedPreferences.setMockInitialValues(_eligibleState(appOpenCount: 3));
    final service = await _service(gateway: _FakePromoGateway());

    expect(await _canShow(service), isFalse);
  });

  test(
    'free user with fewer than 3 successful scans or logs is not eligible',
    () async {
      SharedPreferences.setMockInitialValues(_eligibleState(mealLogCount: 2));
      final service = await _service(gateway: _FakePromoGateway());

      expect(await _canShow(service), isFalse);
    },
  );

  test(
    'free user with fewer than 2 distinct usage days is not eligible',
    () async {
      SharedPreferences.setMockInitialValues(
        _eligibleState(days: const ['2026-06-03']),
      );
      final service = await _service(gateway: _FakePromoGateway());

      expect(await _canShow(service), isFalse);
    },
  );

  test(
    'eligible free user can see promotional paywall after home loads',
    () async {
      SharedPreferences.setMockInitialValues(_eligibleState());
      final service = await _service(gateway: _FakePromoGateway());

      expect(await _canShow(service), isTrue);
    },
  );

  test('promotional paywall is shown only once in a session', () async {
    SharedPreferences.setMockInitialValues(_eligibleState());
    final service = await _service(gateway: _FakePromoGateway());

    expect(await _canShow(service), isTrue);
    await service.recordPromotionalPaywallShown();

    expect(await _canShow(service), isFalse);
  });

  test('promotional paywall is not shown again within 7 days', () async {
    SharedPreferences.setMockInitialValues(
      _eligibleState(lastShownAt: '2026-05-31T12:00:00.000'),
    );
    final service = await _service(gateway: _FakePromoGateway());

    expect(await _canShow(service), isFalse);
  });

  test('promotional paywall is never shown more than 3 total times', () async {
    SharedPreferences.setMockInitialValues(
      _eligibleState(totalDisplayCount: 3),
    );
    final service = await _service(gateway: _FakePromoGateway());

    expect(await _canShow(service), isFalse);
  });

  test(
    'offerings unavailable means paywall is not shown and app does not crash',
    () async {
      SharedPreferences.setMockInitialValues(_eligibleState());
      final service = await _service(
        gateway: _FakePromoGateway(hasOfferings: false),
      );

      expect(await _canShow(service), isFalse);
    },
  );

  test('purchase flow active means promotional paywall is not shown', () async {
    SharedPreferences.setMockInitialValues(_eligibleState());
    final service = await _service(
      gateway: _FakePromoGateway(purchaseInFlight: true),
    );

    expect(await _canShow(service), isFalse);
  });

  test(
    'review prompt and promotional paywall never show in the same session',
    () async {
      SharedPreferences.setMockInitialValues(_eligibleState());
      AppPromptSessionCoordinator().markReviewPromptAttempted();
      final service = await _service(gateway: _FakePromoGateway());
      AppPromptSessionCoordinator().markReviewPromptAttempted();

      expect(await _canShow(service), isFalse);
    },
  );
}
