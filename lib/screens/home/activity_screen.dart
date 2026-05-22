import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/activity_summary.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/activity_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/premium_prompt_card.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/ambient_mesh_background.dart';
import '../../widgets/activity_ring_gauge.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ActivityProvider>().syncNow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final isPro = context.select<SettingsProvider, bool>((p) => p.isPro);
    final progress = (activity.steps / math.max(activity.stepGoal, 1)).clamp(
      0.0,
      1.0,
    );
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
          _TrackingStatusCard(activity: activity),
          const SizedBox(height: 24),
          Center(
            child: ActivityRingGauge(
              progress: progress,
              steps: activity.steps,
              centerSubLabel: l10n.activity_steps_today_label,
              size: 280,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.activity_steps_goal(activity.stepGoal),
              style: AppTypography.labelMedium.copyWith(
                color: context.textMutedColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _DisclaimerCard(),
          const SizedBox(height: 14),
          if (isPro)
            _PremiumActivityDashboard(activity: activity)
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

class _TrackingStatusCard extends StatelessWidget {
  final ActivityProvider activity;

  const _TrackingStatusCard({required this.activity});

  @override
  Widget build(BuildContext context) {
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
            activity.isConnected
                ? LucideIcons.footprints
                : LucideIcons.alertCircle,
            color: activity.isConnected ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.sourceName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  activity.statusLabel(),
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
              if (activity.isConnected) ...[
                TextButton(
                  onPressed: activity.disconnect,
                  child: Text(
                    'Disable',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              TextButton.icon(
                onPressed:
                    activity.isSyncing
                        ? null
                        : activity.isConnected
                        ? activity.syncNow
                        : activity.startTracking,
                icon:
                    activity.isSyncing
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(
                          activity.isConnected
                              ? LucideIcons.refreshCw
                              : LucideIcons.play,
                        ),
                label: Text(activity.isConnected ? 'Sync' : 'Enable'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          const Icon(LucideIcons.info, color: AppColors.warning, size: 18),
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

class _PremiumActivityDashboard extends StatelessWidget {
  final ActivityProvider activity;

  const _PremiumActivityDashboard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final today = activity.today;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.flame,
                color: Colors.orange,
                label: l10n.activity_estimated_calories,
                value: '${today.activityCalories}',
                unit: l10n.settings_kcal_unit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.trophy,
                color: AppColors.primary,
                label: l10n.activity_step_streak,
                value: '${today.stepStreak}',
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
                value: '${today.manualWorkoutCalories}',
                unit: l10n.settings_kcal_unit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.activity,
                color: AppColors.sky,
                label: l10n.activity_score,
                value: '${today.activityScore}',
                unit: '/100',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _WeeklyStepChart(week: activity.week),
        const SizedBox(height: 18),
        _ManualWorkoutCard(activity: activity),
        const SizedBox(height: 18),
        _InsightCard(activity: activity),
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

class _WeeklyStepChart extends StatelessWidget {
  final List<ActivitySummary> week;

  const _WeeklyStepChart({required this.week});

  @override
  Widget build(BuildContext context) {
    final data = week.isEmpty ? _emptyWeek() : week;
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

class _ManualWorkoutCard extends StatelessWidget {
  final ActivityProvider activity;

  const _ManualWorkoutCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.activity_manual_workouts,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showWorkoutSheet(context, activity),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(l10n.home_add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activity.today.workouts.isEmpty)
            Text(
              l10n.activity_no_manual_workouts,
              style: AppTypography.bodySmall.copyWith(
                color: context.textMutedColor,
              ),
            )
          else
            ...activity.today.workouts.map(
              (workout) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.dumbbell),
                title: Text(_workoutTypeLabel(context, workout.type)),
                subtitle: Text(
                  l10n.common_minutes_short(workout.duration.inMinutes),
                ),
                trailing: Text(l10n.common_kcal_value(workout.calories)),
              ),
            ),
        ],
      ),
    );
  }

  String _workoutTypeLabel(BuildContext context, String type) {
    if (type == WorkoutEntry.defaultType ||
        type == WorkoutEntry.legacyDefaultType) {
      return AppLocalizations.of(context)!.activity_default_workout;
    }
    return type;
  }

  void _showWorkoutSheet(BuildContext context, ActivityProvider activity) {
    final l10n = AppLocalizations.of(context)!;
    final typeController = TextEditingController(
      text: l10n.activity_default_workout,
    );
    final caloriesController = TextEditingController();
    final minutesController = TextEditingController(text: '30');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (sheetContext) => Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.activity_add_workout, style: AppTypography.heading3),
                const SizedBox(height: 16),
                TextField(
                  controller: typeController,
                  decoration: InputDecoration(
                    labelText: l10n.activity_workout_type,
                  ),
                ),
                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.result_calories),
                ),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.activity_minutes),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    final calories = int.tryParse(caloriesController.text) ?? 0;
                    final minutes = int.tryParse(minutesController.text) ?? 0;
                    if (calories <= 0 || minutes <= 0) return;
                    activity.addManualWorkout(
                      type: typeController.text,
                      calories: calories,
                      start: DateTime.now().subtract(
                        Duration(minutes: minutes),
                      ),
                      duration: Duration(minutes: minutes),
                    );
                    Navigator.pop(sheetContext);
                  },
                  child: Text(l10n.activity_save_workout),
                ),
              ],
            ),
          ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final ActivityProvider activity;

  const _InsightCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final avgSteps =
        activity.week.isEmpty
            ? 0
            : activity.week.fold<int>(0, (sum, day) => sum + day.steps) ~/
                activity.week.length;
    final insight =
        avgSteps >= activity.stepGoal
            ? AppLocalizations.of(context)!.activity_insight_goal_met(avgSteps)
            : AppLocalizations.of(context)!.activity_insight_goal_gap(avgSteps);

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      glass: true,
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, color: AppColors.primary),
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
