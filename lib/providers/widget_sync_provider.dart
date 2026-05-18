import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/data/services/widget_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class WidgetSyncProvider {
  final MealProvider _mealProvider;
  final SettingsProvider _settingsProvider;
  final ActivityProvider _activityProvider;

  Timer? _debounceTimer;
  DateTime? _lastSyncTime;

  WidgetSyncProvider(
    this._mealProvider,
    this._settingsProvider,
    this._activityProvider,
  ) {
    _mealProvider.addListener(_sync);
    _settingsProvider.addListener(_sync);
    _activityProvider.addListener(_sync);
    _sync();
  }

  void _sync() {
    // If there's already a pending update scheduled, we don't need to do anything.
    // The pending update will pick up the latest state from the providers.
    if (_debounceTimer?.isActive ?? false) return;

    final now = DateTime.now();
    final timeSinceLastSync =
        _lastSyncTime == null
            ? const Duration(days: 1)
            : now.difference(_lastSyncTime!);

    if (timeSinceLastSync >= const Duration(seconds: 10)) {
      _performSync();
    } else {
      // Schedule an update to happen once the 10-second window has passed
      final delay = const Duration(seconds: 10) - timeSinceLastSync;
      _debounceTimer = Timer(delay, _performSync);
    }
  }

  void _performSync() {
    _debounceTimer?.cancel();
    _lastSyncTime = DateTime.now();

    final eaten = _mealProvider.todaysTotalCalories;
    final burned = _activityProvider.burnedCalories;
    final goal = _settingsProvider.dailyCalorieGoal;
    final lang = _settingsProvider.languageCode;

    final netGoal = goal + burned;
    final remaining = netGoal - eaten;
    final progress =
        netGoal > 0 ? (eaten / netGoal).toDouble().clamp(0.0, 1.0) : 0.0;

    String status = _getStatus(remaining.toDouble(), progress, lang);

    WidgetService.updateWidgetData(
      remainingCalories: remaining.toInt(),
      progress: progress,
      status: status,
    );
  }

  String _getStatus(double remaining, double progress, String lang) {
    final supported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == lang,
    );
    final l10n = lookupAppLocalizations(Locale(supported ? lang : 'en'));

    if (remaining < 0) return l10n.widget_status_over_goal;
    if (progress > 0.8) return l10n.widget_status_almost_there;
    return l10n.widget_status_on_track;
  }

  void dispose() {
    _mealProvider.removeListener(_sync);
    _settingsProvider.removeListener(_sync);
    _activityProvider.removeListener(_sync);
    _debounceTimer?.cancel();
  }
}
