import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/metrics_provider.dart';
import '../../../widgets/ui_blocks.dart';
import '../../settings/widgets/weight_entry_modal.dart';

class BodyReportView extends StatelessWidget {
  const BodyReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MetricsProvider>(
      builder: (context, metricsProvider, _) {
        if (metricsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final metrics = metricsProvider.metrics;
        if (metrics.isEmpty) {
          return Center(
            child: AppEmptyState(
              icon: LucideIcons.scale,
              title: 'No weight entries yet',
              body: 'Add your first entry so your body trend can start.',
              actionLabel: 'Log weight',
              onAction:
                  () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const WeightEntryModal(),
                  ),
            ),
          );
        }

        final current = metricsProvider.currentWeight;
        final start = metricsProvider.startWeight;
        final change = current != null && start != null ? current - start : 0;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: 'Current',
                      value: '${current?.toStringAsFixed(1) ?? '--'} kg',
                      accent: AppColors.primary,
                      icon: LucideIcons.scale,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      label: 'Change',
                      value:
                          '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                      accent: change <= 0 ? AppColors.protein : AppColors.fat,
                      icon: LucideIcons.trendingUp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel(title: 'Weight history'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: _WeightChart(metrics: metrics),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel(title: 'Recent entries'),
                    const SizedBox(height: 12),
                    ...metrics
                        .take(5)
                        .map(
                          (metric) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    LucideIcons.scale,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${metric.date.day}/${metric.date.month}/${metric.date.year}',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${metric.weight.toStringAsFixed(1)} kg',
                                      style: AppTypography.labelLarge,
                                    ),
                                    if (metric.bodyFat != null)
                                      Text(
                                        '${metric.bodyFat!.toStringAsFixed(1)}% body fat',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

class _WeightChart extends StatelessWidget {
  final List<dynamic> metrics;

  const _WeightChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final series = metrics.take(14).toList().reversed.toList();
    final spots =
        series
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weight))
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
            spots: spots,
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
