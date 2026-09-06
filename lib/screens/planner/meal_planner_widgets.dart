import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/grocery_item.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_plan.dart';

class PlannerTopBar extends StatelessWidget {
  const PlannerTopBar({
    super.key,
    required this.groceryCount,
    required this.isPro,
    required this.onBack,
    required this.onGrocery,
    required this.onPreferences,
    required this.onRegenerate,
  });

  final int groceryCount;
  final bool isPro;
  final VoidCallback onBack;
  final VoidCallback onGrocery;
  final VoidCallback onPreferences;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.common_back,
            onPressed: onBack,
            icon: const Icon(LucideIcons.arrowLeft, size: 21),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.planner_title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ProBadge(active: isPro),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: l10n.planner_tab_grocery,
                onPressed: onGrocery,
                icon: const Icon(LucideIcons.shoppingBag, size: 21),
              ),
              if (groceryCount > 0 && isPro)
                PositionedDirectional(
                  end: 2,
                  top: 1,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      groceryCount > 99 ? '99+' : '$groceryCount',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: l10n.planner_meal_preferences,
            icon: const Icon(LucideIcons.moreVertical, size: 21),
            onSelected: (value) {
              if (value == 'preferences') onPreferences();
              if (value == 'regenerate') onRegenerate();
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'preferences',
                    child: _MenuLabel(
                      icon: LucideIcons.slidersHorizontal,
                      label: l10n.planner_meal_preferences,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'regenerate',
                    child: _MenuLabel(
                      icon: LucideIcons.refreshCw,
                      label: l10n.planner_regenerate,
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}

class PlannerTabs extends StatelessWidget {
  const PlannerTabs({
    super.key,
    required this.grocerySelected,
    required this.onPlan,
    required this.onGrocery,
  });

  final bool grocerySelected;
  final VoidCallback onPlan;
  final VoidCallback onGrocery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.cardSoftColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _TabButton(
              label: l10n.planner_plan_tab,
              icon: LucideIcons.calendarDays,
              selected: !grocerySelected,
              onTap: onPlan,
            ),
            _TabButton(
              label: l10n.planner_tab_grocery,
              icon: LucideIcons.shoppingBag,
              selected: grocerySelected,
              onTap: onGrocery,
            ),
          ],
        ),
      ),
    );
  }
}

class WeekNavigator extends StatelessWidget {
  const WeekNavigator({super.key, required this.plan});
  final MealPlan plan;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!.localeName;
    final sameMonth = plan.startDate.month == plan.endDate.month;
    final range =
        sameMonth
            ? '${DateFormat.MMM(locale).format(plan.startDate)} ${plan.startDate.day}–${plan.endDate.day}'
            : '${DateFormat.MMMd(locale).format(plan.startDate)} – ${DateFormat.MMMd(locale).format(plan.endDate)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.planner_week_label,
            style: AppTypography.labelMedium.copyWith(
              color: context.textMutedColor,
            ),
          ),
          const Spacer(),
          Text(
            range,
            style: AppTypography.labelLarge.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PlannerDayStrip extends StatelessWidget {
  const PlannerDayStrip({
    super.key,
    required this.plan,
    required this.selectedIndex,
    required this.lockedAfterIndex,
    required this.onSelected,
  });

  final MealPlan plan;
  final int selectedIndex;
  final int? lockedAfterIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!.localeName;
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final date = plan.startDate.add(Duration(days: index));
          final selected = index == selectedIndex;
          final locked = lockedAfterIndex != null && index > lockedAfterIndex!;
          return InkWell(
            key: ValueKey('planner-day-$index'),
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 43,
              decoration: BoxDecoration(
                color: selected ? context.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      selected ? context.primaryColor : context.cardBorderColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E(locale).format(date).substring(0, 1),
                    style: AppTypography.labelSmall.copyWith(
                      color: selected ? Colors.white70 : context.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: AppTypography.labelLarge.copyWith(
                          color:
                              selected
                                  ? Colors.white
                                  : context.textPrimaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 2),
                        Icon(
                          LucideIcons.lock,
                          size: 8,
                          color:
                              selected
                                  ? Colors.white70
                                  : context.textMutedColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlannerPreviewLabel extends StatelessWidget {
  const PlannerPreviewLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(LucideIcons.eye, size: 15, color: context.primaryColor),
        const SizedBox(width: 7),
        Text(
          AppLocalizations.of(context)!.planner_one_day_preview,
          style: AppTypography.labelMedium.copyWith(
            color: context.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class PlannerDayHeading extends StatelessWidget {
  const PlannerDayHeading({
    super.key,
    required this.date,
    required this.mealCount,
    required this.calories,
    required this.showRegenerate,
    required this.onRegenerate,
  });
  final DateTime date;
  final int mealCount;
  final int calories;
  final bool showRegenerate;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d', l10n.localeName).format(date),
                style: AppTypography.titleLarge.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.planner_meals_kcal_summary(
                  mealCount,
                  NumberFormat.decimalPattern(l10n.localeName).format(calories),
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
        ),
        if (showRegenerate)
          IconButton.outlined(
            tooltip: l10n.planner_regenerate,
            onPressed: onRegenerate,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
          ),
      ],
    );
  }
}

class PlannerNutritionBand extends StatelessWidget {
  const PlannerNutritionBand({
    super.key,
    required this.meals,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
  });
  final List<Meal> meals;
  final int calorieGoal;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final protein = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.macros.protein,
    );
    final carbs = meals.fold<int>(0, (sum, meal) => sum + meal.macros.carbs);
    final fat = meals.fold<int>(0, (sum, meal) => sum + meal.macros.fat);
    final progress =
        calorieGoal <= 0 ? 0.0 : (calories / calorieGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: context.cardSoftColor,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _MacroValue(
                label: 'kcal',
                value: '$calories',
                goal: '$calorieGoal',
              ),
              _MacroValue(
                label: 'P',
                value: '${protein}g',
                goal: '${proteinGoal}g',
              ),
              _MacroValue(label: 'C', value: '${carbs}g', goal: '${carbGoal}g'),
              _MacroValue(label: 'F', value: '${fat}g', goal: '${fatGoal}g'),
            ],
          ),
        ],
      ),
    );
  }
}

class PlannerSectionTitle extends StatelessWidget {
  const PlannerSectionTitle({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.titleMedium.copyWith(
        color: context.textPrimaryColor,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class PlannerMealRow extends StatelessWidget {
  const PlannerMealRow({
    super.key,
    required this.meal,
    required this.isNext,
    required this.isLogged,
    required this.interactive,
    required this.onOpen,
    required this.onLog,
    required this.onSwap,
  });
  final Meal meal;
  final bool isNext;
  final bool isLogged;
  final bool interactive;
  final VoidCallback onOpen;
  final VoidCallback? onLog;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              isNext
                  ? context.primaryColor.withValues(alpha: 0.5)
                  : context.cardBorderColor,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlannerMealImage(meal: meal, width: 64, height: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isNext) ...[
                          Text(
                            l10n.planner_next_meal.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: context.primaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            meal.mealType ?? l10n.planner_meal,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: context.textMutedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal.foodName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${meal.formattedTime}  ·  ${meal.prepTimeMins ?? 15} min  ·  ${meal.calories} kcal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (interactive) ...[
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip:
                          isLogged
                              ? l10n.planner_logged
                              : l10n.planner_log_meal,
                      onPressed: onLog,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 40,
                      ),
                      padding: const EdgeInsets.all(8),
                      icon: Icon(
                        isLogged ? LucideIcons.checkCircle : LucideIcons.plus,
                        size: 19,
                        color:
                            isLogged
                                ? context.primaryColor
                                : context.textPrimaryColor,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.planner_swap_meal,
                      onPressed: onSwap,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 40,
                      ),
                      padding: const EdgeInsets.all(8),
                      icon: const Icon(LucideIcons.repeat2, size: 17),
                    ),
                  ],
                ),
              ] else
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: context.textMutedColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlannerBottomActions extends StatelessWidget {
  const PlannerBottomActions({
    super.key,
    required this.isPro,
    required this.onAdjust,
    required this.onGrocery,
  });
  final bool isPro;
  final VoidCallback onAdjust;
  final VoidCallback onGrocery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(top: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAdjust,
              icon: Icon(
                isPro ? LucideIcons.slidersHorizontal : LucideIcons.lock,
                size: 17,
              ),
              style: _buttonStyle(context, outlined: true),
              label: Text(l10n.planner_adjust_day),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: onGrocery,
              icon: const Icon(LucideIcons.shoppingBag, size: 17),
              style: _buttonStyle(context),
              label: Text(
                isPro ? l10n.planner_view_grocery : l10n.planner_unlock_pro,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle(BuildContext context, {bool outlined = false}) {
    if (outlined) {
      return OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class PlannerLockedWeekCard extends StatelessWidget {
  const PlannerLockedWeekCard({super.key, required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.cardBorderColor),
                ),
                child: Icon(
                  LucideIcons.lock,
                  size: 18,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.planner_unlock_title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.planner_locked_days,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.planner_unlock_pro),
            ),
          ),
        ],
      ),
    );
  }
}

class PlannerNotice extends StatelessWidget {
  const PlannerNotice({
    super.key,
    required this.message,
    required this.onDismiss,
  });
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, size: 17, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTypography.bodySmall)),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(LucideIcons.x, size: 16),
          ),
        ],
      ),
    );
  }
}

class PlannerEmptyMeals extends StatelessWidget {
  const PlannerEmptyMeals({super.key, required this.onRegenerate});
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            LucideIcons.utensilsCrossed,
            size: 28,
            color: context.textMutedColor,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.planner_no_meals_body,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          TextButton.icon(
            onPressed: onRegenerate,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(AppLocalizations.of(context)!.planner_regenerate),
          ),
        ],
      ),
    );
  }
}

class PlannerGeneratingScreen extends StatefulWidget {
  const PlannerGeneratingScreen({super.key, required this.onLeave});
  final VoidCallback onLeave;

  @override
  State<PlannerGeneratingScreen> createState() =>
      _PlannerGeneratingScreenState();
}

class _PlannerGeneratingScreenState extends State<PlannerGeneratingScreen> {
  int _stage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _stage >= 3) return;
      setState(() => _stage++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      l10n.planner_preferences_checked,
      l10n.planner_balancing_nutrition,
      l10n.planner_choosing_meals,
      l10n.planner_preparing_grocery,
    ];
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onLeave,
                    icon: const Icon(LucideIcons.arrowLeft, size: 21),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.planner_creating,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _ProBadge(active: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                children: [
                  Center(
                    child: SizedBox(
                      width: 142,
                      height: 142,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const PlannerMealImage(
                            width: 116,
                            height: 116,
                            assetOverride:
                                'assets/images/paywall/onboarding_grilled_chicken_bowl.png',
                          ),
                          SizedBox(
                            width: 142,
                            height: 142,
                            child: CircularProgressIndicator(
                              value: (_stage + 1) / 4,
                              strokeWidth: 4,
                              backgroundColor: context.cardBorderColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.planner_creating_body,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(steps.length, (index) {
                    final complete = index < _stage;
                    final active = index == _stage;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                active
                                    ? const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    )
                                    : Icon(
                                      complete
                                          ? LucideIcons.checkCircle
                                          : LucideIcons.circle,
                                      size: 21,
                                      color:
                                          complete
                                              ? context.primaryColor
                                              : context.textMutedColor,
                                    ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              steps[index],
                              style: AppTypography.bodyMedium.copyWith(
                                color:
                                    active || complete
                                        ? context.textPrimaryColor
                                        : context.textMutedColor,
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text(
                    l10n.planner_week_contains,
                    style: AppTypography.labelMedium.copyWith(
                      color: context.textMutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuietChip(
                        icon: LucideIcons.clock3,
                        label: l10n.planner_under_30,
                      ),
                      _QuietChip(
                        icon: LucideIcons.wallet,
                        label: l10n.planner_style_budget,
                      ),
                      _QuietChip(
                        icon: LucideIcons.recycle,
                        label: l10n.planner_smart_leftovers,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                children: [
                  Text(
                    l10n.planner_generation_leave,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onLeave,
                    child: Text(l10n.planner_cancel_generation),
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

class GroceryPlannerView extends StatelessWidget {
  const GroceryPlannerView({
    super.key,
    required this.items,
    required this.groupedItems,
    required this.selectedFilter,
    required this.shoppingMode,
    required this.onFilterChanged,
    required this.onToggle,
    required this.onClearChecked,
    required this.onShoppingMode,
    required this.onShare,
  });
  final List<GroceryItem> items;
  final Map<String, List<GroceryItem>> groupedItems;
  final int selectedFilter;
  final bool shoppingMode;
  final ValueChanged<int> onFilterChanged;
  final Future<void> Function(String id) onToggle;
  final Future<void> Function() onClearChecked;
  final VoidCallback onShoppingMode;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checked = items.where((item) => item.isChecked).length;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.planner_tab_grocery,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.planner_grocery_progress(checked, items.length),
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: l10n.planner_share,
              onPressed: onShare,
              icon: const Icon(LucideIcons.share2, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: items.isEmpty ? 0 : checked / items.length,
            minHeight: 5,
            backgroundColor: context.cardSoftColor,
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(l10n.planner_filter_all)),
            ButtonSegment(value: 1, label: Text(l10n.planner_filter_needed)),
            ButtonSegment(value: 2, label: Text(l10n.planner_filter_checked)),
          ],
          selected: {selectedFilter},
          onSelectionChanged: (selection) => onFilterChanged(selection.first),
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(LucideIcons.combine, size: 15, color: context.textMutedColor),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                l10n.planner_combined_quantities,
                style: AppTypography.bodySmall.copyWith(
                  color: context.textMutedColor,
                ),
              ),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Column(
              children: [
                Icon(
                  LucideIcons.shoppingBag,
                  size: 30,
                  color: context.textMutedColor,
                ),
                const SizedBox(height: 10),
                Text(l10n.planner_grocery_empty),
              ],
            ),
          )
        else
          ...groupedItems.entries.map(
            (group) => _GroceryGroup(
              title: group.key,
              items: group.value,
              onToggle: onToggle,
            ),
          ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: checked == 0 ? null : onClearChecked,
                  icon: const Icon(LucideIcons.eraser, size: 17),
                  label: Text(l10n.planner_clear_checked),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShoppingMode,
                  icon: Icon(
                    shoppingMode ? LucideIcons.x : LucideIcons.shoppingCart,
                    size: 17,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text(l10n.planner_shopping_mode),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class PlannerMealDetailScreen extends StatefulWidget {
  const PlannerMealDetailScreen({
    super.key,
    required this.meal,
    required this.isPro,
    required this.onLog,
    required this.onSwap,
  });
  final Meal meal;
  final bool isPro;
  final Future<void> Function(Meal meal) onLog;
  final VoidCallback onSwap;

  @override
  State<PlannerMealDetailScreen> createState() =>
      _PlannerMealDetailScreenState();
}

class _PlannerMealDetailScreenState extends State<PlannerMealDetailScreen> {
  int _servings = 1;
  final Set<int> _checkedIngredients = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meal = widget.meal;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.planner_meal_details),
        actions: [
          if (widget.isPro)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onSwap();
              },
              icon: const Icon(LucideIcons.repeat2, size: 16),
              label: Text(l10n.planner_swap_meal),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: context.backgroundColor,
            border: Border(top: BorderSide(color: context.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSwap();
                  },
                  icon: Icon(
                    widget.isPro ? LucideIcons.repeat2 : LucideIcons.lock,
                    size: 17,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text(l10n.planner_swap_meal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.isPro ? _log : null,
                  icon: const Icon(LucideIcons.plus, size: 17),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text(l10n.planner_log_meal),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                PlannerMealImage(
                  meal: meal,
                  width: double.infinity,
                  height: 210,
                ),
                PositionedDirectional(
                  start: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${meal.mealType ?? l10n.planner_meal} · ${meal.formattedTime}',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            meal.foodName,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${meal.portion ?? '1 serving'} · ${meal.prepTimeMins ?? 15} min',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textMutedColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Row(
              children: [
                _MacroValue(
                  label: 'kcal',
                  value: '${meal.calories * _servings}',
                  goal: '',
                ),
                _MacroValue(
                  label: 'P',
                  value: '${meal.macros.protein * _servings}g',
                  goal: '',
                ),
                _MacroValue(
                  label: 'C',
                  value: '${meal.macros.carbs * _servings}g',
                  goal: '',
                ),
                _MacroValue(
                  label: 'F',
                  value: '${meal.macros.fat * _servings}g',
                  goal: '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: PlannerSectionTitle(label: l10n.planner_servings),
              ),
              _Stepper(
                value: _servings,
                onMinus:
                    _servings > 1 ? () => setState(() => _servings--) : null,
                onPlus:
                    _servings < 4 ? () => setState(() => _servings++) : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          PlannerSectionTitle(label: l10n.planner_ingredients),
          const SizedBox(height: 8),
          ...(meal.ingredients ?? const <String>[]).asMap().entries.map(
            (entry) => CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checkedIngredients.contains(entry.key),
              onChanged: (_) {
                setState(() {
                  if (_checkedIngredients.contains(entry.key)) {
                    _checkedIngredients.remove(entry.key);
                  } else {
                    _checkedIngredients.add(entry.key);
                  }
                });
              },
              title: Text(entry.value, style: AppTypography.bodyMedium),
            ),
          ),
          const SizedBox(height: 16),
          PlannerSectionTitle(label: l10n.planner_preparation),
          const SizedBox(height: 10),
          ...[
            l10n.planner_prep_ingredients,
            l10n.planner_prep_cook,
            l10n.planner_prep_combine,
            l10n.planner_prep_serve,
          ].asMap().entries.map(
            (entry) =>
                _PreparationStep(number: entry.key + 1, text: entry.value),
          ),
        ],
      ),
    );
  }

  Future<void> _log() async {
    final meal = widget.meal;
    final scaled = meal.copyWith(
      calories: meal.calories * _servings,
      macros: Macros(
        protein: meal.macros.protein * _servings,
        carbs: meal.macros.carbs * _servings,
        fat: meal.macros.fat * _servings,
      ),
      portion: '${meal.portion ?? '1 serving'} × $_servings',
    );
    Navigator.pop(context);
    await widget.onLog(scaled);
  }
}

class PlannerSwapResult {
  const PlannerSwapResult({required this.intent, required this.note});
  final String intent;
  final String note;
}

class PlannerSwapSheet extends StatefulWidget {
  const PlannerSwapSheet({super.key, required this.meal});
  final Meal meal;

  @override
  State<PlannerSwapSheet> createState() => _PlannerSwapSheetState();
}

class _PlannerSwapSheetState extends State<PlannerSwapSheet> {
  final _noteController = TextEditingController();
  String _intent = 'higher_protein';
  bool _keepCalories = true;
  bool _keepTime = true;
  bool _keepPreferences = true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intents = [
      ('lower_calorie', l10n.planner_swap_lower_calorie, LucideIcons.flame),
      (
        'higher_protein',
        l10n.planner_swap_higher_protein,
        LucideIcons.dumbbell,
      ),
      ('faster_prep', l10n.planner_swap_faster_prep, LucideIcons.timer),
      ('cheaper', l10n.planner_swap_cheaper, LucideIcons.wallet),
      (
        'different_cuisine',
        l10n.planner_swap_different_cuisine,
        LucideIcons.globe2,
      ),
      ('surprise', l10n.planner_swap_surprise, LucideIcons.sparkles),
    ];
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: context.cardBorderColor)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.cardBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.planner_swap_title,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.planner_swap_replacing(widget.meal.foodName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                l10n.planner_swap_intent,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    intents.map((option) {
                      return ChoiceChip(
                        avatar: Icon(option.$3, size: 15),
                        label: Text(option.$2),
                        selected: _intent == option.$1,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _intent = option.$1);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              _CompactSwitch(
                label: l10n.planner_keep_calories,
                value: _keepCalories,
                onChanged: (value) => setState(() => _keepCalories = value),
              ),
              _CompactSwitch(
                label: l10n.planner_keep_time,
                value: _keepTime,
                onChanged: (value) => setState(() => _keepTime = value),
              ),
              _CompactSwitch(
                label: l10n.planner_keep_preferences,
                value: _keepPreferences,
                onChanged: (value) => setState(() => _keepPreferences = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.planner_swap_custom_note,
                  hintText: l10n.planner_swap_note_hint,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 15,
                    color: context.textMutedColor,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    l10n.planner_only_meal_changes,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textMutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final constraints = [
                      if (_keepCalories) 'keep similar calories',
                      if (_keepTime) 'keep similar prep time',
                      if (_keepPreferences) 'respect saved preferences',
                      _noteController.text.trim(),
                    ].where((value) => value.isNotEmpty).join('; ');
                    Navigator.pop(
                      context,
                      PlannerSwapResult(intent: _intent, note: constraints),
                    );
                  },
                  icon: const Icon(LucideIcons.sparkles, size: 18),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text(l10n.planner_find_replacement),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlannerWorkingDialog extends StatelessWidget {
  const PlannerWorkingDialog({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(label, style: AppTypography.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class PlannerMealImage extends StatelessWidget {
  const PlannerMealImage({
    super.key,
    this.meal,
    required this.width,
    required this.height,
    this.assetOverride,
  });
  final Meal? meal;
  final double width;
  final double height;
  final String? assetOverride;

  @override
  Widget build(BuildContext context) {
    final uri = meal?.imageUri;
    Widget image;
    if (assetOverride != null) {
      image = Image.asset(assetOverride!, fit: BoxFit.cover);
    } else if (uri != null && uri.startsWith('http')) {
      image = Image.network(
        uri,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _assetImage(),
      );
    } else if (uri != null && File(uri).existsSync()) {
      image = Image.file(
        File(uri),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _assetImage(),
      );
    } else {
      image = _assetImage();
    }
    return SizedBox(width: width, height: height, child: image);
  }

  Widget _assetImage() {
    final type = (meal?.mealType ?? '').toLowerCase();
    final hour =
        meal == null
            ? 19
            : DateTime.fromMillisecondsSinceEpoch(meal!.timestamp).hour;
    final path =
        type.contains('breakfast') || hour < 11
            ? 'assets/images/paywall/hero_breakfast_scan.png'
            : type.contains('lunch') || hour < 15
            ? 'assets/images/paywall/onboarding_grilled_chicken_bowl.png'
            : type.contains('snack') || hour < 18
            ? 'assets/images/paywall/showcase_plate_1.png'
            : 'assets/images/paywall/hero_dinner_scan.png';
    return Image.asset(path, fit: BoxFit.cover);
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? context.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border:
                selected ? Border.all(color: context.cardBorderColor) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? context.primaryColor : context.textMutedColor,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color:
                      selected
                          ? context.textPrimaryColor
                          : context.textMutedColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color:
            active
                ? context.primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              active
                  ? context.primaryColor.withValues(alpha: 0.55)
                  : context.cardBorderColor,
        ),
      ),
      child: Text(
        'PRO',
        style: AppTypography.labelSmall.copyWith(
          color: active ? context.primaryColor : context.textMutedColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
    );
  }
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({
    required this.label,
    required this.value,
    required this.goal,
  });
  final String label;
  final String value;
  final String goal;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: AppTypography.titleSmall.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            goal.isEmpty ? label : '$label / $goal',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietChip extends StatelessWidget {
  const _QuietChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _GroceryGroup extends StatelessWidget {
  const _GroceryGroup({
    required this.title,
    required this.items,
    required this.onToggle,
  });
  final String title;
  final List<GroceryItem> items;
  final Future<void> Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Column(
              children:
                  items.map((item) {
                    return CheckboxListTile(
                      value: item.isChecked,
                      onChanged: (_) => onToggle(item.id),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        item.name,
                        style: AppTypography.bodyMedium.copyWith(
                          decoration:
                              item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                      secondary: Text(
                        item.amount,
                        style: AppTypography.labelMedium.copyWith(
                          color: context.textMutedColor,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMinus,
            icon: const Icon(LucideIcons.minus, size: 17),
          ),
          Text(
            '$value',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(LucideIcons.plus, size: 17),
          ),
        ],
      ),
    );
  }
}

class _PreparationStep extends StatelessWidget {
  const _PreparationStep({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$number',
              style: AppTypography.labelSmall.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
