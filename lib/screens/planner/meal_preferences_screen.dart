import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/planner_provider.dart';
import '../../widgets/ui_blocks.dart';

class MealPreferencesScreen extends StatefulWidget {
  final VoidCallback onGenerate;

  const MealPreferencesScreen({super.key, required this.onGenerate});

  @override
  State<MealPreferencesScreen> createState() => _MealPreferencesScreenState();
}

class _MealPreferencesScreenState extends State<MealPreferencesScreen> {
  late int _mealsPerDay;
  late String _restriction;
  late String _cuisine;
  late String _prepTime;
  late String _budget;

  @override
  void initState() {
    super.initState();
    final sp = context.read<SettingsProvider>();
    _mealsPerDay = sp.mealsPerDay;
    _restriction = sp.dietaryRestriction;
    _cuisine = sp.cuisinePreference;
    final planner = context.read<PlannerProvider>();
    _prepTime = planner.prepTimePreference;
    _budget = planner.budgetPreference;
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: context.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.planner_meal_preferences,
                    style: AppTypography.headlineSmall.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.planner_setup_desc,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BentoSection(
                      title: "PLAN STYLE",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.planner_prep_time,
                            style: AppTypography.titleSmall.copyWith(
                              color: context.textSecondaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                ['quick', 'balanced', 'batch']
                                    .map(
                                      (value) => _ChipButton(
                                        label: _getPrepTimeLabel(
                                          context,
                                          value,
                                        ),
                                        selected: _prepTime == value,
                                        onTap:
                                            () => setState(
                                              () => _prepTime = value,
                                            ),
                                        icon: _getPrepTimeIcon(value),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.planner_budget,
                            style: AppTypography.titleSmall.copyWith(
                              color: context.textSecondaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                ['budget', 'standard', 'premium']
                                    .map(
                                      (value) => _ChipButton(
                                        label: _getBudgetLabel(context, value),
                                        selected: _budget == value,
                                        onTap:
                                            () =>
                                                setState(() => _budget = value),
                                        icon: _getBudgetIcon(value),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),

                    _BentoSection(
                      title:
                          AppLocalizations.of(
                            context,
                          )!.planner_meals_per_day.toUpperCase(),
                      child: Row(
                        children:
                            [2, 3, 4, 5]
                                .map(
                                  (n) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: n < 5 ? 8 : 0,
                                      ),
                                      child: _SegmentButton(
                                        label: '$n',
                                        selected: _mealsPerDay == n,
                                        onTap:
                                            () => setState(
                                              () => _mealsPerDay = n,
                                            ),
                                        icon: LucideIcons.utensils,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),

                    _BentoSection(
                      title:
                          AppLocalizations.of(
                            context,
                          )!.planner_dietary_restriction.toUpperCase(),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  'none',
                                  'vegetarian',
                                  'vegan',
                                  'gluten-free',
                                  'keto',
                                  'halal',
                                ]
                                .map(
                                  (r) => _ChipButton(
                                    label: _getRestrictionLabel(context, r),
                                    selected: _restriction == r,
                                    onTap:
                                        () => setState(() => _restriction = r),
                                    icon: _getRestrictionIcon(r),
                                  ),
                                )
                                .toList(),
                      ),
                    ),

                    _BentoSection(
                      title:
                          AppLocalizations.of(
                            context,
                          )!.planner_cuisine_style.toUpperCase(),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  'international',
                                  'south asian',
                                  'mediterranean',
                                  'east asian',
                                  'american',
                                  'middle eastern',
                                ]
                                .map(
                                  (c) => _ChipButton(
                                    label: _getCuisineLabel(context, c),
                                    selected: _cuisine == c,
                                    onTap: () => setState(() => _cuisine = c),
                                    icon: _getCuisineIcon(c),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                border: Border(
                  top: BorderSide(color: context.dividerColor, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      sp.updatePlannerPreferences(
                        mealsPerDay: _mealsPerDay,
                        dietaryRestriction: _restriction,
                        cuisinePreference: _cuisine,
                      );
                      context.read<PlannerProvider>().setPlanningPreferences(
                        prepTimePreference: _prepTime,
                        budgetPreference: _budget,
                      );
                      Navigator.pop(context);
                      widget.onGenerate();
                    },
                    icon: const Icon(LucideIcons.sparkles, size: 18),
                    label: Text(
                      AppLocalizations.of(context)!.planner_generate_plan,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.planner_ai_disclaimer,
                      style: AppTypography.labelSmall.copyWith(
                        color: context.textMutedColor,
                      ),
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

  String _getRestrictionLabel(BuildContext context, String restriction) {
    final l10n = AppLocalizations.of(context)!;
    switch (restriction) {
      case 'none':
        return l10n.planner_restriction_none;
      case 'vegetarian':
        return l10n.planner_restriction_vegetarian;
      case 'vegan':
        return l10n.planner_restriction_vegan;
      case 'gluten-free':
        return l10n.planner_restriction_gluten_free;
      case 'keto':
        return l10n.planner_restriction_keto;
      case 'halal':
        return l10n.planner_restriction_halal;
      default:
        return restriction;
    }
  }

  String _getCuisineLabel(BuildContext context, String cuisine) {
    final l10n = AppLocalizations.of(context)!;
    switch (cuisine) {
      case 'international':
        return l10n.planner_cuisine_international;
      case 'south asian':
        return l10n.planner_cuisine_south_asian;
      case 'mediterranean':
        return l10n.planner_cuisine_mediterranean;
      case 'east asian':
        return l10n.planner_cuisine_east_asian;
      case 'american':
        return l10n.planner_cuisine_american;
      case 'middle eastern':
        return l10n.planner_cuisine_middle_eastern;
      default:
        return cuisine;
    }
  }

  String _getPrepTimeLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'quick':
        return l10n.planner_prep_quick;
      case 'batch':
        return l10n.planner_prep_batch;
      case 'balanced':
      default:
        return l10n.planner_prep_balanced;
    }
  }

  String _getBudgetLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'budget':
        return l10n.planner_budget_value;
      case 'premium':
        return l10n.planner_budget_premium;
      case 'standard':
      default:
        return l10n.planner_budget_standard;
    }
  }

  IconData _getPrepTimeIcon(String value) {
    switch (value) {
      case 'quick':
        return LucideIcons.timer;
      case 'batch':
        return LucideIcons.layers;
      case 'balanced':
      default:
        return LucideIcons.scale;
    }
  }

  IconData _getBudgetIcon(String value) {
    switch (value) {
      case 'budget':
        return LucideIcons.piggyBank;
      case 'premium':
        return LucideIcons.gem;
      case 'standard':
      default:
        return LucideIcons.coins;
    }
  }

  IconData _getRestrictionIcon(String r) {
    switch (r) {
      case 'none':
        return LucideIcons.ban;
      case 'vegetarian':
        return LucideIcons.leaf;
      case 'vegan':
        return LucideIcons.sprout;
      case 'gluten-free':
        return LucideIcons.wheat;
      case 'keto':
        return LucideIcons.flame;
      case 'halal':
        return LucideIcons.checkCircle;
      default:
        return LucideIcons.utensils;
    }
  }

  IconData _getCuisineIcon(String c) {
    switch (c) {
      case 'international':
        return LucideIcons.globe;
      case 'south asian':
        return LucideIcons.soup;
      case 'mediterranean':
        return LucideIcons.sun;
      case 'east asian':
        return LucideIcons.chefHat;
      case 'american':
        return LucideIcons.beef;
      case 'middle eastern':
        return LucideIcons.star;
      default:
        return LucideIcons.globe;
    }
  }
}

// ── Preference Section ───────────────────────────────────────────────────────
class _BentoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _BentoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Frequency Segment Button ─────────────────────────────────────────────────
class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : context.cardSoftColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? context.primaryColor : context.cardBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : context.textSecondaryColor,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge.copyWith(
                  color: selected ? Colors.white : context.textPrimaryColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── General Chip Button ──────────────────────────────────────────────────────
class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 8 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : context.cardSoftColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? context.primaryColor : context.cardBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : context.textSecondaryColor,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? Colors.white : context.textPrimaryColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
