import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/activity_summary.dart';
import '../../data/services/activity_service.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/activity_provider.dart' as ap;
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/premium_prompt_card.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/ambient_mesh_background.dart';
import '../../widgets/activity_ring_gauge.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'widgets/activity_health_connect_sheet.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(ap.activityProvider);
    final activityVal = activityAsync.valueOrNull;
    final isPro = ref.watch(settingsProvider).valueOrNull?.isPro ?? false;
    final steps = activityVal?.steps ?? 0;
    final stepGoal = 10000;
    final progress = (steps / math.max(stepGoal, 1)).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context)!;

    return AppPageScaffold(
      title: l10n.home_metric_activity,
      scrollable: true,
      background: const AmbientMeshBackground(),
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrackingStatusCard(),
          const SizedBox(height: 24),
          Center(
            child: ActivityRingGauge(
              progress: progress,
              steps: steps,
              centerSubLabel: l10n.activity_steps_today_label,
              size: 280,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.activity_steps_goal(stepGoal),
              style: AppTypography.labelMedium.copyWith(
                color: context.textMutedColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _DisclaimerCard(),
          const SizedBox(height: 14),
          if (isPro)
            const _PremiumActivityDashboard()
          else
            PremiumPromptCard(
              title: l10n.activity_unlock_pro_title,
              subtitle: l10n.activity_unlock_pro_subtitle,
              buttonText: l10n.home_go_pro,
              icon: LucideIcons.lock,
              style: PremiumPromptStyle.glass,
              onTap:
                  () => PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.homeAha,
                    featureName: 'activity_insights',
                  ),
            ),
        ],
      ),
    );
  }
}

class _TrackingStatusCard extends ConsumerWidget {
  const _TrackingStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(ap.activityProvider);
    final activityVal = activityAsync.valueOrNull;
    final isConnected = activityVal?.healthConnected ?? false;
    final isSyncing = activityAsync.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(
          alpha: isDark ? 0.2 : 0.6,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? LucideIcons.footprints
                : LucideIcons.alertCircle,
            color: isConnected ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Health Connect' : 'Not connected',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isConnected ? 'Connected' : 'Tap to connect',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed:
                    isSyncing
                        ? null
                        : () async {
                            await ref.read(ap.activityProvider.notifier).authorize();
                            ref.invalidate(ap.activityProvider);
                          },
                icon:
                    isSyncing
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(LucideIcons.link),
                label: Text(isConnected ? 'Sync' : 'Connect'),
              ),
              IconButton(
                tooltip: 'Health Connect details',
                onPressed: () => showActivityHealthConnectSheet(context),
                icon: Icon(LucideIcons.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends ConsumerWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.activity_calorie_estimate_disclaimer,
              style: AppTypography.bodySmall.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActivityDashboard extends ConsumerWidget {
  const _PremiumActivityDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(ap.activityProvider);
    final activityVal = activityAsync.valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final steps = activityVal?.steps ?? 0;
    final activeCalories = activityVal?.activeCalories?.toInt() ?? 0;
    final workoutCalories = activityVal?.workouts.fold<int>(0, (sum, w) => sum + w.calories) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.flame,
                color: Colors.orange,
                label: 'Active calories',
                value: '$activeCalories',
                unit: l10n.settings_kcal_unit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.trophy,
                color: AppColors.primary,
                label: l10n.activity_step_streak,
                value: '0',
                unit: l10n.common_days,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.dumbbell,
                color: AppColors.violet,
                label: l10n.activity_workout_calories,
                value: '$workoutCalories',
                unit: l10n.settings_kcal_unit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.activity,
                color: AppColors.sky,
                label: l10n.activity_score,
                value: '0',
                unit: '/100',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _WeeklyStepChart(),
        const SizedBox(height: 18),
        const _HealthConnectWorkoutCard(),
        const SizedBox(height: 18),
        const _InsightCard(),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.w900,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: AppTypography.labelSmall.copyWith(
                      color: context.textMutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeeklyStepChart extends ConsumerWidget {
  const _WeeklyStepChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = _emptyWeek();
    final maxY = math.max(
      1000,
      data.map((day) => day.steps).fold<int>(0, math.max),
    );

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly steps',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final label =
                            [
                              'M',
                              'T',
                              'W',
                              'T',
                              'F',
                              'S',
                              'S',
                            ][data[index].date.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(label, style: AppTypography.labelSmall),
                        );
                      },
                    ),
                  ),
                ),
                barGroups:
                    data.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.steps.toDouble(),
                            width: 14,
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ActivitySummary> _emptyWeek() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      return ActivitySummary.empty(
        DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: 6 - index)),
      );
    });
  }
}

class _HealthConnectWorkoutCard extends ConsumerWidget {
  const _HealthConnectWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(ap.activityProvider);
    final activityVal = activityAsync.valueOrNull;
    final workouts = activityVal?.workouts ?? [];
    final workout = workouts.isEmpty ? null : workouts.first;
    final title =
        workout == null ? 'No workout data today' : workout.name;
    final subtitle =
        workout == null
            ? 'Health Connect has no workout session records for today.'
            : '${workout.duration.inMinutes} min • ${workout.calories} kcal from Health Connect';

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      glass: true,
      child: Row(
        children: [
          Icon(LucideIcons.dumbbell, color: AppColors.violet),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends ConsumerWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(ap.activityProvider);
    final activityVal = activityAsync.valueOrNull;
    final steps = activityVal?.steps ?? 0;
    final avgSteps = steps;
    final insight =
        avgSteps >= 10000
            ? AppLocalizations.of(context)!.activity_insight_goal_met(avgSteps)
            : AppLocalizations.of(context)!.activity_insight_goal_gap(avgSteps);

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      glass: true,
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

