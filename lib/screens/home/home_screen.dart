import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/services/preload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/meal.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/macro_card.dart';
import 'widgets/recent_meal_tile.dart';
import 'widgets/water_tracking_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PreloadService().preloadAll(context);
    });

    final totalCalories = context.select<MealProvider, int>(
      (p) => p.todaysTotalCalories,
    );
    final macros = context.select<MealProvider, dynamic>(
      (p) => p.todaysTotalMacros,
    );
    final calorieGoal = context.select<SettingsProvider, int>(
      (p) => p.dailyCalorieGoal,
    );
    final streak = context.select<SettingsProvider, int>(
      (p) => p.currentStreak,
    );
    final user = context.select<AuthProvider, User?>((p) => p.user);
    final isAnonymous = context.select<AuthProvider, bool>(
      (p) => p.isAnonymous,
    );
    final isOnline = context.select<ConnectivityService, bool>(
      (p) => p.isOnline,
    );
    final recentMeals = context.select<MealProvider, List<Meal>>(
      (p) => p.recentMeals,
    );

    final name =
        user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'Friend';

    return AppPageScaffold(
      title: 'Good ${_getTimeOfDay()}, $name',
      subtitle:
          isOnline
              ? 'Stay on track with one clear target today.'
              : 'You are offline. Tracking still works locally.',
      trailing: IconButton.filledTonal(
        icon: const Icon(LucideIcons.sparkles),
        onPressed: () => context.push('/assistant'),
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CalorieRing(
                  consumed: totalCalories,
                  goal: calorieGoal,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StreakBadge(streak: streak),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel(title: 'Today at a glance'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Goal',
                  value: '$calorieGoal kcal',
                  hint: 'Daily target',
                  accent: AppColors.primary,
                  icon: LucideIcons.flame,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: 'Meals',
                  value:
                      '${context.select<MealProvider, int>((p) => p.todaysMealCount)}',
                  hint: 'Logged today',
                  accent: AppColors.carbs,
                  icon: LucideIcons.utensils,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel(title: 'Macros'),
          const SizedBox(height: 10),
          Row(
            children: [
              MacroCard(
                label: 'Protein',
                consumed: macros.protein,
                goal: context.select<SettingsProvider, int>(
                  (p) => p.dailyProteinGoal,
                ),
                color: AppColors.protein,
                icon: LucideIcons.beef,
              ),
              const SizedBox(width: 10),
              MacroCard(
                label: 'Carbs',
                consumed: macros.carbs,
                goal: context.select<SettingsProvider, int>(
                  (p) => p.dailyCarbGoal,
                ),
                color: AppColors.carbs,
                icon: LucideIcons.wheat,
              ),
              const SizedBox(width: 10),
              MacroCard(
                label: 'Fat',
                consumed: macros.fat,
                goal: context.select<SettingsProvider, int>(
                  (p) => p.dailyFatGoal,
                ),
                color: AppColors.fat,
                icon: LucideIcons.droplets,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const WaterTrackingCard(),
          const SizedBox(height: 18),
          const SectionLabel(title: 'Quick actions'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ActionChipButton(
                icon: LucideIcons.camera,
                label: 'Snap a meal',
                onTap: () => context.go('/snap'),
              ),
              ActionChipButton(
                icon: LucideIcons.clipboardList,
                label: 'Open log',
                onTap: () => context.go('/log'),
              ),
              ActionChipButton(
                icon: LucideIcons.barChart3,
                label: 'See reports',
                onTap: () => context.go('/reports'),
              ),
            ],
          ),
          if (isAnonymous && recentMeals.isNotEmpty) ...[
            const SizedBox(height: 18),
            AppSectionCard(
              color: context.cardSoftColor,
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create an account to sync your progress and keep your streak safe.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => AuthModal.show(context),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const SectionLabel(title: 'Recent meals'),
          const SizedBox(height: 10),
          if (recentMeals.isEmpty)
            AppEmptyState(
              icon: LucideIcons.camera,
              title: 'No meals logged yet',
              body:
                  'Start with one quick snap and your day will feel much easier to track.',
              actionLabel: 'Snap first meal',
              onAction: () => context.go('/snap'),
            )
          else
            Column(
              children:
                  recentMeals
                      .take(3)
                      .map((meal) => RecentMealTile(meal: meal))
                      .toList(),
            ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: ShapeDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            '$streak Day Streak',
            style: AppTypography.labelLarge.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
