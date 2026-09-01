import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';
import 'horizontal_day_calendar.dart' show DailySummary;

/// Surfaces that only the Log screen can show.
///
/// Home is today, at a glance: one calorie ring, one macro row. Repeating that
/// here left Log with nothing of its own. These three read across days instead
/// — the week's shape, how the selected day sits against it, and where the
/// day's calories actually came from — which is what a log is for.

// ── Card shell ───────────────────────────────────────────────────────────────

BoxDecoration _shell(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color:
          isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFEDE9E1),
    ),
  );
}

// ── This week ────────────────────────────────────────────────────────────────

/// Seven days of calories against the goal line.
///
/// A day counts as on target when something was logged and it landed at or
/// under the goal — an untouched day is not a win.
class WeekSummaryCard extends StatelessWidget {
  final List<DailySummary> week;
  final String selectedDate;
  final String Function(int value) format;

  const WeekSummaryCard({
    super.key,
    required this.week,
    required this.selectedDate,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = scheme.onSurface;

    final logged = week.where((d) => d.calories > 0).toList();
    final onTarget =
        week.where((d) => d.calories > 0 && d.calories <= d.calorieGoal).length;
    final average =
        logged.isEmpty
            ? 0
            : (logged.fold<int>(0, (sum, d) => sum + d.calories) /
                    logged.length)
                .round();
    final goal = week.isEmpty ? 0 : week.last.calorieGoal;
    final peak = math.max(
      goal,
      week.fold<int>(0, (m, d) => math.max(m, d.calories)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _shell(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 78,
            child:
                logged.isEmpty
                    ? Center(
                      child: Text(
                        l10n.log_week_no_data,
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.40),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    )
                    : Stack(
                      children: [
                        // The goal, as a line the bars are read against.
                        if (goal > 0 && peak > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: (1 - goal / peak) * 78,
                            child: CustomPaint(
                              painter: _GuidePainter(
                                color: onSurface.withValues(
                                  alpha: isDark ? 0.16 : 0.13,
                                ),
                              ),
                              size: const Size(double.infinity, 1),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < week.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: _Bar(
                                  summary: week[i],
                                  peak: peak,
                                  selected: week[i].dateString == selectedDate,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                l10n.log_week_average(format(average)),
                style: AppTypography.labelSmall.copyWith(
                  color: onSurface.withValues(alpha: isDark ? 0.62 : 0.60),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '·',
                style: TextStyle(color: onSurface.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.log_week_on_target('$onTarget', '${week.length}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: scheme.primary.withValues(alpha: isDark ? 0.9 : 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final DailySummary summary;
  final int peak;
  final bool selected;
  final bool isDark;

  const _Bar({
    required this.summary,
    required this.peak,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over =
        summary.calorieGoal > 0 && summary.calories > summary.calorieGoal;
    final ratio = peak <= 0 ? 0.0 : (summary.calories / peak).clamp(0.0, 1.0);
    // 58 for the bar, 20 for the weekday letter beneath it.
    final barHeight = math.max(ratio * 58, summary.calories > 0 ? 4.0 : 2.0);
    final color =
        summary.calories <= 0
            ? scheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.09)
            : over
            ? AppColors.warning
            : scheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: barHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 1 : 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _weekdayLetter(summary.dateString),
          style: AppTypography.labelSmall.copyWith(
            color: scheme.onSurface.withValues(
              alpha: selected ? 0.75 : (isDark ? 0.35 : 0.38),
            ),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 10,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  String _weekdayLetter(String dateString) {
    final parsed = DateTime.tryParse(dateString);
    if (parsed == null) return '';
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return letters[(parsed.weekday - 1) % 7];
  }
}

class _GuidePainter extends CustomPainter {
  final Color color;

  const _GuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dash, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => old.color != color;
}

// ── Where the calories came from ─────────────────────────────────────────────

enum _Slot { breakfast, lunch, dinner, snack }

/// The day's calories split by meal time.
///
/// Uses the meal's own `mealType` when it has one and falls back to the hour it
/// was logged, so meals saved before slots existed still land somewhere sane.
class MealSplitBar extends StatelessWidget {
  final List<Meal> meals;
  final String Function(int value) format;

  const MealSplitBar({super.key, required this.meals, required this.format});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totals = <_Slot, int>{for (final s in _Slot.values) s: 0};
    for (final meal in meals) {
      totals[_slotOf(meal)] = (totals[_slotOf(meal)] ?? 0) + meal.calories;
    }
    final total = totals.values.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();

    final colors = <_Slot, Color>{
      _Slot.breakfast: AppColors.warning,
      _Slot.lunch: scheme.primary,
      _Slot.dinner: AppColors.violet,
      _Slot.snack: AppColors.sky,
    };
    final labels = <_Slot, String>{
      _Slot.breakfast: l10n.result_meal_breakfast,
      _Slot.lunch: l10n.result_meal_lunch,
      _Slot.dinner: l10n.result_meal_dinner,
      _Slot.snack: l10n.result_meal_snack,
    };
    final present =
        _Slot.values.where((s) => (totals[s] ?? 0) > 0).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _shell(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.log_meal_split,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.60 : 0.55),
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (var i = 0; i < present.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: math.max(totals[present[i]] ?? 0, 1),
                      child: ColoredBox(color: colors[present[i]]!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final slot in present)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors[slot],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${labels[slot]} ${format(totals[slot] ?? 0)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: isDark ? 0.62 : 0.58,
                        ),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  _Slot _slotOf(Meal meal) {
    switch (meal.mealType?.toLowerCase()) {
      case 'breakfast':
        return _Slot.breakfast;
      case 'lunch':
        return _Slot.lunch;
      case 'dinner':
        return _Slot.dinner;
      case 'snack':
        return _Slot.snack;
    }
    final hour = DateTime.fromMillisecondsSinceEpoch(meal.timestamp).hour;
    if (hour < 11) return _Slot.breakfast;
    if (hour < 16) return _Slot.lunch;
    if (hour < 21) return _Slot.dinner;
    return _Slot.snack;
  }
}

// ── One line against the week ────────────────────────────────────────────────

/// How the selected day sits against the seven-day average.
///
/// This is the line that gives the date strip a point: it only says something
/// when you have a week to compare against and something logged on the day.
class DayComparisonLine extends StatelessWidget {
  final int consumed;
  final int average;
  final String Function(int value) format;

  const DayComparisonLine({
    super.key,
    required this.consumed,
    required this.average,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    if (consumed <= 0 || average <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delta = consumed - average;
    // Inside 3% of the average is the same day, not a trend.
    final same = average > 0 && (delta.abs() / average) < 0.03;

    final text =
        same
            ? l10n.log_vs_average_same
            : delta > 0
            ? l10n.log_vs_average_above(format(delta))
            : l10n.log_vs_average_below(format(delta.abs()));

    return Row(
      children: [
        Icon(
          same
              ? Icons.remove_rounded
              : delta > 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          size: 15,
          color: scheme.onSurface.withValues(alpha: isDark ? 0.40 : 0.42),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.52 : 0.50),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
