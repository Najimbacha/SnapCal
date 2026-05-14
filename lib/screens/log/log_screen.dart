import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../data/models/meal_template.dart';
import '../../providers/meal_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/edit_meal_modal.dart';
import 'widgets/horizontal_day_calendar.dart';
import 'widgets/save_routine_sheet.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<Animation<double>> _itemAnims = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    for (int i = 0; i < 6; i++) {
      _itemAnims.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1, (i * 0.1) + 0.4, curve: Curves.easeOutQuart),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().loadMealsForDate(
        app_date.DateUtils.getTodayString(),
      );
      _animController.forward();
    });
  }

  void _showEditModal(Meal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: EditMealModal(
              meal: meal,
              onSave: (updatedMeal) async {
                Navigator.pop(context);
                await context.read<MealProvider>().updateMeal(updatedMeal);
              },
              onCancel: () => Navigator.pop(context),
              onDelete: () async {
                Navigator.pop(context);
                await context.read<MealProvider>().deleteMeal(
                  meal.id,
                  settings: context.read<SettingsProvider>(),
                );
              },
            ),
          ),
    );
  }

  void _showManualAddModal() {
    if (!mounted) return;
    final mealProvider = context.read<MealProvider>();
    final selectedDate = mealProvider.selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: EditMealModal(
              meal: Meal(
                id: 'temp',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                dateString: selectedDate,
                foodName: '',
                calories: 0,
                macros: Macros(protein: 0, carbs: 0, fat: 0),
                synced: false,
              ),
              onSave: (newMeal) async {
                Navigator.pop(context);
                await context.read<MealProvider>().addMeal(
                  foodName: newMeal.foodName,
                  calories: newMeal.calories,
                  protein: newMeal.macros.protein,
                  carbs: newMeal.macros.carbs,
                  fat: newMeal.macros.fat,
                  portion: newMeal.portion,
                  dateString: newMeal.dateString,
                  settings: context.read<SettingsProvider>(),
                );
              },
              onCancel: () => Navigator.pop(context),
              onDelete: () => Navigator.pop(context),
            ),
          ),
    );
  }

  void _showSaveRoutineModal(List<Meal> meals) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveRoutineSheet(meals: meals),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = context.select<MealProvider, List<Meal>>(
      (p) => p.selectedDateMeals,
    );
    final selectedDate = context.select<MealProvider, String>(
      (p) => p.selectedDate,
    );
    final settings = context.watch<SettingsProvider>();
    final water = context.watch<WaterProvider>();
    final activity = context.watch<ActivityProvider>();
    final mealProvider = context.read<MealProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final summaries = _buildDailySummaries(
      mealProvider: mealProvider,
      settings: settings,
      water: water,
      activity: activity,
    );
    final selectedSummary = summaries.firstWhere(
      (summary) => summary.dateString == selectedDate,
      orElse:
          () => _buildSummaryForDate(
            dateString: selectedDate,
            mealProvider: mealProvider,
            settings: settings,
            water: water,
            activity: activity,
          ),
    );

    return AppPageScaffold(
      title: l10n.log_title,
      subtitle:
          app_date.DateUtils.isToday(selectedDate)
              ? 'Track what you eat today'
              : 'Review this day',
      trailing: Tooltip(
        message: 'Monthly calendar coming soon',
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(
            LucideIcons.calendarDays,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
        ),
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.06,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.sky.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                          center: const Alignment(-0.8, -0.6),
                          radius: 1.8,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 10.seconds, curve: Curves.easeInOut)
                     .blur(begin: const Offset(60, 60), end: const Offset(100, 100)),
                  ),
                ),
                Column(
                  children: [
                    HorizontalDayCalendar(
                      selectedDate: selectedDate,
                      dailySummaries: summaries,
                      onDateSelected: mealProvider.loadMealsForDate,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DayCommandCard(summary: selectedSummary),
          const SizedBox(height: 12),
          _LogActionBar(
            onScanTap: () {
              HapticFeedback.mediumImpact();
              context.go('/snap');
            },
            onManualTap: _showManualAddModal,
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.log_history,
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (meals.length >= 2 &&
                    app_date.DateUtils.isToday(selectedDate))
                  AppScaleTap(
                    onTap: () => _showSaveRoutineModal(meals),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.save,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.feature_templates_save_prompt,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            _staggeredSlide(
              _itemAnims[4],
              _LogEmptyState(
                isToday: app_date.DateUtils.isToday(selectedDate),
                onScan: () => context.go('/snap'),
                onManual: _showManualAddModal,
              ),
            )
          else
            _staggeredSlide(
              _itemAnims[4],
              _MealTimeline(
                meals: meals,
                onMealTap: _showEditModal,
                onMealDelete: (meal) async {
                  final messenger = ScaffoldMessenger.of(context);
                  await mealProvider.deleteMeal(
                    meal.id,
                    settings: context.read<SettingsProvider>(),
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.log_removed_snackbar(meal.foodName)),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          _SavedMealsStrip(selectedDate: selectedDate),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<DailySummary> _buildDailySummaries({
    required MealProvider mealProvider,
    required SettingsProvider settings,
    required WaterProvider water,
    required ActivityProvider activity,
  }) {
    final today = DateTime.now();
    return List.generate(14, (index) {
      final date = today.subtract(Duration(days: 13 - index));
      return _buildSummaryForDate(
        dateString: app_date.DateUtils.getDateString(date),
        mealProvider: mealProvider,
        settings: settings,
        water: water,
        activity: activity,
      );
    });
  }

  DailySummary _buildSummaryForDate({
    required String dateString,
    required MealProvider mealProvider,
    required SettingsProvider settings,
    required WaterProvider water,
    required ActivityProvider activity,
  }) {
    final meals = mealProvider.getMealsForDate(dateString);
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

    final isToday = app_date.DateUtils.isToday(dateString);
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
      waterMl: isToday ? water.total : 0,
      waterGoal: water.goal,
      steps: isToday && activity.isTracking ? activity.steps : 0,
      stepGoal: 10000,
      mealCount: meals.length,
    );
  }
}

class _DayCommandCard extends StatelessWidget {
  final DailySummary summary;

  const _DayCommandCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = summary.calorieGoal - summary.calories;
    final isOver = remaining < 0;
    final statusColor = _calorieColor;

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calories eaten',
                      style: AppTypography.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${summary.calories}',
                          style: AppTypography.displayLarge.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 52,
                            height: 0.95,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'kcal',
                          style: AppTypography.labelLarge.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  isOver
                      ? '${remaining.abs()} over'
                      : summary.hasData
                      ? '$remaining left'
                      : 'No data',
                  style: AppTypography.labelLarge.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _insight(remaining),
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1.28,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          _MacroBars(summary: summary),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: LucideIcons.utensils,
                label: '${summary.mealCount} meals',
                color: AppColors.primary,
              ),
              _InfoChip(
                icon: LucideIcons.droplets,
                label: '${summary.waterMl} ml',
                color: AppColors.sky,
              ),
              _InfoChip(
                icon: LucideIcons.footprints,
                label: '${summary.steps} steps',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _insight(int remaining) {
    if (!summary.hasData) {
      return 'No details logged for this day yet.';
    }
    if (remaining < 0) {
      return 'You logged ${remaining.abs()} kcal over target. Review the heavier meals below.';
    }
    if (summary.proteinProgress < 0.55) {
      return 'You logged ${summary.calories} kcal and protein was behind target.';
    }
    if (summary.waterProgress < 1 &&
        app_date.DateUtils.isToday(summary.dateString)) {
      return 'You logged ${summary.calories} kcal. Water is still behind today.';
    }
    return 'You logged ${summary.calories} kcal with a balanced day so far.';
  }

  Color get _calorieColor {
    if (!summary.hasData) return AppColors.lightTextSecondary;
    final ratio = summary.calorieProgress;
    if (ratio >= 0.75 && ratio <= 1.08) return AppColors.primary;
    if (ratio <= 1.18) return AppColors.amber;
    return AppColors.error;
  }
}

class _MacroBars extends StatelessWidget {
  final DailySummary summary;

  const _MacroBars({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MacroBar(
          label: 'Protein',
          value: summary.protein,
          goal: summary.proteinGoal,
          color: AppColors.protein,
        ),
        const SizedBox(height: 8),
        _MacroBar(
          label: 'Carbs',
          value: summary.carbs,
          goal: summary.carbGoal,
          color: AppColors.carbs,
        ),
        const SizedBox(height: 8),
        _MacroBar(
          label: 'Fat',
          value: summary.fat,
          goal: summary.fatGoal,
          color: AppColors.fat,
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (value / math.max(goal, 1)).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
            ),
            clipBehavior: Clip.antiAlias,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ).animate()
               .scaleX(begin: 0, duration: 800.ms, curve: Curves.easeOutCubic),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: Text(
            '${value}g',
            textAlign: TextAlign.right,
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.86),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogActionBar extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onManualTap;

  const _LogActionBar({required this.onScanTap, required this.onManualTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AppScaleTap(
            onTap: onScanTap,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.camera, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.snap_log_meal,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: AppScaleTap(
            onTap: onManualTap,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.58,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      l10n.log_add_manually,
                      style: AppTypography.labelMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealTimeline extends StatelessWidget {
  final List<Meal> meals;
  final ValueChanged<Meal> onMealTap;
  final ValueChanged<Meal> onMealDelete;

  const _MealTimeline({
    required this.meals,
    required this.onMealTap,
    required this.onMealDelete,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = _groupMeals(meals);
    return Column(
      children:
          grouped.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (meal) => _LogMealTile(
                      meal: meal,
                      onTap: () => onMealTap(meal),
                      onDelete: () => onMealDelete(meal),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Map<String, List<Meal>> _groupMeals(List<Meal> meals) {
    final sorted = [...meals]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final map = <String, List<Meal>>{};
    for (final meal in sorted) {
      final group = _mealGroup(meal);
      map.putIfAbsent(group, () => []).add(meal);
    }
    return map;
  }

  String _mealGroup(Meal meal) {
    final type = meal.mealType?.trim();
    if (type != null && type.isNotEmpty) return type;
    final hour = DateTime.fromMillisecondsSinceEpoch(meal.timestamp).hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 16) return 'Lunch';
    if (hour < 21) return 'Dinner';
    return 'Snack';
  }
}

class _LogMealTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LogMealTile({
    required this.meal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final macroTotal =
        meal.macros.protein + meal.macros.carbs + meal.macros.fat;
    final confidence = meal.scanConfidence;

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
      ),
      child: AppScaleTap(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.formattedTime,
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _mealIcon(meal),
                        color: AppColors.primary,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meal.foodName,
                            style: AppTypography.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (confidence != null) ...[
                          const SizedBox(width: 6),
                          _TrustBadge(confidence: confidence),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.portion?.isNotEmpty == true
                          ? meal.portion!
                          : 'Portion not set',
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    Container(
                      height: 5,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children:
                            macroTotal == 0
                                ? [
                                  Expanded(
                                    child: ColoredBox(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                ]
                                : [
                                  if (meal.macros.protein > 0)
                                    Expanded(
                                      flex: meal.macros.protein,
                                      child: const ColoredBox(
                                        color: AppColors.protein,
                                      ),
                                    ),
                                  if (meal.macros.carbs > 0)
                                    Expanded(
                                      flex: meal.macros.carbs,
                                      child: const ColoredBox(
                                        color: AppColors.carbs,
                                      ),
                                    ),
                                  if (meal.macros.fat > 0)
                                    Expanded(
                                      flex: meal.macros.fat,
                                      child: const ColoredBox(
                                        color: AppColors.fat,
                                      ),
                                    ),
                                ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal.calories}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fade(duration: 400.ms).slideX(begin: 0.05, curve: Curves.easeOutCubic),
      ),
    );
  }

  IconData _mealIcon(Meal meal) {
    final name = meal.foodName.toLowerCase();
    if (name.contains('coffee') || name.contains('tea')) {
      return LucideIcons.coffee;
    }
    if (name.contains('egg') || name.contains('breakfast')) {
      return LucideIcons.egg;
    }
    if (name.contains('fish') || name.contains('shrimp')) {
      return LucideIcons.fish;
    }
    if (name.contains('salad') || name.contains('fruit')) {
      return LucideIcons.apple;
    }
    if (name.contains('beef') || name.contains('meat')) {
      return LucideIcons.beef;
    }
    return LucideIcons.utensils;
  }
}

class _TrustBadge extends StatelessWidget {
  final double confidence;

  const _TrustBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final value = (confidence.clamp(0.0, 1.0) * 100).round();
    return Tooltip(
      message: 'AI estimate confidence',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.shieldCheck,
              color: AppColors.primary,
              size: 11,
            ),
            const SizedBox(width: 3),
            Text(
              '$value%',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedMealsStrip extends StatelessWidget {
  final String selectedDate;

  const _SavedMealsStrip({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateProvider>().templates;
    if (templates.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'SAVED MEALS',
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              fontSize: 10,
            ),
          ),
        ),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _SavedMealCard(
                template: template,
                onTap: () => _logTemplate(context, template),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _logTemplate(BuildContext context, MealTemplate template) async {
    HapticFeedback.mediumImpact();
    final mealProvider = context.read<MealProvider>();
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    for (final item in template.items) {
      await mealProvider.addMeal(
        foodName: item.foodName,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
        portion: item.servingSize,
        dateString: selectedDate,
        settings: settings,
      );
    }

    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Saved meal added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SavedMealCard extends StatelessWidget {
  final MealTemplate template;
  final VoidCallback onTap;

  const _SavedMealCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(template.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    template.name,
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${template.totalCalories} kcal',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
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

class _LogEmptyState extends StatelessWidget {
  final bool isToday;
  final VoidCallback onScan;
  final VoidCallback onManual;

  const _LogEmptyState({
    required this.isToday,
    required this.onScan,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppSectionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft pulsing background aura
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 2.seconds, curve: Curves.easeInOut),
                
                // Main icon with a gradient glow
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.utensils,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .moveY(begin: 0, end: -8, duration: 1.5.seconds, curve: Curves.easeInOut),

                // Decorative floating "sparks"
                ...List.generate(3, (index) => Positioned(
                  top: 40 + (index * 40),
                  left: 30 + (index * 60),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 0 ? AppColors.sky : AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .moveY(begin: 0, end: -15, duration: (1 + index * 0.5).seconds, curve: Curves.easeInOut)
                   .fade(begin: 0.2, end: 0.8),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isToday ? 'Ready to log your first meal?' : 'No activity on this day',
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isToday
                ? 'Your nutrition journey starts here. Scan a meal or add it manually to see your insights.'
                : 'It looks like nothing was recorded for this date.',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (isToday) ...[
                Expanded(
                  child: AppScaleTap(
                    onTap: onScan,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Scan Food',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AppScaleTap(
                  onTap: onManual,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded, color: colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Add Manually',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}
