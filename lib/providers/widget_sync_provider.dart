import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/services/widget_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'meal_provider.dart';
import 'settings_provider.dart';
import 'activity_provider.dart';

part 'widget_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class WidgetSync extends _$WidgetSync {
  Timer? _debounceTimer;
  DateTime? _lastSyncTime;

  @override
  FutureOr<void> build() {
    ref.listen(todaysMealsProvider, (_, __) => _scheduleSync());
    ref.listen(settingsProvider, (_, __) => _scheduleSync());
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_debounceTimer?.isActive ?? false) return;
    final now = DateTime.now();
    final diff = _lastSyncTime == null ? const Duration(days: 1) : now.difference(_lastSyncTime!);
    if (diff >= const Duration(seconds: 10)) {
      _performSync();
    } else {
      _debounceTimer = Timer(const Duration(seconds: 10) - diff, _performSync);
    }
  }

  void _performSync() {
    _debounceTimer?.cancel();
    _lastSyncTime = DateTime.now();

    final settings = ref.read(settingsProvider).valueOrNull;
    final activity = ref.read(activityProvider).valueOrNull;
    if (settings == null) return;

    final eaten = ref.read(todaysMealsProvider).valueOrNull?.fold<int>(0, (s, m) => s + m.calories) ?? 0;
    final burned = activity?.activeCalories?.toInt() ?? 0;
    final goal = settings.dailyCalorieGoal;
    final lang = settings.languageCode ?? 'en';
    final isPro = settings.isPro;

    final netGoal = isPro ? goal + burned : goal;
    final remaining = netGoal - eaten;
    final progress = netGoal > 0 ? (eaten / netGoal).clamp(0.0, 1.0) : 0.0;
    final status = _getStatus(remaining.toDouble(), progress, lang);

    WidgetService.updateWidgetData(
      remainingCalories: remaining.toInt(),
      progress: progress,
      status: status,
      isLocked: !isPro,
    );
  }

  String _getStatus(double remaining, double progress, String lang) {
    final supported = AppLocalizations.supportedLocales.any((l) => l.languageCode == lang);
    final l10n = lookupAppLocalizations(Locale(supported ? lang : 'en'));
    if (remaining < 0) return l10n.widget_status_over_goal;
    if (progress > 0.8) return l10n.widget_status_almost_there;
    return l10n.widget_status_on_track;
  }
}
