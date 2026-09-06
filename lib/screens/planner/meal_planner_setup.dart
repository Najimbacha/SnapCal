import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/user_settings.dart';

class PlannerSetupResult {
  const PlannerSetupResult({
    required this.mealsPerDay,
    required this.dietaryRestriction,
    required this.cuisines,
    required this.prepTime,
    required this.budget,
    required this.foodsToAvoid,
    required this.usePantry,
    required this.planLeftovers,
    required this.repeatBreakfasts,
    required this.planStyle,
  });

  final int mealsPerDay;
  final String dietaryRestriction;
  final List<String> cuisines;
  final String prepTime;
  final String budget;
  final String foodsToAvoid;
  final bool usePantry;
  final bool planLeftovers;
  final bool repeatBreakfasts;
  final String planStyle;
}

class MealPlannerSetup extends StatefulWidget {
  const MealPlannerSetup({
    super.key,
    required this.settings,
    required this.initialPrepTime,
    required this.initialBudget,
    required this.editingExistingPlan,
    required this.onClose,
    required this.onGenerate,
  });

  final UserSettings settings;
  final String initialPrepTime;
  final String initialBudget;
  final bool editingExistingPlan;
  final VoidCallback onClose;
  final Future<void> Function(PlannerSetupResult result) onGenerate;

  @override
  State<MealPlannerSetup> createState() => _MealPlannerSetupState();
}

class _MealPlannerSetupState extends State<MealPlannerSetup> {
  final _avoidController = TextEditingController();
  int _step = 0;
  late int _mealsPerDay;
  late String _restriction;
  late String _prepTime;
  late String _budget;
  late Set<String> _cuisines;
  String _planStyle = 'protein';
  bool _usePantry = true;
  bool _planLeftovers = true;
  bool _repeatBreakfasts = false;

  @override
  void initState() {
    super.initState();
    _mealsPerDay = widget.settings.mealsPerDay ?? 4;
    _restriction = widget.settings.dietaryRestriction ?? 'none';
    _prepTime = widget.initialPrepTime;
    _budget = widget.initialBudget;
    _avoidController.text = widget.settings.foodDislikes ?? '';
    final savedCuisines =
        (widget.settings.cuisinePreference ?? 'international')
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet();
    _cuisines = savedCuisines.isEmpty ? {'international'} : savedCuisines;
  }

  @override
  void dispose() {
    _avoidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _SetupTopBar(
              title: l10n.planner_build_week,
              step: _step,
              onClose: widget.onClose,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                child:
                    _step == 0
                        ? _buildFirstStep(key: const ValueKey('setup-step-1'))
                        : _buildSecondStep(key: const ValueKey('setup-step-2')),
              ),
            ),
            _SetupBottomBar(
              step: _step,
              onBack: () => setState(() => _step = 0),
              onNext: () {
                HapticFeedback.selectionClick();
                setState(() => _step = 1);
              },
              onGenerate:
                  () => widget.onGenerate(
                    PlannerSetupResult(
                      mealsPerDay: _mealsPerDay,
                      dietaryRestriction: _restriction,
                      cuisines: _cuisines.toList(),
                      prepTime: _prepTime,
                      budget: _budget,
                      foodsToAvoid: _avoidController.text.trim(),
                      usePantry: _usePantry,
                      planLeftovers: _planLeftovers,
                      repeatBreakfasts: _repeatBreakfasts,
                      planStyle: _planStyle,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstStep({required Key key}) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _GoalSummary(settings: widget.settings),
        const SizedBox(height: 24),
        _SetupLabel(l10n.planner_meals_per_day),
        const SizedBox(height: 8),
        Row(
          children:
              [3, 4, 5]
                  .map(
                    (count) => Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: count == 5 ? 0 : 8,
                        ),
                        child: _ChoiceTile(
                          label: '$count',
                          selected: _mealsPerDay == count,
                          onTap: () => setState(() => _mealsPerDay = count),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 22),
        _SetupLabel(l10n.planner_cooking_time),
        const SizedBox(height: 8),
        Row(
          children:
              [
                    ('quick', l10n.planner_cooking_quick, LucideIcons.timer),
                    (
                      'balanced',
                      l10n.planner_cooking_balanced,
                      LucideIcons.scale,
                    ),
                    ('enjoy', l10n.planner_cooking_enjoy, LucideIcons.chefHat),
                  ]
                  .map(
                    (option) => Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: option.$1 == 'enjoy' ? 0 : 8,
                        ),
                        child: _ChoiceTile(
                          label: option.$2,
                          icon: option.$3,
                          selected: _prepTime == option.$1,
                          onTap: () => setState(() => _prepTime = option.$1),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 22),
        _SetupLabel(l10n.planner_plan_style),
        const SizedBox(height: 8),
        _OptionList(
          value: _planStyle,
          options: [
            ('budget', l10n.planner_style_budget, LucideIcons.wallet),
            ('protein', l10n.planner_style_protein, LucideIcons.dumbbell),
            ('simple', l10n.planner_style_simple, LucideIcons.listChecks),
            ('variety', l10n.planner_style_variety, LucideIcons.shuffle),
          ],
          onChanged: (value) {
            setState(() {
              _planStyle = value;
              if (value == 'budget') _budget = 'budget';
              if (value == 'protein') _budget = 'standard';
              if (value == 'simple') _prepTime = 'quick';
            });
          },
        ),
        const SizedBox(height: 22),
        _SetupLabel(l10n.planner_food_preferences),
        const SizedBox(height: 8),
        _RestrictionPicker(
          value: _restriction,
          onChanged: (value) => setState(() => _restriction = value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _avoidController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.planner_foods_avoid,
            hintText: l10n.planner_foods_avoid_hint,
            prefixIcon: const Icon(LucideIcons.circleSlash2, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondStep({required Key key}) {
    final l10n = AppLocalizations.of(context)!;
    final cuisines = [
      ('mediterranean', l10n.planner_cuisine_mediterranean),
      ('middle eastern', l10n.planner_cuisine_middle_eastern),
      ('south asian', l10n.planner_cuisine_south_asian),
      ('east asian', l10n.planner_cuisine_east_asian),
      ('latin', l10n.planner_cuisine_latin),
      ('african', l10n.planner_cuisine_african),
      ('european', l10n.planner_cuisine_european),
      ('international', l10n.planner_cuisine_surprise),
    ];
    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _SetupLabel(l10n.planner_choose_cuisines),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              cuisines.map((cuisine) {
                final selected = _cuisines.contains(cuisine.$1);
                return FilterChip(
                  label: Text(cuisine.$2),
                  selected: selected,
                  showCheckmark: true,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (selected && _cuisines.length > 1) {
                        _cuisines.remove(cuisine.$1);
                      } else {
                        _cuisines.add(cuisine.$1);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 24),
        _SetupLabel(l10n.planner_shopping_style),
        const SizedBox(height: 8),
        Row(
          children:
              [
                    ('budget', l10n.planner_shopping_save),
                    ('standard', l10n.planner_shopping_balanced),
                    ('premium', l10n.planner_shopping_premium),
                  ]
                  .map(
                    (option) => Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: option.$1 == 'premium' ? 0 : 8,
                        ),
                        child: _ChoiceTile(
                          label: option.$2,
                          selected: _budget == option.$1,
                          onTap: () => setState(() => _budget = option.$1),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 24),
        _SetupSwitch(
          icon: LucideIcons.packageOpen,
          label: l10n.planner_use_pantry,
          value: _usePantry,
          onChanged: (value) => setState(() => _usePantry = value),
        ),
        _SetupSwitch(
          icon: LucideIcons.refrigerator,
          label: l10n.planner_plan_leftovers,
          value: _planLeftovers,
          onChanged: (value) => setState(() => _planLeftovers = value),
        ),
        _SetupSwitch(
          icon: LucideIcons.repeat2,
          label: l10n.planner_repeat_breakfasts,
          value: _repeatBreakfasts,
          onChanged: (value) => setState(() => _repeatBreakfasts = value),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 18,
                color: context.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.planner_allergies_respected,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupTopBar extends StatelessWidget {
  const _SetupTopBar({
    required this.title,
    required this.step,
    required this.onClose,
  });

  final String title;
  final int step;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.common_cancel,
                onPressed: onClose,
                icon: const Icon(LucideIcons.x, size: 21),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _ProBadge(),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (step + 1) / 2,
                    minHeight: 3,
                    backgroundColor: context.cardBorderColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.planner_step_of(step + 1, 2),
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.settings});
  final UserSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.planner_goal_summary,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/settings/nutrition-goals'),
                child: Text(l10n.planner_edit_goals),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _GoalValue('${settings.dailyCalorieGoal}', 'kcal'),
              _GoalValue('${settings.dailyProteinGoal}g', 'P'),
              _GoalValue('${settings.dailyCarbGoal}g', 'C'),
              _GoalValue('${settings.dailyFatGoal}g', 'F'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalValue extends StatelessWidget {
  const _GoalValue(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupLabel extends StatelessWidget {
  const _SetupLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.titleSmall.copyWith(
        color: context.textPrimaryColor,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected
                  ? context.primaryColor.withValues(alpha: 0.08)
                  : context.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? context.primaryColor : context.cardBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color:
                    selected
                        ? context.primaryColor
                        : context.textSecondaryColor,
              ),
              const SizedBox(height: 5),
            ],
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color:
                    selected ? context.primaryColor : context.textPrimaryColor,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final List<(String, String, IconData)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children:
            options.map((option) {
              final selected = value == option.$1;
              return InkWell(
                onTap: () => onChanged(option.$1),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          option == options.last
                              ? BorderSide.none
                              : BorderSide(color: context.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.$3,
                        size: 18,
                        color: context.textSecondaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(option.$2, style: AppTypography.bodyMedium),
                      ),
                      Icon(
                        selected ? LucideIcons.checkCircle : LucideIcons.circle,
                        size: 19,
                        color:
                            selected
                                ? context.primaryColor
                                : context.textMutedColor,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _RestrictionPicker extends StatelessWidget {
  const _RestrictionPicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      ('none', l10n.planner_no_restrictions),
      ('vegetarian', l10n.planner_restriction_vegetarian),
      ('vegan', l10n.planner_restriction_vegan),
      ('gluten-free', l10n.planner_restriction_gluten_free),
      ('halal', l10n.planner_restriction_halal),
    ];
    return DropdownButtonFormField<String>(
      initialValue: options.any((o) => o.$1 == value) ? value : 'none',
      decoration: const InputDecoration(
        prefixIcon: Icon(LucideIcons.leaf, size: 18),
      ),
      items:
          options
              .map(
                (option) =>
                    DropdownMenuItem(value: option.$1, child: Text(option.$2)),
              )
              .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _SetupSwitch extends StatelessWidget {
  const _SetupSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: context.textSecondaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SetupBottomBar extends StatelessWidget {
  const _SetupBottomBar({
    required this.step,
    required this.onBack,
    required this.onNext,
    required this.onGenerate,
  });
  final int step;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(top: BorderSide(color: context.dividerColor)),
      ),
      child:
          step == 0
              ? FilledButton(
                key: const ValueKey('planner-setup-continue'),
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.common_continue),
              )
              : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(l10n.common_back),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: const ValueKey('planner-generate-plan'),
                      onPressed: onGenerate,
                      icon: const Icon(LucideIcons.sparkles, size: 18),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      label: Text(l10n.planner_generate_plan),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        'PRO',
        style: AppTypography.labelSmall.copyWith(
          color: context.primaryColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
