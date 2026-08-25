import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/pref_scoping.dart';
import 'analytics_service.dart';
import 'app_prompt_session_coordinator.dart';
import 'subscription_service.dart';

abstract class PromotionalPaywallSubscriptionGateway {
  bool get purchaseInFlight;
  Future<bool> hasActivePremiumEntitlement();
  Future<bool> hasValidCurrentOffering();
}

class RevenueCatPromotionalPaywallGateway
    implements PromotionalPaywallSubscriptionGateway {
  RevenueCatPromotionalPaywallGateway({SubscriptionService? subscription})
    : _subscription = subscription ?? SubscriptionService();

  final SubscriptionService _subscription;

  @override
  bool get purchaseInFlight => _subscription.isPurchaseInFlight;

  @override
  Future<bool> hasActivePremiumEntitlement() {
    return _subscription.hasActivePremiumEntitlement();
  }

  @override
  Future<bool> hasValidCurrentOffering() {
    return _subscription.hasValidCurrentOffering();
  }
}

typedef PromotionalPaywallClock = DateTime Function();

class PromotionalPaywallService {
  PromotionalPaywallService({
    SharedPreferences? preferences,
    PromotionalPaywallSubscriptionGateway? subscriptionGateway,
    AnalyticsService? analytics,
    AppPromptSessionCoordinator? session,
    PromotionalPaywallClock? clock,
  }) : _prefs = preferences,
       _subscriptionGateway =
           subscriptionGateway ?? RevenueCatPromotionalPaywallGateway(),
       _analytics = analytics ?? AnalyticsService(),
       _session = session ?? AppPromptSessionCoordinator(),
       _clock = clock ?? DateTime.now;

  static final PromotionalPaywallService _instance =
      PromotionalPaywallService._internal();
  factory PromotionalPaywallService.instance() => _instance;
  PromotionalPaywallService._internal()
    : _subscriptionGateway = RevenueCatPromotionalPaywallGateway(),
      _analytics = AnalyticsService(),
      _session = AppPromptSessionCoordinator(),
      _clock = DateTime.now;

  static const int minimumAppOpens = 4;
  static const int minimumDistinctUsageDays = 2;
  static const int minimumSuccessfulMealLogs = 3;
  static const int maximumTotalDisplays = 3;
  static const Duration promotionalCooldown = Duration(days: 7);

  static const String _appOpenCountKey = 'promo_paywall_app_open_count';
  static const String _distinctUsageDaysKey =
      'promo_paywall_distinct_usage_days';
  static const String _successfulMealLogCountKey =
      'promo_paywall_successful_meal_log_count';
  static const String _lastShownAtKey = 'promo_paywall_last_shown_at';
  static const String _totalDisplayCountKey =
      'promo_paywall_total_display_count';
  static const String _lastDismissedAtKey = 'promo_paywall_last_dismissed_at';

  /// All base keys, used for scoped reads/writes and session cleanup.
  static List<String> get _allKeys => [
    _appOpenCountKey,
    _distinctUsageDaysKey,
    _successfulMealLogCountKey,
    _lastShownAtKey,
    _totalDisplayCountKey,
    _lastDismissedAtKey,
  ];

  SharedPreferences? _prefs;
  final PromotionalPaywallSubscriptionGateway _subscriptionGateway;
  final AnalyticsService _analytics;
  final AppPromptSessionCoordinator _session;
  final PromotionalPaywallClock _clock;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs ??= await SharedPreferences.getInstance();
    _initialized = true;
    await recordAppOpen();
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
  }

  /// Removes every user-scoped counter. Invoked by SessionCleanupService on
  /// sign-out so eligibility (opens, meal logs, cooldowns) never leaks across
  /// accounts.
  Future<void> resetSessionState() async {
    final prefs = await _safePrefs();
    if (prefs == null) return;
    final keys =
        prefs
            .getKeys()
            .where((k) => _allKeys.any((base) => prefKeyBelongsTo(k, base)))
            .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  bool get promotionalPaywallShownThisSession =>
      _session.promotionalPaywallShown;

  Future<void> recordAppOpen() async {
    final prefs = await _safePrefs();
    if (prefs == null) return;

    final current = prefs.getInt(scopedPrefKey(_appOpenCountKey)) ?? 0;
    await prefs.setInt(scopedPrefKey(_appOpenCountKey), current + 1);
    await _recordUsageDay(prefs);
  }

  Future<void> recordSuccessfulMealScanOrLog() async {
    final prefs = await _safePrefs();
    if (prefs == null) return;

    await _recordUsageDay(prefs);
    final current =
        prefs.getInt(scopedPrefKey(_successfulMealLogCountKey)) ?? 0;
    await prefs.setInt(scopedPrefKey(_successfulMealLogCountKey), current + 1);
  }

  Future<bool> canShowPromotionalPaywall({
    required bool isPremium,
    required bool onboardingComplete,
    required bool homeLoaded,
  }) async {
    final prefs = await _safePrefs();
    if (prefs == null) return false;
    if (isPremium || !onboardingComplete || !homeLoaded) return false;
    if (_subscriptionGateway.purchaseInFlight) return false;
    if (!_session.canShowPromotionalPaywall) return false;
    if (_session.promotionalPaywallShown) return false;

    if ((prefs.getInt(scopedPrefKey(_appOpenCountKey)) ?? 0) <
        minimumAppOpens) {
      return false;
    }
    final days =
        prefs.getStringList(scopedPrefKey(_distinctUsageDaysKey)) ?? <String>[];
    if (days.length < minimumDistinctUsageDays) return false;
    if ((prefs.getInt(scopedPrefKey(_successfulMealLogCountKey)) ?? 0) <
        minimumSuccessfulMealLogs) {
      return false;
    }
    if ((prefs.getInt(scopedPrefKey(_totalDisplayCountKey)) ?? 0) >=
        maximumTotalDisplays) {
      return false;
    }

    final lastShown = _readDate(
      prefs.getString(scopedPrefKey(_lastShownAtKey)),
    );
    if (lastShown != null &&
        _clock().difference(lastShown) < promotionalCooldown) {
      return false;
    }

    final activePremium =
        isPremium || await _subscriptionGateway.hasActivePremiumEntitlement();
    if (activePremium) return false;

    final hasOffering = await _subscriptionGateway.hasValidCurrentOffering();
    if (!hasOffering) return false;

    _analytics.logEvent('promo_paywall_eligible');
    return true;
  }

  Future<void> recordPromotionalPaywallShown() async {
    final prefs = await _safePrefs();
    if (prefs == null) return;

    _session.markPromotionalPaywallShown();
    final count = prefs.getInt(scopedPrefKey(_totalDisplayCountKey)) ?? 0;
    await prefs.setInt(scopedPrefKey(_totalDisplayCountKey), count + 1);
    await prefs.setString(
      scopedPrefKey(_lastShownAtKey),
      _clock().toIso8601String(),
    );
    _analytics.logEvent('promo_paywall_shown');
  }

  Future<void> recordPromotionalPaywallDismissed() async {
    final prefs = await _safePrefs();
    if (prefs == null) return;

    await prefs.setString(
      scopedPrefKey(_lastDismissedAtKey),
      _clock().toIso8601String(),
    );
    _analytics.logEvent('promo_paywall_dismissed');
  }

  Future<void> _recordUsageDay(SharedPreferences prefs) async {
    final today = _dateKey(_clock());
    final days =
        prefs.getStringList(scopedPrefKey(_distinctUsageDaysKey)) ?? <String>[];
    if (!days.contains(today)) {
      days.add(today);
      days.sort();
      await prefs.setStringList(scopedPrefKey(_distinctUsageDaysKey), days);
    }
  }

  DateTime? _readDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<SharedPreferences?> _safePrefs() async {
    try {
      if (!_initialized) await init();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
