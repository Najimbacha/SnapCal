import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';
import '../../../widgets/glass_card.dart';

/// Tile for displaying a recent meal on the home screen
class RecentMealTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;

  const RecentMealTile({super.key, required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Food icon placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.utensilsCrossed,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(meal.formattedTime, style: AppTypography.bodySmall),
              ],
            ),
          ),
          // Calorie count
          Text(
            '${meal.calories}',
            style: AppTypography.heading3.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          Text('kcal', style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}
