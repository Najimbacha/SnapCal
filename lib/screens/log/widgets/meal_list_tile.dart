import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';
import '../../../widgets/ui_blocks.dart';

/// Swipeable tile for displaying a meal in the log with Elite styling
class MealListTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MealListTile({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(LucideIcons.trash2, color: AppColors.error, size: 28),
      ),
      child: AppScaleTap(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Icon(
                    _getMealIcon(meal),
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.foodName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        fontSize: 16,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 10, color: context.textMutedColor),
                        const SizedBox(width: 4),
                        Text(
                          meal.formattedTime,
                          style: AppTypography.labelSmall.copyWith(
                            color: context.textMutedColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (meal.portion != null && meal.portion!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(width: 3, height: 3, decoration: BoxDecoration(color: context.textMutedColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal.portion!,
                              style: AppTypography.labelSmall.copyWith(
                                color: context.textMutedColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
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

              // Metrics Section
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${meal.calories}',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'KCAL',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _EliteMacroPill(color: AppColors.protein, value: '${meal.macros.protein}'),
                      const SizedBox(width: 6),
                      _EliteMacroPill(color: AppColors.carbs, value: '${meal.macros.carbs}'),
                      const SizedBox(width: 6),
                      _EliteMacroPill(color: AppColors.fat, value: '${meal.macros.fat}'),
                    ],
                  ),
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
    if (name.contains('coffee') || name.contains('tea')) return LucideIcons.coffee;
    if (name.contains('egg') || name.contains('breakfast')) return LucideIcons.egg;
    if (name.contains('burger') || name.contains('meat') || name.contains('beef')) return LucideIcons.beef;
    if (name.contains('apple') || name.contains('fruit') || name.contains('salad')) return LucideIcons.apple;
    if (name.contains('bread') || name.contains('toast')) return LucideIcons.croissant;
    if (name.contains('fish') || name.contains('shrimp')) return LucideIcons.fish;
    if (name.contains('cake') || name.contains('cookie') || name.contains('sweet')) return LucideIcons.cake;
    return LucideIcons.utensils;
  }
}

class _EliteMacroPill extends StatelessWidget {
  final Color color;
  final String value;

  const _EliteMacroPill({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Text(
        value,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
