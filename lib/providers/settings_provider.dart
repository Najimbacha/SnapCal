import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/scan_gate_service.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/services/notification_service.dart';
import '../data/services/calorie_onboarding_service.dart';
import '../core/network/api_client.dart';
import '../core/services/config_service.dart';
import '../core/state/async_ui_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/services/app_lifecycle_service.dart';

/// Provider for managing user settings and subscription state
class SettingsProvider with ChangeNotifier {
  // Pro display state is cached locally, but authorization is enforced by the
  // backend from server-verified subscription records.
  static const bool debugForcePro = false;

  final SettingsRepository _repository;
  final NotificationService _notificationService = NotificationService();

  late UserSettings _settings;
  AsyncUiState _uiState = const AsyncUiState.success();
  StreamSubscription<UserSettings>? _settingsSubscription;
  Future<void> _notificationSync = Future.value();

  SettingsProvider(this._repository) {
    _loadInitialSettings();
    _validateStreakOnStart();
    AppLifecycleService().addListener(_onLifecycleChanged);
  }

  /// Ensure streak isn't stale when app opens.
  /// If the last logged date is more than 1 day ago, the consecutive streak
  /// is broken. Set to 0 so the next meal log can restart it at 1.
  /// Do NOT alter lastLoggedDate — that reflects the actual last logged day.
  void _validateStreakOnStart() {
    final today = app_date.DateUtils.getTodayString();
    final yesterday = app_date.DateUtils.getPreviousDay(today);
    final lastLogged = _settings.lastLoggedDate;

    if (lastLogged != null && lastLogged != today && lastLogged != yesterday) {
      // Streak broken due to inactivity. Set the consecutive counter to 0
      // (the chain is broken), but keep lastLoggedDate unchanged so the
      // next meal log correctly restarts at 1 (not 0).
      if (_settings.currentStreak > 0) {
        _settings = _settings.copyWith(currentStreak: 0);
        _repository.saveSettings(_settings);
        notifyListeners();
      }
    }
  }

  void _loadInitialSettings() {
    try {
      _settings = _repository.getSettings();
    } catch (e) {
      debugPrint('⚠️ SettingsProvider: Error loading initial settings: $e');
      _settings = UserSettings.defaults();
    }

    _settingsSubscription = _repository.settingsStream.listen((newSettings) {
      _settings = newSettings;
      _syncNotifications();
      notifyListeners();
    });
    _syncNotifications();
    updateLastOpenedDate();
  }

  @override
  void dispose() {
    AppLifecycleService().removeListener(_onLifecycleChanged);
    _settingsSubscription?.cancel();
    super.dispose();
  }

  void _onLifecycleChanged() {
    if (AppLifecycleService().isResumed) {
      updateLastOpenedDate();
    }
  }

  // Getters
  SettingsRepository get repository =>
      _repository; // Expose for mock subscription service
  UserSettings get settings => _settings;
  bool get isLoading => _uiState.isBlocking;
  bool get isRefreshing => _uiState.isRefreshing;
  AsyncUiState get uiState => _uiState;
  bool? _debugProOverride;
  bool get isPro {
    if (kDebugMode && _debugProOverride != null) {
      return _debugProOverride!;
    }
    return _settings.isPro;
  }
  // Debug helpers for testing Pro features
  void toggleDebugPro() {
    assert(() {
      _debugProOverride = _debugProOverride == null ? true : !_debugProOverride!;
      debugPrint('🔧 Debug Pro: ${_debugProOverride! ? "ENABLED" : "DISABLED"}');
      _syncDebugProToBackend(_debugProOverride!);
      notifyListeners();
      return true;
    }());
  }

  Future<void> _syncDebugProToBackend(bool enable) async {
    try {
      final path = enable ? '/api/debug/grant-premium' : '/api/debug/revoke-premium';
      await ApiClient.dio.post('${ConfigService().backendProxyUrl}$path');
      debugPrint('🔧 Debug Pro synced to backend: $enable');
    } catch (e) {
      debugPrint('⚠️ Debug Pro sync failed (backend may not have debug routes): $e');
    }
  }

  int get currentStreak => _settings.currentStreak;

  int get dailyCalorieGoal => _settings.dailyCalorieGoal;
  int get dailyProteinGoal => _settings.dailyProteinGoal;
  int get dailyCarbGoal => _settings.dailyCarbGoal;
  int get dailyFatGoal => _settings.dailyFatGoal;
  double? get height => _settings.height;
  double? get targetWeight => _settings.targetWeight;
  int? get age => _settings.age;
  String? get gender => _settings.gender;
  String? get activityLevel => _settings.activityLevel;
  int? get goalTimelineMonths => _settings.goalTimelineMonths;
  double? get startingWeight => _settings.startingWeight;
  String get weightUnit => _settings.weightUnit ?? 'kg';
  String get heightUnit => _settings.heightUnit ?? 'cm';
  String get goalMode => _settings.goalMode ?? 'maintain';
  double get weeklyRateKg => _settings.weeklyRateKg ?? 0.0;
  String get recommendationInsight => _settings.recommendationInsight ?? '';
  String get recommendationTip => _settings.recommendationTip ?? '';
  String get recommendationSafetyNote =>
      _settings.recommendationSafetyNote ?? '';

  // Planner Preferences
  int get mealsPerDay => _settings.mealsPerDay ?? 3;
  String get dietaryRestriction => _settings.dietaryRestriction ?? 'none';
  String get cuisinePreference =>
      _settings.cuisinePreference ?? 'international';

  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get mealRemindersEnabled => _settings.mealRemindersEnabled;
  bool get goalAlertsEnabled => _settings.goalAlertsEnabled;
  bool get dailyMotivationEnabled => _settings.dailyMotivationEnabled;
  String get themeMode => _settings.themeMode;
  bool get onboardingComplete => _settings.onboardingComplete;
  String get breakfastTime => _settings.breakfastTime;
  String get lunchTime => _settings.lunchTime;
  String get dinnerTime => _settings.dinnerTime;
  String get languageCode => _settings.languageCode ?? 'en';
  String? get lastOpenedDate => _settings.lastOpenedDate;
  String? get foodDislikes => _settings.foodDislikes;
  String? get medicalNotes => _settings.medicalNotes;

  /// Update language
  Future<void> setLanguage(String code) async {
    _settings = _settings.copyWith(languageCode: code);
    await _repository.saveSettings(_settings);
    await _syncNotifications();
    notifyListeners();
  }

  /// Load settings from repository
  void _loadSettings() {
    _settings = _repository.getSettings();
    notifyListeners();
  }

  /// Sync notifications with current settings
  Future<void> _syncNotifications() async {
    final nextSync = _notificationSync
        .catchError((_) {})
        .then((_) => _performNotificationSync());
    _notificationSync = nextSync;
    return nextSync;
  }

  Future<void> _performNotificationSync() async {
    if (!_settings.notificationsEnabled) {
      await _notificationService.cancelAll();
      return;
    }

    if (_settings.mealRemindersEnabled) {
      await _scheduleReminders();
    } else {
      await _notificationService.cancelNotification(1);
      await _notificationService.cancelNotification(2);
      await _notificationService.cancelNotification(3);
    }

    if (_settings.dailyMotivationEnabled) {
      await _scheduleDailyMotivation();
    } else {
      await _notificationService.cancelDailyMotivation();
    }
  }

  /// Schedule daily meal reminders
  Future<void> _scheduleReminders() async {
    final times = {
      1: _settings.breakfastTime,
      2: _settings.lunchTime,
      3: _settings.dinnerTime,
    };
    final lang = languageCode;
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

    for (var entry in times.entries) {
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

  /// Schedule daily motivation at the user's best local time.
  Future<void> _scheduleDailyMotivation() async {
    final time = _getDailyMotivationTime();
    final l10n = _localizationsFor(languageCode);
    final today = app_date.DateUtils.getTodayString();
    final hasEngagedToday =
        _settings.lastOpenedDate == today || _settings.lastLoggedDate == today;
    await _notificationService.scheduleDailyMotivation(
      messages: _getDailyMotivationMessages(languageCode),
      channelName: l10n.notif_daily_motivation_channel,
      channelDescription: l10n.notif_daily_motivation_channel_description,
      hour: time.key,
      minute: time.value,
      skipToday: hasEngagedToday,
    );
  }

  MapEntry<int, int> _getDailyMotivationTime() {
    final parts = _settings.breakfastTime.split(':');
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
    final preferredMinuteOfDay = (breakfastHour * 60 + breakfastMinute - 30)
        .clamp(earliestMinuteOfDay, latestMinuteOfDay);

    return MapEntry(preferredMinuteOfDay ~/ 60, preferredMinuteOfDay % 60);
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

  /// Toggle global notifications
  Future<void> toggleNotifications(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _repository.saveSettings(_settings);
    await _syncNotifications();
    notifyListeners();
  }

  /// Toggle meal reminders
  Future<void> toggleMealReminders(bool enabled) async {
    _settings = _settings.copyWith(mealRemindersEnabled: enabled);
    await _repository.saveSettings(_settings);
    await _syncNotifications();
    notifyListeners();
  }

  /// Toggle daily motivation
  Future<void> toggleDailyMotivation(bool enabled) async {
    _settings = _settings.copyWith(dailyMotivationEnabled: enabled);
    await _repository.saveSettings(_settings);
    await _syncNotifications();
    notifyListeners();
  }

  /// Toggle goal alerts
  Future<void> toggleGoalAlerts(bool enabled) async {
    _settings = _settings.copyWith(goalAlertsEnabled: enabled);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Trigger calorie goal alert
  Future<void> triggerCalorieGoalAlert(int goal) async {
    if (_settings.notificationsEnabled && _settings.goalAlertsEnabled) {
      final lang = languageCode;
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
  }

  /// Trigger protein goal alert
  Future<void> triggerProteinGoalAlert(int goal) async {
    if (_settings.notificationsEnabled && _settings.goalAlertsEnabled) {
      final lang = languageCode;
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
  }

  /// Update reminder times
  Future<void> updateReminderTimes({
    String? breakfast,
    String? lunch,
    String? dinner,
  }) async {
    _settings = _settings.copyWith(
      breakfastTime: breakfast,
      lunchTime: lunch,
      dinnerTime: dinner,
    );
    await _repository.saveSettings(_settings);
    await _syncNotifications();
    notifyListeners();
  }

  /// Check if user can add more meals today (free tier limit)
  bool canAddMeal(int currentMealCount) {
    if (isPro) return true;
    return ScanGateService().canScan(false);
  }

  /// Get remaining free meals today
  int getRemainingFreeMeals(int currentMealCount) {
    if (isPro) return -1; // Unlimited
    final count = ScanGateService().getTodayScanCount();
    return (3 - count).clamp(0, 3);
  }

  /// Update calorie goal
  Future<void> updateCalorieGoal(int goal) async {
    _settings = _settings.copyWith(dailyCalorieGoal: goal);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update protein goal
  Future<void> updateProteinGoal(int goal) async {
    _settings = _settings.copyWith(dailyProteinGoal: goal);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update carb goal
  Future<void> updateCarbGoal(int goal) async {
    _settings = _settings.copyWith(dailyCarbGoal: goal);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update fat goal
  Future<void> updateFatGoal(int goal) async {
    _settings = _settings.copyWith(dailyFatGoal: goal);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Upgrade to pro (disabled: premium access is server verified)
  Future<void> upgradeToPro() async {
    refresh();
    notifyListeners();
  }

  /// Update body profile (height, target weight, age, gender, activity)
  Future<void> updateBodyProfile({
    double? height,
    double? targetWeight,
    int? age,
    String? gender,
    String? activityLevel,
    double? currentWeightKg,
    bool recalculateNutrition = true,
  }) async {
    _settings = _settings.copyWith(
      height: height ?? _settings.height,
      targetWeight: targetWeight ?? _settings.targetWeight,
      age: age ?? _settings.age,
      gender: gender ?? _settings.gender,
      activityLevel: activityLevel ?? _settings.activityLevel,
    );
    await _repository.saveSettings(_settings);
    notifyListeners();

    if (recalculateNutrition) {
      await _recalculatePlanIfProfileComplete(currentWeightKg);
    }
  }

  /// Update Coach Profile fields
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
    _settings = _settings.copyWith(
      height: height ?? _settings.height,
      targetWeight: targetWeight ?? _settings.targetWeight,
      age: age ?? _settings.age,
      gender: gender ?? _settings.gender,
      activityLevel: activityLevel ?? _settings.activityLevel,
      dietaryRestriction: dietaryRestriction ?? _settings.dietaryRestriction,
      foodDislikes: foodDislikes ?? _settings.foodDislikes,
      medicalNotes: medicalNotes ?? _settings.medicalNotes,
      startingWeight: startingWeight ?? _settings.startingWeight,
      goalMode: goalMode ?? _settings.goalMode,
    );
    await _repository.saveSettings(_settings);
    notifyListeners();

    if (recalculateNutrition) {
      await _recalculatePlanIfProfileComplete(startingWeight);
    }
  }

  /// Update planner preferences (meals per day, dietary restriction, cuisine)
  Future<void> updatePlannerPreferences({
    int? mealsPerDay,
    String? dietaryRestriction,
    String? cuisinePreference,
  }) async {
    _settings = _settings.copyWith(
      mealsPerDay: mealsPerDay,
      dietaryRestriction: dietaryRestriction,
      cuisinePreference: cuisinePreference,
    );
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update units
  Future<void> updateUnits({String? weightUnit, String? heightUnit}) async {
    _settings = _settings.copyWith(
      weightUnit: weightUnit ?? _settings.weightUnit,
      heightUnit: heightUnit ?? _settings.heightUnit,
    );
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Mock export data logic
  Future<String> exportUserData() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    final l10n = lookupAppLocalizations(
      Locale(_supportedLanguage(languageCode)),
    );
    return '${l10n.settings_export_data}: ${_settings.dailyCalorieGoal} kcal';
  }

  /// Complete onboarding and persist the profile + recommendation result
  Future<void> completeOnboarding({
    required OnboardingProfileInput profile,
    required OnboardingRecommendation recommendation,
  }) async {
    _settings = _settings.copyWith(
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
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Set theme mode ('system', 'light', 'dark')
  Future<void> setThemeMode(String mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update streak when user logs a meal.
  /// Now date-aware to allow retroactive logging.
  Future<void> updateStreakOnMealLog({String? mealDate}) async {
    final today = app_date.DateUtils.getTodayString();
    final logDate = mealDate ?? today;
    final lastLogged = _settings.lastLoggedDate;

    if (lastLogged == null) {
      // First time logging
      _settings = _settings.copyWith(currentStreak: 1, lastLoggedDate: logDate);
    } else if (lastLogged == logDate) {
      // Already logged for this date, no streak increment
      return;
    } else {
      // Check if the log is in the past relative to the last recorded date
      try {
        final lastDate = DateTime.parse(lastLogged);
        final currentDate = DateTime.parse(logDate);
        if (currentDate.isBefore(lastDate)) {
          // Retroactive log - do not change the forward-moving streak
          return;
        }
      } catch (_) {
        // Fallback for unexpected date formats
      }

      final dayBeforeLog = app_date.DateUtils.getPreviousDay(logDate);
      if (lastLogged == dayBeforeLog) {
        // Continuous streak
        _settings = _settings.copyWith(
          currentStreak: _settings.currentStreak + 1,
          lastLoggedDate: logDate,
        );
      } else {
        // Gap in logging, reset to 1
        _settings = _settings.copyWith(
          currentStreak: 1,
          lastLoggedDate: logDate,
        );
      }
    }

    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update the date when the app was last opened/resumed.
  /// If it is a new day, this updates lastOpenedDate and triggers notification rescheduling.
  Future<void> updateLastOpenedDate() async {
    final today = app_date.DateUtils.getTodayString();
    if (_settings.lastOpenedDate != today) {
      _settings = _settings.copyWith(lastOpenedDate: today);
      await _repository.saveSettings(_settings);
      await _syncNotifications();
      notifyListeners();
    }
  }

  /// Called when a meal is deleted. If it was the only meal for that day,
  /// we may need to adjust the streak backwards.
  Future<void> adjustStreakOnDeletion({
    required String dateOfDeletedMeal,
    required bool wasLastMealOfDay,
  }) async {
    if (!wasLastMealOfDay) return;

    final lastLogged = _settings.lastLoggedDate;
    if (lastLogged == dateOfDeletedMeal) {
      // We deleted the most recent meal date anchor
      final newStreak = (_settings.currentStreak - 1).clamp(0, 9999);
      final previousDay = app_date.DateUtils.getPreviousDay(dateOfDeletedMeal);

      _settings = _settings.copyWith(
        currentStreak: newStreak,
        lastLoggedDate: newStreak == 0 ? null : previousDay,
      );

      await _repository.saveSettings(_settings);
      notifyListeners();
    }
  }

  /// Recalculate nutrition plan based on current weight
  /// Uses Mifflin-St Jeor via CalorieOnboardingService
  Future<bool> recalculatePlan({required double currentWeightKg}) async {
    final age = _settings.age;
    final gender = _settings.gender;
    final heightCm = _settings.height;
    final targetWeight = _settings.targetWeight;

    if (_uiState.isBusy) return false;
    if (age == null ||
        gender == null ||
        heightCm == null ||
        targetWeight == null) {
      return false; // Not enough data to recalculate
    }

    _uiState = const AsyncUiState.refreshing();
    notifyListeners();

    try {
      final service = CalorieOnboardingService();
      final input = OnboardingProfileInput(
        age: age,
        gender: gender,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        goalWeightKg: targetWeight,
        timelineMonths: _settings.goalTimelineMonths ?? 6,
        activityLevel: _settings.activityLevel ?? 'active',
        weightUnit: _settings.weightUnit ?? 'kg',
        heightUnit: _settings.heightUnit ?? 'cm',
      );

      final recommendation = await service.buildRecommendation(
        input,
        languageCode: languageCode,
      );

      _settings = _settings.copyWith(
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
      );

      await _repository.saveSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ SettingsProvider: Recalculation failed: $e');
      _uiState = const AsyncUiState.error('Unable to refresh nutrition plan.');
      return false;
    } finally {
      if (_uiState.hasError) {
        Future.microtask(() {
          _uiState = const AsyncUiState.success();
          notifyListeners();
        });
      } else {
        _uiState = const AsyncUiState.success();
      }
      notifyListeners();
    }
  }

  Future<bool> _recalculatePlanIfProfileComplete(
    double? preferredCurrentWeightKg,
  ) async {
    final currentWeightKg =
        preferredCurrentWeightKg ?? _settings.startingWeight;
    if (currentWeightKg == null) return false;
    return recalculatePlan(currentWeightKg: currentWeightKg);
  }

  /// Refresh settings
  void refresh() {
    _loadSettings();
  }

  /// Clear settings on logout
  Future<void> clear() async {
    await _repository.clear();
    _settings = UserSettings.defaults();
    notifyListeners();
  }
}
