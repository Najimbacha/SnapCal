import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/ui_blocks.dart';

/// Tile for displaying a recent meal on the home screen
class RecentMealTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;

  const RecentMealTile({super.key, required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppScaleTap(
      onTap: onTap ?? () => context.push('/log'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Meal Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: meal.imageUri != null
                    ? (meal.imageUri!.startsWith('http')
                        ? Image.network(meal.imageUri!, fit: BoxFit.cover)
                        : Image.file(File(meal.imageUri!), fit: BoxFit.cover))
                    : Center(
                        child: Icon(
                          LucideIcons.utensilsCrossed,
                          color: AppColors.primary.withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Meal Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.foodName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 12, color: context.textMutedColor),
                      const SizedBox(width: 4),
                      Text(
                        meal.formattedTime,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.textMutedColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mini Macro Bar
                      Container(
                        width: 60,
                        height: 4,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: context.dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: meal.macros.protein, child: Container(color: AppColors.protein)),
                            Expanded(flex: meal.macros.carbs, child: Container(color: AppColors.carbs)),
                            Expanded(flex: meal.macros.fat, child: Container(color: AppColors.fat)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Calorie Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${meal.calories}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
