import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_modal.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/macro_card.dart';
import 'widgets/recent_meal_tile.dart';
import 'widgets/water_tracking_card.dart';

/// Home screen with dashboard and stats
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Consumer3<MealProvider, SettingsProvider, AuthProvider>(
          builder: (
            context,
            mealProvider,
            settingsProvider,
            authProvider,
            child,
          ) {
            final totalCalories = mealProvider.todaysTotalCalories;
            final macros = mealProvider.todaysTotalMacros;
            final recentMeals = mealProvider.recentMeals;
            final streak = settingsProvider.currentStreak;

            // Show nudge if anonymous and has logged meaningful data (3+ meals)
            // Using todaysMeals as a proxy for engagement
            final showNudge =
                authProvider.isAnonymous &&
                mealProvider.todaysMeals.length >= 1;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context, streak),

                    if (showNudge) ...[
                      const SizedBox(height: 24),
                      _buildNudgeCard(context),
                    ],

                    const SizedBox(height: 32),

                    // Calorie Ring
                    Center(
                      child: RepaintBoundary(
                        child: CalorieRing(
                              consumed: totalCalories,
                              goal: settingsProvider.dailyCalorieGoal,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              duration: 400.ms,
                            ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Macro Cards Row
                    RepaintBoundary(
                      child: Row(
                            children: [
                              MacroCard(
                                label: 'Protein',
                                consumed: macros.protein,
                                goal: settingsProvider.dailyProteinGoal,
                                color: AppColors.protein,
                              ),
                              const SizedBox(width: 12),
                              MacroCard(
                                label: 'Carbs',
                                consumed: macros.carbs,
                                goal: settingsProvider.dailyCarbGoal,
                                color: AppColors.carbs,
                              ),
                              const SizedBox(width: 12),
                              MacroCard(
                                label: 'Fat',
                                consumed: macros.fat,
                                goal: settingsProvider.dailyFatGoal,
                                color: AppColors.fat,
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.2, duration: 400.ms),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons (Insights)
                    _buildInsightsButton(context, settingsProvider),

                    const SizedBox(height: 32),

                    // Water Tracking
                    const WaterTrackingCard()
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.1, duration: 400.ms),

                    const SizedBox(height: 32),

                    // Recent Meals Section
                    if (recentMeals.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Meals', style: AppTypography.heading3),
                          Text(
                            '${mealProvider.todaysMealCount} today',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...recentMeals.asMap().entries.map((entry) {
                        return RecentMealTile(meal: entry.value)
                            .animate()
                            .fadeIn(
                              delay: (300 + entry.key * 100).ms,
                              duration: 400.ms,
                            )
                            .slideX(begin: 0.1, duration: 400.ms);
                      }),
                    ] else ...[
                      _buildEmptyState(context),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int streak) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getTimeOfDay()}!',
                style: AppTypography.heading2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Track your nutrition today',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.textSecondaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            // AI Assistant Icon
            IconButton(
              onPressed: () => context.push('/assistant'),
              icon: const Icon(
                LucideIcons.sparkles,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 4),
            // Streak Counter
            GestureDetector(
              onTap: () => context.push('/reports'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.glassBorderColor),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      'Day $streak',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsButton(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (settingsProvider.isPro) {
              context.push('/planner');
            } else {
              context.push('/paywall');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    settingsProvider.isPro
                        ? AppColors.primary.withOpacity(0.5)
                        : context.glassBorderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.chefHat, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Smart Meal Planner',
                            style: AppTypography.labelMedium,
                          ),
                          if (settingsProvider.isPro) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Generate weekly plans & grocery lists',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  settingsProvider.isPro
                      ? LucideIcons.chevronRight
                      : LucideIcons.lock,
                  color:
                      settingsProvider.isPro
                          ? context.textSecondaryColor
                          : AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => context.push('/reports'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.barChart3, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Insights', style: AppTypography.labelMedium),
                      Text(
                        'Check your progress and macro distribution',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.glassBorderColor),
          ),
          child: Column(
            children: [
              Icon(
                LucideIcons.camera,
                size: 48,
                color: context.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text('No meals logged yet', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Text(
                'Tap the camera button to snap your first meal!',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }

  Widget _buildNudgeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(20),
            AppColors.protein.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceLightColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.shieldAlert,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Save Your Progress', style: AppTypography.labelLarge),
                const SizedBox(height: 4),
                Text(
                  'Don\'t lose your easy streaks and stats.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => AuthModal.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
