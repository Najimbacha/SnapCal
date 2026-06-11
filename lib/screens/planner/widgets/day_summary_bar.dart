import 'package:flutter/material.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

class DaySummaryBar extends StatelessWidget {
  final int totalCalories;
  final int targetCalories;

  const DaySummaryBar({super.key, required this.totalCalories, required this.targetCalories});

  @override
  Widget build(BuildContext context) {
    final progress = targetCalories > 0 ? (totalCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
    final delta = totalCalories - targetCalories;
    final isOver = delta > 50;
    final isUnder = delta < -50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 48, height: 48, child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: context.cardBorderColor.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.error : context.primaryColor),
                )),
                Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('$totalCalories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.textPrimaryColor, height: 1.1)),
                    const SizedBox(width: 4),
                    Text('/ $targetCalories kcal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textMutedColor)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isOver
                      ? AppLocalizations.of(context)!.planner_kcal_over(delta.abs())
                      : isUnder
                          ? AppLocalizations.of(context)!.planner_kcal_under(delta.abs())
                          : AppLocalizations.of(context)!.planner_kcal_on_target,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isOver ? AppColors.error : isUnder ? AppColors.warning : AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
