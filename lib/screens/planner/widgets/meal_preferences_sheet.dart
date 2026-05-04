import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/ui_blocks.dart';

class MealPreferencesSheet extends StatefulWidget {
  final VoidCallback onGenerate;

  const MealPreferencesSheet({super.key, required this.onGenerate});

  @override
  State<MealPreferencesSheet> createState() => _MealPreferencesSheetState();
}

class _MealPreferencesSheetState extends State<MealPreferencesSheet> {
  late int _mealsPerDay;
  late String _restriction;
  late String _cuisine;

  @override
  void initState() {
    super.initState();
    final sp = context.read<SettingsProvider>();
    _mealsPerDay = sp.mealsPerDay;
    _restriction = sp.dietaryRestriction;
    _cuisine = sp.cuisinePreference;
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.read<SettingsProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, 86 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title row
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LucideIcons.chefHat, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.planner_meal_preferences, style: AppTypography.heading3),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.planner_setup_desc,
                        style: AppTypography.bodySmall.copyWith(color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Calorie target summary
            AppSectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(label: AppLocalizations.of(context)!.planner_target, value: '${sp.dailyCalorieGoal}', unit: 'kcal'),
                  _MiniStat(label: AppLocalizations.of(context)!.result_protein, value: '${sp.dailyProteinGoal}', unit: 'g'),
                  _MiniStat(label: AppLocalizations.of(context)!.result_carbs, value: '${sp.dailyCarbGoal}', unit: 'g'),
                  _MiniStat(label: AppLocalizations.of(context)!.result_fat, value: '${sp.dailyFatGoal}', unit: 'g'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Meals per day
            Text(AppLocalizations.of(context)!.planner_meals_per_day, style: AppTypography.labelLarge.copyWith(
              color: context.textPrimaryColor, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 10),
            Row(
              children: [2, 3, 4, 5].map((n) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: n < 5 ? 8 : 0),
                  child: _SegmentButton(
                    label: '$n',
                    selected: _mealsPerDay == n,
                    onTap: () => setState(() => _mealsPerDay = n),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Dietary restriction
            Text(AppLocalizations.of(context)!.planner_dietary_restriction, style: AppTypography.labelLarge.copyWith(
              color: context.textPrimaryColor, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['none', 'vegetarian', 'vegan', 'gluten-free', 'keto', 'halal'].map((r) =>
                _ChipButton(
                  label: _getRestrictionLabel(context, r),
                  selected: _restriction == r,
                  onTap: () => setState(() => _restriction = r),
                ),
              ).toList(),
            ),
            const SizedBox(height: 20),

            // Cuisine preference
            Text(AppLocalizations.of(context)!.planner_cuisine_style, style: AppTypography.labelLarge.copyWith(
              color: context.textPrimaryColor, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['international', 'south asian', 'mediterranean', 'east asian', 'american', 'middle eastern'].map((c) =>
                _ChipButton(
                  label: _getCuisineLabel(context, c),
                  selected: _cuisine == c,
                  onTap: () => setState(() => _cuisine = c),
                ),
              ).toList(),
            ),
            const SizedBox(height: 24),

            // Generate button
            FilledButton.icon(
              onPressed: () {
                sp.updatePlannerPreferences(
                  mealsPerDay: _mealsPerDay,
                  dietaryRestriction: _restriction,
                  cuisinePreference: _cuisine,
                );
                Navigator.pop(context);
                widget.onGenerate();
              },
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: Text(AppLocalizations.of(context)!.planner_generate_plan),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                AppLocalizations.of(context)!.planner_ai_disclaimer,
                style: AppTypography.labelSmall.copyWith(color: context.textMutedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRestrictionLabel(BuildContext context, String restriction) {
    final l10n = AppLocalizations.of(context)!;
    switch (restriction) {
      case 'none': return l10n.planner_restriction_none;
      case 'vegetarian': return l10n.planner_restriction_vegetarian;
      case 'vegan': return l10n.planner_restriction_vegan;
      case 'gluten-free': return l10n.planner_restriction_gluten_free;
      case 'keto': return l10n.planner_restriction_keto;
      case 'halal': return l10n.planner_restriction_halal;
      default: return restriction;
    }
  }

  String _getCuisineLabel(BuildContext context, String cuisine) {
    final l10n = AppLocalizations.of(context)!;
    switch (cuisine) {
      case 'international': return l10n.planner_cuisine_international;
      case 'south asian': return l10n.planner_cuisine_south_asian;
      case 'mediterranean': return l10n.planner_cuisine_mediterranean;
      case 'east asian': return l10n.planner_cuisine_east_asian;
      case 'american': return l10n.planner_cuisine_american;
      case 'middle eastern': return l10n.planner_cuisine_middle_eastern;
      default: return cuisine;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value, unit;
  const _MiniStat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.headlineSmall.copyWith(
          fontWeight: FontWeight.w800, color: context.textPrimaryColor,
        )),
        Text('$unit $label', style: AppTypography.labelSmall.copyWith(
          color: context.textSecondaryColor,
        )),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.14) : context.cardSoftColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : context.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(label, style: AppTypography.labelLarge.copyWith(
            color: selected ? AppColors.primary : context.textSecondaryColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.14) : context.cardSoftColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : context.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label, style: AppTypography.labelMedium.copyWith(
          color: selected ? AppColors.primary : context.textSecondaryColor,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
    );
  }
}
