import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/scan_gate_service.dart';
import '../data/services/pro_feature_service.dart';
import '../data/services/subscription_service.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/services/notification_service.dart';
import '../data/services/fcm_service.dart';
import '../core/nutrition/plan_math.dart';
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

/// Whether Pro status is known yet, and what it is.
///
/// The third state is the point. Reading `settings.valueOrNull?.isPro ?? false`
/// answers "free" for a user whose settings simply have not loaded — so a Pro
/// user was shown upgrade prompts during every cold start, and for a moment
/// after every provider refresh. "Not loaded" and "not subscribed" are
/// different answers and the UI has to be able to tell them apart.
enum ProStatus { unknown, free, pro }

/// The single answer to "what may this user do?".
///
/// Ask [can] for feature access and [shouldOfferUpgrade] before showing
/// anything that sells Pro. Never branch on [isPro] alone to decide whether to
/// show a paywall: that treats [ProStatus.unknown] as a free user.
class ProAccess {
  const ProAccess(this.status);

  final ProStatus status;

  /// True only when we know the user is subscribed.
  bool get isPro => status == ProStatus.pro;

  /// True only when we know the user is *not* subscribed.
  bool get isFree => status == ProStatus.free;

  /// Status has not resolved yet: show neither the feature nor the upsell.
  bool get isUnknown => status == ProStatus.unknown;

  /// Whether [feature] is unlocked, per [ProFeatureService].
  bool can(ProFeature feature) =>
      const ProFeatureService().canUse(feature, isPro: isPro);

  /// Whether a paywall card, lock badge or upgrade prompt may be shown for
  /// [feature]. False while status is unknown, by construction.
  bool shouldOfferUpgrade(ProFeature feature) => isFree && !can(feature);

  @override
  bool operator ==(Object other) =>
      other is ProAccess && other.status == status;

  @override
  int get hashCode => status.hashCode;
}

/// The one place Pro status is decided. Everything else reads this.
@Riverpod(keepAlive: true)
ProAccess proAccess(ProAccessRef ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (settings == null) return const ProAccess(ProStatus.unknown);

  var isPro = settings.isPro;
  if (kDebugMode && !isPro) {
    isPro = ref.watch(debugProOverrideProvider);
  }
  return ProAccess(isPro ? ProStatus.pro : ProStatus.free);
}

/// Whether Pro status has resolved. Guard delayed upsells with this.
@Riverpod(keepAlive: true)
bool isProResolved(IsProResolvedRef ref) =>
    !ref.watch(proAccessProvider).isUnknown;

/// Combines real Pro status with debug override.
/// In debug mode, the debug override can toggle Pro features on/off.
///
/// Kept as the plain-boolean view of [proAccessProvider] for the many call
/// sites that only gate a feature (where "unknown" and "free" behave the same
/// way — the feature stays locked until status resolves). Anything that *sells*
/// Pro must read [proAccessProvider] instead.
@Riverpod(keepAlive: true)
bool effectiveIsPro(EffectiveIsProRef ref) =>
    ref.watch(proAccessProvider).isPro;

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<UserSettings>? _settingsSubscription;

  @override
  Future<UserSettings> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    // Use the streak repair's result. The write stays fire-and-forget (it
    // reaches Firestore, which must not block first paint), but build() now
    // returns the *repaired* object. It used to return the stale one, and the
    // stream listener below was attached after the write, so the correction
    // was dropped and the UI disagreed with Hive until the next settings save.
    final settings = _validateStreakOnStart(repo.getSettings(), repo);
    _settingsSubscription = repo.settingsStream.listen((s) {
      state = AsyncData(s);
    });
    ref.onDispose(() => _settingsSubscription?.cancel());

    AppLifecycleService().addListener(_onLifecycleChanged);
    ref.onDispose(
      () => AppLifecycleService().removeListener(_onLifecycleChanged),
    );

    updateLastOpenedDate();
    _syncNotifications(settings);
    return settings;
  }

  UserSettings _validateStreakOnStart(
    UserSettings settings,
    SettingsRepository repo,
  ) {
    final today = app_date.DateUtils.getTodayString();
    final yesterday = app_date.DateUtils.getPreviousDay(today);
    final lastLogged = settings.lastLoggedDate;
    if (lastLogged != null && lastLogged != today && lastLogged != yesterday) {
      if (settings.currentStreak > 0) {
        final repaired = settings.copyWith(currentStreak: 0);
        unawaited(repo.saveSettings(repaired));
        return repaired;
      }
    }
    return settings;
  }

  void _onLifecycleChanged() {
    if (AppLifecycleService().isResumed) {
      updateLastOpenedDate();
    }
  }

  UserSettings? get _data => state.valueOrNull;

  // ── Internal helpers ──

  /// Pro status including the debug override (debug builds only).
  bool _effectiveIsPro(UserSettings s) {
    if (s.isPro) return true;
    if (kDebugMode) return ref.read(debugProOverrideProvider);
    return false;
  }

  Future<void> _updateSettings(UserSettings updated) async {
    state = AsyncData(updated);
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.saveSettings(updated);
    _syncNotifications(updated);
  }

  /// Re-reads Pro status from the store and the backend, and pushes the result
  /// into state.
  ///
  /// Use this instead of `ref.invalidate(settingsProvider)` after a purchase.
  /// Invalidating drops the provider back to `loading`, which makes every
  /// consumer briefly see "unknown" — including, before this change, as
  /// "free". This keeps the current value on screen and updates it in place.
  Future<void> refreshProStatus() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await SubscriptionService().verifyCurrentEntitlement();
    // The repository stream is the normal path, but emit directly too so the
    // update lands even if the listener has not been re-attached yet.
    state = AsyncData(repo.getSettings());
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
    final hasEngagedToday =
        s.lastOpenedDate == today || s.lastLoggedDate == today;
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
    if (breakfastHour == null ||
        breakfastMinute == null ||
        breakfastHour < 0 ||
        breakfastHour > 23 ||
        breakfastMinute < 0 ||
        breakfastMinute > 59) {
      return const MapEntry(8, 30);
    }
    const earliestMinuteOfDay = 8 * 60;
    const latestMinuteOfDay = 20 * 60;
    final preferred = (breakfastHour * 60 + breakfastMinute - 30).clamp(
      earliestMinuteOfDay,
      latestMinuteOfDay,
    );
    return MapEntry(preferred ~/ 60, preferred % 60);
  }

  List<MotivationNotificationCopy> _getDailyMotivationMessages(String lang) {
    final l10n = _localizationsFor(lang);
    return [
      MotivationNotificationCopy(
        title: l10n.notif_motivation_1_title,
        body: l10n.notif_motivation_1_body,
      ),
      MotivationNotificationCopy(
        title: l10n.notif_motivation_2_title,
        body: l10n.notif_motivation_2_body,
      ),
      MotivationNotificationCopy(
        title: l10n.notif_motivation_3_title,
        body: l10n.notif_motivation_3_body,
      ),
      MotivationNotificationCopy(
        title: l10n.notif_motivation_4_title,
        body: l10n.notif_motivation_4_body,
      ),
      MotivationNotificationCopy(
        title: l10n.notif_motivation_5_title,
        body: l10n.notif_motivation_5_body,
      ),
      MotivationNotificationCopy(
        title: l10n.notif_motivation_6_title,
        body: l10n.notif_motivation_6_body,
      ),
      MotivationNotificationCopy(
        title: l10n.notif_motivation_7_title,
        body: l10n.notif_motivation_7_body,
      ),
      MotivationNotificationCopy(
        title: l10n.notif_motivation_8_title,
        body: l10n.notif_motivation_8_body,
      ),
    ];
  }

  String _getNotifString(String lang, String key) {
    final l10n = _localizationsFor(lang);
    switch (key) {
      case 'breakfast_title':
        return l10n.notif_breakfast_title;
      case 'breakfast_body':
        return l10n.notif_breakfast_body;
      case 'lunch_title':
        return l10n.notif_lunch_title;
      case 'lunch_body':
        return l10n.notif_lunch_body;
      case 'dinner_title':
        return l10n.notif_dinner_title;
      case 'dinner_body':
        return l10n.notif_dinner_body;
      case 'goal_calories_title':
        return l10n.notif_goal_calories_title;
      case 'goal_calories_body':
        return l10n.notif_goal_calories_body('{goal}');
      case 'goal_protein_title':
        return l10n.notif_goal_protein_title;
      case 'goal_protein_body':
        return l10n.notif_goal_protein_body('{goal}');
      default:
        return '';
    }
  }

  String _supportedLanguage(String lang) {
    return AppLocalizations.supportedLocales.any((l) => l.languageCode == lang)
        ? lang
        : 'en';
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
    } catch (e) {
      debugPrint('❌ Settings: Reminder registration failed: $e');
    }
  }

  Future<void> triggerCalorieGoalAlert(int goal) async {
    final s = _data;
    if (s == null || !s.notificationsEnabled || !s.goalAlertsEnabled) return;
    final lang = s.languageCode ?? 'en';
    final title = _getNotifString(lang, 'goal_calories_title');
    final body = _getNotifString(
      lang,
      'goal_calories_body',
    ).replaceAll('{goal}', goal.toString());
    final l10n = _localizationsFor(lang);
    await _notificationService.showGoalAlert(
      title: title,
      body: body,
      channelName: l10n.notif_goal_alerts_channel,
      channelDescription: l10n.notif_goal_alerts_channel_description,
    );
  }

  Future<void> triggerProteinGoalAlert(int goal) async {
    final s = _data;
    if (s == null || !s.notificationsEnabled || !s.goalAlertsEnabled) return;
    final lang = s.languageCode ?? 'en';
    final title = _getNotifString(lang, 'goal_protein_title');
    final body = _getNotifString(
      lang,
      'goal_protein_body',
    ).replaceAll('{goal}', goal.toString());
    final l10n = _localizationsFor(lang);
    await _notificationService.showGoalAlert(
      title: title,
      body: body,
      channelName: l10n.notif_goal_alerts_channel,
      channelDescription: l10n.notif_goal_alerts_channel_description,
    );
  }

  Future<void> updateReminderTimes({
    String? breakfast,
    String? lunch,
    String? dinner,
  }) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(
      current.copyWith(
        breakfastTime: breakfast,
        lunchTime: lunch,
        dinnerTime: dinner,
      ),
    );
  }

  bool canAddMeal(int currentMealCount) {
    final s = _data;
    if (s == null) return true;
    if (_effectiveIsPro(s)) return true;
    return ScanGateService().canScan(false);
  }

  int getRemainingFreeMeals(int currentMealCount) {
    final s = _data;
    if (s == null) return -1;
    if (_effectiveIsPro(s)) return -1;
    // Ask the gate rather than re-deriving the number. This used to hardcode
    // `3 - count`, ignoring bonus scans, so a user who had earned extras was
    // told they had none left while canScan() happily allowed more.
    return ScanGateService().getRemainingScans(false);
  }

  /// The current macro targets as one object.
  MacroSplit get _currentSplit {
    final s = _data ?? UserSettings.defaults();
    return MacroSplit(
      protein: s.dailyProteinGoal,
      carbs: s.dailyCarbGoal,
      fat: s.dailyFatGoal,
    );
  }

  /// Sets the calorie target and scales the macros to match.
  ///
  /// Calories and macros describe one plan, and letting them disagree produced
  /// a user-visible lie: a 2000 kcal goal displayed directly above a macro
  /// chart that added up to 2500. The scaling holds the user's existing ratio
  /// rather than normalising it — someone eating high-protein chose that, and
  /// a calorie change is not the moment to overrule them.
  Future<void> updateCalorieGoal(int goal) async {
    final current = _data ?? UserSettings.defaults();
    final clamped = goal.clamp(PlanLimits.minCalories, PlanLimits.maxCalories);
    final split = rebalanceToCalories(
      current: _currentSplit,
      targetCalories: clamped,
    );

    await _updateSettings(
      current.copyWith(
        dailyCalorieGoal: clamped,
        dailyProteinGoal: split.protein,
        dailyCarbGoal: split.carbs,
        dailyFatGoal: split.fat,
      ),
    );
  }

  /// Applies a macro change and moves the calorie target to match it.
  ///
  /// The reverse direction of [updateCalorieGoal]. Editing one macro is an
  /// explicit statement about that macro, so the other two are left exactly as
  /// they are and the calorie total absorbs the change — anything else would
  /// silently edit a number the user did not touch.
  Future<void> _applyMacroChange(MacroSplit split) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(
      current.copyWith(
        dailyProteinGoal: split.protein,
        dailyCarbGoal: split.carbs,
        dailyFatGoal: split.fat,
        dailyCalorieGoal: split.kcal.clamp(
          PlanLimits.minCalories,
          PlanLimits.maxCalories,
        ),
      ),
    );
  }

  Future<void> updateProteinGoal(int goal) =>
      _applyMacroChange(_currentSplit.copyWith(protein: goal));

  Future<void> updateCarbGoal(int goal) =>
      _applyMacroChange(_currentSplit.copyWith(carbs: goal));

  Future<void> updateFatGoal(int goal) =>
      _applyMacroChange(_currentSplit.copyWith(fat: goal));

  Future<void> updateBodyProfile({
    double? height,
    double? targetWeight,
    int? age,
    String? gender,
    String? activityLevel,
    double? currentWeightKg,
    bool recalculateNutrition = true,
  }) async {
    final current = _data ?? UserSettings.defaults();
    final updated = current.copyWith(
      height: height,
      targetWeight: targetWeight,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
    );
    await _updateSettings(updated);
    if (recalculateNutrition) {
      await _recalculatePlanIfProfileComplete(currentWeightKg);
    }
  }

  Future<void> updateCoachProfile({
    double? height,
    double? targetWeight,
    int? age,
    String? gender,
    String? activityLevel,
    String? dietaryRestriction,
    String? foodDislikes,
    String? medicalNotes,
    double? startingWeight,
    String? goalMode,
    bool recalculateNutrition = true,
  }) async {
    final current = _data ?? UserSettings.defaults();
    final updated = current.copyWith(
      height: height,
      targetWeight: targetWeight,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      dietaryRestriction: dietaryRestriction,
      foodDislikes: foodDislikes,
      medicalNotes: medicalNotes,
      startingWeight: startingWeight,
      goalMode: goalMode,
    );
    await _updateSettings(updated);
    if (recalculateNutrition) {
      await _recalculatePlanIfProfileComplete(startingWeight);
    }
  }

  Future<void> updatePlannerPreferences({
    int? mealsPerDay,
    String? dietaryRestriction,
    String? cuisinePreference,
  }) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(
      current.copyWith(
        mealsPerDay: mealsPerDay,
        dietaryRestriction: dietaryRestriction,
        cuisinePreference: cuisinePreference,
      ),
    );
  }

  Future<void> updateUnits({String? weightUnit, String? heightUnit}) async {
    final current = _data ?? UserSettings.defaults();
    await _updateSettings(
      current.copyWith(weightUnit: weightUnit, heightUnit: heightUnit),
    );
  }

  Future<String> exportUserData() async {
    final s = _data ?? UserSettings.defaults();
    final l10n = _localizationsFor(s.languageCode ?? 'en');
    return '${l10n.settings_export_data}: ${s.dailyCalorieGoal} kcal';
  }

  Future<void> completeOnboarding({
    required OnboardingProfileInput profile,
    required OnboardingRecommendation recommendation,
  }) async {
    final current = _data ?? UserSettings.defaults();
    final updated = current.copyWith(
      dailyCalorieGoal: recommendation.dailyCalories,
      dailyProteinGoal: recommendation.proteinGrams,
      dailyCarbGoal: recommendation.carbGrams,
      dailyFatGoal: recommendation.fatGrams,
      age: profile.age,
      gender: profile.gender,
      activityLevel: profile.activityLevel,
      goalTimelineMonths: profile.timelineMonths,
      startingWeight: profile.currentWeightKg,
      height: profile.heightCm,
      targetWeight: profile.goalWeightKg,
      weightUnit: profile.weightUnit,
      heightUnit: profile.heightUnit,
      goalMode: recommendation.goalMode,
      weeklyRateKg: recommendation.weeklyRateKg,
      recommendationInsight: recommendation.insight,
      recommendationTip: recommendation.tip,
      recommendationSafetyNote: recommendation.safetyNote,
      onboardingComplete: true,
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
      await _updateSettings(
        s.copyWith(currentStreak: 1, lastLoggedDate: logDate),
      );
    } else if (lastLogged == logDate) {
      return;
    } else {
      try {
        final lastDate = DateTime.parse(lastLogged);
        final currentDate = DateTime.parse(logDate);
        if (currentDate.isBefore(lastDate)) return;
      } catch (e) {
        debugPrint('⚠️ Settings: Streak date parse failed: $e');
      }
      final dayBeforeLog = app_date.DateUtils.getPreviousDay(logDate);
      if (lastLogged == dayBeforeLog) {
        await _updateSettings(
          s.copyWith(
            currentStreak: s.currentStreak + 1,
            lastLoggedDate: logDate,
          ),
        );
      } else {
        await _updateSettings(
          s.copyWith(currentStreak: 1, lastLoggedDate: logDate),
        );
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

  Future<void> adjustStreakOnDeletion({
    required String dateOfDeletedMeal,
    required bool wasLastMealOfDay,
  }) async {
    if (!wasLastMealOfDay) return;
    final s = _data;
    if (s == null) return;
    if (s.lastLoggedDate != dateOfDeletedMeal) return;

    // Recompute from the meals that actually exist, rather than decrementing
    // and rolling `lastLoggedDate` back a calendar day. The old version
    // invented a logged day: delete today's only meal after a break and the
    // app believed you had logged yesterday, so the next meal extended a
    // streak that was never earned.
    final repo = await ref.read(mealRepositoryProvider.future);
    final loggedDays = repo.getAllMeals().map((m) => m.dateString).toSet();

    if (loggedDays.isEmpty) {
      await _updateSettings(
        s.copyWith(currentStreak: 0, clearLastLoggedDate: true),
      );
      return;
    }

    final sortedDays = loggedDays.toList()..sort();
    final mostRecent = sortedDays.last;

    var streak = 1;
    var cursor = mostRecent;
    while (true) {
      final previous = app_date.DateUtils.getPreviousDay(cursor);
      if (!loggedDays.contains(previous)) break;
      streak++;
      cursor = previous;
    }

    await _updateSettings(
      s.copyWith(currentStreak: streak, lastLoggedDate: mostRecent),
    );
  }

  Future<bool> recalculatePlan({required double currentWeightKg}) async {
    final s = _data;
    if (s == null) return false;
    if (s.age == null ||
        s.gender == null ||
        s.height == null ||
        s.targetWeight == null) {
      return false;
    }
    try {
      final service = CalorieOnboardingService();
      final input = OnboardingProfileInput(
        age: s.age!,
        gender: s.gender!,
        heightCm: s.height!,
        currentWeightKg: currentWeightKg,
        goalWeightKg: s.targetWeight!,
        timelineMonths: s.goalTimelineMonths ?? 6,
        activityLevel: s.activityLevel ?? 'active',
        weightUnit: s.weightUnit ?? 'kg',
        heightUnit: s.heightUnit ?? 'cm',
      );
      final recommendation = await service.buildRecommendation(
        input,
        languageCode: s.languageCode ?? 'en',
      );
      await _updateSettings(
        s.copyWith(
          dailyCalorieGoal: recommendation.dailyCalories,
          dailyProteinGoal: recommendation.proteinGrams,
          dailyCarbGoal: recommendation.carbGrams,
          dailyFatGoal: recommendation.fatGrams,
          startingWeight: currentWeightKg,
          goalMode: recommendation.goalMode,
          weeklyRateKg: recommendation.weeklyRateKg,
          recommendationInsight: recommendation.insight,
          recommendationTip: recommendation.tip,
          recommendationSafetyNote: recommendation.safetyNote,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('❌ Settings: Recalculation failed: $e');
      return false;
    }
  }

  Future<bool> _recalculatePlanIfProfileComplete(
    double? preferredCurrentWeightKg,
  ) async {
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
