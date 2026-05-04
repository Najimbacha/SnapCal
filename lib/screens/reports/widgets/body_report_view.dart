import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/metrics_provider.dart';
import '../../../widgets/ui_blocks.dart';
import '../../settings/widgets/weight_entry_modal.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

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
              title: AppLocalizations.of(context)!.report_no_weight_title,
              body: AppLocalizations.of(context)!.report_no_weight_body,
              actionLabel: AppLocalizations.of(context)!.report_log_weight,
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
                      label: AppLocalizations.of(context)!.report_weight_current,
                      value: '${current?.toStringAsFixed(1) ?? '--'} kg',
                      accent: AppColors.primary,
                      icon: LucideIcons.scale,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      label: AppLocalizations.of(context)!.report_weight_change,
                      value:
                          '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                      accent: change <= 0 ? AppColors.protein : AppColors.fat,
                      icon: change <= 0 ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppSectionCard(
                glass: true,
                padding: EdgeInsets.zero,
                child: _ScaleTap(
                  onTap: () => context.push('/progress'),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.camera, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.report_progress_timeline, 
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.report_progress_gallery,
                      style: AppTypography.bodySmall.copyWith(color: context.textSecondaryColor),
                    ),
                    trailing: Icon(LucideIcons.chevronRight, size: 18, color: context.textMutedColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppSectionCard(
                glass: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(title: AppLocalizations.of(context)!.report_weight_analytics),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: _WeightChart(metrics: metrics),
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
                    SectionLabel(title: AppLocalizations.of(context)!.report_recent_history),
                    const SizedBox(height: 16),
                    ...metrics
                        .take(5)
                        .map(
                          (metric) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.backgroundColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.calendar,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    '${metric.date.day}/${metric.date.month}/${metric.date.year}',
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${metric.weight.toStringAsFixed(1)} kg',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (metric.bodyFat != null)
                                      Text(
                                        AppLocalizations.of(context)!.report_body_fat_pct(metric.bodyFat!.toStringAsFixed(1)),
                                        style: AppTypography.bodySmall.copyWith(
                                          color: context.textSecondaryColor,
                                          fontWeight: FontWeight.w600,
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
    final colorScheme = Theme.of(context).colorScheme;
    final series = metrics.take(14).toList().reversed.toList();
    final spots =
        series
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weight))
            .toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minY.floorToDouble(),
        maxY: maxY.ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
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
                  '${spot.y.toStringAsFixed(1)} kg',
                  AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
 LineChartBarData(
            spots: spots,
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

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
