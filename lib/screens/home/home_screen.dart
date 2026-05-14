import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/widgets/ad_banner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/water_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/recent_meal_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _animatedItemCount = 9;

  late final AnimationController _animController;
  late final List<Animation<double>> _itemAnims;
  bool _openingInsights = false;

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
    _animController.forward();
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

    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final activity = context.watch<ActivityProvider>();
    final water = context.watch<WaterProvider>();

    final greeting = _getGreeting(l10n);
    final displayName = auth.user?.displayName;
    final userName =
        (displayName != null && displayName.isNotEmpty)
            ? displayName
            : 'SnapCal Member';

    final calorieGoal = math.max(settings.dailyCalorieGoal, 1);
    final remaining = calorieGoal - totalCalories;
    final progress = (totalCalories / calorieGoal).clamp(0.0, 1.0);
    final hasMealsToday = mealCount > 0 || totalCalories > 0;
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
          bottom: 110,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          _staggeredSlide(
            _itemAnims[0],
            _HomeInset(
              child: _HomeDashboardHeader(
                greeting: greeting,
                userName: userName,
                isRefreshing: mealState.refreshing,
                onSettingsTap: () => context.go('/settings'),
                onAssistantTap: () => context.push('/assistant'),
                assistantLabel: l10n.assistant_title,
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
                  progress: progress,
                  streak: settings.currentStreak,
                  mealCount: mealCount,
                ),
          ),
          if (!showFirstLoadSkeleton && !hasMealsToday) ...[
            const SizedBox(height: 10),
            _staggeredSlide(
              _itemAnims[2],
              _HomeInset(
                child: _FirstMealPrompt(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/snap');
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[hasMealsToday ? 2 : 3],
            _MacroOverviewCard(
              macros: macros,
              proteinGoal: settings.dailyProteinGoal,
              carbGoal: settings.dailyCarbGoal,
              fatGoal: settings.dailyFatGoal,
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[hasMealsToday ? 3 : 4],
            _SecondaryDashboardGrid(
              waterTotal: water.total,
              waterGoal: water.goal,
              steps: activity.isTracking ? activity.steps : 0,
              stepsUnit: l10n.home_steps_today,
              activityLive: activity.status == 'walking',
              onWaterAdd: () => _addWater(water),
              onWaterRemove: () => _removeWater(water),
              onActivityTap: () => context.push('/activity'),
            ),
          ),
          const SizedBox(height: 18),
          _staggeredSlide(
            _itemAnims[hasMealsToday ? 4 : 5],
            _HomeInset(
              child: _QuickActionRow(
                onReportsTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/reports');
                },
                onInsightsTap: _openInsights,
              ),
            ),
          ),
          if (auth.isAnonymous && recentMeals.isNotEmpty) ...[
            const SizedBox(height: 18),
            _staggeredSlide(
              _itemAnims[5],
              _SyncPromptCard(onSaveTap: () => AuthModal.show(context)),
            ),
          ],
          const SizedBox(height: 22),
          _staggeredSlide(
            _itemAnims[6],
            _HomeInset(
              child: SectionLabel(
                title: l10n.home_recent_meals,
                action: recentMeals.isEmpty ? null : l10n.home_view_all,
                onActionTap:
                    recentMeals.isEmpty ? null : () => context.go('/log'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _staggeredSlide(
            _itemAnims[7],
            _HomeInset(
              child:
                  recentMeals.isEmpty
                      ? const _EmptyMealsCard()
                      : Column(
                        children:
                            recentMeals
                                .take(3)
                                .map((meal) => RecentMealTile(meal: meal))
                                .toList(),
                      ),
            ),
          ),
          const SizedBox(height: 18),
          _staggeredSlide(_itemAnims[8], _HomeInset(child: AdBanner())),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.home_greeting_morning;
    if (hour < 17) return l10n.home_greeting_afternoon;
    return l10n.home_greeting_evening;
  }

  void _openInsights() {
    if (_openingInsights) return;
    _openingInsights = true;
    HapticFeedback.lightImpact();
    final insights = context.read<InsightsProvider>();
    if (!insights.hasReport) {
      insights.generateWeeklyReport(
        meals: context.read<MealProvider>(),
        settings: context.read<SettingsProvider>(),
        activity: context.read<ActivityProvider>(),
        waterRepo: context.read<WaterRepository>(),
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }
    context.push('/insights');
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _openingInsights = false;
    });
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

class _HomeDashboardHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final bool isRefreshing;
  final VoidCallback onSettingsTap;
  final VoidCallback onAssistantTap;
  final String assistantLabel;

  const _HomeDashboardHeader({
    required this.greeting,
    required this.userName,
    required this.isRefreshing,
    required this.onSettingsTap,
    required this.onAssistantTap,
    required this.assistantLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 35,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        greeting,
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.92,
                          ),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0,
                          height: 0.9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: AppTypography.titleMedium.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.94),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
          const SizedBox(width: 6),
          _HomeHeaderAiButton(label: assistantLabel, onTap: onAssistantTap),
          const SizedBox(width: 6),
          _HomeHeaderSettingsButton(
            label: MaterialLocalizations.of(context).showMenuTooltip,
            onTap: onSettingsTap,
          ),
        ],
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

class _HomeHeaderAiButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HomeHeaderAiButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.primary.withValues(
                alpha: isDark ? 0.28 : 0.18,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.10 : 0.06,
                ),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.sparkles, color: colorScheme.primary, size: 14),
              const SizedBox(width: 5),
              Text(
                'Coach',
                style: AppTypography.labelLarge.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeaderSettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HomeHeaderSettingsButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.18)
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.settings,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Settings',
                style: AppTypography.labelLarge.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalorieDashboardCard extends StatelessWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final double progress;
  final int streak;
  final int mealCount;

  const _CalorieDashboardCard({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.streak,
    required this.mealCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isOverGoal = remaining < 0;
    final statusColor = isOverGoal ? colorScheme.error : colorScheme.primary;

    return _DashboardSectionFrame(
      accentColor: statusColor,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final ringSize = compact ? 78.0 : 88.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: _StatusPill(
                      icon: LucideIcons.sparkle,
                      label:
                          isOverGoal
                              ? l10n.home_goal_reached
                              : l10n.home_calories_remaining,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Streak pill with subtle pulse
                  _StatusPill(
                        icon: LucideIcons.calendarCheck,
                        label: l10n.home_streak_days(streak),
                        color: AppColors.sky,
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 1.0,
                        end: 1.02,
                        duration: 3000.ms,
                        curve: Curves.easeInOut,
                      ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ★ Gradient hero number — the single biggest "wow" detail
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
                                color: Colors.white, // Shader needs white
                                fontSize: compact ? 54 : 64,
                                fontWeight: FontWeight.w900,
                                height: 0.92,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          isOverGoal ? 'kcal over' : l10n.home_kcal_left,
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.86,
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
                  const SizedBox(width: 16),
                  // Calorie ring with ambient glow
                  _GlowingCalorieRing(
                    size: ringSize,
                    progress: progress,
                    color: statusColor,
                    center: '${(progress * 100).round()}%',
                    label: l10n.home_eaten_progress,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress rail with shimmer on completion
              _ModernProgressRail(progress: progress, color: statusColor),
              const SizedBox(height: 10),
              _DashboardStatsStrip(
                consumed: consumed,
                goal: goal,
                mealCount: mealCount,
                statusColor: statusColor,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FirstMealPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const _FirstMealPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.camera,
                  color: colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.home_first_meal_cta_title,
                      style: AppTypography.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.home_first_meal_cta_body,
                      style: AppTypography.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                color: colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSectionFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? accentColor;

  const _DashboardSectionFrame({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.radius = 28,
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
              accent.withValues(alpha: isDark ? 0.09 : 0.06),
              colorScheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.38 : 0.74,
              ),
            ),
            colorScheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.20 : 0.56,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
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
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          // Accent edge glow — premium depth
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 32,
            offset: const Offset(-6, -6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ModernProgressRail extends StatelessWidget {
  final double progress;
  final Color color;

  const _ModernProgressRail({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: progress),
      builder: (context, value, child) {
        return Container(
          height: 14,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          Color.lerp(color, AppColors.sky, 0.42)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  )
                  // ★ Shimmer sweep after the bar fills
                  .animate(delay: 800.ms)
                  .shimmer(
                    duration: 1200.ms,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
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
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
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
        color: color.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.12 : 0.10),
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

class _AnimatedCalorieRing extends StatelessWidget {
  final double size;
  final double progress;
  final Color color;
  final String center;
  final String label;

  const _AnimatedCalorieRing({
    required this.size,
    required this.progress,
    required this.color,
    required this.center,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: progress),
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _CalorieRingPainter(
                  progress: animatedProgress,
                  color: color,
                  trackColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.62,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        center,
                        style: AppTypography.headlineSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Calorie ring wrapped with an ambient glow that intensifies with progress
class _GlowingCalorieRing extends StatelessWidget {
  final double size;
  final double progress;
  final Color color;
  final String center;
  final String label;

  const _GlowingCalorieRing({
    required this.size,
    required this.progress,
    required this.color,
    required this.center,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Ambient glow — always present at a subtle base, scales with progress
    final glowAlpha =
        progress < 0.1
            ? 0.03
            : (progress < 0.3
                ? 0.045
                : (progress < 0.7 ? 0.075 : (progress >= 1.0 ? 0.16 : 0.10)));
    final glowRadius =
        progress < 0.1
            ? 12.0
            : (progress < 0.3
                ? 16.0
                : (progress < 0.7 ? 24.0 : (progress >= 1.0 ? 40.0 : 32.0)));

    Widget ring = _AnimatedCalorieRing(
      size: size,
      progress: progress,
      color: color,
      center: center,
      label: label,
    );

    // Celebration shimmer when 100%
    if (progress >= 1.0) {
      ring = ring
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 2400.ms,
            color: Colors.white.withValues(alpha: 0.12),
          );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glowAlpha),
            blurRadius: glowRadius,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ring,
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _CalorieRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.width < 140 ? 6.5 : 8.0;
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = trackColor;
    final active =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color;

    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
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
    final normalizedGoal = math.max(goal, 1);
    final progress = (consumed / normalizedGoal).clamp(0.0, 1.0);
    // Lighter end-color for gradient bar
    final barEndColor = Color.lerp(color, Colors.white, 0.35)!;

    return Container(
      height: 102,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
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
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${consumed}g',
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 7),
          // ★ Gradient macro bar instead of flat color
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, child) {
              return Container(
                height: 6,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, barEndColor]),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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
  final String stepsUnit;
  final bool activityLive;
  final VoidCallback onWaterAdd;
  final VoidCallback onWaterRemove;
  final VoidCallback onActivityTap;

  const _SecondaryDashboardGrid({
    required this.waterTotal,
    required this.waterGoal,
    required this.steps,
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
      accentColor: AppColors.sky,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${l10n.water_hydration} • ${l10n.home_metric_activity}',
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
                  onTap: onWaterAdd,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppPulse(
                  pulsing: activityLive,
                  child: _ModernMetricPanel(
                    icon: LucideIcons.footprints,
                    color: AppColors.sky,
                    title: l10n.home_metric_activity,
                    primaryMetric: '$steps',
                    secondaryMetric: 'Goal: 10,000',
                    progress: stepsProgress,
                    footerText: activityLive ? 'Walking • Live' : 'Steps today',
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

class _ModernMetricPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String primaryMetric;
  final String secondaryMetric;
  final double progress;
  final String footerText;
  final VoidCallback onTap;

  const _ModernMetricPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.primaryMetric,
    required this.secondaryMetric,
    required this.progress,
    required this.footerText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barEndColor = Color.lerp(color, Colors.white, 0.35)!;

    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
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
                primaryMetric,
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
              secondaryMetric,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, value, child) {
                return Container(
                  height: 5,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, barEndColor],
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
              footerText,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final VoidCallback onReportsTap;
  final VoidCallback onInsightsTap;

  const _QuickActionRow({
    required this.onReportsTap,
    required this.onInsightsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChipButton(
          icon: LucideIcons.barChart3,
          label: l10n.home_action_reports,
          onTap: onReportsTap,
        ),
        ActionChipButton(
          icon: LucideIcons.sparkles,
          label: l10n.feature_insights_title,
          onTap: onInsightsTap,
        ),
      ],
    );
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

class _EmptyMealsCard extends StatelessWidget {
  const _EmptyMealsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              LucideIcons.utensilsCrossed,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.home_no_meals_title,
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.log_track_prompt,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
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
