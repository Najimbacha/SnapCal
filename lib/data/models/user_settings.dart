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
    );
  }
}
