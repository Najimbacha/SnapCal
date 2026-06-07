import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

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
    return SizedBox(
      height: 56,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: widget.dailySummaries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 2),
        itemBuilder: (context, index) {
          final summary = widget.dailySummaries[index];
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
        },
      ),
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
    final dayLabel = today ? l10n.common_today : DateFormat.E(l10n.localeName).format(date);

    return Semantics(
      button: true,
      selected: selected,
      label: today ? l10n.common_today : DateFormat.yMMMMEEEEd(l10n.localeName).format(date),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: AppTypography.titleSmall.copyWith(
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 15,
                ),
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
