import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/app_icon.dart';

/// A compact horizontal row of four progress rings showing today's macro
/// status at a glance. Replaces the bulky metrics card in the original design.
class MetricProgressStrip extends StatelessWidget {
  final int calories;
  final int targetCalories;
  final int protein;
  final int targetProtein;
  final int carbs;
  final int targetCarbs;
  final int fat;
  final int targetFat;

  const MetricProgressStrip({
    super.key,
    required this.calories,
    required this.targetCalories,
    required this.protein,
    required this.targetProtein,
    required this.carbs,
    required this.targetCarbs,
    required this.fat,
    required this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MetricItem>[
      _MetricItem(
        icon: AppSymbols.flame,
        label: 'Cal',
        value: calories,
        target: targetCalories,
        color: AppColors.calories,
      ),
      _MetricItem(
        icon: AppSymbols.dumbbell,
        label: 'Protein',
        value: protein,
        target: targetProtein,
        color: AppColors.protein,
      ),
      _MetricItem(
        icon: AppSymbols.wheat,
        label: 'Carbs',
        value: carbs,
        target: targetCarbs,
        color: AppColors.carbs,
      ),
      _MetricItem(
        icon: AppSymbols.droplet,
        label: 'Fat',
        value: fat,
        target: targetFat,
        color: AppColors.fat,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _MetricCell(item: items[i]),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _MetricItem {
  final IconData icon;
  final String label;
  final int value;
  final int target;
  final Color color;

  _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });
}

class _MetricCell extends StatelessWidget {
  final _MetricItem item;
  const _MetricCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final progress = item.target > 0
        ? (item.value / item.target).clamp(0.0, 1.0)
        : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(track),
                  ),
                ),
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(item.color),
                      );
                    },
                  ),
                ),
                Icon(
                  item.icon,
                  size: 12,
                  color: item.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.value}',
            style: AppTypography.titleSmall.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '/${item.target}',
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w500,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
