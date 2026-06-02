import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';
import '../../../widgets/ui_blocks.dart';

/// Tile for displaying a recent meal on the home screen
class RecentMealTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;

  const RecentMealTile({super.key, required this.meal, this.onTap});

  String _getFoodEmoji(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('avocado')) {
      return '🥑';
    }
    if (name.contains('toast')) {
      return '🍞';
    }
    if (name.contains('egg') || name.contains('scramble')) {
      return '🍳';
    }
    if (name.contains('salad') ||
        name.contains('spinach') ||
        name.contains('veggie') ||
        name.contains('vegetable') ||
        name.contains('asparagus')) {
      return '🥗';
    }
    if (name.contains('chicken') || name.contains('poultry')) {
      return '🍗';
    }
    if (name.contains('turkey') ||
        name.contains('wrap') ||
        name.contains('sandwich')) {
      return '🥪';
    }
    if (name.contains('salmon') ||
        name.contains('cod') ||
        name.contains('fish') ||
        name.contains('seafood')) {
      return '🐟';
    }
    if (name.contains('steak') ||
        name.contains('beef') ||
        name.contains('meat') ||
        name.contains('pork')) {
      return '🥩';
    }
    if (name.contains('apple')) {
      return '🍎';
    }
    if (name.contains('banana')) {
      return '🍌';
    }
    if (name.contains('berry') ||
        name.contains('berries') ||
        name.contains('fruit')) {
      return '🍓';
    }
    if (name.contains('hummus') ||
        name.contains('soup') ||
        name.contains('bowl') ||
        name.contains('lentil')) {
      return '🥣';
    }
    if (name.contains('yogurt') ||
        name.contains('cheese') ||
        name.contains('dairy')) {
      return '🥛';
    }
    if (name.contains('rice') ||
        name.contains('quinoa') ||
        name.contains('grain')) {
      return '🍚';
    }
    if (name.contains('coffee') || name.contains('tea')) {
      return '☕';
    }
    if (name.contains('shake') ||
        name.contains('smoothie') ||
        name.contains('protein')) {
      return '🥤';
    }
    if (name.contains('nuts') ||
        name.contains('almond') ||
        name.contains('walnut') ||
        name.contains('peanut')) {
      return '🥜';
    }
    if (name.contains('tomato')) {
      return '🍅';
    }
    if (name.contains('broccoli')) {
      return '🥦';
    }
    return '🍽️';
  }

  Color _getFoodBgColor(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('avocado') ||
        name.contains('salad') ||
        name.contains('spinach') ||
        name.contains('veggie') ||
        name.contains('broccoli') ||
        name.contains('asparagus')) {
      return const Color(0xFFE8F5E9); // Light green
    }
    if (name.contains('apple') ||
        name.contains('berry') ||
        name.contains('berries') ||
        name.contains('tomato') ||
        name.contains('steak') ||
        name.contains('beef')) {
      return const Color(0xFFFFEBEE); // Light red/pink
    }
    if (name.contains('egg') ||
        name.contains('banana') ||
        name.contains('hummus') ||
        name.contains('toast') ||
        name.contains('nuts') ||
        name.contains('almond')) {
      return const Color(0xFFFFF8E1); // Light amber/yellow
    }
    if (name.contains('salmon') ||
        name.contains('chicken') ||
        name.contains('turkey') ||
        name.contains('fish')) {
      return const Color(0xFFFFF3E0); // Light orange/peach
    }
    if (name.contains('water') ||
        name.contains('shake') ||
        name.contains('smoothie') ||
        name.contains('protein')) {
      return const Color(0xFFE3F2FD); // Light blue
    }
    return const Color(0xFFF3E5F5); // Light purple default
  }

  @override
  Widget build(BuildContext context) {
    final macroTotal =
        meal.macros.protein + meal.macros.carbs + meal.macros.fat;

    final imageUri = meal.imageUri;
    final localImageExists =
        imageUri != null && !imageUri.startsWith('http')
            ? File(imageUri).existsSync()
            : false;

    return AppScaleTap(
      onTap: onTap ?? () => context.push('/log'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Meal Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    imageUri != null
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : _getFoodBgColor(meal.foodName),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    imageUri != null
                        ? (imageUri.startsWith('http')
                            ? Image.network(
                              imageUri,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Center(
                                    child: Text(
                                      _getFoodEmoji(meal.foodName),
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                            )
                            : localImageExists
                            ? Image.file(
                              File(imageUri),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Center(
                                    child: Text(
                                      _getFoodEmoji(meal.foodName),
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                            )
                            : Center(
                              child: Text(
                                _getFoodEmoji(meal.foodName),
                                style: const TextStyle(fontSize: 28),
                              ),
                            ))
                        : Center(
                          child: Text(
                            _getFoodEmoji(meal.foodName),
                            style: const TextStyle(fontSize: 28),
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
                      letterSpacing: 0,
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
                          children:
                              macroTotal == 0
                                  ? [
                                    Expanded(
                                      child: Container(
                                        color: context.dividerColor.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                  ]
                                  : [
                                    if (meal.macros.protein > 0)
                                      Expanded(
                                        flex: meal.macros.protein,
                                        child: Container(
                                          color: AppColors.protein,
                                        ),
                                      ),
                                    if (meal.macros.carbs > 0)
                                      Expanded(
                                        flex: meal.macros.carbs,
                                        child: Container(
                                          color: AppColors.carbs,
                                        ),
                                      ),
                                    if (meal.macros.fat > 0)
                                      Expanded(
                                        flex: meal.macros.fat,
                                        child: Container(color: AppColors.fat),
                                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${meal.calories}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    'KCAL',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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
