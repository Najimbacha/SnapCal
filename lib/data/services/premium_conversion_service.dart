import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'analytics_service.dart';
import 'premium_gate_service.dart';

enum PaywallEntryPoint {
  scanLimit,
  aiCoachLimit,
  plannerLockedDay,
  plannerPreferences,
  groceryList,
  progressPhotoLimit,
  reportInsight,
  mealInsight,
  adRemoval,
  settings,
  homeAha,
}

extension PaywallEntryPointName on PaywallEntryPoint {
  String get analyticsName => name;
}

class PremiumConversionService {
  static final PremiumConversionService _instance =
      PremiumConversionService._internal();

  factory PremiumConversionService() => _instance;

  PremiumConversionService._internal();

  final PremiumGateService _gate = PremiumGateService();
  final AnalyticsService _analytics = AnalyticsService();

  Future<void> openPaywall(
    BuildContext context,
    PaywallEntryPoint entryPoint, {
    String? featureName,
    bool limitReached = false,
  }) async {
    final source = entryPoint.analyticsName;
    await _gate.recordCtaClicked(source);
    _analytics.logEvent(
      'paywall_opened',
      parameters: {
        'entry_point': source,
        if (featureName != null) 'feature_name': featureName,
        if (limitReached) 'limit_reached': true,
      },
    );

    if (!context.mounted) return;
    context.push(
      '/paywall',
      extra: {
        'entryPoint': source,
        if (featureName != null) 'featureName': featureName,
        if (limitReached) 'limitReached': true,
      },
    );
  }

  Future<void> recordPromptSeen(
    PaywallEntryPoint entryPoint, {
    String? featureName,
  }) async {
    _analytics.logEvent(
      'premium_prompt_seen',
      parameters: {
        'entry_point': entryPoint.analyticsName,
        if (featureName != null) 'feature_name': featureName,
      },
    );
  }

  Future<bool> maybeShowAhaPrompt(
    BuildContext context, {
    required PaywallEntryPoint entryPoint,
    required bool isPro,
    required bool hasCompletedValueAction,
    String? featureName,
  }) async {
    if (!_gate.canShowAhaPrompt(
      isPremium: isPro,
      hasCompletedValueAction: hasCompletedValueAction,
    )) {
      return false;
    }

    await _gate.recordPopupShown();
    await recordPromptSeen(entryPoint, featureName: featureName);
    return context.mounted;
  }

  Future<void> recordPromptDismissed(
    PaywallEntryPoint entryPoint, {
    String? featureName,
  }) async {
    await _gate.recordPopupClosed();
    _analytics.logEvent(
      'premium_prompt_dismissed',
      parameters: {
        'entry_point': entryPoint.analyticsName,
        if (featureName != null) 'feature_name': featureName,
      },
    );
  }

  PaywallEntryPoint parseEntryPoint(
    String? value, {
    bool limitReached = false,
  }) {
    if (limitReached) return PaywallEntryPoint.scanLimit;
    if (value == null) return PaywallEntryPoint.settings;
    return PaywallEntryPoint.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => PaywallEntryPoint.settings,
    );
  }
}
