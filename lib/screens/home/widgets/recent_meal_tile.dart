import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';
import '../../../widgets/glass_container.dart';

/// Tile for displaying a recent meal on the home screen
class RecentMealTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;

  const RecentMealTile({super.key, required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: 24,
        backgroundColor: context.surfaceColor.withValues(alpha: 0.4),
        child: Row(
          children: [
            // Food icon container with glass effect
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6B4DFF).withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                LucideIcons.utensilsCrossed,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.foodName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: context.textMutedColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meal.formattedTime,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Calorie count
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
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'kcal',
                      style: AppTypography.labelSmall.copyWith(
                        color: context.textMutedColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Tiny macro indicators
                Row(
                  children: [
                    _miniMacro(AppColors.protein),
                    const SizedBox(width: 4),
                    _miniMacro(AppColors.carbs),
                    const SizedBox(width: 4),
                    _miniMacro(AppColors.fat),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMacro(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
