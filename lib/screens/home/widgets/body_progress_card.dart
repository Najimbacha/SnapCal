import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../../../providers/metrics_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../settings/widgets/weight_entry_modal.dart';

class BodyProgressCard extends StatelessWidget {
  const BodyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MetricsProvider>(
      builder: (context, provider, child) {
        final currentWeight = provider.currentWeight;
        final bmi = provider.bmi;
        final bmiCategory = provider.bmiCategory;
        final recentTrend = provider.recentTrend;
        final hasData = currentWeight != null;

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const WeightEntryModal(),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.glassBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4DFF).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.scale,
                            color: Color(0xFF6B4DFF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.home_body_stats, style: AppTypography.heading3),
                      ],
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: context.textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!hasData)
                  _buildEmptyState(context)
                else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  currentWeight.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'kg',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getBmiColor(bmi).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'BMI ${bmi?.toStringAsFixed(1) ?? "--"} • $bmiCategory',
                                style: TextStyle(
                                  color: _getBmiColor(bmi),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 60,
                        child: _buildMiniChart(recentTrend),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Tap to log your customized weight',
          style: AppTypography.bodySmall.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<dynamic> metrics) {
    if (metrics.length < 2) return const SizedBox.shrink();

    // Take last 7 entries for mini chart (metrics is newest first)
    final chartData = metrics.take(7).toList().reversed.toList();
    final spots =
        chartData
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
            .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF6B4DFF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6B4DFF).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBmiColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 25) return Colors.greenAccent;
    if (bmi < 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
