import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/water_log.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/activity_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import 'widgets/edit_meal_modal.dart';
import 'widgets/horizontal_day_calendar.dart';
import 'widgets/hydration_sheet.dart';
import 'widgets/meal_list_tile.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider);
    ref.watch(activityProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final proAccess = ref.watch(proAccessProvider);
    final isPro = proAccess.isPro;

    // Stay reactive to meal writes, then read the date the user selected.
    final todayMeals = ref.watch(todaysMealsProvider).valueOrNull;
    final mealRepository = ref.watch(mealRepositoryProvider).valueOrNull;
    final selectedDateMeals =
        mealRepository?.getMealsByDate(selectedDate) ??
        (app_date.DateUtils.isToday(selectedDate)
            ? todayMeals ?? const <Meal>[]
            : const <Meal>[]);

    final summaries = _buildDailySummaries(isPro: isPro);
    final selectedSummary = _summaryFor(
      summaries: summaries,
      selectedDate: selectedDate,
      settings: settings,
      water: water,
    );
    final groups = _groupMeals(context, selectedDateMeals);
    final isToday = app_date.DateUtils.isToday(selectedDate);
    final proteinRemaining = math.max(
      selectedSummary.proteinGoal - selectedSummary.protein,
      0,
    );

    return AppPageScaffold(
      title: '',
      showHeader: false,
      scrollable: false,
      padding: EdgeInsets.zero,
      backgroundColor:
          context.isDarkMode
              ? const Color(0xFF11120F)
              : AppColors.lightBackground,
      child: Stack(
        children: [
          ListView(
            key: const ValueKey('food-log-scroll'),
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 196),
            children: [
              _LogHeader(
                title: l10n.log_title,
                onCalendarTap:
                    () => _showDatePicker(
                      selectedDate: selectedDate,
                      isPro: isPro,
                    ),
                onReportsTap: () => context.go('/reports'),
                onSettingsTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 10),
              HorizontalDayCalendar(
                selectedDate: selectedDate,
                dailySummaries: summaries,
                onDateSelected: (date) {
                  ref.read(selectedDateProvider.notifier).select(date);
                },
                isDateLocked:
                    (date) => !(isPro || app_date.DateUtils.isToday(date)),
                onLockedDateSelected: (_) {
                  PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.settings,
                    featureName: 'history_days',
                  );
                },
              ),
              const SizedBox(height: 14),
              _DailyBalanceCard(summary: selectedSummary),
              const SizedBox(height: 24),
              _SectionHeading(
                title: l10n.home_metric_meals,
                actionLabel: l10n.log_add_manually,
                onAction:
                    () => _showNewMealSheet(
                      dateString: selectedDate,
                      mealType: _suggestedMealType(),
                    ),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < groups.length; index++) ...[
                _MealGroupSection(
                  group: groups[index],
                  isPro: isPro,
                  onAdd:
                      () => _showNewMealSheet(
                        dateString: selectedDate,
                        mealType: groups[index].key,
                      ),
                  onEdit: _showEditMealSheet,
                  onDelete: _deleteMeal,
                ),
                if (index != groups.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              _DailyHealthCard(
                waterMl: selectedSummary.waterMl,
                waterGoal: selectedSummary.waterGoal,
                steps: selectedSummary.steps,
                onWaterTap:
                    isToday
                        ? () => showHydrationSheet(context)
                        : () => context.push('/log/metric/water'),
                onStepsTap: () => context.push('/log/metric/steps'),
              ),
              const SizedBox(height: 10),
              _ProteinInsightTile(
                proteinRemaining: proteinRemaining,
                showUpgrade: proAccess.isFree,
                onTap: () {
                  if (proAccess.isPro) {
                    context.push('/assistant');
                  } else if (proAccess.isFree) {
                    PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.macroDetails,
                      featureName: 'log_protein_insight',
                    );
                  }
                },
              ),
            ],
          ),
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 96,
            child: _LogActionDock(
              onScan: () {
                ref.read(selectedDateProvider.notifier).goToToday();
                context.go('/snap');
              },
              onManual:
                  () => _showNewMealSheet(
                    dateString: selectedDate,
                    mealType: _suggestedMealType(),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker({
    required String selectedDate,
    required bool isPro,
  }) async {
    final now = DateTime.now();
    final firstDate = now.subtract(Duration(days: isPro ? 89 : 13));
    final selected = app_date.DateUtils.parseDate(selectedDate);
    final initialDate = selected.isBefore(firstDate) ? firstDate : selected;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked == null || !mounted) return;

    final dateString = app_date.DateUtils.getDateString(picked);
    if (!isPro && !app_date.DateUtils.isToday(dateString)) {
      PremiumConversionService().openPaywall(
        context,
        PaywallEntryPoint.settings,
        featureName: 'history_days',
      );
      return;
    }
    ref.read(selectedDateProvider.notifier).select(dateString);
  }

  Future<void> _showEditMealSheet(Meal meal) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => EditMealModal(
            meal: meal,
            onSave: (updatedMeal) async {
              Navigator.of(modalContext).pop();
              await ref.read(mealLogProvider.notifier).updateMeal(updatedMeal);
              if (mounted) setState(() {});
            },
            onDelete: () async {
              Navigator.of(modalContext).pop();
              await _deleteMeal(meal);
            },
            onCancel: () => Navigator.of(modalContext).pop(),
          ),
    );
  }

  Future<void> _showNewMealSheet({
    required String dateString,
    required String mealType,
  }) async {
    final now = DateTime.now();
    final date = app_date.DateUtils.parseDate(dateString);
    final eatenAt = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
    );
    final draft = Meal(
      id: 'new',
      timestamp: eatenAt.millisecondsSinceEpoch,
      dateString: dateString,
      foodName: '',
      calories: 0,
      macros: Macros.empty(),
      mealType: mealType,
      portion: '',
    );

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => EditMealModal(
            meal: draft,
            isNew: true,
            onSave: (meal) async {
              Navigator.of(modalContext).pop();
              final savedMeal = meal.copyWith(
                id: ref.read(mealLogProvider.notifier).generateMealId(),
              );
              await ref
                  .read(mealLogProvider.notifier)
                  .addMeal(savedMeal, mealDate: dateString);
              if (mounted) setState(() {});
            },
            onDelete: () => Navigator.of(modalContext).pop(),
            onCancel: () => Navigator.of(modalContext).pop(),
          ),
    );
  }

  Future<void> _deleteMeal(Meal meal) async {
    await ref.read(mealLogProvider.notifier).deleteMeal(meal.id);
    if (mounted) setState(() {});
  }

  List<_MealGroupData> _groupMeals(BuildContext context, List<Meal> meals) {
    final l10n = AppLocalizations.of(context)!;
    final buckets = <String, List<Meal>>{
      'Breakfast': [],
      'Lunch': [],
      'Snack': [],
      'Dinner': [],
    };
    final sorted = [...meals]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (final meal in sorted) {
      buckets[_normalizedMealType(meal)]!.add(meal);
    }

    return [
      _MealGroupData(
        key: 'Breakfast',
        label: l10n.result_meal_breakfast,
        meals: buckets['Breakfast']!,
      ),
      _MealGroupData(
        key: 'Lunch',
        label: l10n.result_meal_lunch,
        meals: buckets['Lunch']!,
      ),
      _MealGroupData(
        key: 'Snack',
        label: l10n.result_meal_snack,
        meals: buckets['Snack']!,
      ),
      _MealGroupData(
        key: 'Dinner',
        label: l10n.result_meal_dinner,
        meals: buckets['Dinner']!,
      ),
    ];
  }

  String _normalizedMealType(Meal meal) {
    final type = meal.mealType?.trim().toLowerCase() ?? '';
    if (type.contains('breakfast')) return 'Breakfast';
    if (type.contains('lunch')) return 'Lunch';
    if (type.contains('dinner')) return 'Dinner';
    if (type.contains('snack')) return 'Snack';

    final hour = DateTime.fromMillisecondsSinceEpoch(meal.timestamp).hour;
    if (hour >= 5 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 16) return 'Lunch';
    if (hour >= 18 && hour < 23) return 'Dinner';
    return 'Snack';
  }

  String _suggestedMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 16) return 'Lunch';
    if (hour >= 18 && hour < 23) return 'Dinner';
    return 'Snack';
  }

  List<DailySummary> _buildDailySummaries({required bool isPro}) {
    final now = DateTime.now();
    final visibleDayCount = isPro ? 90 : 14;
    final todayKey = app_date.DateUtils.getDateString(now);
    final liveSteps = ref.watch(activityProvider).valueOrNull?.steps ?? 0;
    return List.generate(visibleDayCount, (index) {
      final date = now.subtract(Duration(days: visibleDayCount - 1 - index));
      final dateString = app_date.DateUtils.getDateString(date);
      return _buildSummaryForDate(
        dateString: dateString,
        steps: dateString == todayKey ? liveSteps : 0,
      );
    });
  }

  DailySummary _buildSummaryForDate({
    required String dateString,
    int steps = 0,
  }) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? UserSettings.defaults();
    final mealRepository = ref.watch(mealRepositoryProvider).valueOrNull;
    final waterRepository = ref.watch(waterRepositoryProvider).valueOrNull;
    final meals = mealRepository?.getMealsByDate(dateString) ?? const <Meal>[];
    var calories = 0;
    var protein = 0;
    var carbs = 0;
    var fat = 0;
    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.macros.protein;
      carbs += meal.macros.carbs;
      fat += meal.macros.fat;
    }
    final waterMl = (waterRepository?.getWaterByDate(dateString) ??
            const <WaterLog>[])
        .fold<int>(0, (total, entry) => total + entry.amountMl);

    return DailySummary(
      dateString: dateString,
      calories: calories,
      calorieGoal: settings.dailyCalorieGoal,
      protein: protein,
      proteinGoal: settings.dailyProteinGoal,
      carbs: carbs,
      carbGoal: settings.dailyCarbGoal,
      fat: fat,
      fatGoal: settings.dailyFatGoal,
      waterMl: waterMl,
      waterGoal: ref.watch(waterProvider).valueOrNull?.goal ?? 2500,
      steps: steps,
      stepGoal: 10000,
      mealCount: meals.length,
    );
  }

  DailySummary _summaryFor({
    required List<DailySummary> summaries,
    required String selectedDate,
    required AsyncValue<UserSettings> settings,
    required AsyncValue<WaterState> water,
  }) {
    final userSettings = settings.valueOrNull ?? UserSettings.defaults();
    final waterState = water.valueOrNull ?? const WaterState(todayTotal: 0);
    return summaries.firstWhere(
      (summary) => summary.dateString == selectedDate,
      orElse:
          () => DailySummary(
            dateString: selectedDate,
            calories: 0,
            calorieGoal: userSettings.dailyCalorieGoal,
            protein: 0,
            proteinGoal: userSettings.dailyProteinGoal,
            carbs: 0,
            carbGoal: userSettings.dailyCarbGoal,
            fat: 0,
            fatGoal: userSettings.dailyFatGoal,
            waterMl: waterState.todayTotal,
            waterGoal: waterState.goal,
            steps: 0,
            stepGoal: 10000,
            mealCount: 0,
          ),
    );
  }
}

class _LogHeader extends StatelessWidget {
  const _LogHeader({
    required this.title,
    required this.onCalendarTap,
    required this.onReportsTap,
    required this.onSettingsTap,
  });

  final String title;
  final VoidCallback onCalendarTap;
  final VoidCallback onReportsTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 25,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _HeaderIconButton(
            icon: LucideIcons.calendarDays,
            tooltip: l10n.nav_stats,
            onTap: onCalendarTap,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_LogMenuAction>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            color: context.cardColor,
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (action) {
              switch (action) {
                case _LogMenuAction.reports:
                  onReportsTap();
                case _LogMenuAction.settings:
                  onSettingsTap();
              }
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: _LogMenuAction.reports,
                    child: _MenuRow(
                      icon: LucideIcons.barChart3,
                      label: l10n.nav_stats,
                    ),
                  ),
                  PopupMenuItem(
                    value: _LogMenuAction.settings,
                    child: _MenuRow(
                      icon: LucideIcons.settings2,
                      label: l10n.nav_profile,
                    ),
                  ),
                ],
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                LucideIcons.moreHorizontal,
                size: 23,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LogMenuAction { reports, settings }

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: context.textPrimaryColor),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.textSecondaryColor),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _DailyBalanceCard extends StatelessWidget {
  const _DailyBalanceCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = summary.calorieGoal - summary.calories;
    final remainingLabel =
        remaining >= 0
            ? l10n.log_calories_left(_formatInt(context, remaining))
            : l10n.log_calories_over(_formatInt(context, remaining.abs()));
    final accent = remaining >= 0 ? AppColors.primaryDark : AppColors.error;

    return Container(
      key: const ValueKey('daily-balance-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.045)
                : AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.log_daily_balance,
            style: AppTypography.titleMedium.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _formatInt(context, summary.calories),
                          style: AppTypography.displaySmall.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 38,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' / ${_formatInt(context, summary.calorieGoal)} ${l10n.settings_kcal_unit}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  remainingLabel,
                  style: AppTypography.titleSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressLine(
            progress: summary.calorieProgress,
            color: accent,
            height: 7,
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MacroProgress(
                    label: l10n.result_protein,
                    value: summary.protein,
                    goal: summary.proteinGoal,
                    color: AppColors.protein,
                  ),
                ),
                _VerticalRule(color: context.dividerColor),
                Expanded(
                  child: _MacroProgress(
                    label: l10n.result_carbs,
                    value: summary.carbs,
                    goal: summary.carbGoal,
                    color: AppColors.carbs,
                  ),
                ),
                _VerticalRule(color: context.dividerColor),
                Expanded(
                  child: _MacroProgress(
                    label: l10n.result_fat,
                    value: summary.fat,
                    goal: summary.fatGoal,
                    color: AppColors.fat,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondaryColor,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${_formatInt(context, value)} / ${_formatInt(context, goal)}g',
              style: AppTypography.titleSmall.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ProgressLine(
            progress: value / math.max(goal, 1),
            color: color,
            height: 4,
          ),
        ],
      ),
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: color.withValues(alpha: 0.55),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.progress,
    required this.color,
    required this.height,
  });

  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFE4E5E1),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: Text(actionLabel),
          style: TextButton.styleFrom(
            foregroundColor: context.primaryColor,
            minimumSize: const Size(44, 40),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _MealGroupData {
  const _MealGroupData({
    required this.key,
    required this.label,
    required this.meals,
  });

  final String key;
  final String label;
  final List<Meal> meals;
}

class _MealGroupSection extends StatelessWidget {
  const _MealGroupSection({
    required this.group,
    required this.isPro,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final _MealGroupData group;
  final bool isPro;
  final VoidCallback onAdd;
  final ValueChanged<Meal> onEdit;
  final ValueChanged<Meal> onDelete;

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        group.meals.length == 1
            ? DateFormat.j(AppLocalizations.of(context)!.localeName).format(
              DateTime.fromMillisecondsSinceEpoch(group.meals.first.timestamp),
            )
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              group.label,
              style: AppTypography.titleMedium.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: 12),
              Text(
                timeLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: context.textMutedColor,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        if (group.meals.isEmpty)
          _EmptyMealSlot(label: group.label, onTap: onAdd)
        else
          Container(
            decoration: BoxDecoration(
              color:
                  context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.025)
                      : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: context.dividerColor.withValues(alpha: 0.55),
                ),
              ),
            ),
            child: Column(
              children: [
                for (var index = 0; index < group.meals.length; index++)
                  MealListTile(
                    meal: group.meals[index],
                    isPro: isPro,
                    showTime: group.meals.length > 1,
                    showDivider: index != group.meals.length - 1,
                    onTap: () => onEdit(group.meals[index]),
                    onDelete: () => onDelete(group.meals[index]),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyMealSlot extends StatelessWidget {
  const _EmptyMealSlot({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.log_add_meal_type(label),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: context.textMutedColor.withValues(alpha: 0.45),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  LucideIcons.plusCircle,
                  size: 20,
                  color: context.primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.log_add_meal_type(label),
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
        );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 5, metric.length)),
          paint,
        );
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DailyHealthCard extends StatelessWidget {
  const _DailyHealthCard({
    required this.waterMl,
    required this.waterGoal,
    required this.steps,
    required this.onWaterTap,
    required this.onStepsTap,
  });

  final int waterMl;
  final int waterGoal;
  final int steps;
  final VoidCallback onWaterTap;
  final VoidCallback onStepsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.log_daily_health,
          style: AppTypography.titleMedium.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 76,
          decoration: BoxDecoration(
            color:
                context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.035)
                    : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: _HealthValue(
                  icon: LucideIcons.droplets,
                  label: l10n.log_metric_water,
                  value:
                      '${_formatLiters(context, waterMl)} / ${_formatLiters(context, waterGoal)} L',
                  onTap: onWaterTap,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: context.dividerColor.withValues(alpha: 0.65),
              ),
              Expanded(
                child: _HealthValue(
                  icon: LucideIcons.footprints,
                  label: l10n.log_metric_steps,
                  value: _formatInt(context, steps),
                  onTap: onStepsTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthValue extends StatelessWidget {
  const _HealthValue({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 19, color: context.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      style: AppTypography.titleMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
}

class _ProteinInsightTile extends StatelessWidget {
  const _ProteinInsightTile({
    required this.proteinRemaining,
    required this.showUpgrade,
    required this.onTap,
  });

  final int proteinRemaining;
  final bool showUpgrade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label =
        proteinRemaining > 0
            ? l10n.log_protein_left_today(_formatInt(context, proteinRemaining))
            : l10n.log_protein_goal_met_today;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.035)
                    : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.messageSquare,
                size: 20,
                color: context.primaryColor,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      showUpgrade
                          ? Colors.transparent
                          : context.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  'PRO',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

class _LogActionDock extends StatelessWidget {
  const _LogActionDock({required this.onScan, required this.onManual});

  final VoidCallback onScan;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? const Color(0xF21B1C19)
                : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.22 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showManualLabel = constraints.maxWidth >= 340;
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const ValueKey('log-scan-meal'),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onScan();
                    },
                    icon: const Icon(LucideIcons.scanLine, size: 20),
                    label: Text(l10n.log_scan_meal),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (showManualLabel)
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      key: const ValueKey('log-add-manually'),
                      onPressed: onManual,
                      icon: const Icon(LucideIcons.pencil, size: 18),
                      label: Text(
                        l10n.log_add_manually,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.primaryColor,
                        side: BorderSide(color: context.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Tooltip(
                  message: l10n.log_add_manually,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                      key: const ValueKey('log-add-manually'),
                      onPressed: onManual,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.primaryColor,
                        side: BorderSide(color: context.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(LucideIcons.pencil, size: 18),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _formatInt(BuildContext context, int value) {
  return NumberFormat.decimalPattern(
    AppLocalizations.of(context)?.localeName,
  ).format(value);
}

String _formatLiters(BuildContext context, int valueMl) {
  return NumberFormat(
    '0.#',
    AppLocalizations.of(context)?.localeName,
  ).format(valueMl / 1000);
}
