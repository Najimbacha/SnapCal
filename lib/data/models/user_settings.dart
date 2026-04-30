import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'user_settings.g.dart';

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
  });

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
  }) {
    return UserSettings(
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyProteinGoal: dailyProteinGoal ?? this.dailyProteinGoal,
      dailyCarbGoal: dailyCarbGoal ?? this.dailyCarbGoal,
      dailyFatGoal: dailyFatGoal ?? this.dailyFatGoal,
      isPro: isPro ?? this.isPro,
      currentStreak: currentStreak ?? this.currentStreak,
      lastLoggedDate: lastLoggedDate ?? this.lastLoggedDate,
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
      height: json['height'] as double?,
      targetWeight: json['targetWeight'] as double?,
      themeMode: json['themeMode'] as String? ?? 'system',
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      activityLevel: json['activityLevel'] as String?,
      goalTimelineMonths: json['goalTimelineMonths'] as int?,
      startingWeight: json['startingWeight'] as double?,
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
      cuisinePreference: json['cuisinePreference'] as String? ?? 'international',
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
    );
  }
}
