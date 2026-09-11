import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../widgets/premium_prompt_card.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../data/models/meal.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/meal_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/async_state_widgets.dart';
import '../../../widgets/ui_blocks.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

/// A period's nutrition, worked out from the meals actually logged.
///
/// The report used to show typed-in zeros -- "0" calories, "0%" consistency,
/// an empty chart and "0g" of every macro -- to every user, Pro included,
/// whatever they had logged.
class NutritionReportSummary {
  const NutritionReportSummary({
    required this.days,
    required this.dailyCalories,
    required this.loggedDays,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
  });

  final int days;

  /// Calories per day, oldest first; zero for a day with nothing logged.
  final List<int> dailyCalories;
  final int loggedDays;

  /// Averages over the days that have meals, so a day that was simply not
  /// logged does not drag them down as if nothing had been eaten.
  final int avgCalories;
  final int avgProtein;
  final int avgCarbs;
  final int avgFat;

  /// The share of the period's days with at least one meal logged.
  int get consistencyPercent =>
      days == 0 ? 0 : (loggedDays * 100 / days).round();

  static NutritionReportSummary compute({
    required int days,
    required DateTime today,
    required List<Meal> Function(String date) mealsForDate,
  }) {
    final calories = <int>[];
    var logged = 0;
    var totalKcal = 0, protein = 0, carbs = 0, fat = 0;
    for (var i = days - 1; i >= 0; i--) {
      final date = app_date.DateUtils.getDateString(
        DateTime(today.year, today.month, today.day - i),
      );
      final meals = mealsForDate(date);
      final dayKcal = meals.fold<int>(0, (sum, m) => sum + m.calories);
      calories.add(dayKcal);
      if (meals.isEmpty) continue;
      logged++;
      totalKcal += dayKcal;
      protein += meals.fold<int>(0, (sum, m) => sum + m.macros.protein);
      carbs += meals.fold<int>(0, (sum, m) => sum + m.macros.carbs);
      fat += meals.fold<int>(0, (sum, m) => sum + m.macros.fat);
    }
    int average(int total) => logged == 0 ? 0 : (total / logged).round();
    return NutritionReportSummary(
      days: days,
      dailyCalories: calories,
      loggedDays: logged,
      avgCalories: average(totalKcal),
      avgProtein: average(protein),
      avgCarbs: average(carbs),
      avgFat: average(fat),
    );
  }
}

class NutritionReportView extends ConsumerWidget {
  const NutritionReportView({super.key, this.days = 7});

  /// 7 for the weekly review, 30 for the monthly one.
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final repoAsync = ref.watch(mealRepositoryProvider);
    // Rebuilt when today's meals change, and when the day itself does.
    ref.watch(todaysMealsProvider);
    if (settings.isLoading || repoAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: AppSectionSkeleton(rows: 3),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final repo = repoAsync.valueOrNull;
    final summary = NutritionReportSummary.compute(
      days: days,
      today: DateTime.now(),
      mealsForDate: (date) => repo?.getMealsByDate(date) ?? const <Meal>[],
    );
    final hasData = summary.loggedDays > 0;
    final isPro = ref.watch(effectiveIsProProvider);
    final number = NumberFormat.decimalPattern(l10n.localeName);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: l10n.report_avg_calories,
                  value: hasData ? number.format(summary.avgCalories) : '–',
                  accent: AppColors.primary,
                  icon: LucideIcons.flame,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: l10n.report_consistency,
                  value: '${summary.consistencyPercent}%',
                  accent: AppColors.protein,
                  icon: LucideIcons.checkCircle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            AppSectionCard(
              glass: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.report_no_meals_title,
                    style: AppTypography.titleMedium.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.report_no_meals_body,
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          if (isPro && hasData) ...[
            AppSectionCard(
              glass: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(title: l10n.report_calorie_trend),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: _CalorieChart(
                      values: [
                        for (final kcal in summary.dailyCalories)
                          kcal.toDouble(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              glass: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(title: l10n.report_macro_dist),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        // Shares of the day's energy, not of its grams: a
                        // gram of fat is more than twice a gram of either.
                        child: _MacroChart(
                          protein: summary.avgProtein * 4,
                          carbs: summary.avgCarbs * 4,
                          fat: summary.avgFat * 9,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _LegendRow(
                              label: l10n.report_macro_protein,
                              value: '${summary.avgProtein}g',
                              color: AppColors.protein,
                            ),
                            const SizedBox(height: 10),
                            _LegendRow(
                              label: l10n.report_macro_carbs,
                              value: '${summary.avgCarbs}g',
                              color: AppColors.carbs,
                            ),
                            const SizedBox(height: 10),
                            _LegendRow(
                              label: l10n.report_macro_fat,
                              value: '${summary.avgFat}g',
                              color: AppColors.fat,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (!isPro) ...[
            const SizedBox(height: 16),
            PremiumPromptCard(
              title: l10n.report_card_title,
              subtitle: l10n.report_card_subtitle,
              buttonText: l10n.report_prompt_btn,
              icon: LucideIcons.fileBarChart,
              onTap:
                  () => PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.reportInsight,
                    featureName: 'weekly_report',
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalorieChart extends StatelessWidget {
  final List<double> values;

  const _CalorieChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots =
        values
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
    // Thirty dots crowd a phone-width chart into a bead string.
    final showDots = values.length <= 14;

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine:
              (value) => FlLine(
                color: context.dividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.surfaceContainerHigh,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.round()} kcal',
                  AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: showDots,
              getDotPainter:
                  (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.primary,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChart extends StatelessWidget {
  final int protein;
  final int carbs;
  final int fat;

  const _MacroChart({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final total = protein + carbs + fat;
    return PieChart(
      PieChartData(
        sectionsSpace: 6,
        centerSpaceRadius: 38,
        sections: [
          PieChartSectionData(
            color: AppColors.protein,
            value: total > 0 ? protein.toDouble() : 1,
            title: '',
            radius: 18,
          ),
          PieChartSectionData(
            color: AppColors.carbs,
            value: total > 0 ? carbs.toDouble() : 1,
            title: '',
            radius: 18,
          ),
          PieChartSectionData(
            color: AppColors.fat,
            value: total > 0 ? fat.toDouble() : 1,
            title: '',
            radius: 18,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
