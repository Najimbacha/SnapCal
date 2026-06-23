import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/scan_gate_service.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/services/notification_service.dart';
import '../data/services/fcm_service.dart';
import '../data/services/calorie_onboarding_service.dart';
import '../core/network/api_client.dart';
import '../core/services/config_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/services/app_lifecycle_service.dart';
import 'repository_providers.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class DebugProOverride extends _$DebugProOverride {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void enable() => state = true;
  void disable() => state = false;
}

/// Combines real Pro status with debug override.
/// In debug mode, the debug override can toggle Pro features on/off.
@Riverpod(keepAlive: true)
bool effectiveIsPro(EffectiveIsProRef ref) {
  final realPro = ref.watch(settingsProvider).valueOrNull?.isPro ?? false;
  if (kDebugMode) {
    final debugOverride = ref.watch(debugProOverrideProvider);
    return realPro || debugOverride;
  }
  return realPro;
}

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<UserSettings>? _settingsSubscription;

  @override
  Future<UserSettings> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    final settings = repo.getSettings();
    _validateStreakOnStart(settings, repo);
    _settingsSubscription = repo.settingsStream.listen((s) {
      state = AsyncData(s);
    });
    ref.onDispose(() => _settingsSubscription?.cancel());

    AppLifecycleService().addListener(_onLifecycleChanged);
    ref.onDispose(() => AppLifecycleService().removeListener(_onLifecycleChanged));

    updateLastOpenedDate();
    _syncNotifications(settings);
    return settings;
  }

  void _validateStreakOnStart(UserSettings settings, SettingsRepository repo) {
    final today = app_date.DateUtils.getTodayString();
    final yesterday = app_date.DateUtils.getPreviousDay(today);
    final lastLogged = settings.lastLoggedDate;
    if (lastLogged != null && lastLogged != today && lastLogged != yesterday) {
      if (settings.currentStreak > 0) {
        repo.saveSettings(settings.copyWith(currentStreak: 0));
      }
    }
  }

  void _onLifecycleChanged() {
    if (AppLifecycleService().isResumed) {
      updateLastOpenedDate();
    }
  }

  UserSettings? get _data => state.valueOrNull;

  // ── Internal helpers ──

  Future<void> _updateSettings(UserSettings updated) async {
    state = AsyncData(updated);
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.saveSettings(updated);
    _syncNotifications(updated);
  }

  void _syncNotifications(UserSettings s) {
    unawaited(_performNotificationSync(s));
  }

  Future<void> _performNotificationSync(UserSettings s) async {
    if (!s.notificationsEnabled) {
      await _notificationService.cancelAll();
      return;
    }
    if (s.mealRemindersEnabled) {
      await _scheduleReminders(s);
    } else {
      await _notificationService.cancelNotification(1);
      await _notificationService.cancelNotification(2);
      await _notificationService.cancelNotification(3);
    }
    if (s.dailyMotivationEnabled) {
      await _scheduleDailyMotivation(s);
    } else {
      await _notificationService.cancelDailyMotivation();
    }
    if (s.foodRemindersEnabled) {
      final fcm = FcmService();
      if (s.fcmToken != fcm.cachedToken) {
        final updated = s.copyWith(fcmToken: fcm.cachedToken);
        final repo = await ref.read(settingsRepositoryProvider.future);
        await repo.saveSettings(updated);
        state = AsyncData(updated);
      }
    }
  }

  Future<void> _scheduleReminders(UserSettings s) async {
    final times = {1: s.breakfastTime, 2: s.lunchTime, 3: s.dinnerTime};
    final lang = s.languageCode ?? 'en';
    final l10n = _localizationsFor(lang);
    final titles = {
      1: _getNotifString(lang, 'breakfast_title'),
      2: _getNotifString(lang, 'lunch_title'),
      3: _getNotifString(lang, 'dinner_title'),
    };
    final bodies = {
      1: _getNotifString(lang, 'breakfast_body'),
      2: _getNotifString(lang, 'lunch_body'),
      3: _getNotifString(lang, 'dinner_body'),
    };
    for (final entry in times.entries) {
      final parts = entry.value.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        await _notificationService.scheduleDailyReminder(
          id: entry.key,
          title: titles[entry.key]!,
          body: bodies[entry.key]!,
          channelName: l10n.notif_meal_reminders_channel,
          channelDescription: l10n.notif_meal_reminders_channel_description,
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  Future<void> _scheduleDailyMotivation(UserSettings s) async {
    final time = _getDailyMotivationTime(s);
    final l10n = _localizationsFor(s.languageCode ?? 'en');
    final today = app_date.DateUtils.getTodayString();
    final hasEngagedToday = s.lastOpenedDate == today || s.lastLoggedDate == today;
    await _notificationService.scheduleDailyMotivation(
      messages: _getDailyMotivationMessages(s.languageCode ?? 'en'),
      channelName: l10n.notif_daily_motivation_channel,
      channelDescription: l10n.notif_daily_motivation_channel_description,
      hour: time.key,
      minute: time.value,
      skipToday: hasEngagedToday,
    );
  }

  MapEntry<int, int> _getDailyMotivationTime(UserSettings s) {
    final parts = s.breakfastTime.split(':');
    if (parts.length != 2) return const MapEntry(8, 30);
    final breakfastHour = int.tryParse(parts[0]);
    final breakfastMinute = int.tryParse(parts[1]);
    if (breakfastHour == null || breakfastMinute == null || breakfastHour < 0 || breakfastHour > 23 || breakfastMinute < 0 || breakfastMinute > 59) {
      return const MapEntry(8, 30);
    }
    const earliestMinuteOfDay = 8 * 60;
    const latestMinuteOfDay = 20 * 60;
    final preferred = (breakfastHour * 60 + breakfastMinute - 30).clamp(earliestMinuteOfDay, latestMinuteOfDay);
    return MapEntry(preferred ~/ 60, preferred % 60);
  }

  List<MotivationNotificationCopy> _getDailyMotivationMessages(String lang) {
    final l10n = _localizationsFor(lang);
    return [
      MotivationNotificationCopy(title: l10n.notif_motivation_1_title, body: l10n.notif_motivation_1_body),
      MotivationNotificationCopy(title: l10n.notif_motivation_2_title, body: l10n.notif_motivation_2_body),
      MotivationNotificationCopy(title: l10n.notif_motivation_3_title, body: l10n.notif_motivation_3_body),
      MotivationNotificationCopy(title: l10n.notif_motivation_4_title, body: l10n.notif_motivation_4_body),
      MotivationNotificationCopy(title: l10n.notif_motivation_5_title, body: l10n.notif_motivation_5_body),
      MotivationNotificationCopy(title: l10n.notif_motivation_6_title, body: l10n.notif_motivation_6_body),
      MotivationNotificationCopy(title: l10n.notif_motivation_7_title, body: l10n.notif_motivation_7_body),
      MotivationNotificationCopy(title: l10n.notif_motivation_8_title, body: l10n.notif_motivation_8_body),
    ];
  }

  String _getNotifString(String lang, String key) {
    final l10n = _localizationsFor(lang);
    switch (key) {
      case 'breakfast_title': return l10n.notif_breakfast_title;
      case 'breakfast_body': return l10n.notif_breakfast_body;
      case 'lunch_title': return l10n.notif_lunch_title;
      case 'lunch_body': return l10n.notif_lunch_body;
      case 'dinner_title': return l10n.notif_dinner_title;
      case 'dinner_body': return l10n.notif_dinner_body;
      case 'goal_calories_title': return l10n.notif_goal_calories_title;
      case 'goal_calories_body': return l10n.notif_goal_calories_body('{goal}');
      case 'goal_protein_title': return l10n.notif_goal_protein_title;
      case 'goal_protein_body': return l10n.notif_goal_protein_body('{goal}');
      default: return '';
    }
  }

  String _supportedLanguage(String lang) {
    return AppLocalizations.supportedLocales.any((l) => l.languageCode == lang) ? lang : 'en';
  }

  AppLocalizations _localizationsFor(String lang) {
    return lookupAppLocalizations(Locale(_supportedLanguage(lang)));
  }

  // ── Public API ──

  bool isPro(UserSettings s) => s.isPro;

  Future<void> setLanguage(String code) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(languageCode: code));
  }

  Future<void> toggleNotifications(bool enabled) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(notificationsEnabled: enabled));
  }

  Future<void> toggleMealReminders(bool enabled) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(mealRemindersEnabled: enabled));
  }

  Future<void> toggleDailyMotivation(bool enabled) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(dailyMotivationEnabled: enabled));
  }

  Future<void> toggleGoalAlerts(bool enabled) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(goalAlertsEnabled: enabled));
  }

  Future<void> toggleFoodReminders(bool enabled) async {
    final current = _data ?? UserSettings.defaults();
    final fcm = FcmService();
    final updated = current.copyWith(foodRemindersEnabled: enabled);
    if (enabled) {
      final token = fcm.cachedToken;
      await _updateSettings(updated.copyWith(fcmToken: token));
      await fcm.subscribeToFoodReminders();
    } else {
      await _updateSettings(updated.copyWith(fcmToken: null));
      await fcm.unsubscribeFromFoodReminders();
    }
    try {
      await ApiClient.dio.post(
        '${ConfigService().backendProxyUrl}/api/notifications/food-reminder/register',
        data: {'fcmToken': fcm.cachedToken, 'enabled': enabled},
      );
    } catch (_) {}
  }

  Future<void> triggerCalorieGoalAlert(int goal) async {
    final s = _data;
    if (s == null || !s.notificationsEnabled || !s.goalAlertsEnabled) return;
    final lang = s.languageCode ?? 'en';
    final title = _getNotifString(lang, 'goal_calories_title');
    final body = _getNotifString(lang, 'goal_calories_body').replaceAll('{goal}', goal.toString());
    final l10n = _localizationsFor(lang);
    await _notificationService.showGoalAlert(title: title, body: body, channelName: l10n.notif_goal_alerts_channel, channelDescription: l10n.notif_goal_alerts_channel_description);
  }

  Future<void> triggerProteinGoalAlert(int goal) async {
    final s = _data;
    if (s == null || !s.notificationsEnabled || !s.goalAlertsEnabled) return;
    final lang = s.languageCode ?? 'en';
    final title = _getNotifString(lang, 'goal_protein_title');
    final body = _getNotifString(lang, 'goal_protein_body').replaceAll('{goal}', goal.toString());
    final l10n = _localizationsFor(lang);
    await _notificationService.showGoalAlert(title: title, body: body, channelName: l10n.notif_goal_alerts_channel, channelDescription: l10n.notif_goal_alerts_channel_description);
  }

  Future<void> updateReminderTimes({String? breakfast, String? lunch, String? dinner}) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(breakfastTime: breakfast, lunchTime: lunch, dinnerTime: dinner));
  }

  bool canAddMeal(int currentMealCount) {
    final s = _data;
    if (s == null || s.isPro) return true;
    return ScanGateService().canScan(false);
  }

  int getRemainingFreeMeals(int currentMealCount) {
    final s = _data;
    if (s == null || s.isPro) return -1;
    final count = ScanGateService().getTodayScanCount();
    return (3 - count).clamp(0, 3);
  }

  Future<void> updateCalorieGoal(int goal) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(dailyCalorieGoal: goal));
  }

  Future<void> updateProteinGoal(int goal) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(dailyProteinGoal: goal));
  }

  Future<void> updateCarbGoal(int goal) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(dailyCarbGoal: goal));
  }

  Future<void> updateFatGoal(int goal) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(dailyFatGoal: goal));
  }

  Future<void> updateBodyProfile({double? height, double? targetWeight, int? age, String? gender, String? activityLevel, double? currentWeightKg, bool recalculateNutrition = true}) async {
    final current = _data ?? UserSettings.defaults();
    final updated = current.copyWith(height: height, targetWeight: targetWeight, age: age, gender: gender, activityLevel: activityLevel);
    await _updateSettings(updated);
    if (recalculateNutrition) {
      await _recalculatePlanIfProfileComplete(currentWeightKg);
    }
  }

  Future<void> updateCoachProfile({double? height, double? targetWeight, int? age, String? gender, String? activityLevel, String? dietaryRestriction, String? foodDislikes, String? medicalNotes, double? startingWeight, String? goalMode, bool recalculateNutrition = true}) async {
    final current = _data ?? UserSettings.defaults();
    final updated = current.copyWith(height: height, targetWeight: targetWeight, age: age, gender: gender, activityLevel: activityLevel, dietaryRestriction: dietaryRestriction, foodDislikes: foodDislikes, medicalNotes: medicalNotes, startingWeight: startingWeight, goalMode: goalMode);
    await _updateSettings(updated);
    if (recalculateNutrition) {
      await _recalculatePlanIfProfileComplete(startingWeight);
    }
  }

  Future<void> updatePlannerPreferences({int? mealsPerDay, String? dietaryRestriction, String? cuisinePreference}) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(mealsPerDay: mealsPerDay, dietaryRestriction: dietaryRestriction, cuisinePreference: cuisinePreference));
  }

  Future<void> updateUnits({String? weightUnit, String? heightUnit}) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(weightUnit: weightUnit, heightUnit: heightUnit));
  }

  Future<String> exportUserData() async {
    final s = _data ?? UserSettings.defaults();
    final l10n = _localizationsFor(s.languageCode ?? 'en');
    return '${l10n.settings_export_data}: ${s.dailyCalorieGoal} kcal';
  }

  Future<void> completeOnboarding({required OnboardingProfileInput profile, required OnboardingRecommendation recommendation}) async {
    final current = _data ?? UserSettings.defaults();
    final updated = current.copyWith(
      dailyCalorieGoal: recommendation.dailyCalories, dailyProteinGoal: recommendation.proteinGrams,
      dailyCarbGoal: recommendation.carbGrams, dailyFatGoal: recommendation.fatGrams,
      age: profile.age, gender: profile.gender, activityLevel: profile.activityLevel,
      goalTimelineMonths: profile.timelineMonths, startingWeight: profile.currentWeightKg,
      height: profile.heightCm, targetWeight: profile.goalWeightKg,
      weightUnit: profile.weightUnit, heightUnit: profile.heightUnit,
      goalMode: recommendation.goalMode, weeklyRateKg: recommendation.weeklyRateKg,
      recommendationInsight: recommendation.insight, recommendationTip: recommendation.tip,
      recommendationSafetyNote: recommendation.safetyNote, onboardingComplete: true,
    );
    await _updateSettings(updated);
  }

  Future<void> setThemeMode(String mode) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(current.copyWith(themeMode: mode));
  }

  Future<void> updateStreakOnMealLog({String? mealDate}) async {
    final s = _data;
    if (s == null) return;
    final today = app_date.DateUtils.getTodayString();
    final logDate = mealDate ?? today;
    final lastLogged = s.lastLoggedDate;

    if (lastLogged == null) {
      await _updateSettings(s.copyWith(currentStreak: 1, lastLoggedDate: logDate));
    } else if (lastLogged == logDate) {
      return;
    } else {
      try {
        final lastDate = DateTime.parse(lastLogged);
        final currentDate = DateTime.parse(logDate);
        if (currentDate.isBefore(lastDate)) return;
      } catch (_) {}
      final dayBeforeLog = app_date.DateUtils.getPreviousDay(logDate);
      if (lastLogged == dayBeforeLog) {
        await _updateSettings(s.copyWith(currentStreak: s.currentStreak + 1, lastLoggedDate: logDate));
      } else {
        await _updateSettings(s.copyWith(currentStreak: 1, lastLoggedDate: logDate));
      }
    }
  }

  Future<void> updateLastOpenedDate() async {
    final s = _data;
    if (s == null) return;
    final today = app_date.DateUtils.getTodayString();
    if (s.lastOpenedDate != today) {
      await _updateSettings(s.copyWith(lastOpenedDate: today));
    }
  }

  Future<void> adjustStreakOnDeletion({required String dateOfDeletedMeal, required bool wasLastMealOfDay}) async {
    if (!wasLastMealOfDay) return;
    final s = _data;
    if (s == null) return;
    if (s.lastLoggedDate == dateOfDeletedMeal) {
      final newStreak = (s.currentStreak - 1).clamp(0, 9999);
      final previousDay = app_date.DateUtils.getPreviousDay(dateOfDeletedMeal);
      await _updateSettings(s.copyWith(currentStreak: newStreak, lastLoggedDate: newStreak == 0 ? null : previousDay));
    }
  }

  Future<bool> recalculatePlan({required double currentWeightKg}) async {
    final s = _data;
    if (s == null) return false;
    if (s.age == null || s.gender == null || s.height == null || s.targetWeight == null) return false;
    try {
      final service = CalorieOnboardingService();
      final input = OnboardingProfileInput(
        age: s.age!, gender: s.gender!, heightCm: s.height!,
        currentWeightKg: currentWeightKg, goalWeightKg: s.targetWeight!,
        timelineMonths: s.goalTimelineMonths ?? 6, activityLevel: s.activityLevel ?? 'active',
        weightUnit: s.weightUnit ?? 'kg', heightUnit: s.heightUnit ?? 'cm',
      );
      final recommendation = await service.buildRecommendation(input, languageCode: s.languageCode ?? 'en');
      await _updateSettings(s.copyWith(
        dailyCalorieGoal: recommendation.dailyCalories, dailyProteinGoal: recommendation.proteinGrams,
        dailyCarbGoal: recommendation.carbGrams, dailyFatGoal: recommendation.fatGrams,
        startingWeight: currentWeightKg, goalMode: recommendation.goalMode,
        weeklyRateKg: recommendation.weeklyRateKg, recommendationInsight: recommendation.insight,
        recommendationTip: recommendation.tip, recommendationSafetyNote: recommendation.safetyNote,
      ));
      return true;
    } catch (e) {
      debugPrint('❌ Settings: Recalculation failed: $e');
      return false;
    }
  }

  Future<bool> _recalculatePlanIfProfileComplete(double? preferredCurrentWeightKg) async {
    final s = _data;
    if (s == null) return false;
    final currentWeightKg = preferredCurrentWeightKg ?? s.startingWeight;
    if (currentWeightKg == null) return false;
    return recalculatePlan(currentWeightKg: currentWeightKg);
  }

  Future<void> clear() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.clear();
    state = AsyncData(UserSettings.defaults());
  }
}
