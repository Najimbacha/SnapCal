import 'premium_conversion_service.dart';

enum ProFeature {
  unlimitedScans,
  aiDetection,
  mealInsights,
  reports,
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

  bool canUse(ProFeature feature, {required bool isPro}) {
    switch (feature) {
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
        return const {
          ProFeature.reports,
          ProFeature.mealInsights,
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
      case PaywallEntryPoint.adRemoval:
        return const {
          ProFeature.adRemoval,
          ProFeature.unlimitedScans,
          ProFeature.nextMealAdvice,
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
