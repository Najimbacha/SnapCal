import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../providers/meal_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/ui_blocks.dart';

class NutritionReportView extends StatelessWidget {
  const NutritionReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MealProvider, SettingsProvider>(
      builder: (context, meals, settings, _) {
        if (meals.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final weeklyMacros = meals.getWeeklyMacroSummary();
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 16,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: 'Avg. Calories',
                      value: '${meals.getWeeklyAverageCalories()}',
                      accent: AppColors.primary,
                      icon: Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      label: 'Consistency',
                      value: meals.getGoalConsistency(
                        settings.dailyCalorieGoal,
                      ),
                      accent: AppColors.protein,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppSectionCard(
                glass: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel(title: 'Calorie trend'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: _CalorieChart(
                        values: meals.getWeeklyCalorieTrend(),
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
                    const SectionLabel(title: 'Macro distribution'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: _MacroChart(
                            protein: weeklyMacros.protein.toDouble(),
                            carbs: weeklyMacros.carbs.toDouble(),
                            fat: weeklyMacros.fat.toDouble(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _LegendRow(
                                label: 'Protein',
                                value: '${weeklyMacros.protein}g',
                                color: AppColors.protein,
                              ),
                              const SizedBox(height: 10),
                              _LegendRow(
                                label: 'Carbs',
                                value: '${weeklyMacros.carbs}g',
                                color: AppColors.carbs,
                              ),
                              const SizedBox(height: 10),
                              _LegendRow(
                                label: 'Fat',
                                value: '${weeklyMacros.fat}g',
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
          ),
        );
      },
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

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) => FlLine(
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
                  AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
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
  final double protein;
  final double carbs;
  final double fat;

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
            value: total > 0 ? protein : 1,
            title: '',
            radius: 18,
            badgeWidget: total > 0 ? null : const Icon(Icons.info_outline, size: 12),
          ),
          PieChartSectionData(
            color: AppColors.carbs,
            value: total > 0 ? carbs : 1,
            title: '',
            radius: 18,
          ),
          PieChartSectionData(
            color: AppColors.fat,
            value: total > 0 ? fat : 1,
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
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1),
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
              )
            )
          ),
          Text(
            value, 
            style: AppTypography.labelMedium.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w900,
            )
          ),
        ],
      ),
    );
  }
}
