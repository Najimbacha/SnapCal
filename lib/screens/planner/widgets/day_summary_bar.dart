import 'package:flutter/material.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';

const _plannerInk = Color(0xFF1C1917);
const _plannerLine = Color(0xFFE8E4DC);
const _plannerGreen = Color(0xFF1A3D2B);

class DaySummaryBar extends StatelessWidget {
  final int totalCalories;
  final int targetCalories;

  const DaySummaryBar({
    super.key,
    required this.totalCalories,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetCalories > 0
        ? (totalCalories / targetCalories).clamp(0.0, 1.0)
        : 0.0;
    final delta = totalCalories - targetCalories;
    final isOver = delta > 50;
    final isUnder = delta < -50;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201F1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : _plannerLine,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$totalCalories',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isOver
                          ? AppColors.error
                          : isDark
                              ? Colors.white
                              : _plannerInk,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.planner_kcal_total(targetCalories),
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOver
                      ? AppColors.error.withValues(alpha: 0.14)
                      : isUnder
                          ? AppColors.warning.withValues(alpha: 0.14)
                          : AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOver
                      ? AppLocalizations.of(context)!.planner_kcal_over(delta.abs())
                      : isUnder
                          ? AppLocalizations.of(context)!.planner_kcal_under(delta.abs())
                          : AppLocalizations.of(context)!.planner_kcal_on_target,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOver
                        ? AppColors.error
                        : isUnder
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              valueColor: AlwaysStoppedAnimation(
                isOver ? AppColors.error : _plannerGreen,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
