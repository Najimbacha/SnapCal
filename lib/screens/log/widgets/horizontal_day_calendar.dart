import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/wazn_icons.dart';

class DailySummary {
  final String dateString;
  final int calories;
  final int calorieGoal;
  final int protein;
  final int proteinGoal;
  final int carbs;
  final int carbGoal;
  final int fat;
  final int fatGoal;
  final int waterMl;
  final int waterGoal;
  final int steps;
  final int stepGoal;
  final int mealCount;

  const DailySummary({
    required this.dateString,
    required this.calories,
    required this.calorieGoal,
    required this.protein,
    required this.proteinGoal,
    required this.carbs,
    required this.carbGoal,
    required this.fat,
    required this.fatGoal,
    required this.waterMl,
    required this.waterGoal,
    required this.steps,
    required this.stepGoal,
    required this.mealCount,
  });

  double get calorieProgress => calories / math.max(calorieGoal, 1);
  double get proteinProgress => protein / math.max(proteinGoal, 1);
  double get carbProgress => carbs / math.max(carbGoal, 1);
  double get fatProgress => fat / math.max(fatGoal, 1);
  double get waterProgress => waterMl / math.max(waterGoal, 1);
  double get stepProgress => steps / math.max(stepGoal, 1);
  bool get hasData => mealCount > 0 || waterMl > 0 || steps > 0;
}

class HorizontalDayCalendar extends StatefulWidget {
  final String selectedDate;
  final List<DailySummary> dailySummaries;
  final ValueChanged<String> onDateSelected;
  final ValueChanged<String>? onLockedDateSelected;
  final bool Function(String dateString)? isDateLocked;
  final int daysBack;
  final int daysForward;

  const HorizontalDayCalendar({
    super.key,
    required this.selectedDate,
    required this.dailySummaries,
    required this.onDateSelected,
    this.onLockedDateSelected,
    this.isDateLocked,
    this.daysBack = 13,
    this.daysForward = 0,
  });

  @override
  State<HorizontalDayCalendar> createState() => _HorizontalDayCalendarState();
}

class _HorizontalDayCalendarState extends State<HorizontalDayCalendar> {
  static const double _cellWidth = 50;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant HorizontalDayCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.dailySummaries.length != widget.dailySummaries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_controller.hasClients) return;
    final index = widget.dailySummaries.indexWhere(
      (summary) => summary.dateString == widget.selectedDate,
    );
    if (index < 0) return;
    final viewport = _controller.position.viewportDimension;
    final target = (index * _cellWidth) - (viewport / 2) + (_cellWidth / 2);
    _controller.animateTo(
      target.clamp(0.0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.dailySummaries.indexWhere(
      (summary) => summary.dateString == widget.selectedDate,
    );
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final count = widget.dailySummaries.length;
    return SizedBox(
      height: 80,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: count * _cellWidth,
          child: Stack(
            children: [
              // One highlight for the whole strip, which slides to the day
              // picked and lands with a small overshoot.
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration:
                      reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 520),
                  curve: AppMotion.springCurve,
                  top: 0,
                  bottom: 0,
                  left:
                      (rtl ? count - 1 - selectedIndex : selectedIndex) *
                          _cellWidth +
                      2,
                  width: _cellWidth - 4,
                  child: DecoratedBox(
                    key: const ValueKey('day-highlight'),
                    decoration: BoxDecoration(
                      color:
                          dark
                              ? Colors.white.withValues(alpha: .07)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:
                          dark
                              ? null
                              : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF16181D,
                                  ).withValues(alpha: .07),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final summary in widget.dailySummaries)
                    _dayCell(summary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCell(DailySummary summary) {
    final locked = widget.isDateLocked?.call(summary.dateString) ?? false;
    return _DayCell(
      summary: summary,
      selected: summary.dateString == widget.selectedDate,
      locked: locked,
      onTap: () {
        HapticFeedback.lightImpact();
        if (locked) {
          widget.onLockedDateSelected?.call(summary.dateString);
          return;
        }
        widget.onDateSelected(summary.dateString);
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final DailySummary summary;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _DayCell({
    required this.summary,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.parse(summary.dateString);
    final today = _isToday(date);
    final l10n = AppLocalizations.of(context)!;
    final fullDayLabel = DateFormat.E(l10n.localeName).format(date);
    final dayLabel = fullDayLabel.isEmpty ? '' : fullDayLabel.substring(0, 1);
    final progress = summary.mealCount > 0 ? summary.calorieProgress : 0.0;

    return Semantics(
      button: true,
      selected: selected,
      label:
          today
              ? l10n.common_today
              : DateFormat.yMMMMEEEEd(l10n.localeName).format(date),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 50,
          child: Column(
            children: [
              const SizedBox(height: 7),
              Text(
                dayLabel,
                style: AppTypography.labelSmall.copyWith(
                  color:
                      selected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.72,
                          ),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              // The day's calories as a ring around its date, filling from
              // empty when the strip first shows. Amber once over the goal.
              _DayRing(
                progress: locked ? 0 : progress,
                over: !locked && summary.mealCount > 0 && progress > 1,
                pop: selected,
                child: Text(
                  '${date.day}',
                  style: AppTypography.titleSmall.copyWith(
                    color:
                        locked
                            ? colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.42,
                            )
                            : colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 13,
                child:
                    today
                        ? Text(
                          l10n.common_today,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        )
                        : locked
                        ? Icon(
                          WaznIcons.lock,
                          size: 9,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.42,
                          ),
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// A progress ring around a date that fills to [progress] and gives a small
/// bounce when its day is picked.
class _DayRing extends StatefulWidget {
  const _DayRing({
    required this.progress,
    required this.over,
    required this.pop,
    required this.child,
  });

  final double progress;
  final bool over;
  final bool pop;
  final Widget child;

  @override
  State<_DayRing> createState() => _DayRingState();
}

class _DayRingState extends State<_DayRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  @override
  void didUpdateWidget(_DayRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pop && !oldWidget.pop && !AppMotion.reduceMotion(context)) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: .09);
    final color = widget.over ? AppColors.warning : AppColors.primary;
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final v = _bounce.value;
        final scale =
            v >= 1
                ? 1.0
                : TweenSequence<double>([
                  TweenSequenceItem(
                    tween: Tween(begin: 1, end: 1.14),
                    weight: 35,
                  ),
                  TweenSequenceItem(
                    tween: Tween(begin: 1.14, end: .97),
                    weight: 30,
                  ),
                  TweenSequenceItem(
                    tween: Tween(begin: .97, end: 1),
                    weight: 35,
                  ),
                ]).transform(v);
        return Transform.scale(scale: scale, child: child);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
        duration: AppMotion.maybeZero(context, AppMotion.count),
        curve: Curves.easeOutCubic,
        builder:
            (context, fill, child) => CustomPaint(
              painter: _RingPainter(fill: fill, color: color, track: track),
              child: child,
            ),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fill,
    required this.color,
    required this.track,
  });

  final double fill;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (fill <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fill,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fill != fill || old.color != color || old.track != track;
}
