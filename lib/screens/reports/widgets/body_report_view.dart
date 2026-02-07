import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/metrics_provider.dart';
import '../../settings/widgets/weight_entry_modal.dart';

class BodyReportView extends StatelessWidget {
  const BodyReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MetricsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = provider.metrics; // Sorted newest first
        if (metrics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.scale,
                  size: 64,
                  color: context.textSecondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No weight data yet',
                  style: AppTypography.heading3.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const WeightEntryModal(),
                    );
                  },
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Log Weight'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildWeightSummary(context, provider),
            const SizedBox(height: 32),
            Text('Weight History', style: AppTypography.heading3),
            const SizedBox(height: 16),
            _buildWeightChart(context, metrics),
            const SizedBox(height: 32),
            Text('Recent Entries', style: AppTypography.heading3),
            const SizedBox(height: 16),
            _buildEntriesList(context, metrics),
          ],
        );
      },
    );
  }

  Widget _buildWeightSummary(BuildContext context, MetricsProvider provider) {
    final current = provider.currentWeight;
    final start = provider.startWeight;
    final change = (current != null && start != null) ? current - start : 0.0;
    final isLoss = change <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            'Current',
            '${current?.toStringAsFixed(1) ?? "--"} kg',
            context,
          ),
          Container(width: 1, height: 40, color: context.glassBorderColor),
          _buildStat(
            'Start',
            '${start?.toStringAsFixed(1) ?? "--"} kg',
            context,
          ),
          Container(width: 1, height: 40, color: context.glassBorderColor),
          _buildStat(
            'Change',
            '${isLoss ? "" : "+"}${change.toStringAsFixed(1)} kg',
            context,
            color: isLoss ? AppColors.protein : AppColors.fat,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value,
    BuildContext context, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.heading2.copyWith(
            color: color ?? context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(BuildContext context, List<dynamic> metrics) {
    // metrics is newest first
    final data = metrics.take(14).toList().reversed.toList();
    if (data.length < 2) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Add more data to see chart',
            style: TextStyle(color: context.textSecondaryColor),
          ),
        ),
      );
    }

    final spots =
        data
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
            .toList();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine:
                (value) => FlLine(
                  color: context.glassBorderColor.withOpacity(0.5),
                  strokeWidth: 1,
                ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: context.textMutedColor,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF6B4DFF),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF6B4DFF).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context, List<dynamic> metrics) {
    return Column(
      children:
          metrics.take(5).map((m) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4DFF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.scale,
                      color: Color(0xFF6B4DFF),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${m.date.day}/${m.date.month}',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${m.weight} kg',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (m.bodyFat != null)
                        Text(
                          '${m.bodyFat}% Body Fat',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
