import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'app_prompt_session_coordinator.dart';

abstract class AppReviewClient {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing();
}

class InAppReviewClient implements AppReviewClient {
  InAppReviewClient({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();

  @override
  Future<void> openStoreListing() => _inAppReview.openStoreListing();
}

typedef AppVersionProvider = Future<String> Function();
typedef AppReviewClock = DateTime Function();
typedef AndroidPlatformCheck = bool Function();

class AppReviewService {
  AppReviewService({
    SharedPreferences? preferences,
    AppReviewClient? reviewClient,
    AnalyticsService? analytics,
    AppVersionProvider? versionProvider,
    AndroidPlatformCheck? isAndroid,
    AppReviewClock? clock,
  }) : _prefs = preferences,
       _reviewClient = reviewClient ?? InAppReviewClient(),
       _analytics = analytics ?? AnalyticsService(),
       _versionProvider = versionProvider ?? _installedAppVersion,
       _isAndroid = isAndroid ?? (() => Platform.isAndroid),
       _clock = clock ?? DateTime.now;

  static final AppReviewService _instance = AppReviewService._internal();
  factory AppReviewService.instance() => _instance;
  AppReviewService._internal()
    : _reviewClient = InAppReviewClient(),
      _analytics = AnalyticsService(),
      _versionProvider = _installedAppVersion,
      _isAndroid = (() => Platform.isAndroid),
      _clock = DateTime.now;

  static const int minimumSuccessfulActions = 5;
  static const int minimumDistinctUsageDays = 3;
  static const Duration reviewAttemptCooldown = Duration(days: 90);

  static const String _firstUseDateKey = 'review_first_use_date';
  static const String _distinctUsageDaysKey = 'review_distinct_usage_days';
  static const String _successfulLogCountKey = 'review_successful_log_count';
  static const String _lastReviewAttemptDateKey = 'review_last_attempt_date';
  static const String _lastReviewAttemptedVersionKey =
      'review_last_attempted_app_version';
  static const String _automaticTriggerUsedVersionKey =
      'review_automatic_trigger_used_app_version';
  static const String _currentVersionFirstSeenDateKey =
      'review_current_version_first_seen_date';

  SharedPreferences? _prefs;
  final AppReviewClient _reviewClient;
  final AnalyticsService _analytics;
  final AppVersionProvider _versionProvider;
  final AndroidPlatformCheck _isAndroid;
  final AppReviewClock _clock;
  bool _initialized = false;
  bool _requestInFlight = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs ??= await SharedPreferences.getInstance();
    _initialized = true;
    await recordUsageDay();
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _requestInFlight = false;
  }

  Future<void> recordUsageDay() async {
    final prefs = await _safePrefs();
    if (prefs == null) return;

    final today = _dateKey(_clock());
    await prefs.setString(
      _firstUseDateKey,
      prefs.getString(_firstUseDateKey) ?? today,
    );

    final days = prefs.getStringList(_distinctUsageDaysKey) ?? <String>[];
    if (!days.contains(today)) {
      days.add(today);
      days.sort();
      await prefs.setStringList(_distinctUsageDaysKey, days);
    }
  }

  Future<void> recordSuccessfulMealScanOrLog() async {
    final prefs = await _safePrefs();
    if (prefs == null) return;

    await recordUsageDay();
    final current = prefs.getInt(_successfulLogCountKey) ?? 0;
    await prefs.setInt(_successfulLogCountKey, current + 1);
  }

  Future<void> requestReviewIfEligible() async {
    if (_requestInFlight) return;
    _requestInFlight = true;

    try {
      final prefs = await _safePrefs();
      if (prefs == null || !_isAndroid()) return;
      final session = AppPromptSessionCoordinator();
      if (!session.canAttemptReviewPrompt) return;

      await recordUsageDay();

      final version = await _versionProvider();
      if (!await _hasVersionSettled(prefs, version)) return;
      if (!_hasMeaningfulUse(prefs)) return;
      if (!_hasEnoughSuccessfulActions(prefs)) return;
      if (!_hasCooledDown(prefs)) return;
      if (prefs.getString(_lastReviewAttemptedVersionKey) == version) return;
      if (prefs.getString(_automaticTriggerUsedVersionKey) == version) return;

      final isAvailable = await _reviewClient.isAvailable();
      if (!isAvailable) return;

      _analytics.logEvent('review_prompt_eligible');
      await _recordAttempt(prefs, version);
      session.markReviewPromptAttempted();
      _analytics.logEvent('review_prompt_requested');
      await _reviewClient.requestReview();
    } catch (_) {
      // Google Play controls display quotas and plugin failures must never
      // interrupt meal logging or navigation.
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> openStoreRatingPage() async {
    try {
      _analytics.logEvent('rate_app_store_opened');
      await _reviewClient.openStoreListing();
    } catch (_) {
      // Settings action is best-effort; never crash if the store is unavailable.
    }
  }

  bool _hasMeaningfulUse(SharedPreferences prefs) {
    final distinctDays =
        prefs.getStringList(_distinctUsageDaysKey) ?? <String>[];
    if (distinctDays.length >= minimumDistinctUsageDays) return true;

    final firstUseDate = prefs.getString(_firstUseDateKey);
    if (firstUseDate == null) return false;

    final firstUse = DateTime.tryParse(firstUseDate);
    if (firstUse == null) return false;

    return _clock().difference(firstUse).inDays >= minimumDistinctUsageDays - 1;
  }

  bool _hasEnoughSuccessfulActions(SharedPreferences prefs) {
    return (prefs.getInt(_successfulLogCountKey) ?? 0) >=
        minimumSuccessfulActions;
  }

  bool _hasCooledDown(SharedPreferences prefs) {
    final lastAttemptDate = prefs.getString(_lastReviewAttemptDateKey);
    if (lastAttemptDate == null) return true;

    final lastAttempt = DateTime.tryParse(lastAttemptDate);
    if (lastAttempt == null) return true;

    return _clock().difference(lastAttempt) >= reviewAttemptCooldown;
  }

  Future<bool> _hasVersionSettled(
    SharedPreferences prefs,
    String version,
  ) async {
    final key = '${_currentVersionFirstSeenDateKey}_$version';
    final firstSeenDate = prefs.getString(key);
    if (firstSeenDate == null) {
      await prefs.setString(key, _dateKey(_clock()));
      return false;
    }

    final firstSeen = DateTime.tryParse(firstSeenDate);
    if (firstSeen == null) {
      await prefs.setString(key, _dateKey(_clock()));
      return false;
    }

    return _clock().difference(firstSeen).inDays >= 1;
  }

  Future<void> _recordAttempt(SharedPreferences prefs, String version) async {
    await prefs.setString(_lastReviewAttemptDateKey, _dateKey(_clock()));
    await prefs.setString(_lastReviewAttemptedVersionKey, version);
    await prefs.setString(_automaticTriggerUsedVersionKey, version);
  }

  Future<SharedPreferences?> _safePrefs() async {
    try {
      if (!_initialized) await init();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  static Future<String> _installedAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
