import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/meal_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/ui_blocks.dart';

class NutritionReportView extends StatelessWidget {
  const NutritionReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MealProvider, SettingsProvider>(
      builder: (context, meals, settings, _) {
        final weeklyMacros = meals.getWeeklyMacroSummary();
        return SingleChildScrollView(
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
              const SizedBox(height: 16),
              AppSectionCard(
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
              const SizedBox(height: 16),
              AppSectionCard(
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
    final spots =
        values
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: context.dividerColor),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
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
        sectionsSpace: 4,
        centerSpaceRadius: 34,
        sections: [
          PieChartSectionData(
            color: AppColors.protein,
            value: total > 0 ? protein : 1,
            title: '',
          ),
          PieChartSectionData(
            color: AppColors.carbs,
            value: total > 0 ? carbs : 1,
            title: '',
          ),
          PieChartSectionData(
            color: AppColors.fat,
            value: total > 0 ? fat : 1,
            title: '',
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
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTypography.bodyMedium)),
        Text(value, style: AppTypography.labelMedium),
      ],
    );
  }
}
