import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/services/preload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../data/models/meal.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/ad_banner.dart';
import 'widgets/liquid_calorie_circle.dart';
import 'widgets/macro_card.dart';
import 'widgets/recent_meal_tile.dart';
import 'widgets/water_tracking_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<Animation<double>> _itemAnims = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Create staggered intervals for home components
    for (int i = 0; i < 8; i++) {
      _itemAnims.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1, ((i * 0.1) + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutQuart),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PreloadService().preloadAll(context);
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalCalories = context.select<MealProvider, int>((p) => p.todaysTotalCalories);
    final macros = context.select<MealProvider, dynamic>((p) => p.todaysTotalMacros);
    final calorieGoal = context.select<SettingsProvider, int>((p) => p.dailyCalorieGoal);
    final streak = context.select<SettingsProvider, int>((p) => p.currentStreak);
    final user = context.select<AuthProvider, User?>((p) => p.user);
    final isAnonymous = context.select<AuthProvider, bool>((p) => p.isAnonymous);
    final isOnline = context.select<ConnectivityService, bool>((p) => p.isOnline);
    final recentMeals = context.select<MealProvider, List<Meal>>((p) => p.recentMeals);

    final name = user?.displayName?.split(' ').first ?? user?.email?.split('@').first ?? 'Friend';
    final size = Responsive.size(context) == ScreenSize.small ? 160.0 : 190.0;
    final timeOfDay = _getTimeOfDay();

    return AppPageScaffold(
      title: '',
      leading: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good $timeOfDay,',
            style: AppTypography.titleSmall.copyWith(
              color: context.textSecondaryColor, 
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            name,
            style: AppTypography.titleLarge.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
        ],
      ),
      trailing: AppScaleTap(
        onTap: () => context.push('/assistant'),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
        ),
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0: Main Calorie Circle
          _staggeredSlide(
            _itemAnims[0],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  LiquidCalorieCircle(
                    current: totalCalories,
                    target: calorieGoal,
                    size: Size(size, size),
                  ),
                  const SizedBox(height: 20),
                  _StreakBadge(streak: streak),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 1: Today Labels
          _staggeredSlide(_itemAnims[1], const SectionLabel(title: 'Today at a glance')),
          const SizedBox(height: 2),

          // 2: Metric Tiles
          _staggeredSlide(
            _itemAnims[2],
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
                    value: '${context.select<MealProvider, int>((p) => p.todaysMealCount)}',
                    hint: 'Logged today',
                    accent: AppColors.carbs,
                    icon: LucideIcons.utensils,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3: Macros Label
          _staggeredSlide(_itemAnims[3], const SectionLabel(title: 'Macros')),
          const SizedBox(height: 6),

          // 4: Macro Cards
          _staggeredSlide(
            _itemAnims[4],
            Row(
              children: [
                MacroCard(
                  label: 'Protein',
                  consumed: macros.protein,
                  goal: context.select<SettingsProvider, int>((p) => p.dailyProteinGoal),
                  color: AppColors.protein,
                  icon: LucideIcons.beef,
                ),
                const SizedBox(width: 10),
                MacroCard(
                  label: 'Carbs',
                  consumed: macros.carbs,
                  goal: context.select<SettingsProvider, int>((p) => p.dailyCarbGoal),
                  color: AppColors.carbs,
                  icon: LucideIcons.wheat,
                ),
                const SizedBox(width: 10),
                MacroCard(
                  label: 'Fat',
                  consumed: macros.fat,
                  goal: context.select<SettingsProvider, int>((p) => p.dailyFatGoal),
                  color: AppColors.fat,
                  icon: LucideIcons.droplets,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(_itemAnims[4], const WaterTrackingCard()),
          const SizedBox(height: 16),

          // 5: Quick Actions
          _staggeredSlide(_itemAnims[5], const SectionLabel(title: 'Quick actions')),
          const SizedBox(height: 6),
          _staggeredSlide(
            _itemAnims[5],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChipButton(
                  icon: LucideIcons.camera,
                  label: 'Snap a meal',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.go('/snap');
                  },
                ),
                ActionChipButton(
                  icon: LucideIcons.clipboardList,
                  label: 'Open log',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/log');
                  },
                ),
                ActionChipButton(
                  icon: LucideIcons.barChart3,
                  label: 'See reports',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/reports');
                  },
                ),
              ],
            ),
          ),

          if (isAnonymous && recentMeals.isNotEmpty) ...[
            const SizedBox(height: 20),
            _staggeredSlide(
              _itemAnims[6],
              AppSectionCard(
                color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create an account to sync your progress.',
                        style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                      ),
                    ),
                    TextButton(
                      onPressed: () => AuthModal.show(context),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          _staggeredSlide(_itemAnims[7], const SectionLabel(title: 'Recent meals')),
          const SizedBox(height: 6),
          _staggeredSlide(
            _itemAnims[7],
            recentMeals.isEmpty
                ? AppEmptyState(
                    icon: LucideIcons.camera,
                    title: 'No meals logged yet',
                    body: 'Start with one quick snap.',
                    actionLabel: 'Snap first meal',
                    onAction: () => context.go('/snap'),
                  )
                : Column(
                    children: recentMeals.take(3).map((meal) => RecentMealTile(meal: meal)).toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _staggeredSlide(_itemAnims[7], const AdBanner()),
          const SizedBox(height: 16),
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





class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, color: colorScheme.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            '$streak Day Streak',
            style: AppTypography.labelMedium.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
