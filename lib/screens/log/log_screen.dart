import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../data/services/pro_feature_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../widgets/wazn_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../data/models/quick_food.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/water_log.dart';
import '../../core/services/config_service.dart';
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
import 'widgets/quick_add_foods.dart';
import '../../core/theme/app_motion.dart';
import '../../widgets/motion/arriving_item.dart';
import '../../widgets/motion/count_up_text.dart';
import '../../widgets/motion/delta_bubble.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  /// The day and meal ids of the last build, to tell a meal that just
  /// arrived from one that was already there.
  String? _lastDate;
  Set<String> _lastIds = const {};
  bool _lastLoaded = false;

  /// 1 when the day picked is later than the last, -1 when earlier.
  int _dayDirection = 1;

  /// Meals swiped away whose Undo is still on screen: hidden from the list,
  /// not yet deleted.
  final Set<String> _pendingDeletes = {};

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
    final allMeals =
        mealRepository?.getAllMeals() ?? todayMeals ?? const <Meal>[];

    final summaries = _buildDailySummaries(isPro: isPro);
    final selectedSummary = _summaryFor(
      summaries: summaries,
      selectedDate: selectedDate,
      settings: settings,
      water: water,
    );
    final groups = _groupMeals(
      context,
      selectedDateMeals.where((m) => !_pendingDeletes.contains(m.id)).toList(),
    );
    // Meals that appeared since the last build of the same day -- added, or
    // brought back by Undo -- slide into place. Switching days slides the
    // whole diary instead.
    final visibleIds = {
      for (final group in groups)
        for (final meal in group.meals) meal.id,
    };
    final sameDay = _lastDate == selectedDate;
    // Meals showing up as the day first loads are not arrivals.
    final loaded = mealRepository != null || todayMeals != null;
    final arrived =
        sameDay && _lastLoaded
            ? visibleIds.difference(_lastIds)
            : const <String>{};
    _lastLoaded = loaded;
    if (_lastDate != null && !sameDay) {
      _dayDirection = selectedDate.compareTo(_lastDate!) > 0 ? 1 : -1;
    }
    _lastDate = selectedDate;
    _lastIds = visibleIds;
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
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
                    (date) =>
                        !ProFeatureService.canViewHistoryDate(
                          date,
                          isPro: isPro,
                        ),
                onLockedDateSelected: (_) {
                  PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.settings,
                    featureName: 'history_days',
                  );
                },
              ),
              const SizedBox(height: 20),
              if (ConfigService().quickFoodsEnabled) ...[
                QuickAddFoods(
                  meals: allMeals,
                  mealType: _suggestedMealType(),
                  cuisinePreference:
                      settings.valueOrNull?.cuisinePreference ??
                      'international',
                  onAddCatalogFood:
                      (food, grams) => _addQuickFood(
                        food: food,
                        grams: grams,
                        dateString: selectedDate,
                        mealType: _suggestedMealType(),
                      ),
                  onRepeatMeal:
                      (meal) => _repeatMeal(
                        meal,
                        dateString: selectedDate,
                        mealType: _suggestedMealType(),
                      ),
                  onUndo:
                      (mealId) =>
                          ref.read(mealLogProvider.notifier).deleteMeal(mealId),
                ),
                const SizedBox(height: 24),
              ],
              _SectionHeading(
                title: l10n.home_metric_meals,
                announceChange: sameDay,
                calories: selectedSummary.calories,
                calorieGoal: selectedSummary.calorieGoal,
                actionLabel: l10n.log_add_manually,
                onAction:
                    () => _showNewMealSheet(
                      dateString: selectedDate,
                      mealType: _suggestedMealType(),
                    ),
              ),
              const SizedBox(height: 10),
              _DaySwitch(
                day: selectedDate,
                direction: _dayDirection,
                child: _MealDiaryCard(
                  groups: groups,
                  arrived: arrived,
                  isPro: isPro,
                  onAdd:
                      (mealType) => _showNewMealSheet(
                        dateString: selectedDate,
                        mealType: mealType,
                      ),
                  onEdit: _showEditMealSheet,
                  onDelete: _deleteWithUndo,
                ),
              ),
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
              if (proAccess.isPro) ...[
                const SizedBox(height: 10),
                _ProteinInsightTile(
                  proteinRemaining: proteinRemaining,
                  showUpgrade: false,
                  onTap: () => context.push('/assistant'),
                ),
              ],
            ],
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
    final firstDate =
        isPro
            ? DateTime(2000)
            : DateTime(
              now.year,
              now.month,
              now.day - (ProFeatureService.freeHistoryDays - 1),
            );
    final selected = app_date.DateUtils.parseDate(selectedDate);
    final initialDate = selected.isBefore(firstDate) ? firstDate : selected;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now,
      switchToInputEntryModeIcon: const Icon(WaznIcons.edit),
      switchToCalendarEntryModeIcon: const Icon(WaznIcons.calendar),
    );
    if (picked == null || !mounted) return;

    final dateString = app_date.DateUtils.getDateString(picked);
    if (!ProFeatureService.canViewHistoryDate(dateString, isPro: isPro)) {
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

  Future<Meal> _addQuickFood({
    required QuickFood food,
    required double grams,
    required String dateString,
    required String mealType,
  }) async {
    final meal = Meal(
      id: ref.read(mealLogProvider.notifier).generateMealId(),
      timestamp: _mealTimestamp(dateString),
      dateString: dateString,
      foodName: food.displayName(Localizations.localeOf(context).languageCode),
      calories: food.caloriesFor(grams),
      macros: food.macrosFor(grams),
      mealType: mealType,
      portion: AppLocalizations.of(context)!.quick_add_grams(grams.round()),
      scanSource: 'quick_add',
      weightG: grams,
      nutritionMatchId: food.nutritionId,
      nutritionPer100g: food.nutritionPer100g,
    );
    await ref
        .read(mealLogProvider.notifier)
        .addMeal(meal, mealDate: dateString);
    if (mounted) setState(() {});
    return meal;
  }

  Future<Meal> _repeatMeal(
    Meal source, {
    required String dateString,
    required String mealType,
  }) async {
    // A repeated meal is a fresh snapshot. Its nutrition and portion are
    // preserved, but an old local photo path is deliberately not copied.
    final meal = Meal(
      id: ref.read(mealLogProvider.notifier).generateMealId(),
      timestamp: _mealTimestamp(dateString),
      dateString: dateString,
      foodName: source.foodName,
      calories: source.calories,
      macros: source.macros.copyWith(),
      mealType: mealType,
      portion: source.portion,
      scanSource: 'quick_repeat',
      originalCalories: source.originalCalories,
      userCorrected: source.userCorrected,
      weightG: source.weightG,
      nutritionMatchId: source.nutritionMatchId,
      nutritionPer100g:
          source.nutritionPer100g == null
              ? null
              : Map<String, dynamic>.from(source.nutritionPer100g!),
    );
    await ref
        .read(mealLogProvider.notifier)
        .addMeal(meal, mealDate: dateString);
    if (mounted) setState(() {});
    return meal;
  }

  int _mealTimestamp(String dateString) {
    final date = app_date.DateUtils.parseDate(dateString);
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    ).millisecondsSinceEpoch;
  }

  Future<void> _deleteMeal(Meal meal) async {
    await ref.read(mealLogProvider.notifier).deleteMeal(meal.id);
    if (mounted) setState(() {});
  }

  /// A swipe deleted the meal on the spot, with no way back from a slip of
  /// the thumb. The meal now leaves the list at once and is deleted when the
  /// Undo snackbar goes: undone in time, it was never deleted at all -- nor
  /// synced as deleted to the user's other devices.
  void _deleteWithUndo(Meal meal) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final mealLog = ref.read(mealLogProvider.notifier);
    setState(() => _pendingDeletes.add(meal.id));

    // A second swipe closes the first snackbar, which deletes its meal.
    messenger.hideCurrentSnackBar();
    messenger
        .showSnackBar(
          SnackBar(
            content: _UndoCountdown(
              text: l10n.log_meal_deleted,
              duration: const Duration(seconds: 4),
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: l10n.result_undo, onPressed: () {}),
          ),
        )
        .closed
        .then((reason) async {
          if (reason != SnackBarClosedReason.action) {
            await mealLog.deleteMeal(meal.id);
          }
          _pendingDeletes.remove(meal.id);
          if (mounted) setState(() {});
        });
  }

  List<_MealGroupData> _groupMeals(BuildContext context, List<Meal> meals) {
    final l10n = AppLocalizations.of(context)!;
    final buckets = <String, List<Meal>>{
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snack': [],
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
        key: 'Dinner',
        label: l10n.result_meal_dinner,
        meals: buckets['Dinner']!,
      ),
      _MealGroupData(
        key: 'Snack',
        label: l10n.result_meal_snack,
        meals: buckets['Snack']!,
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

  String _suggestedMealType() => app_date.DateUtils.suggestedMealType();

  List<DailySummary> _buildDailySummaries({required bool isPro}) {
    final now = DateTime.now();
    final visibleDayCount = isPro ? 90 : 14;
    final todayKey = app_date.DateUtils.getDateString(now);
    final liveSteps = ref.watch(activityProvider).valueOrNull?.steps ?? 0;
    return List.generate(visibleDayCount, (index) {
      final date = app_date.DateUtils.addDays(
        now,
        -(visibleDayCount - 1 - index),
      );
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
    return summaries.firstWhere(
      (summary) => summary.dateString == selectedDate,
      orElse: () => _buildSummaryForDate(dateString: selectedDate),
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
            icon: WaznIcons.calendar,
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
                      icon: WaznIcons.stats,
                      label: l10n.nav_stats,
                    ),
                  ),
                  PopupMenuItem(
                    value: _LogMenuAction.settings,
                    child: _MenuRow(
                      icon: WaznIcons.settings,
                      label: l10n.nav_profile,
                    ),
                  ),
                ],
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                WaznIcons.more,
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

/// The raised surface shared by the Food Log's cards: no hard outline, a
/// soft shadow in light mode and a faint lift in dark mode.
BoxDecoration _softCard(BuildContext context, {double radius = 18}) {
  final dark = context.isDarkMode;
  return BoxDecoration(
    color: dark ? Colors.white.withValues(alpha: 0.045) : AppColors.cardBg,
    borderRadius: BorderRadius.circular(radius),
    border:
        dark ? Border.all(color: Colors.white.withValues(alpha: 0.06)) : null,
    boxShadow:
        dark
            ? null
            : [
              BoxShadow(
                color: const Color(0xFF16181D).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.announceChange = true,
    required this.calories,
    required this.calorieGoal,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;

  /// Whether a change in [calories] floats up as "+190" or "−610": yes for
  /// a meal added or removed, no for switching days.
  final bool announceChange;
  final int calories;
  final int calorieGoal;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress =
        calorieGoal <= 0 ? 0.0 : (calories / calorieGoal).clamp(0.0, 1.0);
    final over = calorieGoal > 0 && calories > calorieGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              key: const ValueKey('log-add-manually'),
              onPressed: onAction,
              icon: const Icon(WaznIcons.plus, size: 16),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: context.primaryColor,
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: const StadiumBorder(),
                textStyle: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: AppMotion.maybeZero(context, AppMotion.count),
                  curve: Curves.easeOutCubic,
                  builder:
                      (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: context.primaryColor.withValues(
                          alpha: 0.12,
                        ),
                        valueColor: AlwaysStoppedAnimation(
                          over ? AppColors.warning : context.primaryColor,
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // The day's total counts to each new value, with the change
            // floating up above it.
            Stack(
              clipBehavior: Clip.none,
              children: [
                DefaultTextStyle.merge(
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMutedColor,
                    fontSize: 12,
                  ),
                  child: Row(
                    key: const ValueKey('log-day-total'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountUpText(
                        value: calories,
                        format: (v) => _formatInt(context, v),
                        duration: const Duration(milliseconds: 700),
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' / ${_formatInt(context, calorieGoal)} '
                        '${l10n.settings_kcal_unit}',
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  top: -24,
                  end: 0,
                  child: DeltaBubble(value: calories, announce: announceChange),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// The day's meals as a stack of cards, one per meal: an icon, the meal's
/// calorie total and an add button, with that meal's entries under it.
class _MealDiaryCard extends StatelessWidget {
  const _MealDiaryCard({
    required this.groups,
    this.arrived = const {},
    required this.isPro,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_MealGroupData> groups;

  /// Meals that have just appeared, which slide in.
  final Set<String> arrived;
  final bool isPro;
  final ValueChanged<String> onAdd;
  final ValueChanged<Meal> onEdit;
  final ValueChanged<Meal> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('log-meal-diary'),
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          if (index != 0) const SizedBox(height: 12),
          _MealGroupSection(
            group: groups[index],
            arrived: arrived,
            isPro: isPro,
            onAdd: () => onAdd(groups[index].key),
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ],
    );
  }
}

/// The day's diary, gliding in from the side of the day picked: a later day
/// comes in from the right, an earlier one from the left.
class _DaySwitch extends StatelessWidget {
  const _DaySwitch({
    required this.day,
    required this.direction,
    required this.child,
  });

  final String day;
  final int direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shift = 28.0 * direction * (rtl ? -1 : 1);
    return AnimatedSwitcher(
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 320)),
      reverseDuration: AppMotion.maybeZero(
        context,
        const Duration(milliseconds: 160),
      ),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      layoutBuilder:
          (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(day);
        final dx = incoming ? shift : -shift;
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder:
                (context, child) => Transform.translate(
                  offset: Offset(dx * (1 - animation.value), 0),
                  child: child,
                ),
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(day), child: child),
    );
  }
}

/// The snackbar's message with a thin line under it that runs down over the
/// time left to undo.
class _UndoCountdown extends StatelessWidget {
  const _UndoCountdown({required this.text, required this.duration});

  final String text;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: duration,
          builder:
              (context, left, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: left,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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

  int get calories => meals.fold(0, (total, meal) => total + meal.calories);

  IconData get icon => switch (key) {
    'Breakfast' => WaznIcons.breakfast,
    'Lunch' => WaznIcons.lunch,
    'Dinner' => WaznIcons.dinner,
    _ => WaznIcons.snack,
  };

  Color get accent => switch (key) {
    'Breakfast' => AppColors.warning,
    'Lunch' => AppColors.primary,
    'Dinner' => AppColors.secondary,
    _ => AppColors.fat,
  };
}

class _MealGroupSection extends StatelessWidget {
  const _MealGroupSection({
    required this.group,
    this.arrived = const {},
    required this.isPro,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final _MealGroupData group;
  final Set<String> arrived;
  final bool isPro;
  final VoidCallback onAdd;
  final ValueChanged<Meal> onEdit;
  final ValueChanged<Meal> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEmpty = group.meals.isEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _softCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: group.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(group.icon, size: 19, color: group.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: AppTypography.titleMedium.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      CountUpText(
                        value: group.calories,
                        duration: const Duration(milliseconds: 700),
                        format:
                            (v) =>
                                '${_formatInt(context, v)} '
                                '${l10n.settings_kcal_unit}',
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isEmpty
                                  ? context.textMutedColor
                                  : context.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: ValueKey('log-add-${group.key.toLowerCase()}'),
                  tooltip: l10n.log_add_meal_type(group.label),
                  onPressed: onAdd,
                  style: IconButton.styleFrom(
                    backgroundColor: context.primaryColor.withValues(
                      alpha: 0.10,
                    ),
                    foregroundColor: context.primaryColor,
                    minimumSize: const Size(40, 40),
                  ),
                  icon: const Icon(WaznIcons.plus, size: 20),
                ),
              ],
            ),
          ),
          if (!isEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              indent: 14,
              endIndent: 14,
              color: context.dividerColor.withValues(alpha: 0.35),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 10, 4),
              child: Column(
                children: [
                  for (var index = 0; index < group.meals.length; index++)
                    ArrivingItem(
                      key: ValueKey('log-meal-${group.meals[index].id}'),
                      arrived: arrived.contains(group.meals[index].id),
                      child: MealListTile(
                        meal: group.meals[index],
                        isPro: isPro,
                        showTime: true,
                        showDivider: index != group.meals.length - 1,
                        onTap: () => onEdit(group.meals[index]),
                        onDelete: () => onDelete(group.meals[index]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
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
          decoration: _softCard(context),
          child: Row(
            children: [
              Expanded(
                child: _HealthValue(
                  icon: WaznIcons.water,
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
                  icon: WaznIcons.steps,
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
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: context.primaryColor),
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: _softCard(context),
          child: Row(
            children: [
              Icon(WaznIcons.coach, size: 20, color: context.primaryColor),
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
                WaznIcons.chevronRight,
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
