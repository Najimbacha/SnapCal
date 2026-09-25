import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/wazn_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';

class MealListTile extends StatefulWidget {
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
  State<MealListTile> createState() => _MealListTileState();
}

class _MealListTileState extends State<MealListTile> {
  /// How far the row has been swiped, 0 to 1 of the way to deleting.
  final _swipe = ValueNotifier<double>(0);
  bool _armed = false;

  Meal get meal => widget.meal;

  @override
  void dispose() {
    _swipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onTap = widget.onTap;
    final showDivider = widget.showDivider;
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      onUpdate: (details) {
        _swipe.value = (details.progress / 0.4).clamp(0.0, 1.0);
        // A tick as the swipe goes far enough to delete, and back.
        if (details.reached != _armed) {
          _armed = details.reached;
          HapticFeedback.selectionClick();
        }
      },
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        widget.onDelete();
      },
      // The bin grows and the red deepens as the row is pulled away.
      background: ValueListenableBuilder<double>(
        valueListenable: _swipe,
        builder:
            (context, pull, _) => Container(
              alignment: AlignmentDirectional.centerEnd,
              padding: const EdgeInsetsDirectional.only(end: 18),
              color: AppColors.error.withValues(alpha: 0.08 + 0.12 * pull),
              child: Transform.scale(
                scale: 0.7 + 0.5 * pull,
                child: Transform.rotate(
                  angle: pull >= 1 ? -0.12 : 0,
                  child: const Icon(
                    WaznIcons.delete,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
            ),
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
    final isPro = widget.isPro;
    final details = <String>[];
    if (widget.showTime) details.add(meal.formattedTime);
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
