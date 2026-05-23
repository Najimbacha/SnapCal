import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../providers/activity_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../data/services/premium_conversion_service.dart';
import 'models/log_metric_models.dart';
import 'widgets/health_metric_dashboard.dart';
import 'widgets/horizontal_day_calendar.dart';


class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().loadMealsForDate(
        app_date.DateUtils.getTodayString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final water = context.watch<WaterProvider>();
    final activity = context.watch<ActivityProvider>();
    final mealProvider = context.watch<MealProvider>();
    final l10n = AppLocalizations.of(context)!;
    final summaries = _buildDailySummaries(
      mealProvider: mealProvider,
      settings: settings,
      water: water,
      activity: activity,
    );
    final dashboardCards = _buildDashboardCards(
      context: context,
      summaries: summaries,
      settings: settings,
      activity: activity,
      water: water,
    );

    return AppPageScaffold(
      title: '',
      showHeader: false,
      scrollable: false,
      padding: EdgeInsets.zero,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF14130F)
              : const Color(0xFFF9F8F5),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          22,
          MediaQuery.of(context).padding.top + 16,
          22,
          112,
        ),
        children: [
          _HealthLogHeader(
            onProfileTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 24),
          HealthMetricDashboard(
            title: l10n.log_key_metrics,
            actionLabel: l10n.log_customize,
            cards: dashboardCards,
            onMetricTap: (type) => context.push('/log/metric/${type.id}'),
            onCustomize: () => _showCustomizeSheet(context, l10n),
          ),
        ],
      ),
    );
  }

  void _showCustomizeSheet(BuildContext ctx, AppLocalizations l10n) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomizeMetricsSheet(l10n: l10n),
    );
  }

  List<DailySummary> _buildDailySummaries({
    required MealProvider mealProvider,
    required SettingsProvider settings,
    required WaterProvider water,
    required ActivityProvider activity,
  }) {
    final today = DateTime.now();
    final visibleMeals = mealProvider.getMealsForVisibleHistory(
      isPro: settings.isPro,
    );
    final oldestMealDate =
        visibleMeals.isEmpty
            ? today
            : visibleMeals
                .map((meal) => DateTime.tryParse(meal.dateString))
                .whereType<DateTime>()
                .fold<DateTime>(today, (oldest, date) {
                  return date.isBefore(oldest) ? date : oldest;
                });
    final todayOnly = DateTime(today.year, today.month, today.day);
    final oldestOnly = DateTime(
      oldestMealDate.year,
      oldestMealDate.month,
      oldestMealDate.day,
    );
    final dayCount =
        settings.isPro ? todayOnly.difference(oldestOnly).inDays + 1 : 14;

    final visibleDayCount = math.max(dayCount, 14);
    return List.generate(visibleDayCount, (index) {
      final date = today.subtract(Duration(days: visibleDayCount - 1 - index));
      return _buildSummaryForDate(
        dateString: app_date.DateUtils.getDateString(date),
        mealProvider: mealProvider,
        settings: settings,
        water: water,
        activity: activity,
      );
    });
  }

  DailySummary _buildSummaryForDate({
    required String dateString,
    required MealProvider mealProvider,
    required SettingsProvider settings,
    required WaterProvider water,
    required ActivityProvider activity,
  }) {
    final meals = mealProvider.getMealsForDate(dateString);
    var calories = 0;
    var protein = 0;
    var carbs = 0;
    var fat = 0;
    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.macros.protein;
      carbs += meal.macros.carbs;
      fat += meal.macros.fat;
    }

    final parsedDate = DateTime.tryParse(dateString);
    final activitySummary =
        parsedDate == null ? null : activity.cachedSummaryForDate(parsedDate);
    return DailySummary(
      dateString: dateString,
      calories: calories,
      calorieGoal: settings.dailyCalorieGoal,
      protein: protein,
      proteinGoal: settings.dailyProteinGoal,
      carbs: carbs,
      carbGoal: settings.dailyCarbGoal,
      fat: fat,
      fatGoal: settings.dailyFatGoal,
      waterMl: water.getTotalForDate(dateString),
      waterGoal: water.goal,
      steps:
          activity.isTracking
              ? activitySummary?.steps ??
                  (app_date.DateUtils.isToday(dateString) ? activity.steps : 0)
              : 0,
      stepGoal: activity.stepGoal,
      mealCount: meals.length,
    );
  }

  List<HealthMetricCardData> _buildDashboardCards({
    required BuildContext context,
    required List<DailySummary> summaries,
    required SettingsProvider settings,
    required ActivityProvider activity,
    required WaterProvider water,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final today = summaries.firstWhere(
      (summary) => app_date.DateUtils.isToday(summary.dateString),
      orElse:
          () =>
              summaries.isEmpty
                  ? DailySummary(
                    dateString: app_date.DateUtils.getTodayString(),
                    calories: 0,
                    calorieGoal: settings.dailyCalorieGoal,
                    protein: 0,
                    proteinGoal: settings.dailyProteinGoal,
                    carbs: 0,
                    carbGoal: settings.dailyCarbGoal,
                    fat: 0,
                    fatGoal: settings.dailyFatGoal,
                    waterMl: water.total,
                    waterGoal: water.goal,
                    steps: activity.steps,
                    stepGoal: activity.stepGoal,
                    mealCount: 0,
                  )
                  : summaries.last,
    );
    final lastSeven =
        summaries.length <= 7
            ? summaries
            : summaries.sublist(summaries.length - 7);
    final activityTrend =
        activity.week.isEmpty
            ? List<int>.filled(7, 0)
            : activity.week
                .map((day) => day.activityCalories + day.manualWorkoutCalories)
                .toList();
    final stepTrend =
        activity.week.isEmpty
            ? lastSeven.map((summary) => summary.steps).toList()
            : activity.week.map((day) => day.steps).toList();

    final energyToday =
        activity.isTracking
            ? activity.burnedCalories + activity.manualWorkoutCalories
            : 0;
    final energyGoal = (activity.stepGoal * 0.04).round();

    return [
      HealthMetricCardData(
        type: LogMetricType.calories,
        title: l10n.log_metric_calories_intake,
        value: _formatInt(context, today.calories),
        unit: 'cal',
        status: _metricStatus(
          context,
          today.calories,
          today.calorieGoal,
          'cal',
        ),
        values: lastSeven.map((summary) => summary.calories).toList(),
        goal: today.calorieGoal,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.utensils,
      ),
      HealthMetricCardData(
        type: LogMetricType.energy,
        title: l10n.log_metric_energy_burned,
        value: _formatInt(context, energyToday),
        unit: 'cal',
        status: _metricStatus(context, energyToday, energyGoal, 'cal'),
        values: activityTrend,
        goal: energyGoal,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.flame,
      ),
      HealthMetricCardData(
        type: LogMetricType.steps,
        title: l10n.log_metric_steps,
        value: _formatInt(context, today.steps),
        unit: '',
        status: _metricStatus(
          context,
          today.steps,
          today.stepGoal,
          l10n.log_metric_steps_unit,
        ),
        values: stepTrend,
        goal: today.stepGoal,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.footprints,
      ),
      HealthMetricCardData(
        type: LogMetricType.water,
        title: l10n.log_metric_water,
        value: _formatInt(context, today.waterMl),
        unit: 'ml',
        status: _metricStatus(context, today.waterMl, today.waterGoal, 'ml'),
        values: lastSeven.map((summary) => summary.waterMl).toList(),
        goal: today.waterGoal,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.droplets,
      ),
      HealthMetricCardData(
        type: LogMetricType.protein,
        title: l10n.log_metric_protein,
        value: _formatInt(context, today.protein),
        unit: l10n.settings_grams_unit,
        status: _metricStatus(
          context,
          today.protein,
          today.proteinGoal,
          l10n.settings_grams_unit,
          belowRangeLabel: true,
        ),
        values: lastSeven.map((summary) => summary.protein).toList(),
        goal: today.proteinGoal,
        chartStyle: HealthMetricChartStyle.line,
        icon: Icons.fitness_center_rounded,
      ),
      HealthMetricCardData(
        type: LogMetricType.carbs,
        title: l10n.log_metric_carbs,
        value: _formatInt(context, today.carbs),
        unit: l10n.settings_grams_unit,
        status: _metricStatus(
          context,
          today.carbs,
          today.carbGoal,
          l10n.settings_grams_unit,
          belowRangeLabel: true,
        ),
        values: lastSeven.map((summary) => summary.carbs).toList(),
        goal: today.carbGoal,
        chartStyle: HealthMetricChartStyle.line,
        icon: Icons.grain_rounded,
      ),
      HealthMetricCardData(
        type: LogMetricType.fat,
        title: l10n.log_metric_fat,
        value: _formatInt(context, today.fat),
        unit: l10n.settings_grams_unit,
        status: _metricStatus(
          context,
          today.fat,
          today.fatGoal,
          l10n.settings_grams_unit,
          belowRangeLabel: true,
        ),
        values: lastSeven.map((summary) => summary.fat).toList(),
        goal: today.fatGoal,
        chartStyle: HealthMetricChartStyle.line,
        icon: Icons.circle_rounded,
      ),
    ];
  }
}

class _HealthLogHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;
  const _HealthLogHeader({this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : const Color(0xFF1C1917);
    final muted = isDark ? Colors.white54 : const Color(0xFFA8A29E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.log_health_title,
                style: AppTypography.titleMedium.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 0,
                ),
              ),
            ),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE8E4DC).withValues(alpha: 0.56),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Icon(
                  LucideIcons.settings2,
                  color: muted,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.log_key_metrics,
          style: AppTypography.labelSmall.copyWith(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

String _metricStatus(
  BuildContext context,
  int value,
  int goal,
  String unit, {
  bool belowRangeLabel = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (value <= 0) return l10n.log_metric_no_data;
  final remaining = goal - value;
  if (remaining <= 0) return l10n.log_metric_goal_hit;
  if (belowRangeLabel) return l10n.log_metric_below_range;
  final unitSuffix = unit.isEmpty ? '' : ' $unit';
  return l10n.log_metric_left('${_formatInt(context, remaining)}$unitSuffix');
}

String _formatInt(BuildContext context, int value) {
  return NumberFormat.decimalPattern(
    AppLocalizations.of(context)?.localeName,
  ).format(value);
}




// ── Customize metrics bottom sheet ───────────────────────────────────────────

class _CustomizeMetricsSheet extends StatelessWidget {
  final AppLocalizations l10n;

  const _CustomizeMetricsSheet({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isDark ? colorScheme.surfaceContainerHigh : Colors.white;
    const accent = Color(0xFF009A92);
    final isPro = context.read<SettingsProvider>().isPro;

    final allMetrics = [
      (l10n.log_metric_calories_intake, '🔥', false),
      (l10n.log_metric_energy_burned, '⚡', false),
      (l10n.log_metric_steps, '👟', false),
      (l10n.log_metric_water, '💧', false),
      (l10n.log_metric_protein, '💪', true),
      (l10n.log_metric_carbs, '🌾', true),
      (l10n.log_metric_fat, '🫧', true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 20),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.log_customize,
                    style: AppTypography.heading3.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF202124),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose which metrics appear on your dashboard',
              style: AppTypography.bodyMedium.copyWith(
                color: (isDark ? Colors.white : const Color(0xFF202124))
                    .withValues(alpha: 0.54),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Metric list
          ...allMetrics.map((item) {
            final isGated = item.$3;
            final isRowLocked = isGated && !isPro;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () {
                  if (isRowLocked) {
                    PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.settings,
                      featureName: 'customize_macros',
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: isRowLocked ? 0.02 : 0.05)
                        : Colors.black.withValues(alpha: isRowLocked ? 0.01 : 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(item.$2, style: TextStyle(fontSize: 20, color: isRowLocked ? Colors.grey : null)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              item.$1,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? Colors.white.withValues(alpha: isRowLocked ? 0.40 : 0.88)
                                    : const Color(0xFF202124).withValues(alpha: isRowLocked ? 0.40 : 1.0),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if (isRowLocked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Color(0xFFE29200),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        isRowLocked ? LucideIcons.lock : Icons.drag_handle_rounded,
                        color: isRowLocked
                            ? const Color(0xFFE29200)
                            : (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.28),
                        size: isRowLocked ? 16 : 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
