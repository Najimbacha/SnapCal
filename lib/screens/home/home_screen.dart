import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meal.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/recent_meal_tile.dart';
import '../../widgets/premium_prompt_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _animatedItemCount = 8;
  static bool _hasPlayedInitialAnimation = false;

  late final AnimationController _animController;
  late final List<Animation<double>> _itemAnims;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _itemAnims = List.generate(_animatedItemCount, (index) {
      final start = (index * 0.07).clamp(0.0, 0.7);
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start, 1, curve: Curves.easeOutCubic),
      );
    });

    if (!_hasPlayedInitialAnimation) {
      _animController.forward();
      _hasPlayedInitialAnimation = true;
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final mealState = context
        .select<MealProvider, ({bool loading, bool refreshing})>(
          (provider) => (
            loading: provider.isLoading,
            refreshing: provider.isRefreshing,
          ),
        );
    final totalCalories = context.select<MealProvider, int>(
      (provider) => provider.todaysTotalCalories,
    );
    final mealCount = context.select<MealProvider, int>(
      (provider) => provider.todaysMealCount,
    );
    final macros = context.select<MealProvider, Macros>(
      (provider) => provider.todaysTotalMacros,
    );
    final recentMeals = context.select<MealProvider, List<Meal>>(
      (provider) => provider.recentMeals,
    );
    final weeklyCalories = context.select<MealProvider, List<double>>(
      (provider) => provider.getWeeklyCalorieTrend(),
    );

    final calorieGoal = context.select<SettingsProvider, int>(
      (p) => math.max(p.dailyCalorieGoal, 1),
    );
    final proteinGoal = context.select<SettingsProvider, int>(
      (p) => p.dailyProteinGoal,
    );
    final carbGoal = context.select<SettingsProvider, int>(
      (p) => p.dailyCarbGoal,
    );
    final fatGoal = context.select<SettingsProvider, int>(
      (p) => p.dailyFatGoal,
    );
    final isPro = context.select<SettingsProvider, bool>((p) => p.isPro);
    final currentStreak = context.select<SettingsProvider, int>(
      (p) => p.currentStreak,
    );

    final authState = context
        .select<AuthProvider, ({String? name, bool isAnon})>(
          (p) => (name: p.user?.displayName, isAnon: p.isAnonymous),
        );

    final activityState = context.select<
      ActivityProvider,
      ({int steps, int burnedCalories, bool isTracking, String status})
    >(
      (p) => (
        steps: p.isTracking ? p.steps : 0,
        burnedCalories: p.isTracking ? p.burnedCalories : 0,
        isTracking: p.isTracking,
        status: p.status,
      ),
    );

    final waterState = context.select<WaterProvider, ({int total, int goal})>(
      (p) => (total: p.total, goal: p.goal),
    );

    final userName =
        (authState.name != null && authState.name!.isNotEmpty)
            ? authState.name!
            : 'SnapCal Member';

    final remaining = calorieGoal - totalCalories;
    final yesterdayCalories =
        weeklyCalories.length >= 2
            ? weeklyCalories[weeklyCalories.length - 2].round()
            : 0;
    final waterProgress = (waterState.total / math.max(waterState.goal, 1))
        .clamp(0.0, 1.0);
    final stepsProgress = (activityState.steps / 10000).clamp(0.0, 1.0);
    final calorieProgress = (totalCalories / calorieGoal).clamp(0.0, 1.4);
    final proteinProgress = (macros.protein / math.max(proteinGoal, 1)).clamp(
      0.0,
      1.0,
    );
    final dailyScore = _dailyScore(
      mealCount: mealCount,
      calorieProgress: calorieProgress,
      proteinProgress: proteinProgress,
      waterProgress: waterProgress,
      stepsProgress: stepsProgress,
    );

    final showFirstLoadSkeleton =
        mealState.loading && totalCalories == 0 && recentMeals.isEmpty;
    return AppPageScaffold(
      title: '',
      padding: EdgeInsets.zero,
      showHeader: false,
      extendBehindStatusBar: true,
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 160,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          _staggeredSlide(
            _itemAnims[0],
            _HomeInset(
              child: _HomeDashboardHeader(
                userName: userName,
                isPro: isPro,
                streak: currentStreak,
                isRefreshing: mealState.refreshing,
                onSettingsTap: () => context.go('/settings'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[1],
            showFirstLoadSkeleton
                ? const _HomeDashboardSkeleton()
                : _CalorieDashboardCard(
                  consumed: totalCalories,
                  goal: calorieGoal,
                  remaining: remaining,
                  mealCount: mealCount,
                  protein: macros.protein,
                  proteinGoal: proteinGoal,
                  yesterdayCalories: yesterdayCalories,
                  onAssistantTap: () => context.push('/assistant'),
                ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[2],
            _HomeInset(
              child: _ScanFoodButton(onTap: () => context.go('/snap')),
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[3],
            _MacroOverviewCard(
              macros: macros,
              proteinGoal: proteinGoal,
              carbGoal: carbGoal,
              fatGoal: fatGoal,
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[4],
            _TodayMealsPreviewCard(
              meals: recentMeals,
              onViewAll: () => context.go('/log'),
              onScan: () => context.go('/snap'),
              onManual: () => context.go('/log'),
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[5],
            _SecondaryDashboardGrid(
              waterTotal: waterState.total,
              waterGoal: waterState.goal,
              steps: activityState.steps,
              burnedCalories: activityState.burnedCalories,
              stepsUnit: l10n.home_steps_today,
              activityLive: activityState.status == 'walking',
              onWaterAdd: () => _addWater(context.read<WaterProvider>()),
              onWaterRemove: () => _removeWater(context.read<WaterProvider>()),
              onActivityTap: () => context.push('/activity'),
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[6],
            _CalendarProgressStrip(
              weeklyCalories: weeklyCalories,
              calorieGoal: calorieGoal,
              dailyScore: dailyScore,
              onTap: () => context.go('/reports'),
            ),
          ),
          if (!isPro && recentMeals.isNotEmpty) ...[
            const SizedBox(height: 10),
            _staggeredSlide(
              _itemAnims[7],
              PremiumPromptCard(
                style: PremiumPromptStyle.mini,
                title: l10n.home_go_deeper_title,
                subtitle: l10n.home_go_deeper_body,
                buttonText: 'Pro',
                icon: LucideIcons.sparkles,
                onTap:
                    () => PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.homeAha,
                    ),
              ),
            ),
          ],
          if (authState.isAnon && recentMeals.isNotEmpty) ...[
            const SizedBox(height: 18),
            _staggeredSlide(
              _itemAnims[7],
              _SyncPromptCard(onSaveTap: () => AuthModal.show(context)),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  int _dailyScore({
    required int mealCount,
    required double calorieProgress,
    required double proteinProgress,
    required double waterProgress,
    required double stepsProgress,
  }) {
    var score = 0;
    if (mealCount > 0) score += 20;
    if (calorieProgress >= 0.65 && calorieProgress <= 1.08) {
      score += 30;
    } else if (calorieProgress > 0.0 && calorieProgress < 1.18) {
      score += 16;
    }
    score += (proteinProgress.clamp(0.0, 1.0) * 20).round();
    score += (waterProgress.clamp(0.0, 1.0) * 15).round();
    score += (stepsProgress.clamp(0.0, 1.0) * 15).round();
    return score.clamp(0, 100);
  }

  void _addWater(WaterProvider water) {
    HapticFeedback.lightImpact();
    water.addWater(250);
  }

  void _removeWater(WaterProvider water) {
    HapticFeedback.lightImpact();
    water.removeWater(250);
  }
}

Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}

class _HomeInset extends StatelessWidget {
  final Widget child;

  const _HomeInset({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}

class _ScanFoodButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanFoodButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return AppScaleTap(
      onTap: onTap,
      child: Container(
        height: 62, // Taller premium feel
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            22,
          ), // Matching card radius perfectly
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10B981), // Premium emerald
              Color(
                0xFF0D9BD8,
              ), // Radiant sky/teal highlight to add incredible depth!
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: isDark ? 0.28 : 0.22,
            ), // 3D glass edge highlight
            width: 1.5,
          ),
          boxShadow: [
            // Glowing neon shadow that makes the card pop off the screen!
            BoxShadow(
              color: const Color(
                0xFF10B981,
              ).withValues(alpha: isDark ? 0.38 : 0.26),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Luxurious scan graphic pattern in background
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(
                  LucideIcons.scan,
                  size: 92,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular neon glow around scan icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.scanLine,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.home_scan_food,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.arrowRight,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardHeader extends StatelessWidget {
  final String userName;
  final bool isPro;
  final int streak;
  final bool isRefreshing;
  final VoidCallback onSettingsTap;

  const _HomeDashboardHeader({
    required this.userName,
    required this.isPro,
    required this.streak,
    required this.isRefreshing,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HomeHeaderButton(
            icon: LucideIcons.user,
            label: MaterialLocalizations.of(context).showMenuTooltip,
            onTap: onSettingsTap,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    userName,
                    style: AppTypography.titleMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _PremiumProBadge(isPro: isPro),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      isRefreshing
                          ? Padding(
                            key: const ValueKey('refreshing'),
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                          : const SizedBox.shrink(key: ValueKey('idle')),
                ),
              ],
            ),
          ),
          if (streak > 0)
            _HeaderStreakBadge(label: l10n.home_streak_days(streak)),
          const SizedBox(width: 6),
          _HomeHeaderButton(
            icon: LucideIcons.settings,
            label: MaterialLocalizations.of(context).showMenuTooltip,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _PremiumProBadge extends StatelessWidget {
  final bool isPro;

  const _PremiumProBadge({required this.isPro});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // If they are Pro, display a clean gold Pro badge
    if (isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD700), // Gold
              Color(0xFFFFA500), // Orange Gold
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.gem, color: Colors.black, size: 11),
            const SizedBox(width: 4),
            Text(
              l10n.home_pro_badge,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    // If they are not Pro, render the gorgeous interactive conversion upgrade pill!
    return AppScaleTap(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/paywall');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF10B981), // Emerald Primary
              Color(0xFF0D9BD8), // Sky Blue
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.gem, // Premium Diamond Icon
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              l10n.home_go_pro,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeHeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isDark
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : AppColors.lightCardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: colorScheme.primary, size: 18),
        ),
      ),
    );
  }
}

class _HeaderStreakBadge extends StatelessWidget {
  final String label;

  const _HeaderStreakBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.sky.withValues(alpha: isDark ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.sky.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendarCheck, color: AppColors.sky, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.90),
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieDashboardCard extends StatelessWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final int mealCount;
  final int protein;
  final int proteinGoal;
  final int yesterdayCalories;
  final VoidCallback onAssistantTap;

  const _CalorieDashboardCard({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.mealCount,
    required this.protein,
    required this.proteinGoal,
    required this.yesterdayCalories,
    required this.onAssistantTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isOverGoal = remaining < 0;
    final statusColor = isOverGoal ? colorScheme.error : colorScheme.primary;

    return _DashboardSectionFrame(
      accentColor: statusColor,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final goalProgress = (consumed / goal).clamp(0.0, 1.25);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gradient hero number: the main visual hierarchy anchor.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: ShaderMask(
                            shaderCallback:
                                (bounds) => LinearGradient(
                                  colors:
                                      isOverGoal
                                          ? [
                                            colorScheme.error,
                                            const Color(0xFFFF8A80),
                                          ]
                                          : [AppColors.primary, AppColors.sky],
                                ).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              '${remaining.abs()}',
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: compact ? 66 : 78,
                                fontWeight: FontWeight.w900,
                                height: 0.9,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOverGoal ? 'kcal over' : l10n.home_kcal_left,
                          style: AppTypography.titleMedium.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.88,
                            ),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CalorieInsightPill(
                    isOverGoal: isOverGoal,
                    remaining: remaining,
                    progress: goalProgress,
                    statusColor: statusColor,
                    compact: compact,
                    onTap: onAssistantTap,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DashboardStatsStrip(
                consumed: consumed,
                goal: goal,
                mealCount: mealCount,
                statusColor: statusColor,
              ),
              const SizedBox(height: 12),
              _YesterdayInsightRow(
                consumed: consumed,
                remaining: remaining,
                protein: protein,
                proteinGoal: proteinGoal,
                yesterdayCalories: yesterdayCalories,
                statusColor: statusColor,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _YesterdayInsightRow extends StatelessWidget {
  final int consumed;
  final int remaining;
  final int protein;
  final int proteinGoal;
  final int yesterdayCalories;
  final Color statusColor;

  const _YesterdayInsightRow({
    required this.consumed,
    required this.remaining,
    required this.protein,
    required this.proteinGoal,
    required this.yesterdayCalories,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final insight = _insightText;
    final comparison = _comparisonText;

    return Row(
      children: [
        Expanded(
          child: _MiniHeroChip(
            icon: LucideIcons.sparkles,
            label: insight,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniHeroChip(
            icon: LucideIcons.history,
            label: comparison,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String get _insightText {
    if (consumed == 0) return 'Scan your first meal';
    if (remaining < 0) return 'Go lighter next meal';
    if (proteinGoal > 0 && protein < proteinGoal * 0.55) {
      return 'Protein is behind';
    }
    return 'Next meal fits today';
  }

  String get _comparisonText {
    if (yesterdayCalories <= 0) return 'Build your baseline';
    final diff = consumed - yesterdayCalories;
    if (diff == 0) return 'Same as yesterday';
    if (diff < 0) return '${diff.abs()} kcal below yesterday';
    return '$diff kcal above yesterday';
  }
}

class _MiniHeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniHeroChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.82),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieInsightPill extends StatelessWidget {
  final bool isOverGoal;
  final int remaining;
  final double progress;
  final Color statusColor;
  final bool compact;
  final VoidCallback onTap;

  const _CalorieInsightPill({
    required this.isOverGoal,
    required this.remaining,
    required this.progress,
    required this.statusColor,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return AppScaleTap(
      onTap: onTap,
      child: Tooltip(
        message: l10n.assistant_title,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : colorScheme.primary).withValues(
                  alpha: isDark ? 0.08 : 0.04,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: (isDark ? Colors.white : colorScheme.primary)
                      .withValues(alpha: isDark ? 0.15 : 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedSparkleIcon(color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    l10n.assistant_title,
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSparkleIcon extends StatefulWidget {
  final Color color;
  const _AnimatedSparkleIcon({required this.color});

  @override
  State<_AnimatedSparkleIcon> createState() => _AnimatedSparkleIconState();
}

class _AnimatedSparkleIconState extends State<_AnimatedSparkleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glow
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: 0.2 + (_controller.value * 0.3),
                    ),
                    blurRadius: 10 + (_controller.value * 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // The Icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color, AppColors.sky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: Colors.white,
                size: 15,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardSectionFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;

  const _DashboardSectionFrame({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.07 : 0.045),
              colorScheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.34 : 0.66,
              ),
            ),
            colorScheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.17 : 0.48,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.20)
                  : AppColors.lightCardBorder.withValues(alpha: 0.7),
        ),
        boxShadow: [
          // Depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          // Accent edge glow — premium depth
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.055 : 0.032),
            blurRadius: 28,
            offset: const Offset(-6, -6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DashboardStatsStrip extends StatelessWidget {
  final int consumed;
  final int goal;
  final int mealCount;
  final Color statusColor;

  const _DashboardStatsStrip({
    required this.consumed,
    required this.goal,
    required this.mealCount,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _FlatStat(
            icon: LucideIcons.utensils,
            label: l10n.home_calories_eaten,
            value: '$consumed',
            unit: 'kcal',
            color: statusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FlatStat(
            icon: LucideIcons.target,
            label: l10n.home_metric_goal,
            value: '$goal',
            unit: 'kcal',
            color: AppColors.violet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FlatStat(
            icon: LucideIcons.utensils,
            label: l10n.home_metric_meals,
            value: '$mealCount',
            unit: l10n.log_entries.toLowerCase(),
            color: AppColors.carbs,
          ),
        ),
      ],
    );
  }
}

class _FlatStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _FlatStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.10 : 0.07),
            colorScheme.surface.withValues(alpha: isDark ? 0.16 : 0.30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.12 : 0.09),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroOverviewCard extends StatelessWidget {
  final Macros macros;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;

  const _MacroOverviewCard({
    required this.macros,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return _DashboardSectionFrame(
      accentColor: AppColors.violet,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.home_section_macros_today,
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Icon(
                LucideIcons.pieChart,
                color: colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MacroMeter(
                  label: l10n.result_protein,
                  consumed: macros.protein,
                  goal: proteinGoal,
                  color: AppColors.protein,
                  icon: LucideIcons.dumbbell,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroMeter(
                  label: l10n.result_carbs,
                  consumed: macros.carbs,
                  goal: carbGoal,
                  color: AppColors.carbs,
                  icon: LucideIcons.wheat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroMeter(
                  label: l10n.result_fat,
                  consumed: macros.fat,
                  goal: fatGoal,
                  color: AppColors.fat,
                  icon: LucideIcons.droplet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroMeter extends StatelessWidget {
  final String label;
  final int consumed;
  final int goal;
  final Color color;
  final IconData icon;

  const _MacroMeter({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedGoal = math.max(goal, 1);
    final progress = (consumed / normalizedGoal).clamp(0.0, 1.0);

    return Container(
      height: 68,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.10 : 0.07),
            colorScheme.surface.withValues(alpha: isDark ? 0.16 : 0.30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.12 : 0.09),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$consumed',
                          style: AppTypography.titleMedium.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            fontSize: 18,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'g',
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Premium bottom-flush progress bar
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, child) {
              return SizedBox(
                height: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(color: color),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SecondaryDashboardGrid extends StatelessWidget {
  final int waterTotal;
  final int waterGoal;
  final int steps;
  final int burnedCalories;
  final String stepsUnit;
  final bool activityLive;
  final VoidCallback onWaterAdd;
  final VoidCallback onWaterRemove;
  final VoidCallback onActivityTap;

  const _SecondaryDashboardGrid({
    required this.waterTotal,
    required this.waterGoal,
    required this.steps,
    required this.burnedCalories,
    required this.stepsUnit,
    required this.activityLive,
    required this.onWaterAdd,
    required this.onWaterRemove,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedWaterGoal = math.max(waterGoal, 1);
    final waterProgress = (waterTotal / normalizedWaterGoal).clamp(0.0, 1.0);
    final stepsProgress = (steps / 10000).clamp(0.0, 1.0);

    return _DashboardSectionFrame(
      accentColor: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.home_daily_wellness,
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Icon(
                LucideIcons.activity,
                color: colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModernMetricPanel(
                  icon: LucideIcons.droplets,
                  color: AppColors.sky,
                  title: l10n.water_hydration,
                  primaryMetric: '$waterTotal ml',
                  secondaryMetric: 'Goal: $waterGoal ml',
                  progress: waterProgress,
                  footerText: '+250ml per tap',
                  liquidFill: true,
                  onTap: onWaterAdd,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppPulse(
                  pulsing: activityLive,
                  child: _ModernMetricPanel(
                    icon: LucideIcons.footprints,
                    color: AppColors.primary,
                    title: l10n.home_metric_activity,
                    primaryMetric: '$steps',
                    secondaryMetric: '$burnedCalories activity kcal',
                    progress: stepsProgress,
                    footerText: activityLive ? 'Walking • Live' : 'Steps today',
                    motionTrail: true,
                    motionActive: activityLive,
                    onTap: onActivityTap,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayMealsPreviewCard extends StatelessWidget {
  final List<Meal> meals;
  final VoidCallback onViewAll;
  final VoidCallback onScan;
  final VoidCallback onManual;

  const _TodayMealsPreviewCard({
    required this.meals,
    required this.onViewAll,
    required this.onScan,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return _DashboardSectionFrame(
      accentColor: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today\'s Meals',
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                  textStyle: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                child: Text(meals.isEmpty ? 'Open log' : l10n.home_view_all),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (meals.isEmpty)
            _EmptyMealsInline(onScan: onScan, onManual: onManual)
          else
            Column(
              children: [
                const SizedBox(height: 4),
                ...meals
                    .take(3)
                    .expand(
                      (meal) => [
                        RecentMealTile(meal: meal, onTap: onViewAll),
                        if (meal != meals.take(3).last)
                          Divider(
                            height: 1,
                            thickness: 0.8,
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.18,
                            ),
                            indent: 80,
                          ),
                      ],
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyMealsInline extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onManual;

  const _EmptyMealsInline({required this.onScan, required this.onManual});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.utensilsCrossed,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.home_no_meals_title,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: onManual,
            child: Text(AppLocalizations.of(context)!.home_add),
          ),
          FilledButton(
            onPressed: onScan,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.home_scan_food),
          ),
        ],
      ),
    );
  }
}

class _CalendarProgressStrip extends StatelessWidget {
  final List<double> weeklyCalories;
  final int calorieGoal;
  final int dailyScore;
  final VoidCallback onTap;

  const _CalendarProgressStrip({
    required this.weeklyCalories,
    required this.calorieGoal,
    required this.dailyScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final calories =
          index < weeklyCalories.length ? weeklyCalories[index].round() : 0;
      return (date: date, calories: calories);
    });

    return AppScaleTap(
      onTap: onTap,
      child: _DashboardSectionFrame(
        accentColor: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: dailyScore / 100,
                    strokeWidth: 6,
                    backgroundColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.18,
                    ),
                    color: _scoreColor(dailyScore),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '$dailyScore',
                      style: AppTypography.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.home_daily_score,
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        color: colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children:
                        days
                            .map(
                              (day) => Expanded(
                                child: _CalendarDayDot(
                                  label: _dayLabel(day.date),
                                  calories: day.calories,
                                  goal: calorieGoal,
                                  isToday:
                                      day.date.day == today.day &&
                                      day.date.month == today.month &&
                                      day.date.year == today.year,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.primary;
    if (score >= 45) return AppColors.amber;
    return AppColors.error;
  }

  String _dayLabel(DateTime date) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }
}

class _CalendarDayDot extends StatelessWidget {
  final String label;
  final int calories;
  final int goal;
  final bool isToday;

  const _CalendarDayDot({
    required this.label,
    required this.calories,
    required this.goal,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _statusColor;
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isToday ? 25 : 20,
          height: isToday ? 25 : 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: calories == 0 ? 0.10 : 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday ? color : color.withValues(alpha: 0.22),
              width: isToday ? 2 : 1,
            ),
          ),
          child:
              calories == 0
                  ? null
                  : Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  Color get _statusColor {
    if (calories == 0) return AppColors.lightTextSecondary;
    final ratio = calories / math.max(goal, 1);
    if (ratio >= 0.75 && ratio <= 1.08) return AppColors.primary;
    if (ratio <= 1.18) return AppColors.amber;
    return AppColors.error;
  }
}

class _ModernMetricPanel extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String primaryMetric;
  final String secondaryMetric;
  final double progress;
  final String footerText;
  final bool liquidFill;
  final bool motionTrail;
  final bool motionActive;
  final VoidCallback onTap;

  const _ModernMetricPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.primaryMetric,
    required this.secondaryMetric,
    required this.progress,
    required this.footerText,
    this.liquidFill = false,
    this.motionTrail = false,
    this.motionActive = false,
    required this.onTap,
  });

  @override
  State<_ModernMetricPanel> createState() => _ModernMetricPanelState();
}

class _ModernMetricPanelState extends State<_ModernMetricPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (_shouldAnimateOverlay) _waveController.repeat();
  }

  @override
  void didUpdateWidget(covariant _ModernMetricPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimateOverlay && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!_shouldAnimateOverlay && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  bool get _shouldAnimateOverlay {
    return widget.liquidFill || (widget.motionTrail && widget.motionActive);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barEndColor = Color.lerp(widget.color, Colors.white, 0.35)!;

    return AppScaleTap(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withValues(alpha: widget.liquidFill ? 0.08 : 0.07),
              colorScheme.surface.withValues(alpha: 0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.color.withValues(alpha: 0.10)),
        ),
        child: Stack(
          children: [
            if (widget.liquidFill)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 720),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(end: widget.progress),
                  builder: (context, animatedProgress, child) {
                    return AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _MetricLiquidFillPainter(
                            animationValue: _waveController.value,
                            progress: animatedProgress,
                            color: widget.color,
                            isDark: isDark,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            if (widget.motionTrail)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 620),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(end: widget.progress),
                  builder: (context, animatedProgress, child) {
                    if (widget.motionActive) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _MetricStepTrailPainter(
                              animationValue: _waveController.value,
                              progress: animatedProgress,
                              color: widget.color,
                              isDark: isDark,
                              active: true,
                            ),
                          );
                        },
                      );
                    }

                    return CustomPaint(
                      painter: _MetricStepTrailPainter(
                        animationValue: 0,
                        progress: animatedProgress,
                        color: widget.color,
                        isDark: isDark,
                        active: false,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, size: 16, color: widget.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.primaryMetric,
                      style: AppTypography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.secondaryMetric,
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: widget.progress),
                    builder: (context, value, child) {
                      return Container(
                        height: 5,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value.clamp(0.0, 1.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [widget.color, barEndColor],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.footerText,
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricLiquidFillPainter extends CustomPainter {
  final double animationValue;
  final double progress;
  final Color color;
  final bool isDark;

  const _MetricLiquidFillPainter({
    required this.animationValue,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fillTop = size.height * (1 - progress.clamp(0.0, 1.0));
    final waveAmplitude = size.height * 0.045;
    final path = Path()..moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final wave = math.sin((x / 18) + animationValue * math.pi * 2);
      path.lineTo(x, fillTop + wave * waveAmplitude);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();

    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              color.withValues(alpha: isDark ? 0.22 : 0.17),
              AppColors.sky.withValues(alpha: isDark ? 0.16 : 0.12),
            ],
          ).createShader(Offset.zero & size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MetricLiquidFillPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

class _MetricStepTrailPainter extends CustomPainter {
  final double animationValue;
  final double progress;
  final Color color;
  final bool isDark;
  final bool active;

  const _MetricStepTrailPainter({
    required this.animationValue,
    required this.progress,
    required this.color,
    required this.isDark,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final clampedProgress = progress.clamp(0.0, 1.0);
    final visibleSteps = 4 + (clampedProgress * 5).round();
    final phase = active ? animationValue : 0.0;
    final baseAlpha = isDark ? 0.26 : 0.18;
    final glowAlpha = active ? (isDark ? 0.16 : 0.10) : 0.0;

    final glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: glowAlpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.74, size.height * 0.34),
              radius: size.width * 0.52,
            ),
          );

    if (active) {
      canvas.drawRect(Offset.zero & size, glowPaint);
    }

    final pathPaint =
        Paint()
          ..color = color.withValues(alpha: isDark ? 0.15 : 0.11)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round;

    final path = Path();
    for (double x = -size.width * 0.12; x <= size.width * 1.04; x += 6) {
      final normalizedX = x / size.width;
      final y =
          size.height * 0.62 -
          math.sin((normalizedX * math.pi * 1.6) + phase * math.pi * 2) *
              size.height *
              0.085;
      if (x == -size.width * 0.12) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, pathPaint);

    for (int i = 0; i < visibleSteps; i++) {
      final t = visibleSteps == 1 ? 0.0 : i / (visibleSteps - 1);
      final shiftedT = active ? (t + phase * 0.18) % 1.0 : t;
      final x = size.width * (0.12 + shiftedT * 0.76);
      final y =
          size.height * 0.60 -
          math.sin((shiftedT * math.pi * 1.6) + phase * math.pi * 2) *
              size.height *
              0.095;
      final fade =
          active ? (0.65 + 0.35 * math.sin((phase + t) * math.pi * 2)) : 0.72;
      final footAlpha = baseAlpha * fade;
      final footprintPaint =
          Paint()
            ..color = Color.lerp(
              color,
              AppColors.primary,
              0.35,
            )!.withValues(alpha: footAlpha);

      _drawFootprint(
        canvas,
        Offset(x, y),
        footprintPaint,
        mirrored: i.isOdd,
        scale: active ? 1.0 + (0.05 * fade) : 0.95,
      );
    }
  }

  void _drawFootprint(
    Canvas canvas,
    Offset center,
    Paint paint, {
    required bool mirrored,
    required double scale,
  }) {
    final direction = mirrored ? -1.0 : 1.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(direction * 0.36);
    canvas.scale(scale, scale);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 12),
      paint,
    );
    canvas.drawCircle(const Offset(-2.5, -7.0), 1.4, paint);
    canvas.drawCircle(const Offset(0, -8.6), 1.3, paint);
    canvas.drawCircle(const Offset(2.4, -7.0), 1.2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MetricStepTrailPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.active != active;
  }
}

class _SyncPromptCard extends StatelessWidget {
  final VoidCallback onSaveTap;

  const _SyncPromptCard({required this.onSaveTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              isDark
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.shieldCheck,
              color: colorScheme.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.home_sync_prompt,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: onSaveTap,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              textStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardSkeleton extends StatelessWidget {
  const _HomeDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _SkeletonBox(
                width: 132,
                height: 132,
                radius: 66,
                color: colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _SkeletonBox(
                      width: double.infinity,
                      height: 24,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 12),
                    _SkeletonBox(
                      width: double.infinity,
                      height: 18,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonBox(
                      width: double.infinity,
                      height: 18,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonBox(
                      width: double.infinity,
                      height: 18,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 52,
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 52,
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween<double>(begin: 0.35, end: 0.75),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: value),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}
