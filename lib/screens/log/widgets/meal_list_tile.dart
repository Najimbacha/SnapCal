import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';

/// Swipeable tile for displaying a meal in the log with Elite styling
class MealListTile extends StatelessWidget {
  final Meal meal;
  final bool isPro;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MealListTile({
    super.key,
    required this.meal,
    required this.isPro,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: AppColors.error, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getMealIcon(meal),
                  color: context.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            meal.foodName,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: context.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 9, color: context.textMutedColor),
                        const SizedBox(width: 4),
                        Text(
                          meal.formattedTime,
                          style: AppTypography.labelSmall.copyWith(
                            color: context.textMutedColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                        if (meal.portion != null && meal.portion!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 2, height: 2,
                            decoration: BoxDecoration(
                              color: context.textMutedColor.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              meal.portion!,
                              style: AppTypography.labelSmall.copyWith(
                                color: context.textMutedColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${meal.calories}',
                        style: AppTypography.titleMedium.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        l10n.settings_kcal_unit,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.primaryColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  if (isPro) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _EliteMacroPill(color: AppColors.protein, value: '${meal.macros.protein}'),
                        const SizedBox(width: 4),
                        _EliteMacroPill(color: AppColors.carbs, value: '${meal.macros.carbs}'),
                        const SizedBox(width: 4),
                        _EliteMacroPill(color: AppColors.fat, value: '${meal.macros.fat}'),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealIcon(Meal meal) {
    final name = meal.foodName.toLowerCase();
    if (name.contains('coffee') || name.contains('tea')) {
      return LucideIcons.coffee;
    }
    if (name.contains('egg') || name.contains('breakfast')) {
      return LucideIcons.egg;
    }
    if (name.contains('burger') ||
        name.contains('meat') ||
        name.contains('beef')) {
      return LucideIcons.beef;
    }
    if (name.contains('apple') ||
        name.contains('fruit') ||
        name.contains('salad')) {
      return LucideIcons.apple;
    }
    if (name.contains('bread') || name.contains('toast')) {
      return LucideIcons.croissant;
    }
    if (name.contains('fish') || name.contains('shrimp')) {
      return LucideIcons.fish;
    }
    if (name.contains('cake') ||
        name.contains('cookie') ||
        name.contains('sweet')) {
      return LucideIcons.cake;
    }
    return LucideIcons.utensils;
  }
}

class _EliteMacroPill extends StatelessWidget {
  final Color color;
  final String value;

  const _EliteMacroPill({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: AppTypography.labelSmall.copyWith(
        color: color.withValues(alpha: 0.7),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
