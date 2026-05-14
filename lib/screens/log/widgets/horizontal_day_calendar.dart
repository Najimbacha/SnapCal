import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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
  final int daysBack;
  final int daysForward;

  const HorizontalDayCalendar({
    super.key,
    required this.selectedDate,
    required this.dailySummaries,
    required this.onDateSelected,
    this.daysBack = 13,
    this.daysForward = 0,
  });

  @override
  State<HorizontalDayCalendar> createState() => _HorizontalDayCalendarState();
}

class _HorizontalDayCalendarState extends State<HorizontalDayCalendar> {
  static const double _cellWidth = 58;
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
    return SizedBox(
      height: 88,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: widget.dailySummaries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final summary = widget.dailySummaries[index];
          return _DayCell(
            summary: summary,
            selected: summary.dateString == widget.selectedDate,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onDateSelected(summary.dateString);
            },
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DailySummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _DayCell({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor;
    final date = DateTime.parse(summary.dateString);
    final today = _isToday(date);
    final dotAlpha = selected ? 1.0 : 0.72;

    return Semantics(
      button: true,
      selected: selected,
      label: today ? 'Today' : '${_weekdayLabel(date)}, ${date.day}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 58,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.primary.withValues(alpha: 0.11)
                    : colorScheme.surfaceContainerHighest.withValues(
                      alpha:
                          Theme.of(context).brightness == Brightness.dark
                              ? 0.14
                              : 0.34,
                    ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? AppColors.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.18),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                today ? 'Today' : _weekdayLabel(date),
                style: AppTypography.labelSmall.copyWith(
                  color:
                      selected
                          ? AppColors.primary
                          : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: today ? 9 : 10,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value:
                          summary.hasData
                              ? summary.calorieProgress.clamp(0.0, 1.0)
                              : 0,
                      strokeWidth: 3.0,
                      backgroundColor: colorScheme.outlineVariant.withValues(
                        alpha: 0.16,
                      ),
                      color: statusColor,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '${date.day}',
                        style: AppTypography.labelLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TinyIndicator(
                    color: AppColors.protein,
                    active: summary.proteinProgress >= 0.75,
                    alpha: dotAlpha,
                  ),
                  _TinyIndicator(
                    color: AppColors.carbs,
                    active: summary.carbProgress >= 0.5,
                    alpha: dotAlpha,
                  ),
                  _TinyIndicator(
                    color: AppColors.sky,
                    active: summary.waterProgress >= 1.0,
                    alpha: dotAlpha,
                  ),
                  _TinyIndicator(
                    color: AppColors.primary,
                    active: summary.stepProgress >= 1.0,
                    alpha: dotAlpha,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    if (!summary.hasData) return AppColors.lightTextSecondary;
    final ratio = summary.calorieProgress;
    if (ratio >= 0.75 && ratio <= 1.08) return AppColors.primary;
    if (ratio <= 1.18) return AppColors.amber;
    return AppColors.error;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }
}

class _TinyIndicator extends StatelessWidget {
  final Color color;
  final bool active;
  final double alpha;

  const _TinyIndicator({
    required this.color,
    required this.active,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? alpha : 0.16),
        shape: BoxShape.circle,
      ),
    );
  }
}
