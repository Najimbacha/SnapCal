import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';

enum _MealCardAction { details, log, swap }

Color _getMealTypeColor(BuildContext context, String? type) {
  if (type == null) return context.primaryColor;
  switch (type.toLowerCase()) {
    case 'breakfast':
      return Colors.orangeAccent;
    case 'lunch':
      return Colors.teal;
    case 'dinner':
      return Colors.indigoAccent;
    case 'snack':
      return Colors.pinkAccent;
    default:
      return context.primaryColor;
  }
}

class MealCard extends StatefulWidget {
  final Meal meal;
  final bool isLocked;
  final bool isLogged;
  final VoidCallback? onLogMeal;
  final VoidCallback? onSwapMeal;

  const MealCard({
    super.key,
    required this.meal,
    this.isLocked = false,
    this.isLogged = false,
    this.onLogMeal,
    this.onSwapMeal,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _expanded = false;

  bool get _hasDetails {
    final meal = widget.meal;
    return meal.macros.protein > 0 ||
        meal.macros.carbs > 0 ||
        meal.macros.fat > 0 ||
        (meal.ingredients != null && meal.ingredients!.isNotEmpty) ||
        (meal.aiRationale != null && meal.aiRationale!.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    if (widget.isLocked) return _LockedMealRow(meal: meal);

    final mealType = _getLocalizedMealType(context, meal.mealType);
    final meta = [
      mealType,
      if (meal.prepTimeMins != null && meal.prepTimeMins! > 0)
        '${meal.prepTimeMins} ${AppLocalizations.of(context)!.common_mins}',
      if (widget.isLogged)
        AppLocalizations.of(context)!.planner_logged.toLowerCase(),
    ].join(' · ');

    return Container(
      key: ValueKey('planner-meal-${meal.id}'),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.cardSoftColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              _hasDetails ? () => setState(() => _expanded = !_expanded) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Vertical accent category stripe
                    Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _getMealTypeColor(context, meal.mealType),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: context.textMutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            meal.foodName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${meal.calories} kcal',
                      style: AppTypography.labelLarge.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _LogButton(
                      isLogged: widget.isLogged,
                      onTap: widget.isLogged ? null : widget.onLogMeal,
                    ),
                    _MealOverflowMenu(
                      hasDetails: _hasDetails,
                      canLog: widget.onLogMeal != null && !widget.isLogged,
                      canSwap: widget.onSwapMeal != null,
                      onSelected: (action) {
                        switch (action) {
                          case _MealCardAction.details:
                            setState(() => _expanded = !_expanded);
                            break;
                          case _MealCardAction.log:
                            widget.onLogMeal?.call();
                            break;
                          case _MealCardAction.swap:
                            widget.onSwapMeal?.call();
                            break;
                        }
                      },
                    ),
                  ],
                ),
                if (_expanded && _hasDetails) ...[
                  const SizedBox(height: 12),
                  Divider(color: context.cardBorderColor, height: 1.2),
                  const SizedBox(height: 12),
                  _MealDetails(meal: meal),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final bool isLogged;
  final VoidCallback? onTap;

  const _LogButton({required this.isLogged, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.snap_log_meal,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        backgroundColor:
            isLogged
                ? AppColors.success.withValues(alpha: 0.12)
                : context.primaryColor.withValues(alpha: 0.10),
        foregroundColor: isLogged ? AppColors.success : context.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(isLogged ? LucideIcons.check : LucideIcons.plus, size: 17),
    );
  }
}

class _MealOverflowMenu extends StatelessWidget {
  final bool hasDetails;
  final bool canLog;
  final bool canSwap;
  final ValueChanged<_MealCardAction> onSelected;

  const _MealOverflowMenu({
    required this.hasDetails,
    required this.canLog,
    required this.canSwap,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasDetails && !canLog && !canSwap) return const SizedBox(width: 4);
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_MealCardAction>(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      icon: const Icon(LucideIcons.moreVertical, size: 17),
      onSelected: onSelected,
      itemBuilder:
          (context) => [
            if (hasDetails)
              PopupMenuItem(
                value: _MealCardAction.details,
                child: _MenuRow(
                  icon: LucideIcons.list,
                  label: l10n.planner_ingredients,
                ),
              ),
            if (canLog)
              PopupMenuItem(
                value: _MealCardAction.log,
                child: _MenuRow(
                  icon: LucideIcons.plus,
                  label: l10n.snap_log_meal,
                ),
              ),
            if (canSwap)
              PopupMenuItem(
                value: _MealCardAction.swap,
                child: _MenuRow(
                  icon: LucideIcons.refreshCw,
                  label: l10n.planner_swap_title,
                ),
              ),
          ],
    );
  }
}

class _MealDetails extends StatelessWidget {
  final Meal meal;

  const _MealDetails({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MacroBadge(
              label: 'PRO',
              value: meal.macros.protein,
              color: Colors.blue,
            ),
            _MacroBadge(
              label: 'CARB',
              value: meal.macros.carbs,
              color: Colors.orange,
            ),
            _MacroBadge(
              label: 'FAT',
              value: meal.macros.fat,
              color: Colors.pink,
            ),
          ],
        ),
        if (meal.ingredients != null && meal.ingredients!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            meal.ingredients!.join(', '),
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (meal.aiRationale != null &&
            meal.aiRationale!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            meal.aiRationale!.trim(),
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${value}g',
            style: AppTypography.labelSmall.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedMealRow extends StatelessWidget {
  final Meal meal;

  const _LockedMealRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardSoftColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.lock, size: 16, color: context.textMutedColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              meal.foodName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${meal.calories} kcal',
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

String _getLocalizedMealType(BuildContext context, String? type) {
  final l10n = AppLocalizations.of(context)!;
  if (type == null) return l10n.planner_meal;
  switch (type.toLowerCase()) {
    case 'breakfast':
      return l10n.result_meal_breakfast;
    case 'lunch':
      return l10n.result_meal_lunch;
    case 'dinner':
      return l10n.result_meal_dinner;
    case 'snack':
      return l10n.result_meal_snack;
    default:
      return type;
  }
}
