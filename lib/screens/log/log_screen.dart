import '../../providers/calorie_budget_provider.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/custom_food_sheet.dart';
import 'widgets/edit_meal_modal.dart';
import 'widgets/horizontal_day_calendar.dart';
import 'widgets/hydration_sheet.dart';
import 'widgets/meal_list_tile.dart';
import 'widgets/quick_add_foods.dart';
import 'widgets/routines_carousel.dart';
import 'widgets/save_routine_sheet.dart';
import '../../core/theme/app_motion.dart';
import '../../widgets/motion/arriving_item.dart';
import '../../widgets/motion/count_up_text.dart';
import '../../widgets/motion/delta_bubble.dart';
import '../../widgets/app_toast.dart';
import '../../data/models/meal_template.dart';
import '../../providers/template_provider.dart';

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

  /// Meals deleted from the edit sheet, sliding out of the list before
  /// their Undo shows.
  final Set<String> _leaving = {};

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
    // Today's goal and "left" match Home's, walking calories included.
    final budget = ref.watch(calorieBudgetProvider);
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
              const SizedBox(height: 18),
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
                  onCustomFood:
                      (name) => _showCustomFood(
                        dateString: selectedDate,
                        mealType: _suggestedMealType(),
                        name: name,
                      ),
                  // Saved routines come first, the newest leading.
                  leading: [
                    for (final routine in _orderedRoutines())
                      RoutineCard(
                        key: ValueKey('routine-card-${routine.id}'),
                        template: routine,
                        isNew: routine.id == _newRoutineId,
                        onLog: () => _logRoutine(routine, selectedDate),
                        onOptions: () => showRoutineOptions(context, routine),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
              _MealsHeading(
                title: l10n.home_metric_meals,
                announceChange: sameDay,
                calories: selectedSummary.calories,
                calorieGoal:
                    isToday ? budget.goal : selectedSummary.calorieGoal,
                activityBonus: isToday ? budget.activityBonus : 0,
              ),
              const SizedBox(height: 8),
              _DaySwitch(
                day: selectedDate,
                direction: _dayDirection,
                child: _MealDiaryCard(
                  groups: groups,
                  arrived: arrived,
                  leaving: _leaving,
                  onLeft: _left,
                  isPro: isPro,
                  onAdd:
                      (mealType) => _showCustomFood(
                        dateString: selectedDate,
                        mealType: mealType,
                      ),
                  onEdit: _showEditMealSheet,
                  onDelete: _deleteWithUndo,
                  onSaveRoutine: _saveRoutine,
                ),
              ),
              const SizedBox(height: 12),
              _DailyHealthCard(
                waterMl: selectedSummary.waterMl,
                waterGoal: selectedSummary.waterGoal,
                steps: selectedSummary.steps,
                onWaterTap:
                    isToday
                        ? () => showHydrationSheet(context)
                        : () => context.push('/log/metric/water'),
                onStepsTap: () => context.push('/log/metric/steps'),
                protein:
                    proAccess.isPro
                        ? _ProteinInsightTile(
                          proteinRemaining: proteinRemaining,
                          onTap: () => context.push('/assistant'),
                        )
                        : null,
              ),
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
            onDelete: () {
              Navigator.of(modalContext).pop();
              _leaveThenDelete(meal);
            },
            onCancel: () => Navigator.of(modalContext).pop(),
          ),
    );
  }

  /// The short form for a food of the user's own. The food lands in the
  /// meal chosen there, with Undo.
  Future<void> _showCustomFood({
    required String dateString,
    required String mealType,
    String name = '',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final mealLog = ref.read(mealLogProvider.notifier);
    final entry = await showCustomFoodSheet(
      context,
      initialName: name,
      mealType: mealType,
    );
    if (entry == null || !mounted) return;
    final meal = Meal(
      id: mealLog.generateMealId(),
      timestamp: _mealTimestamp(dateString),
      dateString: dateString,
      foodName: entry.name,
      calories: entry.calories,
      macros: Macros(
        protein: entry.protein,
        carbs: entry.carbs,
        fat: entry.fat,
      ),
      mealType: entry.mealType,
      portion: entry.portion,
    );
    await mealLog.addMeal(meal, mealDate: dateString);
    if (!mounted) return;
    setState(() {});
    messenger.hideCurrentSnackBar();
    showAppToast(
      messenger,
      kind: ToastKind.success,
      title: l10n.quick_add_added(meal.foodName),
      actionLabel: l10n.quick_add_undo,
      onAction: () => mealLog.deleteMeal(meal.id),
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

  /// A meal deleted from its sheet slides out once the sheet has dropped,
  /// then goes the way a swiped one does, with Undo.
  Future<void> _leaveThenDelete(Meal meal) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _leaving.add(meal.id));
  }

  void _left(Meal meal) {
    if (!mounted || !_leaving.remove(meal.id)) return;
    _deleteWithUndo(meal);
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
    showAppToast(
      messenger,
      kind: ToastKind.undo,
      title: l10n.log_meal_deleted,
      detail: meal.foodName,
      actionLabel: l10n.result_undo,
    ).closed.then((reason) async {
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

  /// The routine saved most recently here, which shows a "New" tag.
  String? _newRoutineId;

  List<MealTemplate> _orderedRoutines() {
    final routines = [
      ...ref.watch(templatesProvider).valueOrNull ?? const <MealTemplate>[],
    ];
    routines.sort((a, b) {
      if (a.id == _newRoutineId) return -1;
      if (b.id == _newRoutineId) return 1;
      final used = b.usageCount.compareTo(a.usageCount);
      return used != 0 ? used : b.createdAt.compareTo(a.createdAt);
    });
    return routines;
  }

  Future<void> _saveRoutine(_MealGroupData group) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showSaveRoutineSheet(
      context,
      meals: group.meals,
      mealType: group.key,
      mealLabel: group.label,
    );
    if (saved == null || !mounted) return;
    setState(() => _newRoutineId = saved.id);
    showAppToast(
      messenger,
      kind: ToastKind.success,
      icon: WaznIcons.bookmarkPlus,
      title: l10n.routine_saved,
      detail: '${saved.emoji} ${saved.name}',
    );
  }

  /// Logs every food in [routine] on [dateString] at once, into the meal it
  /// was saved from, with one Undo for all of them.
  Future<void> _logRoutine(MealTemplate routine, String dateString) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final mealLog = ref.read(mealLogProvider.notifier);
    HapticFeedback.mediumImpact();
    final mealType = routine.mealType ?? _suggestedMealType();
    final ids = await ref
        .read(templatesProvider.notifier)
        .logFromTemplate(routine, dateString: dateString, mealType: mealType);
    if (!mounted) return;
    final label = switch (mealType) {
      'Breakfast' => l10n.result_meal_breakfast,
      'Lunch' => l10n.result_meal_lunch,
      'Dinner' => l10n.result_meal_dinner,
      _ => l10n.result_meal_snack,
    };
    showAppToast(
      messenger,
      kind: ToastKind.success,
      title: l10n.routine_logged,
      detail: l10n.routine_logged_detail(ids.length, label),
      actionLabel: l10n.result_undo,
      onAction: () async {
        for (final id in ids) {
          await mealLog.deleteMeal(id);
        }
      },
    );
  }

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

/// "Meals", with the day's total beside it on one quiet line and a thin
/// bar under it. The big day summary lives on Home; this line keeps the
/// total in view when looking back at other days.
class _MealsHeading extends StatelessWidget {
  const _MealsHeading({
    required this.title,
    this.announceChange = true,
    required this.calories,
    required this.calorieGoal,
    this.activityBonus = 0,
  });

  final String title;

  /// Walking calories already in [calorieGoal], named under the bar.
  final int activityBonus;

  /// Whether a change in [calories] floats up as "+190" or "−610": yes for
  /// a meal added or removed, no for switching days.
  final bool announceChange;
  final int calories;
  final int calorieGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress =
        calorieGoal <= 0 ? 0.0 : (calories / calorieGoal).clamp(0.0, 1.0);
    final over = calorieGoal > 0 && calories > calorieGoal;
    final remaining = (calorieGoal - calories).abs();
    final accent = over ? AppColors.warning : context.primaryColor;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // The day's total counts to each new value, with the change
                // floating up above it.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DefaultTextStyle.merge(
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textMutedColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
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
                              '${l10n.settings_kcal_unit} · ',
                            ),
                            Text(
                              over
                                  ? l10n.log_calories_over(
                                    _formatInt(context, remaining),
                                  )
                                  : l10n.log_calories_left(
                                    _formatInt(context, remaining),
                                  ),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: -24,
                      end: 0,
                      child: DeltaBubble(
                        value: calories,
                        announce: announceChange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: AppMotion.maybeZero(context, AppMotion.count),
                      curve: Curves.easeOutCubic,
                      builder:
                          (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
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
                if (activityBonus > 0) ...[
                  const SizedBox(height: 5),
                  Text(
                    l10n.home_goal_activity_bonus(activityBonus),
                    key: const ValueKey('log-activity-bonus'),
                    style: AppTypography.labelSmall.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The day's meals in one card, split by thin lines: each meal's name, its
/// calorie total and a single plus, with its foods under it.
class _MealDiaryCard extends StatelessWidget {
  const _MealDiaryCard({
    required this.groups,
    this.arrived = const {},
    this.leaving = const {},
    required this.onLeft,
    required this.isPro,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onSaveRoutine,
  });

  final List<_MealGroupData> groups;

  /// Saves a meal's foods as a routine.
  final ValueChanged<_MealGroupData> onSaveRoutine;

  /// Meals that have just appeared, which slide in.
  final Set<String> arrived;

  /// Meals on their way out, which slide away.
  final Set<String> leaving;
  final ValueChanged<Meal> onLeft;
  final bool isPro;
  final ValueChanged<String> onAdd;
  final ValueChanged<Meal> onEdit;
  final ValueChanged<Meal> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('log-meal-diary'),
      clipBehavior: Clip.antiAlias,
      decoration: _softCard(context),
      child: Column(
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            if (index != 0)
              Divider(
                height: 1,
                thickness: 1,
                color: context.dividerColor.withValues(alpha: 0.35),
              ),
            _MealGroupSection(
              group: groups[index],
              arrived: arrived,
              leaving: leaving,
              onLeft: onLeft,
              isPro: isPro,
              onAdd: () => onAdd(groups[index].key),
              onSaveRoutine: () => onSaveRoutine(groups[index]),
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ],
      ),
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
    required this.onSaveRoutine,
    this.arrived = const {},
    this.leaving = const {},
    required this.onLeft,
    required this.isPro,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onSaveRoutine;
  final _MealGroupData group;
  final Set<String> arrived;
  final Set<String> leaving;
  final ValueChanged<Meal> onLeft;
  final bool isPro;
  final VoidCallback onAdd;
  final ValueChanged<Meal> onEdit;
  final ValueChanged<Meal> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEmpty = group.meals.isEmpty;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Icon(
                  group.icon,
                  size: 18,
                  color:
                      isEmpty
                          ? group.accent.withValues(alpha: 0.6)
                          : group.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.label,
                    style: AppTypography.titleMedium.copyWith(
                      color:
                          isEmpty
                              ? context.textMutedColor
                              : context.textPrimaryColor,
                      fontWeight: isEmpty ? FontWeight.w600 : FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isEmpty)
                  CountUpText(
                    value: group.calories,
                    duration: const Duration(milliseconds: 700),
                    format: (v) => _formatInt(context, v),
                    style: AppTypography.titleSmall.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                if (!isEmpty)
                  Text(
                    ' ${l10n.settings_kcal_unit}',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textMutedColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                IconButton(
                  key: ValueKey('log-add-${group.key.toLowerCase()}'),
                  tooltip: l10n.log_add_meal_type(group.label),
                  onPressed: onAdd,
                  color: context.primaryColor,
                  iconSize: 20,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(WaznIcons.plus),
                ),
              ],
            ),
          ),
          if (!isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 28, end: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < group.meals.length; index++)
                    ArrivingItem(
                      key: ValueKey('log-meal-${group.meals[index].id}'),
                      arrived: arrived.contains(group.meals[index].id),
                      leaving: leaving.contains(group.meals[index].id),
                      onLeft: () => onLeft(group.meals[index]),
                      child: MealListTile(
                        meal: group.meals[index],
                        isPro: isPro,
                        compact: true,
                        showTime: true,
                        onTap: () => onEdit(group.meals[index]),
                        onDelete: () => onDelete(group.meals[index]),
                      ),
                    ),
                  // Worth saving once a meal has a few foods in it.
                  if (group.meals.length >= 2)
                    TextButton.icon(
                      key: ValueKey('log-save-${group.key.toLowerCase()}'),
                      onPressed: onSaveRoutine,
                      icon: const Icon(WaznIcons.bookmarkPlus, size: 15),
                      label: Text(l10n.routine_save_as),
                      style: TextButton.styleFrom(
                        foregroundColor: context.textSecondaryColor,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          0,
                          0,
                          10,
                          0,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Water and steps side by side in one card, with the Pro protein line
/// under them when there is one.
class _DailyHealthCard extends StatelessWidget {
  const _DailyHealthCard({
    required this.waterMl,
    required this.waterGoal,
    required this.steps,
    required this.onWaterTap,
    required this.onStepsTap,
    this.protein,
  });

  final int waterMl;
  final int waterGoal;
  final int steps;
  final VoidCallback onWaterTap;
  final VoidCallback onStepsTap;
  final Widget? protein;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = context.dividerColor.withValues(alpha: 0.35);
    return Container(
      key: const ValueKey('log-health-card'),
      clipBehavior: Clip.antiAlias,
      decoration: _softCard(context),
      child: Column(
        children: [
          SizedBox(
            height: 68,
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
                Container(width: 1, height: 40, color: line),
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
          if (protein != null) ...[
            Divider(height: 1, thickness: 1, color: line),
            protein!,
          ],
        ],
      ),
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
    required this.onTap,
  });

  final int proteinRemaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label =
        proteinRemaining > 0
            ? l10n.log_protein_left_today(_formatInt(context, proteinRemaining))
            : l10n.log_protein_goal_met_today;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(WaznIcons.coach, size: 18, color: context.primaryColor),
            const SizedBox(width: 10),
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
                color: context.primaryColor.withValues(alpha: 0.08),
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
            const SizedBox(width: 6),
            Icon(
              WaznIcons.chevronRight,
              size: 18,
              color: context.textMutedColor,
            ),
          ],
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
