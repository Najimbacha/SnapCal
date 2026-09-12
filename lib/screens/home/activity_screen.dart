import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart' as ap;
import '../../providers/settings_provider.dart';
import '../../screens/settings/widgets/settings_kit.dart';
import '../../widgets/activity_ring_gauge.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/premium_prompt_card.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/activity_health_connect_sheet.dart';

/// The activity screen, on the app's own paper.
///
/// The old one sat on an animated mesh of green blobs used nowhere else, and
/// its Pro half was scenery: a bar chart of a week of zeros, a hardcoded "0"
/// step streak and activity score, and an insight that called today's steps a
/// weekly average. Everything here comes from Health Connect or is not shown.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = ref.watch(ap.activityProvider).valueOrNull;
    final connected = summary?.healthConnected ?? false;
    final isPro = ref.watch(effectiveIsProProvider);

    return AppPageScaffold(
      title: l10n.home_metric_activity,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      backgroundColor: isDark ? Colors.black : const Color(0xFFFBFCFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ConnectionCard(),
          const SizedBox(height: 16),
          if (!connected)
            const _NotConnectedCard()
          else ...[
            const _TodayCard(),
            const SizedBox(height: 12),
            const _TodayMetrics(),
            const SizedBox(height: 28),
            if (isPro) const _WeekSection() else const _WeekTeaser(),
          ],
        ],
      ),
    );
  }
}

/// Health Connect, its state, and the two things you can do about it.
class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(ap.activityProvider);
    final connected = async.valueOrNull?.healthConnected ?? false;
    final busy = async.isLoading;

    return AppSectionCard(
      glass: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => showActivityHealthConnectSheet(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (connected ? AppColors.primary : AppColors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              connected ? LucideIcons.footprints : LucideIcons.alertCircle,
              size: 19,
              color: connected ? AppColors.primary : AppColors.warning,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Health Connect',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  connected
                      ? l10n.settings_status_connected
                      : l10n.settings_status_not_connected,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              tooltip: l10n.home_metric_activity_sync,
              onPressed: () async {
                await ref.read(ap.activityProvider.notifier).authorize();
                ref.invalidate(ap.activityProvider);
              },
              icon: Icon(
                LucideIcons.refreshCw,
                size: 18,
                color: context.textSecondaryColor,
              ),
            ),
          Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: context.textMutedColor,
          ),
        ],
      ),
    );
  }
}

/// Nothing to show until Health Connect is connected, so this says so and
/// offers the one action worth taking.
class _NotConnectedCard extends ConsumerWidget {
  const _NotConnectedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppSectionCard(
      glass: true,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: AppEmptyState(
        icon: LucideIcons.footprints,
        title: l10n.activity_not_connected_title,
        body: l10n.activity_not_connected_body,
        actionLabel: l10n.activity_connect,
        onAction: () async {
          await ref.read(ap.activityProvider.notifier).authorize();
          ref.invalidate(ap.activityProvider);
        },
      ),
    );
  }
}

/// Today: the ring, and the goal it is measured against.
class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final steps = ref.watch(ap.activityProvider).valueOrNull?.steps ?? 0;
    final goal =
        ref.watch(ap.stepGoalProvider).valueOrNull ??
        ActivityRepository.defaultStepGoal;
    final progress = (steps / math.max(goal, 1)).clamp(0.0, 1.0);

    return AppSectionCard(
      glass: true,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Column(
        children: [
          ActivityRingGauge(
            progress: progress,
            steps: steps,
            centerSubLabel: l10n.activity_steps_today_label,
            size: 230,
          ),
          const SizedBox(height: 18),
          // The goal is editable where it is shown; it was a line of text
          // fixed at 10,000 with no way to change it.
          _GoalPill(goal: goal),
        ],
      ),
    );
  }
}

class _GoalPill extends ConsumerWidget {
  const _GoalPill({required this.goal});

  final int goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap:
            () => showSettingsNumberDialog(
              context,
              title: l10n.settings_step_goal,
              currentValue: goal,
              unit: 'steps',
              min: 2000,
              max: 30000,
              step: 500,
              onSave: (value) => ap.setStepGoal(ref, value),
            ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.activity_steps_goal(goal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(LucideIcons.pencil, size: 13, color: context.textMutedColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Steps and calories, in the tiles the reports and diary use.
class _TodayMetrics extends ConsumerWidget {
  const _TodayMetrics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(ap.activityProvider).valueOrNull;
    final goal =
        ref.watch(ap.stepGoalProvider).valueOrNull ??
        ActivityRepository.defaultStepGoal;
    final steps = summary?.steps ?? 0;
    final calories = summary?.activeCalories.round() ?? 0;
    final estimated = summary?.activeCaloriesEstimated ?? true;
    final percent = ((steps / math.max(goal, 1)) * 100).round();
    final number = NumberFormat.decimalPattern(l10n.localeName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: l10n.activity_calories_label,
                value: '$calories',
                hint:
                    estimated
                        ? l10n.activity_calories_estimated_hint
                        : l10n.activity_calories_measured_hint,
                accent: AppColors.fat,
                icon: LucideIcons.flame,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: l10n.activity_goal_label,
                value: '$percent%',
                hint: number.format(goal),
                accent: AppColors.primary,
                icon: LucideIcons.target,
              ),
            ),
          ],
        ),
        if (estimated) ...[
          const SizedBox(height: 10),
          // The caveat, once and quietly, where the number it qualifies is --
          // not a yellow warning box shouting it on every visit.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.activity_calorie_estimate_disclaimer,
              style: AppTypography.labelSmall.copyWith(
                color: context.textMutedColor,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The week, for Pro. Every figure is read from Health Connect.
class _WeekSection extends ConsumerWidget {
  const _WeekSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final weekAsync = ref.watch(ap.activityWeekProvider);
    final goal =
        ref.watch(ap.stepGoalProvider).valueOrNull ??
        ActivityRepository.defaultStepGoal;
    final week = weekAsync.valueOrNull ?? const <DailySteps>[];
    final streak = ref.watch(ap.stepStreakProvider).valueOrNull ?? 0;

    if (weekAsync.isLoading && week.isEmpty) {
      return const AppSectionSkeleton(rows: 3);
    }

    final number = NumberFormat.decimalPattern(l10n.localeName);
    final totals = week.map((day) => day.steps).toList();
    final average =
        totals.isEmpty
            ? 0
            : (totals.reduce((a, b) => a + b) / totals.length).round();
    final best = totals.isEmpty ? 0 : totals.reduce(math.max);
    final daysMet = totals.where((steps) => steps >= goal).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title: l10n.activity_this_week),
        const SizedBox(height: 12),
        AppSectionCard(
          glass: true,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Column(
            children: [
              SizedBox(height: 170, child: _WeekChart(week: week, goal: goal)),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: context.dividerColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _WeekStat(
                    label: l10n.activity_avg_per_day,
                    value: number.format(average),
                  ),
                  _WeekStat(
                    label: l10n.activity_best_day,
                    value: number.format(best),
                  ),
                  _WeekStat(
                    label: l10n.activity_days_goal_met,
                    value: '$daysMet/7',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: l10n.activity_step_streak,
                value: '$streak',
                hint: l10n.common_days,
                accent: AppColors.carbs,
                icon: LucideIcons.flame,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _WorkoutTile()),
          ],
        ),
        const SizedBox(height: 12),
        _InsightCard(averageSteps: average, goal: goal),
      ],
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.week, required this.goal});

  final List<DailySteps> week;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final maxSteps = week.fold<int>(
      0,
      (best, day) => math.max(best, day.steps),
    );
    final maxY = math.max(goal, maxSteps) * 1.15;
    final today = DateTime.now();

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor:
                (_) => Theme.of(context).colorScheme.surfaceContainerHigh,
            getTooltipItem:
                (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  '${rod.toY.round()}',
                  AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          ),
        ),
        // The goal, drawn once, so a bar means something without a legend.
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goal.toDouble(),
              color: AppColors.primary.withValues(alpha: 0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
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
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= week.length) {
                  return const SizedBox.shrink();
                }
                final date = week[index].date;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _weekdayInitial(context, date),
                    style: AppTypography.labelSmall.copyWith(
                      color:
                          isToday
                              ? context.textPrimaryColor
                              : context.textMutedColor,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < week.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: week[i].steps.toDouble(),
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  color:
                      week[i].steps >= goal
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.35),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// The first letter of the weekday in the app's language, not a hardcoded
  /// English "M T W T F S S".
  static String _weekdayInitial(BuildContext context, DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    final name = localizations.narrowWeekdays[date.weekday % 7];
    return name;
  }
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workouts = ref.watch(ap.activityProvider).valueOrNull?.workouts ?? [];
    final workout = workouts.isEmpty ? null : workouts.first;

    return MetricTile(
      label: l10n.activity_workout_calories,
      value: workout == null ? '–' : '${workout.calories}',
      hint:
          workout == null
              ? l10n.activity_no_workout_today
              : l10n.activity_workout_minutes(workout.duration.inMinutes),
      accent: AppColors.violet,
      icon: LucideIcons.dumbbell,
    );
  }
}

/// One line about the week, from the week's own average.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.averageSteps, required this.goal});

  final int averageSteps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final met = averageSteps >= goal;
    return AppSectionCard(
      glass: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            met ? LucideIcons.sparkles : LucideIcons.trendingUp,
            size: 18,
            color: met ? AppColors.primary : AppColors.sky,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              met
                  ? l10n.activity_insight_goal_met(averageSteps)
                  : l10n.activity_insight_goal_gap(averageSteps),
              style: AppTypography.bodySmall.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What Pro adds here, named rather than mocked up. The old screen showed a
/// chart of zeros to free users and called it a preview.
class _WeekTeaser extends ConsumerWidget {
  const _WeekTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PremiumPromptCard(
      title: l10n.activity_unlock_pro_title,
      subtitle: l10n.activity_unlock_pro_subtitle,
      buttonText: l10n.home_go_pro,
      icon: LucideIcons.lineChart,
      style: PremiumPromptStyle.glass,
      onTap:
          () => PremiumConversionService().openPaywall(
            context,
            PaywallEntryPoint.homeAha,
            featureName: 'activity_insights',
          ),
    );
  }
}
