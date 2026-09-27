import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/services/widget_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'settings_provider.dart';
import 'calorie_budget_provider.dart';

part 'widget_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class WidgetSync extends _$WidgetSync {
  Timer? _debounceTimer;

  @override
  FutureOr<void> build() {
    // The widget shows the same "left" as Home, from the one budget, and
    // follows it within a moment: it used to wait up to 10 seconds after a
    // meal was logged, and to check Pro its own way.
    ref.listen(calorieBudgetProvider, (_, _) => _scheduleSync());
    ref.listen(settingsProvider, (_, _) => _scheduleSync());
    ref.onDispose(() => _debounceTimer?.cancel());
    _scheduleSync();
  }

  /// A burst of changes, as when a routine logs several foods, writes once.
  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), _performSync);
  }

  void _performSync() {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return;
    final budget = ref.read(calorieBudgetProvider);
    final lang = settings.languageCode ?? 'en';
    final isPro = ref.read(effectiveIsProProvider);

    final remaining = budget.left;
    final progress =
        budget.goal > 0 ? (budget.eaten / budget.goal).clamp(0.0, 1.0) : 0.0;
    final status = _getStatus(remaining.toDouble(), progress, lang);

    WidgetService.updateWidgetData(
      remainingCalories: remaining,
      progress: progress,
      status: status,
      isLocked: !isPro,
    );
  }

  String _getStatus(double remaining, double progress, String lang) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == lang,
    );
    final l10n = lookupAppLocalizations(Locale(supported ? lang : 'en'));
    if (remaining < 0) return l10n.widget_status_over_goal;
    if (progress > 0.8) return l10n.widget_status_almost_there;
    return l10n.widget_status_on_track;
  }
}
