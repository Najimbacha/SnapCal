import 'dart:ui' as ui;

import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';

part 'user_settings.g.dart';

/// The device's language when SnapCal ships that language, English otherwise.
///
/// This is the default for a user who has never opened the language picker.
/// It used to be a flat 'en', which meant the Arabic, Spanish and French
/// translations only ever appeared for someone who went looking for them --
/// a new user on an Arabic phone got an English app and no hint that
/// anything else existed.
///
/// Resolved once, when settings are first created, and stored like any other
/// choice. Everything downstream -- the AI prompts, the planner, the weekly
/// report -- reads the stored code, so the assistant answers in the same
/// language the UI is written in rather than falling back to English on its
/// own.
String _deviceLanguageOrEnglish() {
  final code = ui.PlatformDispatcher.instance.locale.languageCode;
  final shipped = AppLocalizations.supportedLocales.any(
    (locale) => locale.languageCode == code,
  );
  return shipped ? code : 'en';
}

/// A daily water target worked out from body weight: about 35 ml per kilo,
/// kept inside what a person can sensibly drink. 2,500 ml when no weight is
/// known -- which is what every user used to get, whatever they weighed.
int waterGoalForWeightKg(double? weightKg) {
  if (weightKg == null || weightKg <= 0) return 2500;
  final rounded = ((weightKg * 35) / 50).round() * 50;
  return rounded.clamp(1500, 4000);
}

/// User settings and goals
@HiveType(typeId: 2)
class UserSettings extends HiveObject {
  @HiveField(0)
  final int dailyCalorieGoal;

  @HiveField(1)
  final int dailyProteinGoal;

  @HiveField(2)
  final int dailyCarbGoal;

  @HiveField(3)
  final int dailyFatGoal;

  @HiveField(4)
  final bool isPro;

  @HiveField(5)
  final int currentStreak;

  @HiveField(6)
  final String? lastLoggedDate;

  @HiveField(7)
  final bool notificationsEnabled;

  @HiveField(8)
  final bool mealRemindersEnabled;

  @HiveField(9)
  final bool goalAlertsEnabled;

  @HiveField(10)
  final String breakfastTime;

  @HiveField(11)
  final String lunchTime;

  @HiveField(12)
  final String dinnerTime;

  @HiveField(13)
  final double? height; // in cm

  @HiveField(14)
  final double? targetWeight; // in kg

  @HiveField(15)
  final String themeMode; // 'system', 'light', 'dark'

  @HiveField(16)
  final bool onboardingComplete;

  @HiveField(17)
  final int? age;

  @HiveField(18)
  final String? gender;

  @HiveField(19)
  final String? activityLevel;

  @HiveField(20)
  final int? goalTimelineMonths;

  @HiveField(21)
  final double? startingWeight;

  @HiveField(22)
  final String? weightUnit;

  @HiveField(23)
  final String? heightUnit;

  @HiveField(24)
  final String? goalMode;

  @HiveField(25)
  final double? weeklyRateKg;

  @HiveField(26)
  final String? recommendationInsight;

  @HiveField(27)
  final String? recommendationTip;

  @HiveField(28)
  final String? recommendationSafetyNote;

  // Planner Preferences
  @HiveField(29)
  final int? mealsPerDay;

  @HiveField(30)
  final String? dietaryRestriction;

  @HiveField(31)
  final String? cuisinePreference;

  @HiveField(32)
  final String? languageCode;

  @HiveField(33)
  final bool dailyMotivationEnabled;

  @HiveField(34)
  final String? lastOpenedDate;

  @HiveField(35)
  final String? foodDislikes;

  @HiveField(36)
  final String? medicalNotes;

  @HiveField(37)
  final bool foodRemindersEnabled;

  @HiveField(38)
  final String? lastFoodReminderDate;

  @HiveField(39)
  final String? fcmToken;

  /// Where the daily targets come from: 'profile' (recomputed whenever age,
  /// height or weight change) or 'custom' (the user's own numbers, left
  /// alone).
  ///
  /// This replaces asking "recalculate your plan?" at a surprising moment.
  /// Editing your height and being told your calorie goal is about to be
  /// overwritten is a question arriving at the wrong time; a mode you can see
  /// on the goals screen is the same decision, made once, where it belongs.
  /// It is also what every tracker people already use does.
  ///
  /// Defaults to 'profile', which is the behaviour every existing user has
  /// today — targets were always derived and always overwritten.
  @HiveField(40)
  final String goalSource;

  /// The daily water target in millilitres, or 0 for "work it out from my
  /// weight". It was a constant 2,500 ml for everyone, with nothing in the
  /// app able to change it.
  ///
  /// Kept on the phone only: the settings document the app is allowed to
  /// write is a fixed list of fields in the security rules, and adding one
  /// there means deploying new rules before any app version can save.
  @HiveField(41)
  final int waterGoalMl;

  UserSettings({
    required this.dailyCalorieGoal,
    required this.dailyProteinGoal,
    required this.dailyCarbGoal,
    required this.dailyFatGoal,
    this.isPro = false,
    this.currentStreak = 0,
    this.lastLoggedDate,
    this.notificationsEnabled = true,
    this.mealRemindersEnabled = true,
    this.goalAlertsEnabled = true,
    this.breakfastTime = '08:00',
    this.lunchTime = '13:00',
    this.dinnerTime = '19:00',
    this.height,
    this.targetWeight,
    this.themeMode = 'system',
    this.onboardingComplete = false,
    this.age,
    this.gender,
    this.activityLevel,
    this.goalTimelineMonths,
    this.startingWeight,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.goalMode = 'maintain',
    this.weeklyRateKg = 0,
    this.recommendationInsight = '',
    this.recommendationTip = '',
    this.recommendationSafetyNote = '',
    this.mealsPerDay = 3,
    this.dietaryRestriction = 'none',
    this.cuisinePreference = 'international',
    this.dailyMotivationEnabled = false,
    this.lastOpenedDate,
    this.foodDislikes,
    this.medicalNotes,
    this.foodRemindersEnabled = false,
    this.lastFoodReminderDate,
    this.fcmToken,
    this.goalSource = 'profile',
    this.waterGoalMl = 0,
    String? languageCode,
  }) : languageCode = languageCode ?? _deviceLanguageOrEnglish();

  /// The water target actually used: the one chosen, or one from body weight.
  int get effectiveWaterGoalMl =>
      waterGoalMl > 0 ? waterGoalMl : waterGoalForWeightKg(startingWeight);

  UserSettings copyWith({
    int? dailyCalorieGoal,
    int? dailyProteinGoal,
    int? dailyCarbGoal,
    int? dailyFatGoal,
    bool? isPro,
    int? currentStreak,
    String? lastLoggedDate,
    bool? notificationsEnabled,
    bool? mealRemindersEnabled,
    bool? goalAlertsEnabled,
    String? breakfastTime,
    String? lunchTime,
    String? dinnerTime,
    double? height,
    double? targetWeight,
    String? themeMode,
    bool? onboardingComplete,
    int? age,
    String? gender,
    String? activityLevel,
    int? goalTimelineMonths,
    double? startingWeight,
    String? weightUnit,
    String? heightUnit,
    String? goalMode,
    double? weeklyRateKg,
    String? recommendationInsight,
    String? recommendationTip,
    String? recommendationSafetyNote,
    int? mealsPerDay,
    String? dietaryRestriction,
    String? cuisinePreference,
    String? languageCode,
    bool? dailyMotivationEnabled,
    String? lastOpenedDate,
    String? foodDislikes,
    String? medicalNotes,
    bool? foodRemindersEnabled,
    String? lastFoodReminderDate,
    String? fcmToken,
    String? goalSource,
    int? waterGoalMl,
    // `copyWith(lastLoggedDate: null)` cannot clear the field — the `??`
    // below reads it as "leave unchanged". Pass this to actually clear it.
    bool clearLastLoggedDate = false,
  }) {
    return UserSettings(
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyProteinGoal: dailyProteinGoal ?? this.dailyProteinGoal,
      dailyCarbGoal: dailyCarbGoal ?? this.dailyCarbGoal,
      dailyFatGoal: dailyFatGoal ?? this.dailyFatGoal,
      isPro: isPro ?? this.isPro,
      currentStreak: currentStreak ?? this.currentStreak,
      lastLoggedDate:
          clearLastLoggedDate ? null : (lastLoggedDate ?? this.lastLoggedDate),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      goalAlertsEnabled: goalAlertsEnabled ?? this.goalAlertsEnabled,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goalTimelineMonths: goalTimelineMonths ?? this.goalTimelineMonths,
      startingWeight: startingWeight ?? this.startingWeight,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      goalMode: goalMode ?? this.goalMode,
      weeklyRateKg: weeklyRateKg ?? this.weeklyRateKg,
      recommendationInsight:
          recommendationInsight ?? this.recommendationInsight,
      recommendationTip: recommendationTip ?? this.recommendationTip,
      recommendationSafetyNote:
          recommendationSafetyNote ?? this.recommendationSafetyNote,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      dietaryRestriction: dietaryRestriction ?? this.dietaryRestriction,
      cuisinePreference: cuisinePreference ?? this.cuisinePreference,
      languageCode: languageCode ?? this.languageCode,
      dailyMotivationEnabled:
          dailyMotivationEnabled ?? this.dailyMotivationEnabled,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      foodDislikes: foodDislikes ?? this.foodDislikes,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      foodRemindersEnabled: foodRemindersEnabled ?? this.foodRemindersEnabled,
      lastFoodReminderDate: lastFoodReminderDate ?? this.lastFoodReminderDate,
      fcmToken: fcmToken ?? this.fcmToken,
      goalSource: goalSource ?? this.goalSource,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyCalorieGoal': dailyCalorieGoal,
      'dailyProteinGoal': dailyProteinGoal,
      'dailyCarbGoal': dailyCarbGoal,
      'dailyFatGoal': dailyFatGoal,
      'isPro': isPro,
      'currentStreak': currentStreak,
      'lastLoggedDate': lastLoggedDate,
      'notificationsEnabled': notificationsEnabled,
      'mealRemindersEnabled': mealRemindersEnabled,
      'goalAlertsEnabled': goalAlertsEnabled,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'dinnerTime': dinnerTime,
      'height': height,
      'targetWeight': targetWeight,
      'themeMode': themeMode,
      'onboardingComplete': onboardingComplete,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
      'goalTimelineMonths': goalTimelineMonths,
      'startingWeight': startingWeight,
      'weightUnit': weightUnit,
      'heightUnit': heightUnit,
      'goalMode': goalMode,
      'weeklyRateKg': weeklyRateKg,
      'recommendationInsight': recommendationInsight,
      'recommendationTip': recommendationTip,
      'recommendationSafetyNote': recommendationSafetyNote,
      'mealsPerDay': mealsPerDay,
      'dietaryRestriction': dietaryRestriction,
      'cuisinePreference': cuisinePreference,
      'languageCode': languageCode,
      'dailyMotivationEnabled': dailyMotivationEnabled,
      'lastOpenedDate': lastOpenedDate,
      'foodDislikes': foodDislikes,
      'medicalNotes': medicalNotes,
      'foodRemindersEnabled': foodRemindersEnabled,
      'lastFoodReminderDate': lastFoodReminderDate,
      'fcmToken': fcmToken,
      'goalSource': goalSource,
      'waterGoalMl': waterGoalMl,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      dailyCalorieGoal:
          json['dailyCalorieGoal'] as int? ?? AppConstants.defaultCalorieGoal,
      dailyProteinGoal:
          json['dailyProteinGoal'] as int? ?? AppConstants.defaultProteinGoal,
      dailyCarbGoal:
          json['dailyCarbGoal'] as int? ?? AppConstants.defaultCarbGoal,
      dailyFatGoal: json['dailyFatGoal'] as int? ?? AppConstants.defaultFatGoal,
      isPro: json['isPro'] as bool? ?? false,
      currentStreak: json['currentStreak'] as int? ?? 0,
      lastLoggedDate: json['lastLoggedDate'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      mealRemindersEnabled: json['mealRemindersEnabled'] as bool? ?? true,
      goalAlertsEnabled: json['goalAlertsEnabled'] as bool? ?? true,
      breakfastTime: json['breakfastTime'] as String? ?? '08:00',
      lunchTime: json['lunchTime'] as String? ?? '13:00',
      dinnerTime: json['dinnerTime'] as String? ?? '19:00',
      // Firestore stores a whole number as an int, so `170 as double?` throws
      // a TypeError and takes the whole settings sync down with it. Always
      // widen through num.
      height: (json['height'] as num?)?.toDouble(),
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      themeMode: json['themeMode'] as String? ?? 'system',
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      activityLevel: json['activityLevel'] as String?,
      goalTimelineMonths: json['goalTimelineMonths'] as int?,
      // `weight` is the legacy key older profile documents were written with.
      startingWeight:
          (json['startingWeight'] as num?)?.toDouble() ??
          (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      heightUnit: json['heightUnit'] as String? ?? 'cm',
      goalMode: json['goalMode'] as String? ?? 'maintain',
      weeklyRateKg: (json['weeklyRateKg'] as num?)?.toDouble() ?? 0,
      recommendationInsight: json['recommendationInsight'] as String? ?? '',
      recommendationTip: json['recommendationTip'] as String? ?? '',
      recommendationSafetyNote:
          json['recommendationSafetyNote'] as String? ?? '',
      mealsPerDay: json['mealsPerDay'] as int? ?? 3,
      dietaryRestriction: json['dietaryRestriction'] as String? ?? 'none',
      cuisinePreference:
          json['cuisinePreference'] as String? ?? 'international',
      // No `?? 'en'`: a document written before this field existed should
      // fall through to the constructor's device resolution, not be pinned
      // to English by the deserializer.
      languageCode: json['languageCode'] as String?,
      dailyMotivationEnabled: json['dailyMotivationEnabled'] as bool? ?? false,
      lastOpenedDate: json['lastOpenedDate'] as String?,
      foodDislikes: json['foodDislikes'] as String?,
      medicalNotes: json['medicalNotes'] as String?,
      foodRemindersEnabled: json['foodRemindersEnabled'] as bool? ?? false,
      lastFoodReminderDate: json['lastFoodReminderDate'] as String?,
      fcmToken: json['fcmToken'] as String?,
      goalSource: json['goalSource'] as String? ?? 'profile',
      waterGoalMl: (json['waterGoalMl'] as num?)?.toInt() ?? 0,
    );
  }

  /// Default settings
  factory UserSettings.defaults() {
    return UserSettings(
      dailyCalorieGoal: AppConstants.defaultCalorieGoal,
      dailyProteinGoal: AppConstants.defaultProteinGoal,
      dailyCarbGoal: AppConstants.defaultCarbGoal,
      dailyFatGoal: AppConstants.defaultFatGoal,
      isPro: false,
      currentStreak: 0,
      lastLoggedDate: null,
      notificationsEnabled: true,
      mealRemindersEnabled: true,
      goalAlertsEnabled: true,
      breakfastTime: '08:00',
      lunchTime: '13:00',
      dinnerTime: '19:00',
      height: null,
      targetWeight: null,
      themeMode: 'system',
      onboardingComplete: false,
      age: null,
      gender: null,
      activityLevel: null,
      goalTimelineMonths: null,
      startingWeight: null,
      weightUnit: 'kg',
      heightUnit: 'cm',
      goalMode: 'maintain',
      weeklyRateKg: 0,
      recommendationInsight: '',
      recommendationTip: '',
      recommendationSafetyNote: '',
      mealsPerDay: 3,
      dietaryRestriction: 'none',
      cuisinePreference: 'international',
      // Deliberately not passed: let the constructor resolve it from the
      // device, the same as any other freshly created settings object.
      dailyMotivationEnabled: false,
      lastOpenedDate: null,
      foodDislikes: null,
      medicalNotes: null,
      foodRemindersEnabled: false,
      lastFoodReminderDate: null,
      fcmToken: null,
      goalSource: 'profile',
      waterGoalMl: 0,
    );
  }
}
