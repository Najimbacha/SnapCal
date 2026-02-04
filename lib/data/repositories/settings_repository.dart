import 'package:hive/hive.dart';
import '../models/user_settings.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing user settings in Hive
class SettingsRepository {
  late Box<UserSettings> _settingsBox;

  /// Initialize the repository
  Future<void> init() async {
    _settingsBox = await Hive.openBox<UserSettings>(
      AppConstants.settingsBoxName,
    );
  }

  /// Get current user settings
  UserSettings getSettings() {
    return _settingsBox.get(AppConstants.settingsKey) ??
        UserSettings.defaults();
  }

  /// Save user settings
  Future<void> saveSettings(UserSettings settings) async {
    await _settingsBox.put(AppConstants.settingsKey, settings);
  }

  /// Update daily calorie goal
  Future<void> updateCalorieGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyCalorieGoal: goal));
  }

  /// Update protein goal
  Future<void> updateProteinGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyProteinGoal: goal));
  }

  /// Update carb goal
  Future<void> updateCarbGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyCarbGoal: goal));
  }

  /// Update fat goal
  Future<void> updateFatGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyFatGoal: goal));
  }

  /// Update pro status
  Future<void> updateProStatus(bool isPro) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(isPro: isPro));
  }

  /// Update streak
  Future<void> updateStreak(int streak, String lastLoggedDate) async {
    final settings = getSettings();
    await saveSettings(
      settings.copyWith(currentStreak: streak, lastLoggedDate: lastLoggedDate),
    );
  }

  /// Check if user is pro
  bool isPro() {
    return getSettings().isPro;
  }

  /// Get current streak
  int getCurrentStreak() {
    return getSettings().currentStreak;
  }
}
