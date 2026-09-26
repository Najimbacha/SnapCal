import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/wazn_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
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

class _MealListTileState extends State<MealListTile>
    with SingleTickerProviderStateMixin {
  /// How far the row has been swiped, 0 to 1 of the way to deleting.
  final _swipe = ValueNotifier<double>(0);
  bool _armed = false;

  /// An edited meal glows softly while its calories roll to the new number,
  /// with the difference floating up beside them.
  late final AnimationController _changed;
  int _delta = 0;

  Meal get meal => widget.meal;

  @override
  void initState() {
    super.initState();
    _changed = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(MealListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.meal;
    if (before.id == meal.id &&
        before.calories != meal.calories &&
        !AppMotion.reduceMotion(context)) {
      _delta = meal.calories - before.calories;
      _changed.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swipe.dispose();
    _changed.dispose();
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
      child: AnimatedBuilder(
        animation: _changed,
        builder: (context, child) {
          final t = _changed.value;
          final glow = t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi) * .12;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: glow),
              borderRadius: BorderRadius.circular(10),
            ),
            child: child,
          );
        },
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
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: AlignmentDirectional.centerEnd,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: meal.calories.toDouble()),
                        duration: AppMotion.maybeZero(
                          context,
                          const Duration(milliseconds: 800),
                        ),
                        curve: Curves.easeOutCubic,
                        builder:
                            (context, calories, _) => Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${calories.round()}',
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
                      ),
                      PositionedDirectional(
                        end: 0,
                        top: -20,
                        child: _DeltaChip(animation: _changed, delta: _delta),
                      ),
                    ],
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

/// The change in calories, floating up beside the new number and fading.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.animation, required this.delta});

  final Animation<double> animation;
  final int delta;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          if (t == 0 || t == 1 || delta == 0) return const SizedBox.shrink();
          final opacity =
              t < .2
                  ? t / .2
                  : t > .75
                  ? (1 - t) / .25
                  : 1.0;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 8 - 18 * Curves.easeOut.transform(t)),
              child: child,
            ),
          );
        },
        child: Container(
          key: const ValueKey('meal-delta'),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${delta > 0 ? '+' : '−'}${delta.abs()}',
            style: AppTypography.labelSmall.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
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
