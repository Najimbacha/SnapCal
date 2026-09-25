import 'package:snapcal/data/services/force_update_service.dart';
import '../../data/repositories/activity_repository.dart';
import '../../providers/achievements_provider.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../widgets/wazn_icons.dart';

import '../../widgets/notification_permission_prompt.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meal.dart';
import 'widgets/activity_health_connect_sheet.dart';
import '../log/widgets/hydration_sheet.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../data/services/promotional_paywall_service.dart';
import '../../data/services/app_prompt_session_coordinator.dart';
import '../../data/services/first_meal_guide_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/home_upgrade_chip.dart';
import '../../widgets/motion/arriving_item.dart';
import '../../widgets/motion/count_up_text.dart';
import '../../widgets/motion/rolling_number.dart';
import '../../widgets/motion/visible_gate.dart';
import '../../widgets/scan_choice_sheet.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/home_nutrition_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _animatedItemCount = 8;
  static bool _hasPlayedInitialAnimation = false;

  late final AnimationController _animController;
  late final List<Animation<double>> _itemAnims;
  late final Future<bool> _firstMealGuidePending;
  Timer? _upgradePromptTimer;
  bool _showFirstMealGuide = false;

  /// The first Home of this app session: its numbers count in from zero.
  late final bool _firstOpen = !_hasPlayedInitialAnimation;

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

    _firstMealGuidePending = _loadFirstMealGuide();

    // Badges are worked out from what is already logged. Nothing ever asked
    // for them, so not one of them could unlock.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(achievementsProvider.notifier).refreshAchievements());
    });

    // Smart Premium Encouragement (Aha Moment)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _upgradePromptTimer = Timer(
        const Duration(milliseconds: 1500),
        _maybePromptUpgrade,
      );
    });
  }

  /// Offers are evaluated only on an unobstructed Home route.
  Future<void> _maybePromptUpgrade() async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

    // A waiting update comes first: it is the one thing worth asking about,
    // and two prompts back to back is one too many.
    if (await ForceUpdateService().checkAndPrompt(context)) {
      AppPromptSessionCoordinator().suppressAutomaticOffers();
      return;
    }
    if (!mounted) return;

    // The user's first useful action comes before permissions or offers. The
    // guide is inline rather than modal, but showing another prompt over it
    // would turn a calm first Home visit into a stack of demands.
    if (await _firstMealGuidePending) {
      AppPromptSessionCoordinator().suppressAutomaticOffers();
      return;
    }
    if (!mounted) return;

    // Reminders need permission, asked here once with a reason rather than
    // cold at first launch. One prompt per visit, so it goes before upsells.
    if (await NotificationPermissionPrompt.maybeShow(context)) {
      AppPromptSessionCoordinator().suppressAutomaticOffers();
      return;
    }
    if (!mounted) return;

    // The promotional paywall: the well-throttled upsell for engaged users
    // (4 opens, 2 distinct days, 3 logged meals, 7-day cooldown, 3 lifetime
    // displays). All of that logic existed but nothing ever called it.
    if (!mounted) return;
    final access = ref.read(proAccessProvider);
    if (!access.isFree) return;

    final settings = ref.read(settingsProvider).valueOrNull;
    final promo = PromotionalPaywallService.instance();
    final eligible = await promo.canShowPromotionalPaywall(
      isPremium: access.isPro,
      onboardingComplete: settings?.onboardingComplete ?? false,
      homeLoaded: true,
    );
    if (!eligible ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        !ref.read(proAccessProvider).isFree) {
      return;
    }
    await PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.homeAha,
      featureName: 'promotional',
      automatic: true,
    );
  }

  Future<bool> _loadFirstMealGuide() async {
    final pending = await FirstMealGuideService().isPending();
    if (pending && mounted) {
      setState(() => _showFirstMealGuide = true);
    }
    return pending;
  }

  Future<void> _dismissFirstMealGuide() async {
    if (mounted) setState(() => _showFirstMealGuide = false);
    await FirstMealGuideService().dismiss();
  }

  @override
  void dispose() {
    _upgradePromptTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todaysMealsAsync = ref.watch(todaysMealsProvider);
    final todaysMeals = todaysMealsAsync.valueOrNull ?? [];
    final totalCalories = todaysMeals.fold<int>(
      0,
      (sum, m) => sum + m.calories,
    );
    final mealCount = todaysMeals.length;
    final macros = Macros(
      protein: todaysMeals.fold<int>(0, (sum, m) => sum + m.macros.protein),
      carbs: todaysMeals.fold<int>(0, (sum, m) => sum + m.macros.carbs),
      fat: todaysMeals.fold<int>(0, (sum, m) => sum + m.macros.fat),
    );

    final settings = ref.watch(settingsProvider).valueOrNull;
    final calorieGoal = math.max(settings?.dailyCalorieGoal ?? 2000, 1);
    final proteinGoal = settings?.dailyProteinGoal ?? 50;
    final carbGoal = settings?.dailyCarbGoal ?? 250;
    final fatGoal = settings?.dailyFatGoal ?? 65;
    final isPro = ref.watch(effectiveIsProProvider);
    final streak = settings?.currentStreak ?? 0;

    final activitySummary = ref.watch(activityProvider).valueOrNull;
    final activitySteps = activitySummary?.steps ?? 0;
    // The goal the user set, from the activity store. Every screen used to
    // hardcode 10,000.
    final activityStepGoal =
        ref.watch(stepGoalProvider).valueOrNull ??
        ActivityRepository.defaultStepGoal;
    final activeCalories = activitySummary?.activeCalories.round() ?? 0;

    final waterState = ref.watch(waterProvider).valueOrNull;
    final waterTotal = waterState?.todayTotal ?? 0;
    final waterGoal = waterState?.goal ?? 2500;

    final isLoading =
        todaysMealsAsync.isLoading || todaysMealsAsync.isRefreshing;
    final isRefreshing = todaysMealsAsync.isRefreshing;

    final adjustedGoal = isPro ? calorieGoal + activeCalories : calorieGoal;
    final remaining = adjustedGoal - totalCalories;
    final calorieProgress = (totalCalories / math.max(adjustedGoal, 1)).clamp(
      0.0,
      1.4,
    );
    final showFirstLoadSkeleton =
        isLoading && totalCalories == 0 && todaysMeals.isEmpty;
    return AppPageScaffold(
      title: '',
      padding: EdgeInsets.zero,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : const Color(0xFFFBFCFA),
      showHeader: false,
      extendBehindStatusBar: true,
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 132,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          _staggeredSlide(
            _itemAnims[0],
            _MinimalHomeTopBar(
              isPro: isPro,
              isRefreshing: isRefreshing,
              streak: streak,
              onSettingsTap: () => context.push('/settings'),
              onUpgradeTap:
                  () => PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.homeAha,
                    featureName: 'home_appbar_upgrade',
                  ),
            ),
          ),
          const SizedBox(height: 20),
          _staggeredSlide(
            _itemAnims[1],
            showFirstLoadSkeleton
                ? const _HomeDashboardSkeleton()
                : _MinimalCalorieHero(
                  consumed: totalCalories,
                  goal: adjustedGoal,
                  remaining: remaining,
                  mealCount: mealCount,
                  progress: calorieProgress,
                  // Pro's goal grows with movement (see adjustedGoal above).
                  // That was folded silently into one number, so the feature
                  // people pay for looked like an arbitrary target.
                  activityBonus: isPro ? activeCalories : 0,
                  animateIn: _firstOpen,
                ),
          ),
          if (_showFirstMealGuide && mealCount == 0)
            _staggeredSlide(
              _itemAnims[2],
              _FirstMealGuideCard(
                onScan: () => context.go('/snap'),
                onDismiss: _dismissFirstMealGuide,
              ),
            ),
          // Macros sit directly under the calorie hero for every user. The
          // previous order pushed them below water and steps for free users,
          // which made sense while the card was a locked placeholder — it now
          // shows real composition, so burying it hid the most useful thing on
          // their dashboard. Gating lives inside the card, not in the ordering.
          _staggeredSlide(
            _itemAnims[2],
            HomeMacroSection(
              hasMeals: mealCount > 0,
              macros: macros,
              proteinGoal: proteinGoal,
              carbGoal: carbGoal,
              fatGoal: fatGoal,
              isPro: isPro,
              onUpgrade:
                  () => PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.macroDetails,
                    featureName: 'home_macros',
                  ),
            ),
          ),
          _staggeredSlide(
            _itemAnims[3],
            HomeWellnessSection(
              waterTotal: waterTotal,
              waterGoal: waterGoal,
              steps: activitySteps,
              stepGoal: activityStepGoal,
              burnedCalories: activeCalories,
              caloriesEstimated:
                  activitySummary?.activeCaloriesEstimated ?? true,
              onWaterTap: () => showHydrationSheet(context),
              // Connected already: the full activity screen, which nothing
              // in the app could open. Otherwise the sheet that connects it.
              onActivityTap:
                  () =>
                      (activitySummary?.healthConnected ?? false)
                          ? context.push('/activity')
                          : showActivityHealthConnectSheet(context),
            ),
          ),
          _staggeredSlide(
            _itemAnims[4],
            HomeToolsSection(
              onPlannerTap: () => context.push('/planner'),
              onCoachTap: () => context.push('/assistant'),
              isPro: isPro,
            ),
          ),
          _staggeredSlide(
            _itemAnims[5],
            _MinimalMealsSection(
              meals: todaysMeals,
              isPro: isPro,
              onViewAll: () => context.go('/log'),
              onScan:
                  () => showScanChoiceSheet(
                    context: context,
                    onFoodScan: () => context.go('/snap'),
                    onBarcodeScan: () => context.go('/snap?mode=barcode'),
                  ),
              onProTap: () => context.push('/paywall'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FirstMealGuideCard extends StatelessWidget {
  const _FirstMealGuideCard({required this.onScan, required this.onDismiss});

  final VoidCallback onScan;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = isDark ? Colors.white70 : _minimalMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C1511) : const Color(0xFFF2FAF6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    WaznIcons.camera,
                    size: 21,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.first_meal_guide_title,
                          style: AppTypography.titleSmall.copyWith(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.first_meal_guide_body,
                          style: AppTypography.bodySmall.copyWith(
                            color: muted,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Tooltip(
                  message: l10n.first_meal_guide_dismiss,
                  child: IconButton(
                    key: const ValueKey('first-meal-guide-dismiss'),
                    onPressed: onDismiss,
                    icon: const Icon(WaznIcons.close, size: 18),
                    color: muted,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('first-meal-guide-scan'),
                onPressed: onScan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(WaznIcons.camera, size: 19),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        l10n.first_meal_guide_action,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

const _minimalInk = Color(0xFF1C1917);

/// Secondary text on the light ground.
///
/// This was #A8A29E, which measures 2.45:1 against the page -- well under the
/// 4.5:1 that small text needs, and far below the 6.1:1 the wellness and tools
/// cards were already hitting. Same warm grey, deep enough to read: 4.56:1.
const _minimalMuted = Color(0xFF777370);
const _minimalGreen = AppColors.primary; // Wazn emerald — brand progress color
const _minimalGreenText = AppColors.primaryDark;

/// The green that reads on the current ground.
///
/// [_minimalGreenText] is #047857 -- a deep green chosen against a near-white
/// card. Several call sites used it unconditionally, so on a black background
/// the goal figure, the "View all" action and the meal bullet were dark green
/// on near-black. The sites that got this right did `isDark ? _minimalGreen :
/// _minimalGreenText` inline; this is that expression, named, so the next call
/// site cannot forget it.
Color _greenInk(bool isDark) => isDark ? _minimalGreen : _minimalGreenText;

class _MinimalHomeTopBar extends StatelessWidget {
  final bool isPro;
  final bool isRefreshing;
  final int streak;
  final VoidCallback onSettingsTap;
  final VoidCallback onUpgradeTap;

  const _MinimalHomeTopBar({
    required this.isPro,
    required this.isRefreshing,
    required this.streak,
    required this.onSettingsTap,
    required this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;

    return Padding(
      // One gutter for the whole screen. The top bar sat at 22 and the hero at
      // 24 while every section below used 20, so the left edge stepped in and
      // out three times on the way down.
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Branding flexes so controls remain reachable at large text sizes.
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Wazn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: ink,
                      fontSize: 22, // Increased for premium presence
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      isRefreshing
                          ? Padding(
                            key: const ValueKey('refreshing'),
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color:
                                    isDark
                                        ? Colors.white70
                                        : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                          : const SizedBox.shrink(key: ValueKey('idle')),
                ),
              ],
            ),
          ),
          // Streak Flame Badge (only if active). This read `>= 0`, which is
          // every possible streak -- so a brand new account was shown an
          // orange flame next to a 0 on its first ever screen.
          if (streak > 0 &&
              MediaQuery.sizeOf(context).width >= 380 &&
              MediaQuery.textScalerOf(context).scale(12) < 18) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(WaznIcons.calories, color: Colors.orange, size: 14),
                const SizedBox(width: 3),
                Text(
                  '$streak',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
          ],
          if (!isPro) ...[
            HomeUpgradeChip(onTap: onUpgradeTap),
            const SizedBox(width: 6),
          ],
          if (isPro) ...[
            Tooltip(
              message: AppLocalizations.of(context)!.home_pro_badge,
              child: Semantics(
                label: AppLocalizations.of(context)!.home_pro_badge,
                child: SizedBox(
                  width: 36,
                  height: 44,
                  child: Icon(
                    WaznIcons.pro,
                    color:
                        isDark
                            ? const Color(0xFFFFD86B)
                            : const Color(0xFFE29200),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Settings button
          GestureDetector(
            onTap: onSettingsTap,
            // The icon was its own hit area -- a 20px target at the very edge
            // of the screen, against a 48dp platform minimum. The glyph stays
            // 20px; only what you can hit changes.
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                WaznIcons.settings,
                color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalCalorieHero extends StatelessWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final int mealCount;
  final double progress;

  /// Active calories folded into [goal]. Zero when there is no bonus to show.
  final int activityBonus;

  /// Count the figures in from the empty day rather than showing them.
  final bool animateIn;

  const _MinimalCalorieHero({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.mealCount,
    required this.progress,
    this.activityBonus = 0,
    this.animateIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = isDark ? Colors.white54 : _minimalMuted;
    final isOverGoal = remaining < 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Column(
        children: [
          // The figure rolls like an odometer whenever it changes, and a
          // chip beside it says by how much.
          Stack(
            clipBehavior: Clip.none,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RollingNumber(
                  value: remaining.abs(),
                  from: animateIn ? goal : null,
                  delay: const Duration(milliseconds: 240),
                  format: (v) => _formatNumber(context, v),
                  style: AppTypography.displayLarge.copyWith(
                    color: ink,
                    fontSize: 54,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: 0,
                child: FractionalTranslation(
                  translation: const Offset(1.12, 0),
                  child: _CalorieDelta(
                    consumed: consumed,
                    remaining: remaining,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            isOverGoal ? l10n.home_kcal_over : l10n.home_kcal_left,
            style: AppTypography.bodyMedium.copyWith(
              color: muted,
              fontSize: 14,
              height: 1.1,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 24),
          _MinimalCalorieTrack(
            progress: progress,
            color: isOverGoal ? AppColors.error : _minimalGreen,
            isDark: isDark,
          ),
          if (activityBonus > 0) ...[
            const SizedBox(height: 12),
            _ActivityBonusPill(kcal: activityBonus, isDark: isDark),
          ],
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_calories_eaten,
                  value: consumed,
                  countIn: animateIn,
                  unit: 'kcal',
                ),
              ),
              _MinimalDivider(isDark: isDark),
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_metric_goal,
                  value: goal,
                  unit: 'kcal',
                  valueColor: _greenInk(isDark),
                ),
              ),
              _MinimalDivider(isDark: isDark),
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_metric_meals,
                  value: mealCount,
                  countIn: animateIn,
                  unit: l10n.log_entries.toLowerCase(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "−523" floating up beside the calorie figure as it rolls, so the change
/// reads at a glance. It says how far the figure on screen moved while it
/// counts what is left; once over the goal it names the calories added.
class _CalorieDelta extends StatefulWidget {
  const _CalorieDelta({required this.consumed, required this.remaining});

  final int consumed;
  final int remaining;

  @override
  State<_CalorieDelta> createState() => _CalorieDeltaState();
}

class _CalorieDeltaState extends State<_CalorieDelta>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
    value: 1,
  );
  String _label = '';

  @override
  void didUpdateWidget(_CalorieDelta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.consumed == oldWidget.consumed) return;
    final fmt = NumberFormat.decimalPattern(
      AppLocalizations.of(context)?.localeName,
    );
    String signed(int d) => '${d < 0 ? '\u2212' : '+'}${fmt.format(d.abs())}';
    _label =
        oldWidget.remaining >= 0 && widget.remaining >= 0
            ? signed(widget.remaining - oldWidget.remaining)
            : '${signed(widget.consumed - oldWidget.consumed)} kcal';
    _controller.value = 0;
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final v = _controller.value;
            if (v <= 0 || v >= 1) return const SizedBox.shrink();
            final opacity =
                v < .15 ? v / .15 : (v > .7 ? 1 - (v - .7) / .3 : 1.0);
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 8 - 30 * Curves.easeOutCubic.transform(v)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? .22 : .13),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _label,
              textDirection: TextDirection.ltr,
              style: AppTypography.labelMedium.copyWith(
                color: _greenInk(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalCalorieTrack extends StatelessWidget {
  const _MinimalCalorieTrack({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: '${(progress * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
        builder: (context, value, _) {
          return SizedBox(
            height: 8,
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE7E9E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (value > 0)
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Names the calories movement added to today's goal.
///
/// Without it the Pro goal just reads as a different number from the free one
/// and the feature is invisible -- which is the whole point of showing it.
class _ActivityBonusPill extends StatelessWidget {
  const _ActivityBonusPill({required this.kcal, required this.isDark});

  final int kcal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              WaznIcons.steps,
              size: 12,
              color: isDark ? _minimalGreen : _minimalGreenText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.home_goal_activity_bonus(kcal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? _minimalGreen : _minimalGreenText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalHeroStat extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color? valueColor;

  /// Count up from zero the first time it shows.
  final bool countIn;

  const _MinimalHeroStat({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
    this.countIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = isDark ? Colors.white54 : _minimalMuted;

    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: CountUpText(
            value: value,
            from: countIn ? 0 : null,
            delay: const Duration(milliseconds: 240),
            format: (v) => _formatNumber(context, v),
            style: AppTypography.titleLarge.copyWith(
              color: valueColor ?? ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: AppTypography.labelSmall.copyWith(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MinimalDivider extends StatelessWidget {
  final bool isDark;

  const _MinimalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color:
          isDark
              ? Colors.white.withValues(alpha: 0.09)
              : const Color(0xFFE2DED8),
    );
  }
}

class _MinimalMealsSection extends StatefulWidget {
  final List<Meal> meals;
  final bool isPro;
  final VoidCallback onViewAll;
  final VoidCallback onScan;
  final VoidCallback onProTap;

  const _MinimalMealsSection({
    required this.meals,
    required this.isPro,
    required this.onViewAll,
    required this.onScan,
    required this.onProTap,
  });

  @override
  State<_MinimalMealsSection> createState() => _MinimalMealsSectionState();
}

class _MinimalMealsSectionState extends State<_MinimalMealsSection> {
  /// Meals that arrived since the last build, which slide into the list.
  Set<String> _arrived = const {};

  @override
  void didUpdateWidget(_MinimalMealsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.meals.map((m) => m.id).toSet();
    _arrived = {
      for (final m in widget.meals)
        if (!before.contains(m.id)) m.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final meals = widget.meals;
    final onViewAll = widget.onViewAll;
    final onScan = widget.onScan;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hiddenMealCount = math.max(0, meals.length - 3);
    final viewAllLabel =
        meals.isEmpty
            ? l10n.home_open_log
            : hiddenMealCount > 0
            ? '${l10n.home_view_all} (${meals.length})'
            : l10n.home_view_all;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MinimalSectionLabel(text: l10n.home_todays_meals),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: _greenInk(isDark),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  viewAllLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: _greenInk(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (meals.isEmpty)
            _MinimalEmptyMealRow(onTap: onScan)
          else
            ...meals
                .take(3)
                .map(
                  (meal) => ArrivingItem(
                    key: ValueKey('home-meal-${meal.id}'),
                    arrived: _arrived.contains(meal.id),
                    child: _MinimalMealRow(meal: meal, onTap: onViewAll),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MinimalSectionLabel extends StatelessWidget {
  final String text;

  const _MinimalSectionLabel({required this.text});

  @override
  Widget build(BuildContext context) => HomeSectionLabel(text);
}

class _MinimalMealRow extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;

  const _MinimalMealRow({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = isDark ? Colors.white54 : _minimalMuted;

    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFECEAE6),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: _greenInk(isDark),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.foodName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: ink,
                      fontSize: 14,
                      // w600, matching the planner and coach row titles. This
                      // was the only 14px row title on the screen set heavier.
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${meal.mealType ?? AppLocalizations.of(context)!.result_meal_snack} · ${meal.formattedTime}',
                    style: AppTypography.labelSmall.copyWith(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatNumber(context, meal.calories),
              style: AppTypography.bodyMedium.copyWith(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalEmptyMealRow extends StatelessWidget {
  final VoidCallback onTap;

  const _MinimalEmptyMealRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF090A09) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF292B29) : const Color(0xFFE1E3DF),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(
                WaznIcons.scan,
                color:
                    isDark
                        ? AppColors.primary.withValues(alpha: 0.86)
                        : _minimalGreenText,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.home_first_meal_cta_title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : _minimalInk,
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Locale-aware grouping, shared with the Log screen's `_formatInt`.
///
/// This used to group only above 10,000 with a hardcoded comma, so the same
/// figure read "1448" here and "1,448" on Log — and always with a comma, even
/// in locales that group differently.
String _formatNumber(BuildContext context, int value) {
  return NumberFormat.decimalPattern(
    AppLocalizations.of(context)?.localeName,
  ).format(value);
}

class _HomeDashboardSkeleton extends StatelessWidget {
  const _HomeDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fill = colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Column(
        children: [
          _SkeletonBox(width: 164, height: 50, radius: 8, color: fill),
          const SizedBox(height: 9),
          _SkeletonBox(width: 72, height: 13, radius: 5, color: fill),
          const SizedBox(height: 25),
          _SkeletonBox(
            width: double.infinity,
            height: 4,
            radius: 2,
            color: fill,
          ),
          const SizedBox(height: 27),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 18),
                Expanded(
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 48,
                    radius: 6,
                    color: fill,
                  ),
                ),
              ],
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
