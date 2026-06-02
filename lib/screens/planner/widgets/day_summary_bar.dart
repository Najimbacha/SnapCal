import 'package:flutter/material.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';

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
    final progress =
        targetCalories > 0
            ? (totalCalories / targetCalories).clamp(0.0, 1.0)
            : 0.0;
    final delta = totalCalories - targetCalories;
    final isOver = delta > 50;
    final isUnder = delta < -50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.flame,
                        size: 14,
                        color: context.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.planner_daily_goal,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOver
                            ? AppColors.error.withValues(alpha: 0.14)
                            : isUnder
                            ? AppColors.warning.withValues(alpha: 0.14)
                            : AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOver
                        ? AppLocalizations.of(
                          context,
                        )!.planner_kcal_over(delta.abs())
                        : isUnder
                        ? AppLocalizations.of(
                          context,
                        )!.planner_kcal_under(delta.abs())
                        : AppLocalizations.of(context)!.planner_kcal_on_target,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color:
                          isOver
                              ? AppColors.error
                              : isUnder
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom Gradient Rounded Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 10,
              width: double.infinity,
              color: context.cardBorderColor.withValues(alpha: 0.5),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: LinearGradient(
                          colors:
                              isOver
                                  ? [AppColors.error, Colors.redAccent]
                                  : [
                                    context.primaryColor,
                                    context.primaryColor
                                        .withBlue(230)
                                        .withRed(40),
                                  ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isOver
                                    ? AppColors.error
                                    : context.primaryColor)
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  '$totalCalories',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: isOver ? AppColors.error : context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.planner_kcal_total(targetCalories),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
