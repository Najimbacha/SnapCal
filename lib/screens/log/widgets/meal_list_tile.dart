import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';


/// Swipeable tile for displaying a meal in the log
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

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(LucideIcons.trash2, color: AppColors.error, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getMealIcon(meal),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.foodName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          meal.formattedTime,
                          style: AppTypography.labelSmall.copyWith(
                            color: context.textMutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (meal.portion != null && meal.portion!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.textMutedColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal.portion!,
                              style: AppTypography.labelSmall.copyWith(
                                color: context.textMutedColor,
                                fontStyle: FontStyle.italic,
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

              // Macro Pills & Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal.calories}',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _CompactMacro(
                        color: AppColors.protein,
                        value: '${meal.macros.protein}g',
                      ),
                      const SizedBox(width: 4),
                      _CompactMacro(
                        color: AppColors.carbs,
                        value: '${meal.macros.carbs}g',
                      ),
                      const SizedBox(width: 4),
                      _CompactMacro(
                        color: AppColors.fat,
                        value: '${meal.macros.fat}g',
                      ),
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

class _CompactMacro extends StatelessWidget {
  final Color color;
  final String value;

  const _CompactMacro({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
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
