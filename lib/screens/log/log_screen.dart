import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/models/meal.dart';
import 'widgets/date_picker_bar.dart';
import 'widgets/meal_list_tile.dart';
import 'widgets/edit_meal_modal.dart';
import '../../widgets/glass_container.dart';

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
      backgroundColor: context.backgroundColor,
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Log',
                                style: AppTypography.heading2.copyWith(
                                  letterSpacing: -1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Track your nutrition journey',
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.textMutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          _buildAddButton(),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 32,
                        backgroundColor: context.surfaceColor.withOpacity(0.4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: 'Logged Meals',
                              value: '${meals.length}',
                              icon: LucideIcons.utensils,
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: context.glassBorderColor.withOpacity(0.3),
                            ),
                            _SummaryItem(
                              label: 'Total Calories',
                              value: '$totalCalories',
                              unit: 'kcal',
                              icon: LucideIcons.flame,
                              valueColor: AppColors.primary,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(
                        begin: 0.2,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),

                const SizedBox(height: 24),

                // Meal list
                Expanded(
                  child:
                      meals.isEmpty
                          ? _buildEmptyState(selectedDate)
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
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
                                              '${meal.foodName} removed',
                                            ),
                                            backgroundColor:
                                                context.surfaceColor,
                                            action: SnackBarAction(
                                              label: 'Undo',
                                              textColor: AppColors.primary,
                                              onPressed: () {
                                                // Undo functionality
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: (index * 80).ms,
                                    duration: 400.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideY(
                                    begin: 0.1,
                                    duration: 400.ms,
                                    curve: Curves.easeOut,
                                  );
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

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showManualAddModal,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.plus, color: AppColors.primary, size: 24),
      ),
    );
  }

  Widget _buildEmptyState(String selectedDate) {
    final isToday = app_date.DateUtils.isToday(selectedDate);

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: context.surfaceColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.glassBorderColor.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: 48,
                    color: context.textMutedColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  isToday ? 'No meals yet' : 'Nothing logged here',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isToday
                      ? 'Start your day by tracking your first meal!'
                      : 'Take a look at another day in your journey.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textSecondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (valueColor ?? context.textSecondaryColor).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: valueColor ?? context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTypography.heading3.copyWith(
                color: valueColor ?? context.textPrimaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                height: 1,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(
                unit!,
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
