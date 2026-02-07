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
import '../../widgets/glass_container.dart';
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
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ).animate().fadeIn(duration: 1000.ms),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.carbs.withOpacity(0.05),
              ),
            ).animate().fadeIn(duration: 1200.ms),
          ),

          SafeArea(
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
                final showNudge =
                    authProvider.isAnonymous &&
                    mealProvider.todaysMeals.isNotEmpty;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Premium Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildHeader(context, streak)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.2, duration: 400.ms),
                      ),
                    ),

                    if (showNudge)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: _buildNudgeCard(context)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.1, duration: 400.ms),
                        ),
                      ),

                    // Main Dashboard Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Calorie Ring
                            Center(
                              child: CalorieRing(
                                    consumed: totalCalories,
                                    goal: settingsProvider.dailyCalorieGoal,
                                  )
                                  .animate()
                                  .fadeIn(delay: 100.ms, duration: 500.ms)
                                  .scale(
                                    begin: const Offset(0.8, 0.8),
                                    curve: Curves.outBack,
                                    duration: 500.ms,
                                  ),
                            ),

                            const SizedBox(height: 40),

                            // Macro Cards Row
                            Row(
                                  children: [
                                    MacroCard(
                                      label: 'Protein',
                                      consumed: macros.protein,
                                      goal: settingsProvider.dailyProteinGoal,
                                      color: AppColors.protein,
                                      icon: LucideIcons.beef,
                                    ),
                                    const SizedBox(width: 12),
                                    MacroCard(
                                      label: 'Carbs',
                                      consumed: macros.carbs,
                                      goal: settingsProvider.dailyCarbGoal,
                                      color: AppColors.carbs,
                                      icon: LucideIcons.wheat,
                                    ),
                                    const SizedBox(width: 12),
                                    MacroCard(
                                      label: 'Fat',
                                      consumed: macros.fat,
                                      goal: settingsProvider.dailyFatGoal,
                                      color: AppColors.fat,
                                      icon: LucideIcons.droplets,
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(delay: 300.ms, duration: 400.ms)
                                .slideY(begin: 0.1, duration: 400.ms),

                            const SizedBox(height: 32),

                            // Action Buttons
                            _buildActionTiles(context, settingsProvider)
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideY(begin: 0.1, duration: 400.ms),

                            const SizedBox(height: 32),

                            // Water Tracking
                            const WaterTrackingCard()
                                .animate()
                                .fadeIn(delay: 500.ms, duration: 400.ms)
                                .slideY(begin: 0.1, duration: 400.ms),

                            const SizedBox(height: 32),

                            // Recent Meals Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RECENT MEALS',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: context.textMutedColor,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${mealProvider.todaysMealCount} today',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (recentMeals.isNotEmpty)
                              ...recentMeals.asMap().entries.take(3).map((
                                entry,
                              ) {
                                return RecentMealTile(meal: entry.value)
                                    .animate()
                                    .fadeIn(
                                      delay: (600 + entry.key * 100).ms,
                                      duration: 400.ms,
                                    )
                                    .slideX(begin: 0.05, duration: 400.ms);
                              })
                            else
                              _buildEmptyState(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int streak) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_getTimeOfDay()},',
              style: AppTypography.bodyLarge.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Shape Your Body',
              style: AppTypography.heading1.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // AI Assistant Premium Icon
            GestureDetector(
              onTap: () => context.push('/assistant'),
              child: GlassContainer(
                padding: const EdgeInsets.all(10),
                borderRadius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                borderColor: AppColors.primary.withOpacity(0.2),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Streak counter
            GestureDetector(
              onTap: () => context.push('/reports'),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                borderRadius: 14,
                backgroundColor: context.surfaceColor.withOpacity(0.5),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '$streak',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTiles(BuildContext context, SettingsProvider settings) {
    return Column(
      children: [
        _actionTile(
          context,
          title: 'Smart Meal Planner',
          subtitle: 'Generate weekly plans & lists',
          icon: LucideIcons.chefHat,
          color: AppColors.primary,
          isPro: true,
          showBadge: settings.isPro,
          onTap: () => context.push(settings.isPro ? '/planner' : '/paywall'),
        ),
        const SizedBox(height: 12),
        _actionTile(
          context,
          title: 'Weekly Insights',
          subtitle: 'Track your macro distribution',
          icon: LucideIcons.barChart3,
          color: AppColors.protein,
          onTap: () => context.push('/reports'),
        ),
      ],
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPro = false,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        backgroundColor: context.surfaceColor.withOpacity(0.4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      if (isPro && !showBadge) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          LucideIcons.lock,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: context.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNudgeCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      borderColor: AppColors.primary.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNC DATA',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Save your progress securely',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => AuthModal.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      borderRadius: 28,
      backgroundColor: context.surfaceColor.withOpacity(0.3),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceLightColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.camera,
              size: 40,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'NO MEALS LOGGED',
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Snap your first meal to start your journey',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
