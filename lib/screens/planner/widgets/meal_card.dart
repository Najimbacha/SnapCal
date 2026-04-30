import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';

class MealCard extends StatefulWidget {
  final Meal meal;
  final bool isLocked;

  const MealCard({super.key, required this.meal, this.isLocked = false});

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.meal;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isLocked
            ? colorScheme.surfaceContainer.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isLocked
              ? colorScheme.outlineVariant.withValues(alpha: 0.2)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          if (!widget.isLocked)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (widget.isLocked || (m.ingredients == null || m.ingredients!.isEmpty))
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: widget.isLocked
                ? _buildLockedCard(m, colorScheme)
                : _buildActiveCard(m, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedCard(Meal m, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.lock, color: colorScheme.outline, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              m.foodName,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${m.calories} kcal',
            style: AppTypography.labelLarge.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(Meal m, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _mealTypeColor(m.mealType!).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _mealTypeIcon(m.mealType!),
                  color: _mealTypeColor(m.mealType!),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.mealType?.toUpperCase() ?? 'MEAL',
                      style: AppTypography.labelSmall.copyWith(
                        color: _mealTypeColor(m.mealType!),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      m.foodName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${m.calories}',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  if (m.prepTimeMins != null && m.prepTimeMins! > 0)
                    Text(
                      '${m.prepTimeMins} MINS',
                      style: AppTypography.labelSmall.copyWith(
                        color: context.textMutedColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroPill(label: 'P', value: m.macros.protein, color: AppColors.protein),
              const SizedBox(width: 6),
              _MacroPill(label: 'C', value: m.macros.carbs, color: AppColors.carbs),
              const SizedBox(width: 6),
              _MacroPill(label: 'F', value: m.macros.fat, color: AppColors.fat),
              const Spacer(),
              if (m.ingredients != null && m.ingredients!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                ),
            ],
          ),
          if (_expanded && m.ingredients != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INGREDIENTS',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...m.ingredients!.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                i,
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _mealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return const Color(0xFFF59E0B);
      case 'lunch': return const Color(0xFF10B981);
      case 'dinner': return const Color(0xFF6366F1);
      case 'snack': return const Color(0xFFEC4899);
      default: return AppColors.primary;
    }
  }

  IconData _mealTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return LucideIcons.egg;
      case 'lunch': return LucideIcons.utensils;
      case 'dinner': return LucideIcons.moon;
      case 'snack': return LucideIcons.cookie;
      default: return LucideIcons.chefHat;
    }
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MacroPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 9,
              ),
            ),
            TextSpan(
              text: '${value}g',
              style: AppTypography.labelSmall.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
