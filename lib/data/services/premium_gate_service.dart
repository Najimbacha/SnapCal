import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

class PremiumGateService {
  static final PremiumGateService _instance = PremiumGateService._internal();
  factory PremiumGateService() => _instance;
  PremiumGateService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Storage Keys
  static const String _lastPopupDateKey = 'last_premium_popup_date';
  static const String _popupCountTodayKey = 'premium_popup_count_today';
  static const String _lastUpgradeTapKey = 'last_upgrade_tap_timestamp';
  static const String _aiMessagesUsedKey = 'ai_messages_used_today';
  static const String _freeScansUsedKey = 'free_scans_used_today';

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      _resetDailyCountsIfNeeded();
    }
  }

  void _resetDailyCountsIfNeeded() {
    final lastDate = _prefs.getString(_lastPopupDateKey);
    final today = _getTodayString();

    if (lastDate != today) {
      _prefs.setString(_lastPopupDateKey, today);
      _prefs.setInt(_popupCountTodayKey, 0);
      _prefs.setInt(_aiMessagesUsedKey, 0);
      _prefs.setInt(_freeScansUsedKey, 0);
    }
  }

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  // --- Logic Checks ---

  bool canShowPopup(bool isPremium) {
    if (isPremium) return false;

    final countToday = _prefs.getInt(_popupCountTodayKey) ?? 0;
    if (countToday >= 2) return false;

    final lastUpgradeTap = _prefs.getInt(_lastUpgradeTapKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Rule: Wait 24h if user tapped upgrade but didn't buy
    if (now - lastUpgradeTap < 24 * 60 * 60 * 1000) {
      return false;
    }

    // Rule: Wait 6 hours between popups
    final lastShown = _prefs.getInt('last_premium_prompt_timestamp') ?? 0;
    if (now - lastShown < 6 * 60 * 60 * 1000) {
      return false;
    }

    return true;
  }

  // --- Recording Actions ---

  Future<void> recordPopupShown() async {
    final count = _prefs.getInt(_popupCountTodayKey) ?? 0;
    await _prefs.setInt(_popupCountTodayKey, count + 1);
    await _prefs.setInt('last_premium_prompt_timestamp', DateTime.now().millisecondsSinceEpoch);
    AnalyticsService().logEvent('premium_popup_seen');
  }

  Future<void> recordCtaClicked(String source) async {
    await _prefs.setInt(_lastUpgradeTapKey, DateTime.now().millisecondsSinceEpoch);
    AnalyticsService().logEvent('premium_cta_clicked', parameters: {'source': source});
  }

  Future<void> recordPopupClosed() async {
    AnalyticsService().logEvent('premium_popup_closed');
  }

  // --- Message/Scan Tracking ---

  int getAiMessagesUsed() => _prefs.getInt(_aiMessagesUsedKey) ?? 0;
  
  Future<void> incrementAiMessages() async {
    final current = getAiMessagesUsed();
    await _prefs.setInt(_aiMessagesUsedKey, current + 1);
  }

  bool hasReachedAiLimit(bool isPremium) {
    if (isPremium) return false;
    return getAiMessagesUsed() >= 5; // Example: 5 free AI messages
  }
}
