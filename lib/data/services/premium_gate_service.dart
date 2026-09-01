import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/pref_scoping.dart';
import 'analytics_service.dart';

class PremiumGateService {
  static final PremiumGateService _instance = PremiumGateService._internal();
  factory PremiumGateService() => _instance;
  PremiumGateService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Storage Keys (always read through scopedPrefKey so they are namespaced by
  // the signed-in UID — account switching must not inherit quota state).
  static const String _lastPopupDateKey = 'last_premium_popup_date';
  static const String _popupCountTodayKey = 'premium_popup_count_today';
  static const String _lastUpgradeTapKey = 'last_upgrade_tap_timestamp';
  static const String _lastPopupShownKey = 'last_premium_prompt_timestamp';
  static const String _lastPopupDismissedKey =
      'last_premium_prompt_dismissed_timestamp';
  static const String _aiMessagesUsedKey = 'ai_messages_used_today';
  static const String _freeScansUsedKey = 'free_scans_used_today';

  static const int _maxAutomaticPopupsPerDay = 1;
  static const Duration _modalCooldown = Duration(hours: 24);
  static const Duration _postDismissCooldown = Duration(hours: 24);
  static const Duration _postCtaCooldown = Duration(hours: 48);

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Wait for auth to settle before touching any key.
    //
    // `scopedPrefKey` namespaces by the current UID, and init() runs inside
    // the parallel background-services block, which is not ordered after
    // Firebase restores its session. With a null user the daily reset wrote to
    // the *bare* key while every later read used `<uid>:...`, so the
    // "one popup per day" ceiling silently reset itself on every launch.
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((user) => user != null)
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // No user within the window: fall through and use the unscoped keys,
      // which is the documented pre-auth behaviour.
    }

    _initialized = true;
    _resetDailyCountsIfNeeded();
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
  }

  void _resetDailyCountsIfNeeded() {
    final lastDate = _prefs.getString(scopedPrefKey(_lastPopupDateKey));
    final today = utcDateKey(DateTime.now());

    if (lastDate != today) {
      _prefs.setString(scopedPrefKey(_lastPopupDateKey), today);
      _prefs.setInt(scopedPrefKey(_popupCountTodayKey), 0);
      _prefs.setInt(scopedPrefKey(_aiMessagesUsedKey), 0);
      _prefs.setInt(scopedPrefKey(_freeScansUsedKey), 0);
    }
  }

  /// Removes every user-scoped counter. Invoked by SessionCleanupService on
  /// sign-out.
  Future<void> resetSessionState() async {
    if (!_initialized) return;
    final keys =
        _prefs
            .getKeys()
            .where(
              (k) => [
                _lastPopupDateKey,
                _popupCountTodayKey,
                _lastUpgradeTapKey,
                _lastPopupShownKey,
                _lastPopupDismissedKey,
                _aiMessagesUsedKey,
                _freeScansUsedKey,
              ].any((base) => prefKeyBelongsTo(k, base)),
            )
            .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  // --- Logic Checks ---

  bool canShowPopup(bool isPremium) {
    return canShowAhaPrompt(
      isPremium: isPremium,
      hasCompletedValueAction: true,
    );
  }

  bool canShowAhaPrompt({
    required bool isPremium,
    required bool hasCompletedValueAction,
  }) {
    if (!_initialized || isPremium || !hasCompletedValueAction) return false;

    _resetDailyCountsIfNeeded();

    final countToday = _prefs.getInt(scopedPrefKey(_popupCountTodayKey)) ?? 0;
    if (countToday >= _maxAutomaticPopupsPerDay) return false;

    final lastUpgradeTap =
        _prefs.getInt(scopedPrefKey(_lastUpgradeTapKey)) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastUpgradeTap < _postCtaCooldown.inMilliseconds) {
      return false;
    }

    final lastDismissed =
        _prefs.getInt(scopedPrefKey(_lastPopupDismissedKey)) ?? 0;
    if (now - lastDismissed < _postDismissCooldown.inMilliseconds) {
      return false;
    }

    final lastShown = _prefs.getInt(scopedPrefKey(_lastPopupShownKey)) ?? 0;
    if (now - lastShown < _modalCooldown.inMilliseconds) {
      return false;
    }

    return true;
  }

  // --- Recording Actions ---

  Future<void> recordPopupShown() async {
    final count = _prefs.getInt(scopedPrefKey(_popupCountTodayKey)) ?? 0;
    await _prefs.setInt(scopedPrefKey(_popupCountTodayKey), count + 1);
    await _prefs.setInt(
      scopedPrefKey(_lastPopupShownKey),
      DateTime.now().millisecondsSinceEpoch,
    );
    AnalyticsService().logEvent('premium_popup_seen');
  }

  Future<void> recordCtaClicked(String source) async {
    await _prefs.setInt(
      scopedPrefKey(_lastUpgradeTapKey),
      DateTime.now().millisecondsSinceEpoch,
    );
    AnalyticsService().logEvent(
      'premium_cta_clicked',
      parameters: {'source': source},
    );
  }

  Future<void> recordPopupClosed() async {
    await _prefs.setInt(
      scopedPrefKey(_lastPopupDismissedKey),
      DateTime.now().millisecondsSinceEpoch,
    );
    AnalyticsService().logEvent('premium_popup_closed');
  }

  // --- Message/Scan Tracking ---

  int getAiMessagesUsed() =>
      _prefs.getInt(scopedPrefKey(_aiMessagesUsedKey)) ?? 0;

  Future<void> incrementAiMessages() async {
    final current = getAiMessagesUsed();
    await _prefs.setInt(scopedPrefKey(_aiMessagesUsedKey), current + 1);
  }

  bool hasReachedAiLimit(bool isPremium) {
    if (isPremium) return false;
    return getAiMessagesUsed() >= 1; // 1 free AI message per day
  }
}
