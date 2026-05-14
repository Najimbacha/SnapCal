import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    // In a real app, this would call Firebase Analytics, Mixpanel, etc.
    debugPrint('📊 ANALYTICS EVENT: $name ${parameters ?? ''}');
  }
}
