import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/widgets/glass_card.dart';

class WeekChart extends StatelessWidget {
  final List<double> dailyCalories;

  const WeekChart({super.key, required this.dailyCalories});

  @override
  Widget build(BuildContext context) {
    if (dailyCalories.isEmpty) return const SizedBox.shrink();

    final maxY = dailyCalories.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxY > 0 ? maxY : 2500) * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      if (value.toInt() < 0 || value.toInt() >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[value.toInt()],
                          style: AppTypography.labelSmall,
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups:
                  dailyCalories.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: AppColors.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
