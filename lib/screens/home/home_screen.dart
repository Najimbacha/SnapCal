import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/meal.dart';
import '../../data/services/connectivity_service.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/glass_container.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/macro_card.dart';
import 'widgets/recent_meal_tile.dart';
import 'widgets/water_tracking_card.dart';

import '../../core/services/preload_service.dart';

/// Home screen with dashboard and stats
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger background preloading after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PreloadService().preloadAll(context);
    });

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Background Glows - Simple containers, very cheap
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
            child: Builder(
              builder: (context) {
                // High-performance granular selection
                final totalCalories = context.select<MealProvider, int>(
                  (p) => p.todaysTotalCalories,
                );
                final macros = context.select<MealProvider, dynamic>(
                  (p) => p.todaysTotalMacros,
                );
                final calorieGoal = context.select<SettingsProvider, int>(
                  (p) => p.dailyCalorieGoal,
                );

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Premium Header - Rebuilds only when streak or user profile changes
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Builder(
                              builder: (context) {
                                final streak = context
                                    .select<SettingsProvider, int>(
                                      (p) => p.currentStreak,
                                    );
                                final user = context
                                    .select<AuthProvider, User?>((p) => p.user);
                                final isOnline = context
                                    .select<ConnectivityService, bool>(
                                      (p) => p.isOnline,
                                    );
                                return _buildHeader(
                                  context,
                                  streak,
                                  user,
                                  isOnline,
                                );
                              },
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.1, duration: 400.ms),
                      ),
                    ),

                    // Nudge Card - Rebuilds only when auth/meal state shifts
                    Builder(
                      builder: (context) {
                        final isAnonymous = context.select<AuthProvider, bool>(
                          (p) => p.isAnonymous,
                        );
                        final hasMeals = context.select<MealProvider, bool>(
                          (p) => p.todaysMeals.isNotEmpty,
                        );
                        final showNudge = isAnonymous && hasMeals;

                        if (!showNudge)
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );

                        return SliverToBoxAdapter(
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
                        );
                      },
                    ),

                    // Main Dashboard Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Calorie Ring - Only rebuilds when calories or goal changes
                            Center(
                              child: RepaintBoundary(
                                child: CalorieRing(
                                      consumed: totalCalories,
                                      goal: calorieGoal,
                                    )
                                    .animate()
                                    .fadeIn(delay: 100.ms, duration: 500.ms)
                                    .scale(
                                      begin: const Offset(0.8, 0.8),
                                      curve: Curves.easeOutBack,
                                      duration: 500.ms,
                                    ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Macro Cards Row - Only rebuilds when macros change
                            RepaintBoundary(
                              child: Row(
                                    children: [
                                      MacroCard(
                                        label: 'Protein',
                                        consumed: macros.protein,
                                        goal: context
                                            .select<SettingsProvider, int>(
                                              (p) => p.dailyProteinGoal,
                                            ),
                                        color: AppColors.protein,
                                        icon: LucideIcons.beef,
                                      ),
                                      const SizedBox(width: 12),
                                      MacroCard(
                                        label: 'Carbs',
                                        consumed: macros.carbs,
                                        goal: context
                                            .select<SettingsProvider, int>(
                                              (p) => p.dailyCarbGoal,
                                            ),
                                        color: AppColors.carbs,
                                        icon: LucideIcons.wheat,
                                      ),
                                      const SizedBox(width: 12),
                                      MacroCard(
                                        label: 'Fat',
                                        consumed: macros.fat,
                                        goal: context
                                            .select<SettingsProvider, int>(
                                              (p) => p.dailyFatGoal,
                                            ),
                                        color: AppColors.fat,
                                        icon: LucideIcons.droplets,
                                      ),
                                    ],
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms, duration: 400.ms)
                                  .slideY(begin: 0.1, duration: 400.ms),
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons - Only rebuilds when isPro changes
                            Builder(
                                  builder: (context) {
                                    final isPro = context
                                        .select<SettingsProvider, bool>(
                                          (p) => p.isPro,
                                        );
                                    return _buildActionTiles(context, isPro);
                                  },
                                )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideY(begin: 0.1, duration: 400.ms),

                            const SizedBox(height: 32),

                            // Water Tracking - Optimized internal rebuilds
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
                                  child: Builder(
                                    builder: (context) {
                                      final count = context
                                          .select<MealProvider, int>(
                                            (p) => p.todaysMealCount,
                                          );
                                      return Text(
                                        '$count today',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Builder(
                              builder: (context) {
                                final recentMeals = context
                                    .select<MealProvider, List<Meal>>(
                                      (p) => p.recentMeals,
                                    );
                                if (recentMeals.isEmpty)
                                  return _buildEmptyState(context);

                                return Column(
                                  children:
                                      recentMeals.asMap().entries.take(3).map((
                                        entry,
                                      ) {
                                        return RecentMealTile(meal: entry.value)
                                            .animate()
                                            .fadeIn(
                                              delay: (200 + entry.key * 100).ms,
                                              duration: 400.ms,
                                            )
                                            .slideX(
                                              begin: 0.05,
                                              duration: 400.ms,
                                            );
                                      }).toList(),
                                );
                              },
                            ),
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

  Widget _buildHeader(
    BuildContext context,
    int streak,
    User? user,
    bool isOnline,
  ) {
    final displayName = user?.displayName?.split(' ').first ?? 'Friend';
    final userInitial =
        user?.displayName?.isNotEmpty == true
            ? user!.displayName![0].toUpperCase()
            : user?.email?.isNotEmpty == true
            ? user!.email![0].toUpperCase()
            : 'S';

    return Row(
      children: [
        // Premium Profile / Initial with Status Dot
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/settings');
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: context.premiumGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  userInitial,
                  style: AppTypography.labelLarge.copyWith(
                    color:
                        context.isDarkMode
                            ? Colors.white
                            : AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!isOnline)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surfaceColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Compact Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Good ${_getTimeOfDay()}, $displayName',
                    style: AppTypography.labelMedium.copyWith(
                      color: context.textMutedColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (!isOnline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OFFLINE',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Shape Your Body',
                style: AppTypography.heading3.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // Action group
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _headerIcon(
              context,
              icon: LucideIcons.sparkles,
              color: AppColors.primary,
              onTap: () => context.push('/assistant'),
              hasPulse: true,
            ),
            const SizedBox(width: 8),
            _headerIcon(
              context,
              icon: LucideIcons.flame,
              color: AppColors.warning,
              onTap: () => context.push('/reports'),
              label: '$streak',
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
    bool hasPulse = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassContainer(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 10,
          vertical: 8,
        ),
        borderRadius: 14,
        backgroundColor: color.withOpacity(0.1),
        borderColor: color.withOpacity(0.2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18)
                .animate(
                  target: hasPulse ? 1 : 0,
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTiles(BuildContext context, bool isPro) {
    return Column(
      children: [
        _actionTile(
          context,
          title: 'Smart Meal Planner',
          subtitle: 'Generate weekly plans & lists',
          icon: LucideIcons.chefHat,
          color: AppColors.primary,
          isPro: true,
          showBadge: isPro,
          onTap: () => context.push(isPro ? '/planner' : '/paywall'),
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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
