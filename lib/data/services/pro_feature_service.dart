import '../../core/services/config_service.dart';
import 'premium_conversion_service.dart';

enum ProFeature {
  unlimitedScans,
  aiDetection,
  mealInsights,
  reports,
  macroDetails,
  unlimitedAiCoach,
  nextMealAdvice,
  macroFixes,
  fullWeekPlanner,
  groceryList,
  plannerRegenerate,
  plannerPreferences,
  fullHistory,
  progressPhotos,
  progressComparisons,
  journeyVideo,
  adRemoval,
}

class ProFeatureService {
  const ProFeatureService();

  static const int freeHistoryDays = 14;

  /// Whether macro grams are visible to this user.
  ///
  /// Macro grams are part of the answer a scan produces, not an add-on, so
  /// free users see them whenever the `free_macros_enabled` Remote Config flag
  /// is on (the default). What stays behind Pro is the coaching layer built on
  /// top: daily targets, goal progress, health score, and AI insights.
  bool canSeeMacros({required bool isPro}) =>
      isPro || ConfigService().freeMacrosEnabled;

  bool canUse(ProFeature feature, {required bool isPro}) {
    switch (feature) {
      case ProFeature.macroDetails:
        return canSeeMacros(isPro: isPro);
      case ProFeature.unlimitedScans:
      case ProFeature.mealInsights:
      case ProFeature.reports:
      case ProFeature.unlimitedAiCoach:
      case ProFeature.fullWeekPlanner:
      case ProFeature.groceryList:
      case ProFeature.plannerRegenerate:
      case ProFeature.plannerPreferences:
      case ProFeature.fullHistory:
      case ProFeature.progressPhotos:
      case ProFeature.journeyVideo:
      case ProFeature.adRemoval:
        return isPro;
      case ProFeature.aiDetection:
      case ProFeature.nextMealAdvice:
      case ProFeature.macroFixes:
      case ProFeature.progressComparisons:
        return true;
    }
  }

  PaywallEntryPoint entryPointFor(ProFeature feature) {
    switch (feature) {
      case ProFeature.unlimitedScans:
      case ProFeature.aiDetection:
        return PaywallEntryPoint.scanLimit;
      case ProFeature.unlimitedAiCoach:
      case ProFeature.nextMealAdvice:
      case ProFeature.macroFixes:
        return PaywallEntryPoint.aiCoachLimit;
      case ProFeature.fullWeekPlanner:
        return PaywallEntryPoint.plannerLockedDay;
      case ProFeature.groceryList:
        return PaywallEntryPoint.groceryList;
      case ProFeature.plannerRegenerate:
      case ProFeature.plannerPreferences:
        return PaywallEntryPoint.plannerPreferences;
      case ProFeature.mealInsights:
        return PaywallEntryPoint.mealInsight;
      case ProFeature.macroDetails:
        return PaywallEntryPoint.macroDetails;
      case ProFeature.reports:
      case ProFeature.fullHistory:
        return PaywallEntryPoint.reportInsight;
      case ProFeature.progressPhotos:
      case ProFeature.progressComparisons:
      case ProFeature.journeyVideo:
        return PaywallEntryPoint.progressPhotoLimit;
      case ProFeature.adRemoval:
        return PaywallEntryPoint.adRemoval;
    }
  }

  Set<ProFeature> featuresForEntryPoint(PaywallEntryPoint entryPoint) {
    switch (entryPoint) {
      case PaywallEntryPoint.scanLimit:
        return const {
          ProFeature.unlimitedScans,
          ProFeature.aiDetection,
          ProFeature.mealInsights,
          ProFeature.reports,
        };
      case PaywallEntryPoint.aiCoachLimit:
        return const {
          ProFeature.unlimitedAiCoach,
          ProFeature.nextMealAdvice,
          ProFeature.macroFixes,
          ProFeature.unlimitedScans,
        };
      case PaywallEntryPoint.plannerLockedDay:
      case PaywallEntryPoint.plannerPreferences:
      case PaywallEntryPoint.groceryList:
        return const {
          ProFeature.fullWeekPlanner,
          ProFeature.groceryList,
          ProFeature.plannerRegenerate,
          ProFeature.plannerPreferences,
        };
      case PaywallEntryPoint.reportInsight:
      case PaywallEntryPoint.mealInsight:
      case PaywallEntryPoint.macroDetails:
        return const {
          ProFeature.reports,
          ProFeature.mealInsights,
          ProFeature.macroDetails,
          ProFeature.macroFixes,
          ProFeature.unlimitedScans,
        };
      case PaywallEntryPoint.progressPhotoLimit:
        return const {
          ProFeature.progressPhotos,
          ProFeature.progressComparisons,
          ProFeature.journeyVideo,
          ProFeature.unlimitedScans,
        };
      // The app has no ads any more, so there is nothing to remove and
      // nothing here should offer it as a benefit. The entry point and the
      // ProFeature value are left in place rather than deleted -- both sit in
      // exhaustive switches -- but nothing routes to this case now, and if
      // something ever does it sells only things that are real.
      case PaywallEntryPoint.adRemoval:
        return const {
          ProFeature.unlimitedScans,
          ProFeature.reports,
        };
      case PaywallEntryPoint.settings:
      case PaywallEntryPoint.homeAha:
        return const {
          ProFeature.unlimitedScans,
          ProFeature.nextMealAdvice,
          ProFeature.fullHistory,
          ProFeature.reports,
        };
    }
  }
}
