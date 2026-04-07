import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/date_picker_bar.dart';
import 'widgets/edit_meal_modal.dart';
import 'widgets/meal_list_tile.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().loadMealsForDate(
        app_date.DateUtils.getTodayString(),
      );
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
                await context.read<MealProvider>().deleteMeal(meal.id);
              },
            ),
          ),
    );
  }

  void _showManualAddModal() {
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
                dateString: app_date.DateUtils.getTodayString(),
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
                  settings: context.read<SettingsProvider>(),
                );
              },
              onCancel: () => Navigator.pop(context),
              onDelete: () => Navigator.pop(context),
            ),
          ),
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

    return AppPageScaffold(
      title: 'Daily Log',
      subtitle:
          'Review and refine your entries for a precise tracking day.',
      scrollable: true,
      trailing: IconButton.filledTonal(
        icon: const Icon(LucideIcons.plus),
        onPressed: _showManualAddModal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                DatePickerBar(
                  selectedDate: selectedDate,
                  onPrevious: mealProvider.goToPreviousDay,
                  onNext: mealProvider.goToNextDay,
                  onToday: mealProvider.goToToday,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        label: 'Entries',
                        value: '${meals.length}',
                        accent: colorScheme.primary,
                        icon: LucideIcons.utensils,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricTile(
                        label: 'Total kcal',
                        value: '$totalCalories',
                        hint: 'on ${selectedDate.split('-').last}',
                        accent: colorScheme.secondary,
                        icon: LucideIcons.flame,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'MEAL HISTORY',
              style: AppTypography.labelMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (meals.isEmpty)
            AppEmptyState(
              icon: LucideIcons.bookOpen,
              title:
                  app_date.DateUtils.isToday(selectedDate)
                      ? 'No logs today'
                      : 'Empty history',
              body:
                  app_date.DateUtils.isToday(selectedDate)
                      ? 'Track your meals to see them here.'
                      : 'There is no data for this day.',
              actionLabel: 'Add Manually',
              onAction: _showManualAddModal,
            )
          else
            Column(
              children:
                  meals
                      .map(
                        (meal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MealListTile(
                            meal: meal,
                            onTap: () => _showEditModal(meal),
                            onDelete: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await mealProvider.deleteMeal(meal.id);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('${meal.foodName} removed'),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }
}
