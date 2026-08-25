import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/constants/app_constants.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/data/services/pro_feature_service.dart';

void main() {
  const service = ProFeatureService();

  test(
    'every paywall entry point maps to at least one claimed Pro feature',
    () {
      for (final entryPoint in PaywallEntryPoint.values) {
        expect(
          service.featuresForEntryPoint(entryPoint),
          isNotEmpty,
          reason: '${entryPoint.name} should have claim coverage',
        );
      }
    },
  );

  test('claimed Pro-only benefits are unavailable to free users', () {
    const proOnlyFeatures = {
      ProFeature.unlimitedScans,
      ProFeature.mealInsights,
      ProFeature.reports,
      ProFeature.unlimitedAiCoach,
      ProFeature.fullWeekPlanner,
      ProFeature.groceryList,
      ProFeature.plannerRegenerate,
      ProFeature.plannerPreferences,
      ProFeature.fullHistory,
      ProFeature.progressPhotos,
      ProFeature.journeyVideo,
      ProFeature.adRemoval,
    };

    for (final feature in proOnlyFeatures) {
      expect(
        service.canUse(feature, isPro: false),
        isFalse,
        reason: '${feature.name} should be locked for free users',
      );
      expect(
        service.canUse(feature, isPro: true),
        isTrue,
        reason: '${feature.name} should unlock for Pro users',
      );
    }
  });

  test('preview benefits remain usable without Pro', () {
    const previewFeatures = {
      ProFeature.aiDetection,
      ProFeature.nextMealAdvice,
      ProFeature.macroFixes,
      ProFeature.progressComparisons,
    };

    for (final feature in previewFeatures) {
      expect(service.canUse(feature, isPro: false), isTrue);
      expect(service.canUse(feature, isPro: true), isTrue);
    }
  });

  test('macro grams follow the free_macros_enabled flag', () {
    // ConfigService is uninitialised under test, so the flag resolves to its
    // compiled default. Macro grams are part of a scan's answer: when the flag
    // is on they are free, and the tier is capped by scan count alone.
    expect(
      service.canSeeMacros(isPro: false),
      AppConstants.defaultFreeMacrosEnabled,
    );
    expect(service.canSeeMacros(isPro: true), isTrue);
    expect(
      service.canUse(ProFeature.macroDetails, isPro: false),
      AppConstants.defaultFreeMacrosEnabled,
    );
    expect(service.canUse(ProFeature.macroDetails, isPro: true), isTrue);
  });

  test('macro details route to the macro paywall entry point', () {
    expect(
      service.entryPointFor(ProFeature.macroDetails),
      PaywallEntryPoint.macroDetails,
    );
    expect(
      service.featuresForEntryPoint(PaywallEntryPoint.macroDetails),
      contains(ProFeature.macroDetails),
    );
  });
}
