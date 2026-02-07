import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/planner_provider.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Smart Planner'),
        backgroundColor: context.backgroundColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondaryColor,
          tabs: const [Tab(text: 'Weekly Plan'), Tab(text: 'Grocery List')],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.sparkles, color: AppColors.primary),
            tooltip: 'Generate New Plan',
            onPressed: () => _confirmGenerate(context),
          ),
        ],
      ),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isGenerating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Chef AI is planning your week...',
                    style: AppTypography.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [_buildPlanTab(provider), _buildGroceryTab(provider)],
          );
        },
      ),
    );
  }

  Future<void> _confirmGenerate(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: context.surfaceColor,
            title: Text(
              'Generate New Plan?',
              style: TextStyle(color: context.textPrimaryColor),
            ),
            content: Text(
              'This will overwrite your current meal plan and grocery list based on your latest settings.',
              style: TextStyle(color: context.textSecondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Generate'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      context.read<PlannerProvider>().generateWeeklyPlan();
    }
  }

  Widget _buildPlanTab(PlannerProvider provider) {
    if (provider.currentPlan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.calendar,
              size: 64,
              color: AppColors.protein, // Using accent color for empty state
            ),
            const SizedBox(height: 16),
            Text('No active plan', style: AppTypography.heading3),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _confirmGenerate(context),
              child: const Text('Generate Plan'),
            ),
          ],
        ),
      );
    }

    final plan = provider.currentPlan!;
    final days = [0, 1, 2, 3, 4, 5, 6]; // Mon-Sun

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final dayIndex = days[index];
        // Simple day name logic
        final dayName = DateFormat('EEEE').format(
          DateTime.now().subtract(
            Duration(days: DateTime.now().weekday - 1 - dayIndex),
          ),
        );
        final meals = plan.weeklyMeals[dayIndex] ?? [];

        return Card(
          color: context.surfaceColor,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            title: Text(dayName, style: AppTypography.heading3),
            subtitle: Text(
              '${meals.fold(0, (sum, m) => sum + m.calories)} kcal',
              style: AppTypography.labelSmall.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            children:
                meals
                    .map(
                      (meal) => ListTile(
                        leading: const Icon(
                          LucideIcons.utensils,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          meal.foodName,
                          style: AppTypography.bodyMedium,
                        ),
                        trailing: Text(
                          '${meal.calories} kcal',
                          style: AppTypography.labelSmall,
                        ),
                      ),
                    )
                    .toList(),
          ),
        );
      },
    );
  }

  Widget _buildGroceryTab(PlannerProvider provider) {
    if (provider.groceryList.isEmpty) {
      return Center(
        child: Text(
          'Grocery list is empty',
          style: TextStyle(color: context.textSecondaryColor),
        ),
      );
    }

    // Group by category
    final grouped = <String, List<dynamic>>{};
    for (var item in provider.groceryList) {
      if (!grouped.containsKey(item.category)) grouped[item.category] = [];
      grouped[item.category]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                ...entry.value.map((item) {
                  return CheckboxListTile(
                    value: item.isChecked,
                    onChanged: (val) => provider.toggleGroceryItem(item.id),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration:
                            item.isChecked ? TextDecoration.lineThrough : null,
                        color:
                            item.isChecked
                                ? context.textMutedColor
                                : context.textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      item.amount,
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
                const Divider(height: 1),
              ],
            );
          }).toList(),
    );
  }
}
