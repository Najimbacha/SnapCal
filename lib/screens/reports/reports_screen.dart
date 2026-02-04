import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _timeRange = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$_timeRange Insights'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _timeRange = value),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                  const PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                ],
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<MealProvider, SettingsProvider>(
        builder: (context, mealProvider, settingsProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(mealProvider, settingsProvider),
                const SizedBox(height: 32),
                Text('Calorie Trend', style: AppTypography.heading3),
                const SizedBox(height: 16),
                _buildCalorieChart(mealProvider),
                const SizedBox(height: 32),
                Text('Macro Distribution', style: AppTypography.heading3),
                const SizedBox(height: 16),
                _buildMacroDistribution(mealProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    MealProvider mealProvider,
    SettingsProvider settingsProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Avg. Calories',
            '${mealProvider.getWeeklyAverageCalories()}',
            Icons.local_fire_department,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Goal Consistency',
            mealProvider.getGoalConsistency(settingsProvider.dailyCalorieGoal),
            Icons.check_circle_outline,
            AppColors.protein,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.heading2),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieChart(MealProvider mealProvider) {
    final trend = mealProvider.getWeeklyCalorieTrend();
    final spots =
        trend
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withAlpha(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroDistribution(MealProvider mealProvider) {
    final macros = mealProvider.getWeeklyMacroSummary();
    final total = macros.protein + macros.carbs + macros.fat;

    double proteinPct = total > 0 ? (macros.protein / total) * 100 : 33.3;
    double carbsPct = total > 0 ? (macros.carbs / total) * 100 : 33.3;
    double fatPct = total > 0 ? (macros.fat / total) * 100 : 33.3;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppColors.protein,
                    value: proteinPct,
                    title: '',
                    radius: 10,
                  ),
                  PieChartSectionData(
                    color: AppColors.carbs,
                    value: carbsPct,
                    title: '',
                    radius: 10,
                  ),
                  PieChartSectionData(
                    color: AppColors.fat,
                    value: fatPct,
                    title: '',
                    radius: 10,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                _buildMacroLegend(
                  'Protein',
                  '${macros.protein}g',
                  AppColors.protein,
                ),
                const SizedBox(height: 12),
                _buildMacroLegend('Carbs', '${macros.carbs}g', AppColors.carbs),
                const SizedBox(height: 12),
                _buildMacroLegend('Fat', '${macros.fat}g', AppColors.fat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.bodySmall),
        const Spacer(),
        Text(value, style: AppTypography.labelMedium),
      ],
    );
  }
}
