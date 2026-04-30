import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../core/utils/responsive_utils.dart';
import '../../data/models/meal.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/ad_banner.dart';
import 'widgets/date_picker_bar.dart';
import 'widgets/edit_meal_modal.dart';
import 'widgets/meal_list_tile.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> with SingleTickerProviderStateMixin {
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
                  portion: newMeal.portion,
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
      subtitle: 'Track your nutrition journey',
      scrollable: true,
      floatingActionButton: _FloatingAddButton(onTap: _showManualAddModal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                          label: 'ENTRIES',
                          value: '${meals.length}',
                          accent: colorScheme.primary,
                          icon: LucideIcons.utensils,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricTile(
                          label: 'TOTAL KCAL',
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
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'MEAL HISTORY',
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            _staggeredSlide(
              _itemAnims[4],
              AppEmptyState(
                icon: LucideIcons.bookOpen,
                title: app_date.DateUtils.isToday(selectedDate) ? 'No logs today' : 'Empty history',
                body: app_date.DateUtils.isToday(selectedDate)
                    ? 'Track your meals to see them here.'
                    : 'There is no data for this day.',
                actionLabel: 'Add Manually',
                onAction: _showManualAddModal,
              ),
            )
          else
            ...meals.asMap().entries.map((entry) {
              final index = entry.key;
              final meal = entry.value;
              final anim = CurvedAnimation(
                parent: _animController,
                curve: Interval(
                  ((index + 4) % 10) * 0.1, 
                  (((index + 4) % 10) * 0.1) + 0.4, 
                  curve: Curves.easeOutQuart
                ),
              );

              return _staggeredSlide(
                anim,
                MealListTile(
                  meal: meal,
                  onTap: () => _showEditModal(meal),
                  onDelete: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await mealProvider.deleteMeal(meal.id);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('${meal.foodName} removed')),
                    );
                  },
                ),
              );
            }).toList(),
          const SizedBox(height: 16),
          const AdBanner(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
      ),
    );
  }
}

Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
