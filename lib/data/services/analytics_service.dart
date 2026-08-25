import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics facade used across the monetization and review flows.
///
/// Events are forwarded to Firebase Analytics. Event names are sanitized to
/// Firebase's constraints (`[A-Za-z0-9_]`, <= 40 chars, must not start with a
/// digit) so call sites can keep readable names like `premium_cta_clicked`.
/// When Firebase is unavailable (unit tests, or before initialization
/// completes) events degrade to debug logging instead of throwing.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const int _maxNameLength = 40;

  FirebaseAnalytics? _analytics;
  bool _unavailable = false;

  FirebaseAnalytics? get _client {
    if (_unavailable) return null;
    try {
      return _analytics ??= FirebaseAnalytics.instance;
    } catch (e) {
      _unavailable = true;
      debugPrint('📊 Analytics unavailable, falling back to logs: $e');
      return null;
    }
  }

  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      debugPrint('📊 ANALYTICS EVENT: $name ${parameters ?? ''}');
    }
    final client = _client;
    if (client == null) return;

    try {
      unawaited(
        client.logEvent(
          name: sanitizeEventName(name),
          parameters: parameters?.map(_normalizeParam),
        ),
      );
    } catch (e) {
      debugPrint('📊 Analytics logEvent("$name") failed: $e');
    }
  }

  /// Maps an arbitrary event name onto Firebase's accepted alphabet.
  @visibleForTesting
  static String sanitizeEventName(String name) {
    var sanitized = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    if (sanitized.isEmpty) sanitized = 'event';
    if (RegExp(r'^[0-9]').hasMatch(sanitized)) sanitized = '_$sanitized';
    if (sanitized.length > _maxNameLength) {
      sanitized = sanitized.substring(0, _maxNameLength);
    }
    return sanitized;
  }

  MapEntry<String, Object> _normalizeParam(String key, dynamic value) {
    final safeKey = sanitizeEventName(key);
    if (value is num || value is String) {
      return MapEntry(safeKey, value);
    }
    return MapEntry(safeKey, value.toString());
  }
}
