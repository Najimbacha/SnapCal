import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/models/meal.dart';
import 'widgets/date_picker_bar.dart';
import 'widgets/meal_list_tile.dart';
import 'widgets/edit_meal_modal.dart';

/// Log screen for viewing and editing meal history
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  @override
  void initState() {
    super.initState();
    // Load today's meals
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
              onDelete:
                  () =>
                      Navigator.pop(context), // Nothing to delete for new entry
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<MealProvider>(
          builder: (context, mealProvider, child) {
            final meals = mealProvider.selectedDateMeals;
            final selectedDate = mealProvider.selectedDate;
            final totalCalories = mealProvider.selectedDateTotalCalories;

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Food Log', style: AppTypography.heading2),
                          IconButton(
                            onPressed: _showManualAddModal,
                            icon: const Icon(
                              LucideIcons.plusCircle,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DatePickerBar(
                        selectedDate: selectedDate,
                        onPrevious: () => mealProvider.goToPreviousDay(),
                        onNext: () => mealProvider.goToNextDay(),
                        onToday: () => mealProvider.goToToday(),
                      ),
                    ],
                  ),
                ),

                // Summary card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withAlpha(20),
                              AppColors.primary.withAlpha(10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(50),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: 'Meals',
                              value: '${meals.length}',
                              icon: LucideIcons.utensilsCrossed,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.glassBorder,
                            ),
                            _SummaryItem(
                              label: 'Total',
                              value: '$totalCalories',
                              unit: 'kcal',
                              icon: LucideIcons.flame,
                              valueColor: AppColors.primary,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, duration: 300.ms),
                ),

                const SizedBox(height: 20),

                // Meal list
                Expanded(
                  child:
                      meals.isEmpty
                          ? _buildEmptyState(selectedDate)
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              final meal = meals[index];
                              return MealListTile(
                                    meal: meal,
                                    onTap: () => _showEditModal(meal),
                                    onDelete: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      await mealProvider.deleteMeal(meal.id);
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${meal.foodName} deleted',
                                            ),
                                            action: SnackBarAction(
                                              label: 'Undo',
                                              textColor: AppColors.primary,
                                              onPressed: () {
                                                // TODO: Implement undo
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: (index * 50).ms,
                                    duration: 300.ms,
                                  )
                                  .slideX(begin: 0.05, duration: 300.ms);
                            },
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String selectedDate) {
    final isToday = app_date.DateUtils.isToday(selectedDate);

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.clipboardList,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  isToday ? 'No meals logged today' : 'No meals on this day',
                  style: AppTypography.heading3,
                ),
                const SizedBox(height: 8),
                Text(
                  isToday
                      ? 'Snap a photo of your food to get started!'
                      : 'Try selecting a different date',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppTypography.heading2.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit!, style: AppTypography.bodySmall),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
