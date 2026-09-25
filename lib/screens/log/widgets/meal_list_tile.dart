import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/wazn_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';

class MealListTile extends StatelessWidget {
  const MealListTile({
    super.key,
    required this.meal,
    required this.isPro,
    required this.onTap,
    required this.onDelete,
    this.showTime = true,
    this.showDivider = false,
  });

  final Meal meal;
  final bool isPro;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showTime;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsetsDirectional.only(end: 18),
        color: AppColors.error.withValues(alpha: 0.08),
        child: const Icon(WaznIcons.delete, color: AppColors.error, size: 20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border:
                  showDivider
                      ? Border(
                        bottom: BorderSide(
                          color: context.dividerColor.withValues(alpha: 0.3),
                        ),
                      )
                      : null,
            ),
            child: Row(
              children: [
                _MealThumbnail(meal: meal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        meal.foodName,
                        style: AppTypography.titleMedium.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_detailText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _detailText,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.textMutedColor,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${meal.calories}',
                        style: AppTypography.titleMedium.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      TextSpan(
                        text: ' ${l10n.settings_kcal_unit}',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textMutedColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                ),
                const SizedBox(width: 8),
                Icon(
                  WaznIcons.chevronRight,
                  size: 16,
                  color: context.textMutedColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _detailText {
    final details = <String>[];
    if (showTime) details.add(meal.formattedTime);
    final portion = meal.portion?.trim();
    if (portion != null && portion.isNotEmpty) details.add(portion);
    if (details.isEmpty && isPro) {
      details.add(
        'P ${meal.macros.protein}g  C ${meal.macros.carbs}g  F ${meal.macros.fat}g',
      );
    }
    return details.join('  ·  ');
  }
}

class _MealThumbnail extends StatelessWidget {
  const _MealThumbnail({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final imageUri = meal.imageUri;
    final isNetwork = imageUri?.startsWith('http') ?? false;
    final localExists =
        imageUri != null && !isNetwork && File(imageUri).existsSync();

    Widget fallback() => Container(
      color: _fallbackColor(meal.foodName),
      alignment: Alignment.center,
      child: Icon(
        _foodIcon(meal.foodName),
        color: context.primaryColor,
        size: 22,
      ),
    );

    Widget child;
    if (imageUri == null) {
      child = fallback();
    } else if (isNetwork) {
      child = Image.network(
        imageUri,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (localExists) {
      child = Image.file(
        File(imageUri),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else {
      child = fallback();
    }

    return SizedBox(
      width: 46,
      height: 46,
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }

  Color _fallbackColor(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('salad') ||
        name.contains('avocado') ||
        name.contains('vegetable')) {
      return const Color(0xFFEAF4ED);
    }
    if (name.contains('chicken') ||
        name.contains('fish') ||
        name.contains('meat')) {
      return const Color(0xFFFFF3E6);
    }
    if (name.contains('yogurt') || name.contains('milk')) {
      return const Color(0xFFEDF3F8);
    }
    return const Color(0xFFF1F2EE);
  }

  IconData _foodIcon(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('coffee') || name.contains('tea')) {
      return WaznIcons.coffee;
    }
    if (name.contains('egg')) return WaznIcons.egg;
    if (name.contains('apple') ||
        name.contains('fruit') ||
        name.contains('salad')) {
      return WaznIcons.snack;
    }
    if (name.contains('bread') || name.contains('toast')) {
      return WaznIcons.croissant;
    }
    if (name.contains('fish') || name.contains('shrimp')) {
      return WaznIcons.fish;
    }
    return WaznIcons.meal;
  }
}
