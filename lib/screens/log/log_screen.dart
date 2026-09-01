import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/water_log.dart';
import '../../providers/activity_provider.dart';
import '../../providers/log_metrics_preferences.dart';
import '../../providers/meal_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/macro_display.dart';
import '../../data/services/premium_conversion_service.dart';
import 'models/log_metric_models.dart';
import 'widgets/day_insights.dart';
import 'widgets/health_metric_dashboard.dart';
import 'widgets/hydration_sheet.dart';
import 'widgets/horizontal_day_calendar.dart';
import 'widgets/meal_list_tile.dart';
import 'widgets/edit_meal_modal.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider);
    final activity = ref.watch(activityProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final todaysMeals = ref.watch(todaysMealsProvider);
    final selectedDateMeals = todaysMeals.valueOrNull ?? [];
    var dayProtein = 0;
    var dayCarbs = 0;
    var dayFat = 0;
    for (final meal in selectedDateMeals) {
      dayProtein += meal.macros.protein;
      dayCarbs += meal.macros.carbs;
      dayFat += meal.macros.fat;
    }
    final isPro = ref.watch(effectiveIsProProvider);
    final l10n = AppLocalizations.of(context)!;
    final summaries = _buildDailySummaries();
    final selectedSummary = _summaryFor(
      summaries: summaries,
      selectedDate: selectedDate,
      settings: settings,
      water: water,
    );
    final lastSevenDays =
        summaries.length <= 7
            ? summaries
            : summaries.sublist(summaries.length - 7);
    final loggedDays =
        lastSevenDays.where((day) => day.calories > 0).toList(growable: false);
    final weekAverage =
        loggedDays.isEmpty
            ? 0
            : (loggedDays.fold<int>(0, (sum, day) => sum + day.calories) /
                    loggedDays.length)
                .round();
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
        children: [
          _HealthLogHeader(
            selectedDate: selectedDate,
            onProfileTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 10),
          HorizontalDayCalendar(
            selectedDate: selectedDate,
            dailySummaries: summaries,
            onDateSelected: (dateStr) {
              ref.read(selectedDateProvider.notifier).select(dateStr);
            },
            isDateLocked:
                (dateStr) => !(isPro || app_date.DateUtils.isToday(dateStr)),
            onLockedDateSelected: (dateStr) {
              PremiumConversionService().openPaywall(
                context,
                PaywallEntryPoint.settings,
                featureName: 'history_days',
              );
            },
          ),
          const SizedBox(height: 14),
          DayComparisonLine(
            consumed: selectedSummary.calories,
            average: weekAverage,
            format: (value) => _formatInt(context, value),
          ),
          const SizedBox(height: 22),
          LogSectionHeader(title: l10n.home_metric_meals),
          const SizedBox(height: 14),
          if (selectedDateMeals.isNotEmpty) ...[
            MealSplitBar(
              meals: selectedDateMeals,
              format: (value) => _formatInt(context, value),
            ),
            const SizedBox(height: 14),
          ],
          if (selectedDateMeals.isEmpty)
            _EmptyMealsState(l10n: l10n)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: selectedDateMeals.length,
              itemBuilder: (context, index) {
                final meal = selectedDateMeals[index];
                return MealListTile(
                  meal: meal,
                  isPro: isPro,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (modalContext) => EditMealModal(
                            meal: meal,
                            onSave: (updatedMeal) {
                              ref
                                  .read(mealLogProvider.notifier)
                                  .updateMeal(updatedMeal);
                              Navigator.of(modalContext).pop();
                            },
                            onDelete: () {
                              Navigator.of(modalContext).pop();
                              ref
                                  .read(mealLogProvider.notifier)
                                  .deleteMeal(meal.id);
                            },
                            onCancel: () => Navigator.of(modalContext).pop(),
                          ),
                    );
                  },
                  onDelete: () {
                    ref.read(mealLogProvider.notifier).deleteMeal(meal.id);
                  },
                );
              },
            ),
          const SizedBox(height: 26),
          LogSectionHeader(title: l10n.log_this_week),
          const SizedBox(height: 14),
          WeekSummaryCard(
            week: lastSevenDays,
            selectedDate: selectedDate,
            format: (value) => _formatInt(context, value),
          ),
          // Macros as the same three rings Home draws. Pro users get
          // protein/carb/fat tiles in the grid below instead.
          if (!isPro) ...[
            const SizedBox(height: 26),
            LogSectionHeader(title: l10n.home_section_macros_today),
            const SizedBox(height: 14),
            MacroDisplay(
              macros: Macros(
                protein: dayProtein,
                carbs: dayCarbs,
                fat: dayFat,
              ),
              proteinGoal: settings.valueOrNull?.dailyProteinGoal ?? 0,
              carbGoal: settings.valueOrNull?.dailyCarbGoal ?? 0,
              fatGoal: settings.valueOrNull?.dailyFatGoal ?? 0,
              variant: MacroDisplayVariant.rings,
              showGrams: false,
              showGoals: false,
              onUpgradeTap:
                  () => PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.macroDetails,
                    featureName: 'log_macros',
                  ),
            ),
          ],
          const SizedBox(height: 26),
          HealthMetricDashboard(
            title: l10n.log_key_metrics,
            actionLabel: l10n.log_customize,
            cards:
                (isPro ? dashboardCards : dashboardCards.take(4).toList())
                    .where(
                      (card) =>
                          // Calories are not repeated here: the week card and
                          // the meal list already carry them.
                          card.type != LogMetricType.calories &&
                          ref
                              .watch(visibleLogMetricsProvider)
                              .contains(card.type),
                    )
                    .toList(),
            onMetricTap: (type) {
              if (type == LogMetricType.water) {
                showHydrationSheet(context);
              } else {
                context.push('/log/metric/${type.id}');
              }
            },
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

  List<DailySummary> _buildDailySummaries() {
    final isPro = ref.watch(effectiveIsProProvider);
    final now = DateTime.now();

    final dayCount = isPro ? 90 : 14;
    final visibleDayCount = math.max(dayCount, 14);
    final todayKey = app_date.DateUtils.getDateString(now);
    final liveSteps = ref.watch(activityProvider).valueOrNull?.steps ?? 0;
    return List.generate(visibleDayCount, (index) {
      final date = now.subtract(Duration(days: visibleDayCount - 1 - index));
      final dateString = app_date.DateUtils.getDateString(date);
      return _buildSummaryForDate(
        dateString: dateString,
        steps: dateString == todayKey ? liveSteps : 0,
      );
    });
  }

  DailySummary _buildSummaryForDate({
    required String dateString,
    int steps = 0,
  }) {
    final settings = ref.watch(settingsProvider);
    final s = settings.valueOrNull ?? UserSettings.defaults();
    // Real per-day data from the repositories. The old implementation iterated
    // a hardcoded empty list, so calories/water/macros were pinned to zero on
    // every card no matter what was logged.
    final mealRepo = ref.watch(mealRepositoryProvider).valueOrNull;
    final waterRepo = ref.watch(waterRepositoryProvider).valueOrNull;
    final meals = mealRepo?.getMealsByDate(dateString) ?? const <Meal>[];
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
    final waterMl = (waterRepo?.getWaterByDate(dateString) ??
            const <WaterLog>[])
        .fold<int>(0, (sum, log) => sum + log.amountMl);

    return DailySummary(
      dateString: dateString,
      calories: calories,
      calorieGoal: s.dailyCalorieGoal,
      protein: protein,
      proteinGoal: s.dailyProteinGoal,
      carbs: carbs,
      carbGoal: s.dailyCarbGoal,
      fat: fat,
      fatGoal: s.dailyFatGoal,
      waterMl: waterMl,
      waterGoal: ref.watch(waterProvider).valueOrNull?.goal ?? 2500,
      steps: steps,
      stepGoal: 10000,
      mealCount: meals.length,
    );
  }

  /// The summary for the day the user is looking at.
  ///
  /// Shared by the summary card and the metric grid so the two can never
  /// disagree about the same day.
  DailySummary _summaryFor({
    required List<DailySummary> summaries,
    required String selectedDate,
    required AsyncValue<UserSettings> settings,
    required AsyncValue<WaterState> water,
  }) {
    final s = settings.valueOrNull ?? UserSettings.defaults();
    final w = water.valueOrNull ?? const WaterState(todayTotal: 0);
    return summaries.firstWhere(
      (summary) => summary.dateString == selectedDate,
      orElse:
          () =>
              summaries.isEmpty
                  ? DailySummary(
                    dateString: selectedDate,
                    calories: 0,
                    calorieGoal: s.dailyCalorieGoal,
                    protein: 0,
                    proteinGoal: s.dailyProteinGoal,
                    carbs: 0,
                    carbGoal: s.dailyCarbGoal,
                    fat: 0,
                    fatGoal: s.dailyFatGoal,
                    waterMl: w.todayTotal,
                    waterGoal: w.goal,
                    steps: 0,
                    stepGoal: 10000,
                    mealCount: 0,
                  )
                  : summaries.last,
    );
  }

  List<HealthMetricCardData> _buildDashboardCards({
    required BuildContext context,
    required List<DailySummary> summaries,
    required AsyncValue<UserSettings> settings,
    required AsyncValue<ActivitySummary> activity,
    required AsyncValue<WaterState> water,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = ref.watch(selectedDateProvider);
    final todaySummary = _summaryFor(
      summaries: summaries,
      selectedDate: selectedDate,
      settings: settings,
      water: water,
    );
    final lastSeven =
        summaries.length <= 7
            ? summaries
            : summaries.sublist(summaries.length - 7);

    final activityTrend = List<int>.filled(7, 0);
    final stepTrend = lastSeven.map((summary) => summary.steps).toList();

    final activityVal = activity.valueOrNull;
    final isTodaySelected =
        todaySummary.dateString ==
        app_date.DateUtils.getDateString(DateTime.now());
    final energyBurned =
        isTodaySelected ? (activityVal?.activeCalories ?? 0).round() : 0;
    final energyEstimated =
        isTodaySelected && (activityVal?.activeCaloriesEstimated ?? true);
    if (activityTrend.isNotEmpty) {
      activityTrend[activityTrend.length - 1] = energyBurned;
    }

    return [
      HealthMetricCardData(
        type: LogMetricType.calories,
        title: l10n.log_metric_calories_intake,
        value: _formatInt(context, todaySummary.calories),
        unit: l10n.settings_kcal_unit,
        status: _metricStatus(
          context,
          todaySummary.calories,
          todaySummary.calorieGoal,
          l10n.settings_kcal_unit,
        ),
        values: lastSeven.map((summary) => summary.calories).toList(),
        goal: todaySummary.calorieGoal,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.utensils,
      ),
      HealthMetricCardData(
        type: LogMetricType.energy,
        title: l10n.log_metric_energy_burned,
        value:
            energyBurned <= 0
                // Nothing measured: the card says "No data" below, so the
                // slot holds a dash rather than a zero that contradicts it.
                ? '–'
                : energyEstimated
                ? '~${_formatInt(context, energyBurned)}'
                : _formatInt(context, energyBurned),
        unit: l10n.settings_kcal_unit,
        status: _metricStatus(
          context,
          energyBurned,
          0,
          l10n.settings_kcal_unit,
        ),
        values: activityTrend,
        goal: 0,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.flame,
      ),
      HealthMetricCardData(
        type: LogMetricType.steps,
        title: l10n.log_metric_steps,
        value: _formatInt(context, todaySummary.steps),
        unit: '',
        status: _metricStatus(
          context,
          todaySummary.steps,
          todaySummary.stepGoal,
          l10n.log_metric_steps_unit,
        ),
        values: stepTrend,
        goal: todaySummary.stepGoal,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.footprints,
      ),
      HealthMetricCardData(
        type: LogMetricType.water,
        title: l10n.log_metric_water,
        value: _formatInt(context, todaySummary.waterMl),
        unit: l10n.settings_milliliters_unit,
        status: _metricStatus(
          context,
          todaySummary.waterMl,
          todaySummary.waterGoal,
          l10n.settings_milliliters_unit,
        ),
        values: lastSeven.map((summary) => summary.waterMl).toList(),
        goal: todaySummary.waterGoal,
        chartStyle: HealthMetricChartStyle.bars,
        icon: LucideIcons.droplets,
      ),
      HealthMetricCardData(
        type: LogMetricType.protein,
        title: l10n.log_metric_protein,
        value: _formatInt(context, todaySummary.protein),
        unit: l10n.settings_grams_unit,
        status: _metricStatus(
          context,
          todaySummary.protein,
          todaySummary.proteinGoal,
          l10n.settings_grams_unit,
          belowRangeLabel: true,
        ),
        values: lastSeven.map((summary) => summary.protein).toList(),
        goal: todaySummary.proteinGoal,
        chartStyle: HealthMetricChartStyle.line,
        icon: LucideIcons.dumbbell,
      ),
      HealthMetricCardData(
        type: LogMetricType.carbs,
        title: l10n.log_metric_carbs,
        value: _formatInt(context, todaySummary.carbs),
        unit: l10n.settings_grams_unit,
        status: _metricStatus(
          context,
          todaySummary.carbs,
          todaySummary.carbGoal,
          l10n.settings_grams_unit,
          belowRangeLabel: true,
        ),
        values: lastSeven.map((summary) => summary.carbs).toList(),
        goal: todaySummary.carbGoal,
        chartStyle: HealthMetricChartStyle.line,
        icon: LucideIcons.wheat,
      ),
      HealthMetricCardData(
        type: LogMetricType.fat,
        title: l10n.log_metric_fat,
        value: _formatInt(context, todaySummary.fat),
        unit: l10n.settings_grams_unit,
        status: _metricStatus(
          context,
          todaySummary.fat,
          todaySummary.fatGoal,
          l10n.settings_grams_unit,
          belowRangeLabel: true,
        ),
        values: lastSeven.map((summary) => summary.fat).toList(),
        goal: todaySummary.fatGoal,
        chartStyle: HealthMetricChartStyle.line,
        icon: LucideIcons.circle,
      ),
    ];
  }
}

class _HealthLogHeader extends StatelessWidget {
  final String selectedDate;
  final VoidCallback? onProfileTap;
  const _HealthLogHeader({required this.selectedDate, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = DateTime.tryParse(selectedDate);
    final dateFormatted =
        parsed != null
            ? DateFormat.yMMMMd(l10n.localeName).format(parsed)
            : selectedDate;
    final muted =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white38
            : const Color(0xFFA8A29E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dateFormatted,
                style: AppTypography.titleMedium.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.settings2, color: muted, size: 17),
              ),
            ),
          ],
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
  // An empty metric with a goal still has something useful to say ("2,000 ml
  // left"). "No data" is reserved for the case where there is no value AND no
  // target — otherwise the card prints a zero and denies it in the same breath.
  if (value <= 0 && goal <= 0) return l10n.log_metric_no_data;
  if (goal <= 0) return '';
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

// ── Empty meals state ────────────────────────────────────────────────────────

class _EmptyMealsState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyMealsState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white38 : const Color(0xFFB4AFA8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.utensilsCrossed, size: 32, color: muted),
          const SizedBox(height: 16),
          Text(
            l10n.home_no_meals_title,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? Colors.white60 : const Color(0xFF78716C),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.home_no_meals_body,
            style: AppTypography.labelSmall.copyWith(
              color: muted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Customize metrics bottom sheet ───────────────────────────────────────────

class _CustomizeMetricsSheet extends ConsumerWidget {
  final AppLocalizations l10n;

  const _CustomizeMetricsSheet({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isDark ? colorScheme.surfaceContainerHigh : Colors.white;
    final accent = Theme.of(context).colorScheme.primary;
    final isPro = ref.watch(effectiveIsProProvider);
    final visible = ref.watch(visibleLogMetricsProvider);

    final allMetrics = [
      (
        l10n.log_metric_calories_intake,
        LucideIcons.utensils,
        LogMetricType.calories,
        false,
      ),
      (
        l10n.log_metric_energy_burned,
        LucideIcons.flame,
        LogMetricType.energy,
        false,
      ),
      (
        l10n.log_metric_steps,
        LucideIcons.footprints,
        LogMetricType.steps,
        false,
      ),
      (l10n.log_metric_water, LucideIcons.droplets, LogMetricType.water, false),
      (
        l10n.log_metric_protein,
        LucideIcons.dumbbell,
        LogMetricType.protein,
        true,
      ),
      (l10n.log_metric_carbs, LucideIcons.wheat, LogMetricType.carbs, true),
      (l10n.log_metric_fat, LucideIcons.circle, LogMetricType.fat, true),
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
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.12,
              ),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.common_done,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w500,
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
              l10n.log_customize_metrics_desc,
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
            final label = item.$1;
            final icon = item.$2;
            final type = item.$3;
            final isGated = item.$4;
            final isRowLocked = isGated && !isPro;
            final isVisible = visible.contains(type);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () {
                  if (isRowLocked) {
                    PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.macroDetails,
                      featureName: 'customize_macros',
                    );
                    return;
                  }
                  ref.read(visibleLogMetricsProvider.notifier).toggle(type);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(
                              alpha: isRowLocked ? 0.02 : 0.05,
                            )
                            : Colors.black.withValues(
                              alpha: isRowLocked ? 0.01 : 0.03,
                            ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color:
                            isRowLocked
                                ? Colors.grey
                                : (isDark
                                    ? Colors.white60
                                    : const Color(0xFF78716C)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: AppTypography.titleMedium.copyWith(
                                color:
                                    isDark
                                        ? Colors.white.withValues(
                                          alpha: isRowLocked ? 0.40 : 0.88,
                                        )
                                        : const Color(0xFF202124).withValues(
                                          alpha: isRowLocked ? 0.40 : 1.0,
                                        ),
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            if (isRowLocked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  l10n.home_pro_badge,
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white38
                                            : const Color(0xFFA8A29E),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isRowLocked)
                        Icon(
                          LucideIcons.lock,
                          color: const Color(0xFFE29200),
                          size: 16,
                        )
                      else
                        Switch.adaptive(
                          value: isVisible,
                          activeThumbColor: accent,
                          onChanged:
                              (_) => ref
                                  .read(visibleLogMetricsProvider.notifier)
                                  .toggle(type),
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
