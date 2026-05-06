import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/widgets/ad_banner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_utils.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/water_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/auth_modal.dart';
import 'widgets/recent_meal_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<Animation<double>> _itemAnims = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    for (int i = 0; i < 10; i++) {
      _itemAnims.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1, (i * 0.1) + 0.4, curve: Curves.easeOutBack),
        ),
      );
    }
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Selectors with explicit types to avoid naming conflicts
    final totalCalories = context.select<MealProvider, int>((p) => p.todaysTotalCalories);
    final macros = context.select<MealProvider, dynamic>((p) => p.todaysTotalMacros);
    final calorieGoal = context.select<SettingsProvider, int>((p) => p.dailyCalorieGoal);
    final streak = context.select<SettingsProvider, int>((p) => p.currentStreak);
    
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAnonymous = auth.isAnonymous;
    
    final recentMeals = context.select<MealProvider, List<Meal>>((p) => p.recentMeals);
    
    // Health / Activity Data
    final activity = context.watch<ActivityProvider>();
    final burnedCalories = activity.burnedCalories;
    final steps = activity.steps;
    final isHealthAuthorized = activity.isAuthorized;

    final l10n = AppLocalizations.of(context)!;
    final name = user?.displayName?.split(' ').first ?? user?.email?.split('@').first ?? l10n.home_default_name;
    final size = Responsive.size(context) == ScreenSize.small ? 130.0 : 150.0;
    final greeting = _getGreeting(l10n);

    return AppPageScaffold(
      title: name,
      subtitle: greeting,
      leading: IconButton(
        icon: const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 22),
        onPressed: () => context.push('/assistant'),
        tooltip: l10n.assistant_title,
      ),
      trailing: AppScaleTap(
        onTap: () => context.go('/settings'),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: Icon(LucideIcons.user, size: 18, color: colorScheme.primary),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // 0: Hero Calorie Tracker
          _staggeredSlide(
            _itemAnims[0],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.8),
                    colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.1 : 0.4),
                  ],
                ),
              ),
              child: Column(
                children: [
                  _StreakBadge(streak: streak),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Glow
                      Container(
                        width: size * 0.8,
                        height: size * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.25),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size,
                        height: size,
                        child: CustomPaint(
                          painter: GlassCaloriePainter(
                            progress: (totalCalories / calorieGoal).clamp(0.0, 1.0),
                            color: colorScheme.primary,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${calorieGoal - totalCalories}',
                            style: AppTypography.heading1.copyWith(
                              fontSize: size * 0.28,
                              fontWeight: FontWeight.w900,
                              color: isDark ? colorScheme.onSurface : colorScheme.onPrimaryContainer,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            l10n.home_calories_remaining.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w800,
                              fontSize: size * 0.05,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppScaleTap(
                    onTap: () {
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
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 12,
                            color: isDark ? colorScheme.primary : colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.feature_insights_title,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? colorScheme.onSurface : colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          // 2: Dashboard Strip
          _staggeredSlide(
            _itemAnims[2],
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.6),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DashboardSegment(
                      label: l10n.home_metric_goal,
                      value: '$calorieGoal',
                      unit: 'kcal',
                      icon: LucideIcons.flame,
                      color: AppColors.primary,
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _DashboardSegment(
                      label: l10n.home_metric_meals,
                      value: '${context.select<MealProvider, int>((p) => p.todaysMealCount)}',
                      unit: l10n.log_entries,
                      icon: LucideIcons.utensils,
                      color: AppColors.carbs,
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _DashboardSegment(
                      label: l10n.home_metric_activity,
                      value: isHealthAuthorized ? '$burnedCalories' : '--',
                      unit: 'kcal',
                      icon: LucideIcons.activity,
                      color: Colors.orange,
                      onTap: isHealthAuthorized ? null : () => activity.authorize(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          // 3: Macro Glass Bar
          _staggeredSlide(
            _itemAnims[3],
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.6),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MacroChip(
                        label: l10n.result_protein,
                        value: '${macros.protein}g',
                        goal: '${context.select<SettingsProvider, int>((p) => p.dailyProteinGoal)}g',
                        color: AppColors.protein,
                      ),
                      _MacroChip(
                        label: l10n.result_carbs,
                        value: '${macros.carbs}g',
                        goal: '${context.select<SettingsProvider, int>((p) => p.dailyCarbGoal)}g',
                        color: AppColors.carbs,
                      ),
                      _MacroChip(
                        label: l10n.result_fat,
                        value: '${macros.fat}g',
                        goal: '${context.select<SettingsProvider, int>((p) => p.dailyFatGoal)}g',
                        color: AppColors.fat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          _MacroProgressPart(
                            value: macros.protein.toDouble(),
                            goal: context.read<SettingsProvider>().dailyProteinGoal.toDouble(),
                            color: AppColors.protein,
                          ),
                          const SizedBox(width: 2),
                          _MacroProgressPart(
                            value: macros.carbs.toDouble(),
                            goal: context.read<SettingsProvider>().dailyCarbGoal.toDouble(),
                            color: AppColors.carbs,
                          ),
                          const SizedBox(width: 2),
                          _MacroProgressPart(
                            value: macros.fat.toDouble(),
                            goal: context.read<SettingsProvider>().dailyFatGoal.toDouble(),
                            color: AppColors.fat,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          // 4: Hydration
          _staggeredSlide(
            _itemAnims[4],
            const _LiquidHydrationTracker(),
          ),

          const SizedBox(height: 24),
          // 5: Quick Actions
          _staggeredSlide(_itemAnims[5], SectionLabel(title: l10n.home_section_actions)),
          const SizedBox(height: 12),
          _staggeredSlide(
            _itemAnims[5],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionChipButton(
                  icon: LucideIcons.camera,
                  label: l10n.snap_log_meal,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.go('/snap');
                  },
                ),
                ActionChipButton(
                  icon: LucideIcons.clipboardList,
                  label: l10n.home_action_log,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/log');
                  },
                ),
                ActionChipButton(
                  icon: LucideIcons.barChart3,
                  label: l10n.home_action_reports,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/reports');
                  },
                ),
                ActionChipButton(
                  icon: LucideIcons.sparkles,
                  label: l10n.feature_insights_title,
                  onTap: () {
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
                  },
                ),
              ],
            ),
          ),

          if (isAnonymous && recentMeals.isNotEmpty) ...[
            const SizedBox(height: 24),
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
                        l10n.home_sync_prompt,
                        style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                      ),
                    ),
                    TextButton(
                      onPressed: () => AuthModal.show(context),
                      child: Text(l10n.common_save),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          _staggeredSlide(_itemAnims[7], SectionLabel(title: l10n.home_recent_meals)),
          const SizedBox(height: 12),
          _staggeredSlide(
            _itemAnims[7],
            recentMeals.isEmpty
                ? AppEmptyState(
                    icon: LucideIcons.camera,
                    title: l10n.home_no_meals_title,
                    body: l10n.home_no_meals_body,
                    actionLabel: l10n.snap_log_meal,
                    onAction: () => context.go('/snap'),
                  )
                : Column(
                    children: recentMeals.take(3).map((meal) => RecentMealTile(meal: meal)).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          _staggeredSlide(_itemAnims[7], const AdBanner()),
          const SizedBox(height: 32),
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
}

Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
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
            AppLocalizations.of(context)!.home_streak_days(streak),
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

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                fontSize: 8,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' / $goal',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroProgressPart extends StatelessWidget {
  final double value;
  final double goal;
  final Color color;

  const _MacroProgressPart({
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = (value / goal).clamp(0.0, 1.0);
    if (percentage == 0) return const SizedBox.shrink();

    return Expanded(
      flex: (percentage * 100).toInt().clamp(1, 100),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSegment extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardSegment({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return AppScaleTap(
      onTap: onTap!,
      child: content,
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colorScheme.outlineVariant.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _LiquidHydrationTracker extends StatelessWidget {
  const _LiquidHydrationTracker();

  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final progress = (water.total / water.goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WavePainter(
                        progress: progress,
                        color: Colors.blue.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      LucideIcons.droplets,
                      color: Colors.blue.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.home_water_title.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${water.total}',
                      style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${water.goal} ml',
                      style: AppTypography.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _WaterButton(
                      icon: LucideIcons.minus,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        water.removeWater(250);
                      },
                    ),
                    const SizedBox(width: 12),
                    _WaterButton(
                      icon: LucideIcons.plus,
                      isPrimary: true,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        water.addWater(250);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _WaterButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.blue : Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : Colors.blue,
          size: 20,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final y = size.height * (1 - progress);
    path.moveTo(0, y);
    path.lineTo(size.width, y);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.progress != progress;
}

class GlassCaloriePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  GlassCaloriePainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            color.withValues(alpha: 0.5),
            color,
            color,
          ],
          stops: const [0.0, 0.8, 1.0],
          transform: const GradientRotation(-3.14159 / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -3.14159 / 2,
        3.14159 * 2 * progress,
        false,
        progressPaint,
      );
      
      final innerShadowPaint = Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.05 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(center, radius - strokeWidth, innerShadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GlassCaloriePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
