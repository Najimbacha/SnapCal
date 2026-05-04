import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/scan_gate_service.dart';
import '../core/utils/date_utils.dart' as app_date;
import '../data/services/notification_service.dart';
import '../data/services/calorie_onboarding_service.dart';

/// Provider for managing user settings and subscription state
class SettingsProvider with ChangeNotifier {
  final SettingsRepository _repository;
  final NotificationService _notificationService = NotificationService();

  late UserSettings _settings;
  bool _isLoading = false;
  StreamSubscription<UserSettings>? _settingsSubscription;

  SettingsProvider(this._repository) {
    _loadInitialSettings();
    _validateStreakOnStart();
  }

  /// Ensure streak isn't stale when app opens
  void _validateStreakOnStart() {
    final today = app_date.DateUtils.getTodayString();
    final yesterday = app_date.DateUtils.getPreviousDay(today);
    final lastLogged = _settings.lastLoggedDate;

    if (lastLogged != null && lastLogged != today && lastLogged != yesterday) {
      // Streak broken due to inactivity
      _settings = _settings.copyWith(currentStreak: 0);
      _repository.saveSettings(_settings);
      notifyListeners();
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
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
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
  String get weightUnit => _settings.weightUnit ?? 'kg';
  String get heightUnit => _settings.heightUnit ?? 'cm';
  String get goalMode => _settings.goalMode ?? 'maintain';
  double get weeklyRateKg => _settings.weeklyRateKg ?? 0.0;
  String get recommendationInsight => _settings.recommendationInsight ?? '';
  String get recommendationTip => _settings.recommendationTip ?? '';
  String get recommendationSafetyNote => _settings.recommendationSafetyNote ?? '';

  // Planner Preferences
  int get mealsPerDay => _settings.mealsPerDay ?? 3;
  String get dietaryRestriction => _settings.dietaryRestriction ?? 'none';
  String get cuisinePreference => _settings.cuisinePreference ?? 'international';

  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get mealRemindersEnabled => _settings.mealRemindersEnabled;
  bool get goalAlertsEnabled => _settings.goalAlertsEnabled;
  String get themeMode => _settings.themeMode;
  bool get onboardingComplete => _settings.onboardingComplete;
  String get breakfastTime => _settings.breakfastTime;
  String get lunchTime => _settings.lunchTime;
  String get dinnerTime => _settings.dinnerTime;
  String get languageCode => _settings.languageCode ?? 'en';

  /// Update language
  Future<void> setLanguage(String code) async {
    _settings = _settings.copyWith(languageCode: code);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

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

  /// Schedule daily meal reminders
  Future<void> _scheduleReminders() async {
    final times = {
      1: _settings.breakfastTime,
      2: _settings.lunchTime,
      3: _settings.dinnerTime,
    };
    final lang = languageCode;
    
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
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  String _getNotifString(String lang, String key) {
    final map = {
      'en': {
        'breakfast_title': 'Breakfast Reminder',
        'breakfast_body': 'Time to log your healthy breakfast!',
        'lunch_title': 'Lunch Reminder',
        'lunch_body': 'Don\'t forget to track your lunch.',
        'dinner_title': 'Dinner Reminder',
        'dinner_body': 'End the day strong—log your dinner now.',
        'goal_calories_title': 'Goal Reached! 🚀',
        'goal_calories_body': "You've hit your daily calorie goal of {goal} kcal!",
        'goal_protein_title': 'Protein Goal Met! 💪',
        'goal_protein_body': "Great job! You've reached your {goal}g protein target.",
      },
      'ar': {
        'breakfast_title': 'تذكير الفطور',
        'breakfast_body': 'حان الوقت لتسجيل فطورك الصحي!',
        'lunch_title': 'تذكير الغداء',
        'lunch_body': 'لا تنسَ تتبع وجبة الغداء.',
        'dinner_title': 'تذكير العشاء',
        'dinner_body': 'أنهِ يومك بقوة - سجل عشاءك الآن.',
        'goal_calories_title': 'تحقق الهدف! 🚀',
        'goal_calories_body': 'لقد وصلت إلى هدفك اليومي من السعرات الحرارية: {goal} سعرة!',
        'goal_protein_title': 'تم تحقيق هدف البروتين! 💪',
        'goal_protein_body': 'عمل رائع! لقد وصلت إلى هدفك البالغ {goal} جرام من البروتين.',
      },
      'es': {
        'breakfast_title': 'Recordatorio de Desayuno',
        'breakfast_body': '¡Es hora de registrar tu desayuno saludable!',
        'lunch_title': 'Recordatorio de Almuerzo',
        'lunch_body': 'No olvides registrar tu almuerzo.',
        'dinner_title': 'Recordatorio de Cena',
        'dinner_body': 'Termina el día con fuerza: registra tu cena ahora.',
        'goal_calories_title': '¡Objetivo Alcanzado! 🚀',
        'goal_calories_body': '¡Has alcanzado tu objetivo diario de {goal} kcal!',
        'goal_protein_title': '¡Meta de Proteína Cumplida! 💪',
        'goal_protein_body': '¡Buen trabajo! Has alcanzado tu meta de {goal}g de proteína.',
      },
      'fr': {
        'breakfast_title': 'Rappel du Petit-déjeuner',
        'breakfast_body': "C'est l'heure d'enregistrer votre petit-déjeuner sain !",
        'lunch_title': 'Rappel du Déjeuner',
        'lunch_body': "N'oubliez pas de suivre votre déjeuner.",
        'dinner_title': 'Rappel du Dîner',
        'dinner_body': 'Finissez la journée en beauté — enregistrez votre dîner dès maintenant.',
        'goal_calories_title': 'Objectif atteint ! 🚀',
        'goal_calories_body': 'Vous avez atteint votre objectif quotidien de {goal} kcal !',
        'goal_protein_title': 'Objectif protéines rempli ! 💪',
        'goal_protein_body': 'Beau travail ! Vous avez atteint votre cible de {goal}g de protéines.',
      },
    };

    return map[lang]?[key] ?? map['en']![key]!;
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

  /// Trigger calorie goal alert
  Future<void> triggerCalorieGoalAlert(int goal) async {
    if (_settings.notificationsEnabled && _settings.goalAlertsEnabled) {
      final lang = languageCode;
      final title = _getNotifString(lang, 'goal_calories_title');
      final body = _getNotifString(lang, 'goal_calories_body').replaceAll('{goal}', goal.toString());
      await _notificationService.showGoalAlert(title: title, body: body);
    }
  }

  /// Trigger protein goal alert
  Future<void> triggerProteinGoalAlert(int goal) async {
    if (_settings.notificationsEnabled && _settings.goalAlertsEnabled) {
      final lang = languageCode;
      final title = _getNotifString(lang, 'goal_protein_title');
      final body = _getNotifString(lang, 'goal_protein_body').replaceAll('{goal}', goal.toString());
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
    return ScanGateService().canScan(false);
  }

  /// Get remaining free meals today
  int getRemainingFreeMeals(int currentMealCount) {
    if (_settings.isPro) return -1; // Unlimited
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

  /// Upgrade to pro (Manual/Mock fallback)
  Future<void> upgradeToPro() async {
    _settings = _settings.copyWith(isPro: true);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Update body profile (height, target weight, age, gender, activity)
  Future<void> updateBodyProfile({
    double? height,
    double? targetWeight,
    int? age,
    String? gender,
    String? activityLevel,
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
    return "Exported data for ${_settings.gender ?? 'User'} - ${_settings.dailyCalorieGoal} kcal plan.";
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
      final dayBeforeLog = app_date.DateUtils.getPreviousDay(logDate);
      if (lastLogged == dayBeforeLog) {
        // Continuous streak
        _settings = _settings.copyWith(
          currentStreak: _settings.currentStreak + 1,
          lastLoggedDate: logDate,
        );
      } else {
        // Gap in logging, reset to 1
        _settings = _settings.copyWith(currentStreak: 1, lastLoggedDate: logDate);
      }
    }

    await _repository.saveSettings(_settings);
    notifyListeners();
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
    if (_isLoading) return false;
    _isLoading = true;
    notifyListeners();

    // Guard: need minimum profile data
    final age = _settings.age;
    final gender = _settings.gender;
    final heightCm = _settings.height;
    final targetWeight = _settings.targetWeight;

    if (age == null || gender == null || heightCm == null || targetWeight == null) {
      return false; // Not enough data to recalculate
    }

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
    } catch (e) {
      debugPrint('❌ SettingsProvider: Recalculation failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
