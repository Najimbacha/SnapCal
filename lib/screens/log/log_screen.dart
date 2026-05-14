import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/ad_banner.dart';
import 'widgets/date_picker_bar.dart';
import 'widgets/edit_meal_modal.dart';
import 'widgets/meal_list_tile.dart';
import 'widgets/routines_carousel.dart';
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
    final totalCalories = context.select<MealProvider, int>(
      (p) => p.selectedDateTotalCalories,
    );
    final mealProvider = context.read<MealProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppPageScaffold(
      title: l10n.log_title,
      subtitle: l10n.log_subtitle,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogActionRow(
            onScanTap: () {
              HapticFeedback.mediumImpact();
              context.go('/snap');
            },
            onManualTap: _showManualAddModal,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: AppSectionCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DatePickerBar(
                    selectedDate: selectedDate,
                    onPrevious: mealProvider.goToPreviousDay,
                    onNext: mealProvider.goToNextDay,
                    onToday: mealProvider.goToToday,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          label: l10n.log_entries,
                          value: '${meals.length}',
                          accent: colorScheme.primary,
                          icon: LucideIcons.utensils,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricTile(
                          label: l10n.log_total_kcal,
                          value: '$totalCalories',
                          accent: AppColors.carbs,
                          icon: LucideIcons.flame,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const RoutinesCarousel(),
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
              AppEmptyState(
                icon: LucideIcons.bookOpen,
                title:
                    app_date.DateUtils.isToday(selectedDate)
                        ? l10n.log_no_entries_today
                        : l10n.log_no_entries_history,
                body:
                    app_date.DateUtils.isToday(selectedDate)
                        ? l10n.log_track_prompt
                        : l10n.log_no_data_prompt,
                actionLabel: l10n.log_add_manually,
                onAction: _showManualAddModal,
              ),
            )
          else
            ...meals.asMap().entries.map((entry) {
              final index = entry.key;
              final meal = entry.value;
              final startDelay = ((index + 4) % 10) * 0.1;
              final endDelay = (startDelay + 0.4).clamp(0.0, 1.0);
              
              final anim = CurvedAnimation(
                parent: _animController,
                curve: Interval(
                  startDelay,
                  endDelay,
                  curve: Curves.easeOutQuart,
                ),
              );

              return _staggeredSlide(
                anim,
                MealListTile(
                  meal: meal,
                  onTap: () => _showEditModal(meal),
                  onDelete: () async {
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
              );
            }),
          const SizedBox(height: 16),
          const AdBanner(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _LogActionRow extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onManualTap;

  const _LogActionRow({required this.onScanTap, required this.onManualTap});

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
                gradient: LinearGradient(
                  colors: [colorScheme.primary, AppColors.sky],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
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
