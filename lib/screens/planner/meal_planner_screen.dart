import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/planner_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
    return AppPageScaffold(
      title: 'Smart planner',
      subtitle:
          'Get a weekly meal plan and grocery list built around your current targets.',
      trailing: ActionChipButton(
        icon: LucideIcons.sparkles,
        label: 'Generate',
        onTap: () => _confirmGenerate(context),
      ),
      child: Consumer<PlannerProvider>(
        builder: (context, provider, _) {
          if (provider.isGenerating) {
            return Center(
              child: AppEmptyState(
                icon: LucideIcons.chefHat,
                title: 'Planning your week',
                body:
                    'Chef AI is building a calmer, ready-to-use plan for the days ahead.',
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionCard(
                padding: const EdgeInsets.all(8),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: context.textSecondaryColor,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Weekly plan'),
                    Tab(text: 'Grocery list'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlanTab(provider),
                    _buildGroceryTab(provider),
                  ],
                ),
              ),
            ],
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
            title: const Text('Generate new plan?'),
            content: const Text(
              'This will replace the current meal plan and grocery list with a new one.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Generate'),
              ),
            ],
          ),
    );

    if (confirm == true && context.mounted) {
      context.read<PlannerProvider>().generateWeeklyPlan();
    }
  }

  Widget _buildPlanTab(PlannerProvider provider) {
    if (provider.currentPlan == null) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.calendar,
          title: 'No plan yet',
          body:
              'Generate a plan when you want meal ideas that match your targets.',
          actionLabel: 'Generate plan',
          onAction: () => _confirmGenerate(context),
        ),
      );
    }

    final days = [0, 1, 2, 3, 4, 5, 6];
    final plan = provider.currentPlan!;

    return ListView.builder(
      itemCount: days.length,
      padding: const EdgeInsets.only(bottom: 12),
      itemBuilder: (context, index) {
        final dayIndex = days[index];
        final dayName = DateFormat('EEEE').format(
          DateTime.now().subtract(
            Duration(days: DateTime.now().weekday - 1 - dayIndex),
          ),
        );
        final meals = plan.weeklyMeals[dayIndex] ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppSectionCard(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(dayName, style: AppTypography.heading3),
              subtitle: Text(
                '${meals.fold(0, (sum, meal) => sum + meal.calories)} kcal',
                style: AppTypography.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
              children:
                  meals
                      .map(
                        (meal) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            LucideIcons.utensils,
                            color: AppColors.primary,
                          ),
                          title: Text(meal.foodName),
                          trailing: Text('${meal.calories} kcal'),
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroceryTab(PlannerProvider provider) {
    if (provider.groceryList.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.shoppingBag,
          title: 'No grocery list yet',
          body:
              'Generate a weekly plan first and your grocery list will appear here.',
        ),
      );
    }

    final grouped = <String, List<dynamic>>{};
    for (final item in provider.groceryList) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      children:
          grouped.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...entry.value.map((item) {
                      return CheckboxListTile(
                        value: item.isChecked,
                        onChanged: (_) => provider.toggleGroceryItem(item.id),
                        title: Text(item.name),
                        subtitle: Text(item.amount),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
