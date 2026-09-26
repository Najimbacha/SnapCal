import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../../widgets/wazn_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/activity_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart' as ap;
import '../../providers/settings_provider.dart';
import '../../screens/settings/widgets/settings_kit.dart';
import '../../widgets/activity_ring_gauge.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/motion/visible_gate.dart';
import '../../widgets/ui_blocks.dart';

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
          if (!connected)
            const _NotConnectedCard()
          else ...[
            const Reveal(offset: Offset(0, 20), child: _TodayCard()),
            const SizedBox(height: 12),
            const _TodayMetrics(),
            const SizedBox(height: 28),
            if (isPro)
              const Reveal(
                delay: Duration(milliseconds: 900),
                offset: Offset(0, 20),
                child: _WeekSection(),
              ),
          ],
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
        icon: WaznIcons.steps,
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
          Reveal(
            delay: const Duration(milliseconds: 700),
            offset: const Offset(0, 10),
            child: _GoalPill(goal: goal),
          ),
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
                // A new goal rolls into place.
                child: _Counting(
                  value: goal,
                  initial: goal,
                  builder:
                      (value) => Text(
                        l10n.activity_steps_goal(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: context.textSecondaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(WaznIcons.edit, size: 13, color: context.textMutedColor),
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
              child: Reveal(
                delay: const Duration(milliseconds: 450),
                offset: const Offset(0, 20),
                child: _Counting(
                  value: calories,
                  delay: const Duration(milliseconds: 450),
                  builder:
                      (value) => MetricTile(
                        label: l10n.activity_calories_label,
                        value: '$value',
                        hint:
                            estimated
                                ? l10n.activity_calories_estimated_hint
                                : l10n.activity_calories_measured_hint,
                        accent: AppColors.fat,
                        icon: WaznIcons.calories,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Reveal(
                delay: const Duration(milliseconds: 530),
                offset: const Offset(0, 20),
                child: _Counting(
                  value: percent,
                  delay: const Duration(milliseconds: 530),
                  builder:
                      (value) => _Counting(
                        value: goal,
                        initial: goal,
                        builder:
                            (shownGoal) => MetricTile(
                              label: l10n.activity_goal_label,
                              value: '$value%',
                              hint: number.format(shownGoal),
                              accent: AppColors.primary,
                              icon: WaznIcons.goal,
                            ),
                      ),
                ),
              ),
            ),
          ],
        ),
        if (estimated) ...[
          const SizedBox(height: 10),
          // The caveat, once and quietly, where the number it qualifies is --
          // not a yellow warning box shouting it on every visit.
          Reveal(
            delay: const Duration(milliseconds: 800),
            offset: const Offset(0, 8),
            child: Padding(
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
              SizedBox(height: 170, child: _WeekBars(week: week, goal: goal)),
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
                    value: average,
                    format: number.format,
                  ),
                  _WeekStat(
                    label: l10n.activity_best_day,
                    value: best,
                    format: number.format,
                  ),
                  _WeekStat(
                    label: l10n.activity_days_goal_met,
                    value: daysMet,
                    format: (value) => '$value/7',
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
              child: _Counting(
                value: streak,
                initial: streak,
                builder:
                    (streak) => MetricTile(
                      label: l10n.activity_step_streak,
                      value: '$streak',
                      hint: l10n.common_days,
                      accent: AppColors.carbs,
                      icon: WaznIcons.calories,
                    ),
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

/// The week's steps as seven bars under a dashed goal line.
///
/// The line draws across and the bars grow one day at a time; days that
/// reach the goal turn full green as they get there. A new goal slides the
/// line and recolours the bars. Tap a bar to see its steps.
class _WeekBars extends StatefulWidget {
  const _WeekBars({required this.week, required this.goal});

  final List<DailySteps> week;
  final int goal;

  @override
  State<_WeekBars> createState() => _WeekBarsState();
}

class _WeekBarsState extends State<_WeekBars>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  int? _picked;

  @override
  void initState() {
    super.initState();
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _grow.value = 1;
      } else {
        _grow.forward();
      }
    });
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  /// Day [i]'s share of the growth, each starting a little after the last.
  double _barT(int i) {
    final start = .12 + i * .07;
    return Curves.easeOutBack.transform(
      ((_grow.value - start) / .45).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final week = widget.week;
    final goal = widget.goal;
    final maxSteps = week.fold<int>(
      0,
      (best, day) => math.max(best, day.steps),
    );
    final maxY = math.max(goal, maxSteps) * 1.15;
    final today = DateTime.now();
    final number = NumberFormat.decimalPattern(
      AppLocalizations.of(context)!.localeName,
    );
    final slide = AppMotion.maybeZero(
      context,
      const Duration(milliseconds: 700),
    );

    return AnimatedBuilder(
      animation: _grow,
      builder: (context, _) {
        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The goal line, drawn across and gliding to a new goal.
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: goal / maxY),
                        duration: slide,
                        curve: AppMotion.springCurve,
                        builder:
                            (context, share, _) => Positioned(
                              left: 0,
                              right: 0,
                              bottom: height * share,
                              child: CustomPaint(
                                key: const ValueKey('week-goal-line'),
                                size: const Size.fromHeight(1.5),
                                painter: _DashedLine(
                                  color: AppColors.primary.withValues(
                                    alpha: .4,
                                  ),
                                  drawn: Curves.easeInOut.transform(
                                    (_grow.value / .45).clamp(0.0, 1.0),
                                  ),
                                ),
                              ),
                            ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < week.length; i++)
                            Expanded(
                              child: _bar(
                                context,
                                index: i,
                                height: height * week[i].steps / maxY,
                                met: week[i].steps >= goal,
                                label: number.format(week[i].steps),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final day in week)
                  Expanded(
                    child: Text(
                      MaterialLocalizations.of(
                        context,
                      ).narrowWeekdays[day.date.weekday % 7],
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color:
                            _sameDay(day.date, today)
                                ? context.textPrimaryColor
                                : context.textMutedColor,
                        fontWeight:
                            _sameDay(day.date, today)
                                ? FontWeight.w900
                                : FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bar(
    BuildContext context, {
    required int index,
    required double height,
    required bool met,
    required String label,
  }) {
    final t = _barT(index);
    // A bar turns full green once it has grown past the goal.
    final lit = met && t >= .75;
    final picked = _picked == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _picked = picked ? null : index),
      child: Semantics(
        button: true,
        label: label,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedOpacity(
              opacity: _picked == null || picked ? 1 : .45,
              duration: AppMotion.standard,
              child: SizedBox(
                width: 16,
                height: math.max(0.0, height * t),
                child: AnimatedContainer(
                  key: ValueKey('week-bar-$index'),
                  duration: AppMotion.maybeZero(
                    context,
                    const Duration(milliseconds: 380),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color:
                        lit
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            if (picked)
              Positioned(
                bottom: height * t + 8,
                child: Reveal(
                  key: ValueKey('week-bubble-$index'),
                  duration: const Duration(milliseconds: 380),
                  offset: const Offset(0, 6),
                  scale: .7,
                  curve: AppMotion.springCurve,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.textPrimaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// A dashed horizontal line, drawn from the start edge [drawn] of the way.
class _DashedLine extends CustomPainter {
  const _DashedLine({required this.color, required this.drawn});

  final Color color;
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;
    final end = size.width * drawn;
    for (var x = 0.0; x < end; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, end), 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) =>
      old.color != color || old.drawn != drawn;
}

/// Shows [value] counting to it: from [initial] (zero by default) after
/// [delay] the first time, and from the old value whenever it changes.
class _Counting extends StatefulWidget {
  const _Counting({
    required this.value,
    required this.builder,
    this.initial = 0,
    this.delay = Duration.zero,
  });

  final int value;
  final int initial;
  final Duration delay;
  final Widget Function(int value) builder;

  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  bool _opening = true;

  @override
  Widget build(BuildContext context) {
    final calm = AppMotion.reduceMotion(context);
    final value = widget.value.toDouble();
    final wait = _opening ? widget.delay : Duration.zero;
    final total = wait + AppMotion.count;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: calm ? value : widget.initial.toDouble(), end: value),
      duration: calm ? Duration.zero : total,
      curve: Interval(
        wait.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      onEnd: () {
        if (_opening && mounted) setState(() => _opening = false);
      },
      builder: (context, shown, _) => widget.builder(shown.round()),
    );
  }
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({
    required this.label,
    required this.value,
    required this.format,
  });

  final String label;
  final int value;
  final String Function(int value) format;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _Counting(
            value: value,
            builder:
                (shown) => Text(
                  format(shown),
                  style: AppTypography.titleMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
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
      icon: WaznIcons.exercise,
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
            met ? WaznIcons.ai : WaznIcons.trend,
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
