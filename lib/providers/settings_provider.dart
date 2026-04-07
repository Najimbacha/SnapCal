import 'package:flutter/foundation.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/services/notification_service.dart';
import '../data/services/calorie_onboarding_service.dart';

/// Provider for managing user settings and subscription state
class SettingsProvider with ChangeNotifier {
  final SettingsRepository _repository;
  final NotificationService _notificationService = NotificationService();

  late UserSettings _settings;
  final bool _isLoading = false;

  SettingsProvider(this._repository) {
    _loadSettings();
    _syncNotifications();
  }

  // Getters
  SettingsRepository get repository =>
      _repository; // Expose for mock subscription service
  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isPro => _settings.isPro;
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
  String get weightUnit => _settings.weightUnit;
  String get heightUnit => _settings.heightUnit;
  String get goalMode => _settings.goalMode;
  double get weeklyRateKg => _settings.weeklyRateKg;
  String get recommendationInsight => _settings.recommendationInsight;
  String get recommendationTip => _settings.recommendationTip;
  String get recommendationSafetyNote => _settings.recommendationSafetyNote;

  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get mealRemindersEnabled => _settings.mealRemindersEnabled;
  bool get goalAlertsEnabled => _settings.goalAlertsEnabled;
  String get themeMode => _settings.themeMode;
  bool get onboardingComplete => _settings.onboardingComplete;

  /// Load settings from repository
  void _loadSettings() {
    _settings = _repository.getSettings();
    notifyListeners();
  }

  /// Sync notifications with current settings
  Future<void> _syncNotifications() async {
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
  }

  Future<void> _scheduleReminders() async {
    final times = {
      1: _settings.breakfastTime,
      2: _settings.lunchTime,
      3: _settings.dinnerTime,
    };

    final labels = {
      1: 'Breakfast Reminder',
      2: 'Lunch Reminder',
      3: 'Dinner Reminder',
    };

    final bodies = {
      1: 'Time to log your healthy breakfast!',
      2: 'Don\'t forget to track your lunch.',
      3: 'End the day strong—log your dinner now.',
    };

    for (var entry in times.entries) {
      final parts = entry.value.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;

        await _notificationService.scheduleDailyReminder(
          id: entry.key,
          title: labels[entry.key]!,
          body: bodies[entry.key]!,
          hour: hour,
          minute: minute,
        );
      }
    }
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

  /// Toggle goal alerts
  Future<void> toggleGoalAlerts(bool enabled) async {
    _settings = _settings.copyWith(goalAlertsEnabled: enabled);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Trigger goal alert if enabled
  Future<void> triggerGoalAlert(String title, String body) async {
    if (_settings.notificationsEnabled && _settings.goalAlertsEnabled) {
      await _notificationService.showGoalAlert(title: title, body: body);
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
    if (_settings.isPro) return true;
    return currentMealCount < AppConstants.freeTierDailyMealLimit;
  }

  /// Get remaining free meals today
  int getRemainingFreeMeals(int currentMealCount) {
    if (_settings.isPro) return -1; // Unlimited
    return AppConstants.freeTierDailyMealLimit - currentMealCount;
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

  /// Upgrade to pro
  Future<void> upgradeToPro() async {
    _settings = _settings.copyWith(isPro: true);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update body profile (height and target weight)
  Future<void> updateBodyProfile({double? height, double? targetWeight}) async {
    _settings = _settings.copyWith(height: height, targetWeight: targetWeight);
    await _repository.saveSettings(_settings);
    notifyListeners();
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

  /// Update streak when user logs a meal
  Future<void> updateStreakOnMealLog() async {
    final today = app_date.DateUtils.getTodayString();
    final lastLogged = _settings.lastLoggedDate;

    if (lastLogged == null) {
      // First time logging
      _settings = _settings.copyWith(currentStreak: 1, lastLoggedDate: today);
    } else if (lastLogged == today) {
      // Already logged today, no change
      return;
    } else {
      final yesterday = app_date.DateUtils.getPreviousDay(today);
      if (lastLogged == yesterday) {
        // Logged yesterday, increment streak
        _settings = _settings.copyWith(
          currentStreak: _settings.currentStreak + 1,
          lastLoggedDate: today,
        );
      } else {
        // Streak broken, reset to 1
        _settings = _settings.copyWith(currentStreak: 1, lastLoggedDate: today);
      }
    }

    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Recalculate nutrition plan based on current weight
  /// Uses Mifflin-St Jeor via CalorieOnboardingService
  Future<bool> recalculatePlan({required double currentWeightKg}) async {
    // Guard: need minimum profile data
    final age = _settings.age;
    final gender = _settings.gender;
    final heightCm = _settings.height;
    final targetWeight = _settings.targetWeight;

    if (age == null || gender == null || heightCm == null || targetWeight == null) {
      return false; // Not enough data to recalculate
    }

    final service = CalorieOnboardingService();
    final input = OnboardingProfileInput(
      age: age,
      gender: gender,
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      goalWeightKg: targetWeight,
      timelineMonths: _settings.goalTimelineMonths ?? 6,
      activityLevel: _settings.activityLevel ?? 'active',
      weightUnit: _settings.weightUnit,
      heightUnit: _settings.heightUnit,
    );

    final recommendation = await service.buildRecommendation(input);

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
  }

  /// Refresh settings
  void refresh() {
    _loadSettings();
  }
}
