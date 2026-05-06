import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/data/services/widget_service.dart';

class WidgetSyncProvider {
  final MealProvider _mealProvider;
  final SettingsProvider _settingsProvider;
  final ActivityProvider _activityProvider;

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
    final eaten = _mealProvider.todaysTotalCalories;
    final burned = _activityProvider.burnedCalories;
    final goal = _settingsProvider.dailyCalorieGoal;
    final lang = _settingsProvider.languageCode;
    
    final netGoal = goal + burned;
    final remaining = netGoal - eaten;
    final progress = netGoal > 0 ? (eaten / netGoal).toDouble().clamp(0.0, 1.0) : 0.0;
    
    String status = _getStatus(remaining.toDouble(), progress, lang);

    WidgetService.updateWidgetData(
      remainingCalories: remaining.toInt(),
      progress: progress,
      status: status,
    );
  }

  String _getStatus(double remaining, double progress, String lang) {
    // Basic hardcoded translations for widget status
    final statusMap = {
      'en': {'track': 'On Track', 'over': 'Over Goal', 'almost': 'Almost There'},
      'ar': {'track': 'على المسار الصحيح', 'over': 'فوق الهدف', 'almost': 'على وشك الوصول'},
      'es': {'track': 'En camino', 'over': 'Meta superada', 'almost': 'Casi listo'},
      'fr': {'track': 'Sur la bonne voie', 'over': 'Objectif dépassé', 'almost': 'Presque arrivé'},
    };

    final map = statusMap[lang] ?? statusMap['en']!;

    if (remaining < 0) return map['over']!;
    if (progress > 0.8) return map['almost']!;
    return map['track']!;
  }

  void dispose() {
    _mealProvider.removeListener(_sync);
    _settingsProvider.removeListener(_sync);
    _activityProvider.removeListener(_sync);
  }
}
