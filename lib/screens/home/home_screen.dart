import 'dart:async';
import 'dart:math' as math;

// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_slot.dart';
import '../../data/models/promo_offer.dart';
import 'widgets/smart_meal_planner_card.dart';
import 'widgets/activity_health_connect_sheet.dart';
import '../log/widgets/hydration_sheet.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../data/services/promotional_paywall_service.dart';
import '../../data/services/pro_feature_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/promo_offer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/macro_display.dart';
import '../../widgets/scan_choice_sheet.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/recent_meal_tile.dart';
import '../../widgets/premium_prompt_modal.dart';

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

  List<MealSlot>? _currentMealPlan;
  String? _lastRestriction;

  List<MealSlot> _getMealsForRestriction(String restriction) {
    if (restriction == 'vegetarian') {
      return [
        const MealSlot(
          mealType: "Breakfast",
          name: "Avocado toast + eggs",
          time: "8:00 AM",
          kcal: 420,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Snack",
          name: "Tomatoes + hummus",
          time: "11:24 AM",
          kcal: 75,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Lunch",
          name: "Grilled tofu + quinoa",
          time: "Up next",
          kcal: 510,
          status: MealSlotStatus.next,
          isLogged: false,
        ),
        const MealSlot(
          mealType: "Dinner",
          name: "Light veggie stir-fry",
          time: "7:30 PM",
          kcal: 380,
          status: MealSlotStatus.upcoming,
          isLogged: false,
        ),
      ];
    } else if (restriction == 'vegan') {
      return [
        const MealSlot(
          mealType: "Breakfast",
          name: "Avocado toast + cherry tomatoes",
          time: "8:00 AM",
          kcal: 320,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Snack",
          name: "Tomatoes + hummus",
          time: "11:24 AM",
          kcal: 75,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Lunch",
          name: "Grilled tofu + quinoa",
          time: "Up next",
          kcal: 510,
          status: MealSlotStatus.next,
          isLogged: false,
        ),
        const MealSlot(
          mealType: "Dinner",
          name: "Light veggie stir-fry",
          time: "7:30 PM",
          kcal: 380,
          status: MealSlotStatus.upcoming,
          isLogged: false,
        ),
      ];
    } else if (restriction == 'keto') {
      return [
        const MealSlot(
          mealType: "Breakfast",
          name: "Scrambled eggs + avocado",
          time: "8:00 AM",
          kcal: 480,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Snack",
          name: "Celery + peanut butter",
          time: "11:24 AM",
          kcal: 190,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Lunch",
          name: "Grilled salmon + broccoli",
          time: "Up next",
          kcal: 620,
          status: MealSlotStatus.next,
          isLogged: false,
        ),
        const MealSlot(
          mealType: "Dinner",
          name: "Veggie stir-fry with zucchini",
          time: "7:30 PM",
          kcal: 310,
          status: MealSlotStatus.upcoming,
          isLogged: false,
        ),
      ];
    } else {
      // Default (Balanced/None)
      return [
        const MealSlot(
          mealType: "Breakfast",
          name: "Avocado toast + eggs",
          time: "8:00 AM",
          kcal: 420,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Snack",
          name: "Tomatoes + grilled chicken",
          time: "11:24 AM",
          kcal: 125,
          status: MealSlotStatus.done,
          isLogged: true,
        ),
        const MealSlot(
          mealType: "Lunch",
          name: "Grilled salmon + quinoa",
          time: "Up next",
          kcal: 620,
          status: MealSlotStatus.next,
          isLogged: false,
        ),
        const MealSlot(
          mealType: "Dinner",
          name: "Light veggie stir-fry",
          time: "7:30 PM",
          kcal: 380,
          status: MealSlotStatus.upcoming,
          isLogged: false,
        ),
      ];
    }
  }

  String _getDietaryRestrictionLabel(BuildContext context, String restriction) {
    final l10n = AppLocalizations.of(context)!;
    switch (restriction) {
      case 'vegetarian':
        return l10n.planner_restriction_vegetarian;
      case 'vegan':
        return l10n.planner_restriction_vegan;
      case 'gluten-free':
        return l10n.planner_restriction_gluten_free;
      case 'keto':
        return l10n.planner_restriction_keto;
      case 'halal':
        return l10n.planner_restriction_halal;
      case 'none':
      default:
        return 'Balanced';
    }
  }

  Widget _buildPremiumPlannerTeaser(
    BuildContext context,
    int calorieGoal,
    String restriction,
  ) {
    return SmartMealPlannerCard(
      key: const ValueKey('teaser_card'),
      goalKcal: calorieGoal,
      dietLabel: _getDietaryRestrictionLabel(context, restriction),
      completedMeals: 1,
      totalMeals: 4,
      meals: _getMealsForRestriction(restriction),
      onLogTap: () {
        HapticFeedback.mediumImpact();
        context.push('/paywall');
      },
      onSwapTap: () {},
      onRefreshTap: () {},
      isTeaser: true,
    );
  }

  void _swapCurrentMeal() {
    setState(() {
      if (_currentMealPlan == null) return;
      final currentMeal = _currentMealPlan![2];
      if (currentMeal.name.contains("quinoa") ||
          currentMeal.name.contains("broccoli")) {
        String swapName;
        int swapKcal;
        if (_lastRestriction == 'vegetarian' || _lastRestriction == 'vegan') {
          swapName = "Chickpea salad + olive oil";
          swapKcal = 480;
        } else if (_lastRestriction == 'keto') {
          swapName = "Turkey wrap in lettuce";
          swapKcal = 350;
        } else {
          swapName = "Turkey wrap + spinach";
          swapKcal = 540;
        }
        _currentMealPlan![2] = currentMeal.copyWith(
          name: swapName,
          kcal: swapKcal,
        );
      } else {
        String origName;
        int origKcal;
        if (_lastRestriction == 'vegetarian' || _lastRestriction == 'vegan') {
          origName = "Grilled tofu + quinoa";
          origKcal = 510;
        } else if (_lastRestriction == 'keto') {
          origName = "Grilled salmon + broccoli";
          origKcal = 620;
        } else {
          origName = "Grilled salmon + quinoa";
          origKcal = 620;
        }
        _currentMealPlan![2] = currentMeal.copyWith(
          name: origName,
          kcal: origKcal,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Swapped lunch suggestion!"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _regeneratePlan() {
    setState(() {
      if (_lastRestriction == 'vegetarian') {
        _currentMealPlan = [
          const MealSlot(
            mealType: "Breakfast",
            name: "Greek yogurt + honey",
            time: "8:00 AM",
            kcal: 310,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Snack",
            name: "Almonds + apple",
            time: "11:24 AM",
            kcal: 180,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Lunch",
            name: "Lentil soup + spinach",
            time: "Up next",
            kcal: 450,
            status: MealSlotStatus.next,
            isLogged: false,
          ),
          const MealSlot(
            mealType: "Dinner",
            name: "Baked tofu + asparagus",
            time: "7:30 PM",
            kcal: 320,
            status: MealSlotStatus.upcoming,
            isLogged: false,
          ),
        ];
      } else if (_lastRestriction == 'vegan') {
        _currentMealPlan = [
          const MealSlot(
            mealType: "Breakfast",
            name: "Oatmeal with almond milk",
            time: "8:00 AM",
            kcal: 290,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Snack",
            name: "Almonds + apple",
            time: "11:24 AM",
            kcal: 180,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Lunch",
            name: "Lentil soup + spinach",
            time: "Up next",
            kcal: 450,
            status: MealSlotStatus.next,
            isLogged: false,
          ),
          const MealSlot(
            mealType: "Dinner",
            name: "Baked tofu + asparagus",
            time: "7:30 PM",
            kcal: 320,
            status: MealSlotStatus.upcoming,
            isLogged: false,
          ),
        ];
      } else if (_lastRestriction == 'keto') {
        _currentMealPlan = [
          const MealSlot(
            mealType: "Breakfast",
            name: "Fried eggs with bacon",
            time: "8:00 AM",
            kcal: 420,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Snack",
            name: "Walnuts",
            time: "11:24 AM",
            kcal: 200,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Lunch",
            name: "Steak salad + olive oil",
            time: "Up next",
            kcal: 580,
            status: MealSlotStatus.next,
            isLogged: false,
          ),
          const MealSlot(
            mealType: "Dinner",
            name: "Baked salmon + spinach",
            time: "7:30 PM",
            kcal: 410,
            status: MealSlotStatus.upcoming,
            isLogged: false,
          ),
        ];
      } else {
        _currentMealPlan = [
          const MealSlot(
            mealType: "Breakfast",
            name: "Greek yogurt + honey",
            time: "8:00 AM",
            kcal: 310,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Snack",
            name: "Almonds + apple",
            time: "11:24 AM",
            kcal: 180,
            status: MealSlotStatus.done,
            isLogged: true,
          ),
          const MealSlot(
            mealType: "Lunch",
            name: "Turkey breast + sweet potato",
            time: "Up next",
            kcal: 540,
            status: MealSlotStatus.next,
            isLogged: false,
          ),
          const MealSlot(
            mealType: "Dinner",
            name: "Baked cod + asparagus",
            time: "7:30 PM",
            kcal: 350,
            status: MealSlotStatus.upcoming,
            isLogged: false,
          ),
        ];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Regenerated today's meal plan!"),
        duration: Duration(seconds: 1),
      ),
    );
  }

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

    // Smart Premium Encouragement (Aha Moment)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), _maybePromptUpgrade);
    });
  }

  /// Runs the two upgrade prompts, in priority order, once Pro status is known.
  ///
  /// `PremiumPromptModal.show` settles the status itself before deciding, so a
  /// paying user is never shown either of these — which is what used to happen
  /// when this fired 1.5s after init, before settings had loaded.
  Future<void> _maybePromptUpgrade() async {
    if (!mounted) return;

    final todaysMealsAsync = ref.read(todaysMealsProvider);
    final hasAiMeal = (todaysMealsAsync.valueOrNull ?? []).any(
      (m) => m.scanSource == 'ai_scan',
    );

    if (hasAiMeal) {
      final l10n = AppLocalizations.of(context)!;
      await PremiumPromptModal.show(
        context,
        ref,
        title: l10n.aha_prompt_title,
        subtitle: l10n.aha_prompt_subtitle,
        buttonText: l10n.aha_prompt_btn,
        icon: LucideIcons.sparkles,
        entryPoint: PaywallEntryPoint.homeAha,
        featureName: 'first_ai_scan',
        hasCompletedValueAction: true,
      );
      return;
    }

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
    if (!eligible || !mounted) return;

    await promo.recordPromotionalPaywallShown();
    if (!mounted) return;
    await PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.homeAha,
      featureName: 'promotional',
    );
  }

  @override
  void dispose() {
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
    // ActivitySummary carries no step goal and no source provides one; the
    // app-wide constant is the single source of truth until a real goal exists.
    final activityStepGoal = 10000;
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
              onProTap: () => context.push('/paywall'),
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
                ),
          ),
          const SizedBox(height: 2),
          // Macros sit directly under the calorie hero for every user. The
          // previous order pushed them below water and steps for free users,
          // which made sense while the card was a locked placeholder — it now
          // shows real composition, so burying it hid the most useful thing on
          // their dashboard. Gating lives inside the card, not in the ordering.
          _staggeredSlide(
            _itemAnims[2],
            _MinimalMacroSection(
              macros: macros,
              proteinGoal: proteinGoal,
              carbGoal: carbGoal,
              fatGoal: fatGoal,
              isPro: isPro,
            ),
          ),
          const SizedBox(height: 2),
          _staggeredSlide(
            _itemAnims[3],
            _SecondaryDashboardGrid(
              waterTotal: waterTotal,
              waterGoal: waterGoal,
              steps: activitySteps,
              stepGoal: activityStepGoal,
              burnedCalories: activeCalories,
              caloriesEstimated:
                  activitySummary?.activeCaloriesEstimated ?? true,
              onWaterTap: () => showHydrationSheet(context),
              onWaterAdd: () => _addWater(ref),
              onWaterUndo: () => _removeWater(ref),
              onActivityTap: () => showActivityHealthConnectSheet(context),
            ),
          ),
          const SizedBox(height: 2),
          _staggeredSlide(
            _itemAnims[4],
            _MinimalToolsSection(
              onPlannerTap: () {
                if (isPro) {
                  context.push('/planner');
                } else {
                  PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.plannerLockedDay,
                    featureName: 'meal_planner',
                  );
                }
              },
              onCoachTap: () {
                if (isPro) {
                  context.push('/assistant');
                } else {
                  PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.aiCoachLimit,
                    featureName: 'ai_coach',
                  );
                }
              },
              isPro: isPro,
            ),
          ),
          const SizedBox(height: 2),
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

  void _addWater(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(waterProvider.notifier).addWater(_waterQuickAddMl);
  }

  void _removeWater(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(waterProvider.notifier).removeWater(_waterQuickAddMl);
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

const _minimalInk = Color(0xFF1C1917);
const _minimalMuted = Color(0xFFA8A29E);
const _minimalLine = Color(0xFFE8E4DC);
const _minimalGreen =
    AppColors.primary; // SnapCal emerald — brand progress color
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

class _MinimalHomeTopBar extends ConsumerWidget {
  final bool isPro;
  final bool isRefreshing;
  final int streak;
  final VoidCallback onSettingsTap;
  final VoidCallback onProTap;

  const _MinimalHomeTopBar({
    required this.isPro,
    required this.isRefreshing,
    required this.streak,
    required this.onSettingsTap,
    required this.onProTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          // Logo/Branding
          Row(
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
              Text(
                'SnapCal',
                style: AppTypography.titleMedium.copyWith(
                  color: ink,
                  fontSize: 22, // Increased for premium presence
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
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
          const Spacer(),
          // Streak Flame Badge (only if active)
          if (streak >= 0) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.flame, color: Colors.orange, size: 14),
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
          // Pro badge, or the live offer when a campaign is running.
          _HeaderProAffordance(
            isPro: isPro,
            onProTap: onProTap,
            onSettingsTap: onSettingsTap,
          ),
          const SizedBox(width: 14),
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
                LucideIcons.settings,
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

  const _MinimalCalorieHero({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.mealCount,
    required this.progress,
    this.activityBonus = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = isDark ? Colors.white54 : _minimalMuted;
    final track = isDark ? Colors.white.withValues(alpha: 0.10) : _minimalLine;
    final isOverGoal = remaining < 0;

    return Column(
      children: [
        SizedBox(
          width: 168,
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: track,
                    color: isOverGoal ? AppColors.error : _minimalGreen,
                  );
                },
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatNumber(context, remaining.abs()),
                        style: AppTypography.displayLarge.copyWith(
                          color: ink,
                          fontSize: 40,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOverGoal ? 'kcal over today' : l10n.home_kcal_left,
                      style: AppTypography.labelSmall.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (activityBonus > 0) ...[
          const SizedBox(height: 12),
          _ActivityBonusPill(kcal: activityBonus, isDark: isDark),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_calories_eaten,
                  value: _formatNumber(context, consumed),
                  unit: 'kcal',
                ),
              ),
              _MinimalDivider(isDark: isDark),
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_metric_goal,
                  value: _formatNumber(context, goal),
                  unit: 'kcal',
                  valueColor: _greenInk(isDark),
                ),
              ),
              _MinimalDivider(isDark: isDark),
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_metric_meals,
                  value: _formatNumber(context, mealCount),
                  unit: l10n.log_entries.toLowerCase(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _MinimalSectionDivider(),
      ],
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
              LucideIcons.footprints,
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
  final String value;
  final String unit;
  final Color? valueColor;

  const _MinimalHeroStat({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = isDark ? Colors.white54 : const Color(0xFFB4AFA8);

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
          child: Text(
            value,
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

class _MinimalSectionDivider extends StatelessWidget {
  const _MinimalSectionDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 22),
      color: isDark ? Colors.white.withValues(alpha: 0.08) : _minimalLine,
    );
  }
}

/// Macros for the home dashboard.
///
/// Both tiers get the same three ring cards, in the same place, at the same
/// size. Pro shows grams inside each ring against the daily target. Free sees
/// its own real progress drawn as a silhouette with the number withheld, plus
/// one upgrade affordance — so upgrading swaps a lock for a number in place
/// and nothing on the screen moves.
class _MinimalMacroSection extends StatelessWidget {
  final Macros macros;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;
  final bool isPro;

  const _MinimalMacroSection({
    required this.macros,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showGrams = const ProFeatureService().canSeeMacros(isPro: isPro);
    // Nothing logged yet: three empty rings each captioned "Pro" is an upgrade
    // prompt for data that does not exist — it reads as a disabled control,
    // and it spends the paywall ask before the user has seen anything worth
    // paying for. The section keeps its place and says what to do instead.
    final empty = macros.protein <= 0 && macros.carbs <= 0 && macros.fat <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinimalSectionLabel(text: l10n.home_section_macros_today),
          const SizedBox(height: 12),
          if (empty)
            _MacroEmptyPrompt(text: l10n.home_macro_empty)
          else
            MacroDisplay(
            macros: macros,
            proteinGoal: proteinGoal,
            carbGoal: carbGoal,
            fatGoal: fatGoal,
            variant: MacroDisplayVariant.rings,
            showGrams: showGrams,
            showGoals: showGrams,
            onUpgradeTap:
                showGrams
                    ? null
                    : () => PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.macroDetails,
                      featureName: 'home_macros',
                    ),
          ),
          const SizedBox(height: 14),
          const _MinimalSectionDivider(),
        ],
      ),
    );
  }
}

/// Holds the macro section's place before the first meal of the day.
///
/// Same height and shell as the ring row it stands in for, so the dashboard
/// does not jump when the first meal lands. It asks for the action that fills
/// the section rather than for money.
class _MacroEmptyPrompt extends StatelessWidget {
  final String text;

  const _MacroEmptyPrompt({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.035)
                : Colors.black.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.07 : 0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.scanLine,
            size: 15,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalToolsSection extends StatelessWidget {
  final VoidCallback onPlannerTap;
  final VoidCallback onCoachTap;
  final bool isPro;

  const _MinimalToolsSection({
    required this.onPlannerTap,
    required this.onCoachTap,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinimalSectionLabel(text: l10n.home_section_plan_coach),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                child: _PremiumBentoCard(
                  icon: LucideIcons.calendarDays,
                  title: l10n.planner_title,
                  subtitle: l10n.planner_generate,
                  isPro: isPro,
                  onTap: onPlannerTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumBentoCard(
                  icon: LucideIcons.sparkles,
                  title: l10n.assistant_title,
                  subtitle: l10n.assistant_home_subtitle,
                  isPro: isPro,
                  onTap: onCoachTap,
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _MinimalSectionDivider(),
        ],
      ),
    );
  }
}

class _PremiumBentoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPro;
  final VoidCallback onTap;

  const _PremiumBentoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // A fixed height overflows the moment the device's text scale grows.
        // The card sizes to its content and the row equalises the pair.
        constraints: const BoxConstraints(minHeight: 86),
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        // The dashboard's shell, with one deliberate exception: these are the
        // paid tools, so they are the single place on Home that gets richness.
        // Everything else stays plain white — spend the boldness once, or the
        // premium tier stops looking like a tier.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Emerald only. Gold at a few percent over white turns beige, which
          // reads as a stain rather than as luxury — it belongs in the badge,
          // saturated enough to actually be a colour.
          // Committed, not hinted. A 7% wash is indistinguishable from white
          // at arm's length, which is the same as having no treatment at all —
          // the tint has to be strong enough to name a tier.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0.05),
                    ]
                    : [
                      const Color(0xFFD9F2E7),
                      const Color(0xFFF4FBF8),
                    ],
            stops: const [0.0, 0.85],
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.24),
          ),
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // The gradient badge is the tier's signature — the same one
                // the paywall and the scan result use, so a paid tool is
                // recognisable before you read its name.
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const Spacer(),
                // Outlined, not filled: it marks the tier without competing
                // with the one ask on the screen that is meant to be clicked.
                if (!isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      l10n.macro_pro_label.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.15,
                color: isDark ? Colors.white : _minimalInk,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                color: scheme.onSurface.withValues(alpha: isDark ? 0.42 : 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalMealsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hiddenMealCount = math.max(0, meals.length - 3);
    final viewAllLabel =
        meals.isEmpty
            ? 'Open log'
            : hiddenMealCount > 0
            ? '${l10n.home_view_all} (${meals.length})'
            : l10n.home_view_all;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _MinimalSectionLabel(text: 'Today\'s meals')),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: _greenInk(isDark),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 32),
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
                .map((meal) => _MinimalMealRow(meal: meal, onTap: onViewAll)),
          if (!isPro) ...[
            // No placeholder meal rows. "Lunch" and "Dinner" were hardcoded
            // and rendered even for a user who had logged nothing, so a new
            // free account saw two meals it never created sitting under its own
            // empty state. One honest upgrade card is the whole upsell here.
            const SizedBox(height: 14),
            _MinimalUnlockPlanCard(onTap: onProTap),
          ],
        ],
      ),
    );
  }
}

class _MinimalSectionLabel extends StatelessWidget {
  final String text;

  const _MinimalSectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: isDark ? Colors.white54 : const Color(0xFFB4AFA8),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
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
                      fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(
              LucideIcons.scanLine,
              color: isDark ? Colors.white54 : _minimalGreenText,
              size: 17,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.home_first_meal_cta_title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : _minimalInk,
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

class _MinimalUnlockPlanCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MinimalUnlockPlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);

    final LinearGradient cardBg;
    final Color borderColor;
    final Color textColor;
    final Color subtitleColor;
    final Color arrowColor;
    final List<BoxShadow> shadow;

    if (isDark) {
      cardBg = const LinearGradient(
        colors: [
          Color(0xFF163E27), // Sleek Emerald
          Color(0xFF0B2114), // Deep Forest Green
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = goldColor.withValues(alpha: 0.4);
      textColor = const Color(0xFFFAF8F5);
      subtitleColor = const Color(0xFFE3D0A4);
      arrowColor = goldColor;
      shadow = [
        BoxShadow(
          color: const Color(0xFF0B2114).withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      cardBg = const LinearGradient(
        colors: [
          Color(0xFFFCF8EF), // Warm champagne light background
          Color(0xFFF9F0DF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = const Color(0xFFE5C060).withValues(alpha: 0.5);
      textColor = const Color(0xFF1A3D2B); // Deep Forest text
      subtitleColor = const Color(0xFF888780); // Muted warm grey
      arrowColor = const Color(0xFFBA7517); // Rich gold/amber
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: shadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock your full meal plan',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Lunch · Dinner · Smart suggestions',
                    style: AppTypography.labelSmall.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.arrowRight, color: arrowColor, size: 18),
          ],
        ),
      ),
    );
  }
}

/// One glass. Tap the card's + to add it, long-press to take it back.
const int _waterQuickAddMl = 250;

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

/// A clean settings gear icon button that replaces the old avatar circle.
/// Makes the navigation affordance immediately clear.
class _HomeSettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isPro;

  const _HomeSettingsButton({required this.onTap, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Icon(
            Icons.settings_rounded,
            size: 20,
            color: d ? Colors.white38 : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

class _HomeCoachButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeCoachButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _HomeDashboardHeader extends StatelessWidget {
  final bool isPro;
  final int streak;
  final bool isRefreshing;
  final VoidCallback onSettingsTap;

  const _HomeDashboardHeader({
    required this.isPro,
    required this.streak,
    required this.isRefreshing,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HomeSettingsButton(onTap: onSettingsTap, isPro: isPro),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Text(
                  'SnapCal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: d ? Colors.white : const Color(0xFF1C1C1E),
                    letterSpacing: -0.5,
                  ),
                ),
                if (isRefreshing)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: d ? Colors.white38 : const Color(0xFFC7C7CC),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _HomeCoachButton(
            onTap: () {
              if (isPro) {
                context.push('/assistant');
              } else {
                PremiumConversionService().openPaywall(
                  context,
                  PaywallEntryPoint.aiCoachLimit,
                  featureName: 'ai_coach',
                );
              }
            },
          ),
          const SizedBox(width: 4),
          if (streak > 0) _HeaderStreakBadge(streak: streak, isPro: isPro),
          const SizedBox(width: 4),
          _PremiumProBadge(isPro: isPro),
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
    final d = Theme.of(context).brightness == Brightness.dark;
    if (isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: d ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.gem, color: const Color(0xFFE29200), size: 11),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.home_pro_badge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE29200),
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/paywall');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: d ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, color: AppColors.primary, size: 11),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.home_go_pro,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The header's Pro affordance, which becomes the offer when one is running.
///
/// Deliberately the same slot rather than a fourth element: the header already
/// carries a streak, an upgrade path and settings, and a badge that fights
/// them for attention gets tuned out. When a campaign is live the upgrade
/// entry point simply says something better.
class _HeaderProAffordance extends ConsumerStatefulWidget {
  const _HeaderProAffordance({
    required this.isPro,
    required this.onProTap,
    required this.onSettingsTap,
  });

  final bool isPro;
  final VoidCallback onProTap;
  final VoidCallback onSettingsTap;

  @override
  ConsumerState<_HeaderProAffordance> createState() =>
      _HeaderProAffordanceState();
}

class _HeaderProAffordanceState extends ConsumerState<_HeaderProAffordance>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _sheen;
  late final AnimationController _glow;
  late final AnimationController _nudge;
  Timer? _tick;
  Timer? _nudgeTimer;
  int _nudgesRun = 0;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // Slow, and only a specular pass — a looping pulse or bounce is what makes
    // a discount badge read as cheap, and it never stops costing frames.
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    // The glow breathes rather than blinks: slow enough to read as light on a
    // surface, not as a notification demanding to be tapped.
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    // The attention cue. A badge that bounces forever reads as spam and stops
    // being seen within a day; a pop every few seconds, a handful of times, is
    // noticed once and then leaves the user alone.
    _nudge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  static const int _maxNudges = 4;
  static const Duration _nudgeGap = Duration(seconds: 6);

  @override
  void dispose() {
    _tick?.cancel();
    _nudgeTimer?.cancel();
    _entrance.dispose();
    _sheen.dispose();
    _glow.dispose();
    _nudge.dispose();
    super.dispose();
  }

  void _syncAnimations({required bool active, required bool counting}) {
    if (!mounted) return;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (active && !reduced) {
      if (!_entrance.isCompleted && !_entrance.isAnimating) _entrance.forward();
      if (!_sheen.isAnimating) _sheen.repeat();
      if (!_glow.isAnimating) _glow.repeat(reverse: true);
      _nudgeTimer ??= Timer.periodic(_nudgeGap, (timer) {
        if (!mounted || _nudgesRun >= _maxNudges) {
          timer.cancel();
          _nudgeTimer = null;
          return;
        }
        _nudgesRun++;
        _nudge.forward(from: 0);
      });
    } else {
      _nudgeTimer?.cancel();
      _nudgeTimer = null;
      _entrance.value = 1;
      if (_sheen.isAnimating) _sheen.stop();
      if (_glow.isAnimating) _glow.stop();
    }
    // One timer, only while a deadline is actually being shown.
    if (active && counting) {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    } else {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = ref.watch(promoOfferProvider).valueOrNull;
    final live = !widget.isPro && offer != null && offer.isLiveAt(_now);
    final remaining = live ? offer.remainingAt(_now) : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAnimations(active: live, counting: remaining != null);
    });

    if (!live) return _plain(context);
    return _offerPill(context, offer, remaining);
  }

  /// The unchanged badge: gem for Pro, crown for everyone else.
  Widget _plain(BuildContext context) {
    return AppScaleTap(
      onTap: widget.isPro ? widget.onSettingsTap : widget.onProTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isPro ? LucideIcons.gem : LucideIcons.crown,
            color: widget.isPro ? AppColors.success : AppColors.premiumGold,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            widget.isPro
                ? AppLocalizations.of(context)!.home_pro_badge
                : AppLocalizations.of(context)!.home_go_pro,
            style: TextStyle(
              color: widget.isPro ? AppColors.success : AppColors.premiumGold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _offerPill(
    BuildContext context,
    PromoOffer offer,
    Duration? remaining,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final urgent =
        remaining != null && remaining <= const Duration(hours: 1);
    // Says "SAVE 76%", the same words and the same number the paywall uses.
    // "76% OFF" would imply 76% off the annual list price, which is not what
    // the comparison measures — it is the saving against paying monthly.
    final label =
        offer.label ?? l10n.paywall_save_percent('${offer.percentOff}');

    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _nudge]),
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_entrance.value.clamp(0.0, 1.0));
        // One pop with a slight tilt: the shape of something tapping you on
        // the shoulder, not of something demanding attention.
        final n = Curves.elasticOut.transform(_nudge.value.clamp(0.0, 1.0));
        final pop = _nudge.isAnimating ? 1 + 0.09 * (1 - n) : 1.0;
        final tilt = _nudge.isAnimating ? 0.035 * (1 - n) : 0.0;
        return Opacity(
          opacity: _entrance.value.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scale: (0.9 + 0.1 * t) * pop,
              child: child,
            ),
          ),
        );
      },
      child: AppScaleTap(
        onTap: widget.onProTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _glow,
                builder: (context, child) {
                  final g = Curves.easeInOut.transform(_glow.value);
                  return Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(9, 5, 10, 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: 0.26 + 0.26 * g,
                          ),
                          blurRadius: 9 + 9 * g,
                          spreadRadius: g,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFFC88A32,
                          ).withValues(alpha: 0.10 + 0.16 * g),
                          blurRadius: 14 + 8 * g,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.zap,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        height: 1,
                      ),
                    ),
                    if (remaining != null) ...[
                      const SizedBox(width: 7),
                      Container(
                        width: 1,
                        height: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _format(remaining),
                        style: TextStyle(
                          // Amber under the hour: colour carries urgency
                          // better than motion, and costs nothing to read.
                          color:
                              urgent
                                  ? const Color(0xFFFFE08A)
                                  : Colors.white.withValues(alpha: 0.92),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          // Without tabular figures the pill twitches every
                          // second as digit widths change.
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // A single specular pass, left to right. Its own builder: as a
              // static `child` it never rebuilt, so the sweep never moved.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sheen,
                    builder:
                        (context, _) => FractionalTranslation(
                          translation: Offset(-1.4 + 2.8 * _sheen.value, 0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.38),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                stops: const [0.34, 0.5, 0.66],
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `2d 04h` above a day, `11:59:32` below it — the shape people read as a
  /// deadline rather than as a number.
  String _format(Duration d) {
    if (d.inDays >= 1) {
      return '${d.inDays}d ${(d.inHours % 24).toString().padLeft(2, '0')}h';
    }
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _HeaderStreakBadge extends StatelessWidget {
  final int streak;
  final bool isPro;

  const _HeaderStreakBadge({required this.streak, this.isPro = false});

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: (d ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, color: const Color(0xFFE29200), size: 13),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: d ? Colors.white : const Color(0xFF1C1C1E),
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

  const _CalorieDashboardCard({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.mealCount,
    required this.protein,
    required this.proteinGoal,
    required this.yesterdayCalories,
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
                                          : [
                                            colorScheme.primary,
                                            AppColors.sky,
                                          ],
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

    Color insightColor = AppColors.green;
    if (consumed == 0) {
      insightColor = colorScheme.primary;
    } else if (remaining < 0) {
      insightColor = AppColors.amber;
    } else if (proteinGoal > 0 && protein < proteinGoal * 0.55) {
      insightColor = colorScheme.primary.withValues(alpha: 0.85);
    }

    Color comparisonColor = AppColors.green;
    if (yesterdayCalories <= 0) {
      comparisonColor = AppColors.blue;
    } else {
      final diff = consumed - yesterdayCalories;
      if (diff == 0) {
        comparisonColor = colorScheme.primary;
      } else if (diff < 0) {
        comparisonColor = AppColors.green;
      } else {
        comparisonColor = AppColors.amber;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _MiniHeroChip(
            icon: LucideIcons.sparkles,
            label: insight,
            color: insightColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniHeroChip(
            icon: LucideIcons.history,
            label: comparison,
            color: comparisonColor,
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
        border: Border.all(color: color.withValues(alpha: 0.16), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.90),
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

class _SecondaryDashboardGrid extends StatelessWidget {
  final int waterTotal;
  final int waterGoal;
  final int steps;
  final int stepGoal;
  final int burnedCalories;
  final bool caloriesEstimated;
  final VoidCallback onWaterTap;
  final VoidCallback onWaterAdd;
  final VoidCallback onWaterUndo;
  final VoidCallback onActivityTap;

  const _SecondaryDashboardGrid({
    required this.waterTotal,
    required this.waterGoal,
    required this.steps,
    required this.stepGoal,
    required this.burnedCalories,
    required this.caloriesEstimated,
    required this.onWaterTap,
    required this.onWaterAdd,
    required this.onWaterUndo,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // "15 estimated kcal" does not fit beside a title in a half-width card.
    // The tilde carries the estimated/measured distinction instead.
    final caloriesText =
        caloriesEstimated
            ? l10n.home_kcal_estimated_short(burnedCalories)
            : l10n.home_kcal_short(burnedCalories);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinimalSectionLabel(text: l10n.home_daily_wellness),
          const SizedBox(height: 8),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WellnessCard(
                    icon: LucideIcons.droplets,
                    accent: const Color(0xFF3B9BE8),
                    title: l10n.water_hydration,
                    value: waterTotal,
                    goal: waterGoal,
                    unit: l10n.water_unit_ml,
                    onTap: onWaterTap,
                    onAdd: onWaterAdd,
                    onUndo: onWaterUndo,
                    addSemanticLabel: l10n.water_add_amount(_waterQuickAddMl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WellnessCard(
                    icon: LucideIcons.footprints,
                    accent: AppColors.primary,
                    title: l10n.home_metric_activity,
                    value: steps,
                    // Was `steps / 10000`. ActivitySummary has carried a real
                    // stepGoal all along; the card just never asked for it,
                    // so a 3k-a-day walker and a 20k-a-day walker saw the
                    // same bar.
                    goal: stepGoal,
                    unit: l10n.log_metric_steps_unit,
                    onTap: onActivityTap,
                    trailingStat: caloriesText,
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

/// One card for every wellness metric.
///
/// Hydration and Activity used to be two unrelated widgets that merely looked
/// alike -- a StatefulWidget and a StatelessWidget sharing no code -- and they
/// had already drifted: one subtitle was an instruction and the other was data,
/// one showed its target only after the first entry and the other never did,
/// one read a real goal and the other divided by a hardcoded 10000. A single
/// widget cannot drift from itself.
///
/// The trailing slot in the header carries an action where one exists (water's
/// quick add) and a stat otherwise (calories burned), so both cards keep the
/// same skeleton.
class _WellnessCard extends StatelessWidget {
  const _WellnessCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.value,
    required this.goal,
    required this.unit,
    required this.onTap,
    this.onAdd,
    this.onUndo,
    this.addSemanticLabel,
    this.trailingStat,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final int value;
  final int goal;
  final String unit;
  final VoidCallback onTap;

  /// Quick add. Present for hydration: logging a glass is the most repeated
  /// action in the app after logging food, and it was costing three taps
  /// through a sheet while this handler sat wired to nothing.
  final VoidCallback? onAdd;

  /// Long-press partner for [onAdd], so a mistaken tap costs one gesture
  /// instead of a trip through the sheet.
  final VoidCallback? onUndo;
  final String? addSemanticLabel;

  /// A short secondary figure, right-aligned on the goal line. Kept short on
  /// purpose: the header has no room for it beside the title.
  final String? trailingStat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = scheme.onSurface.withValues(alpha: isDark ? 0.45 : 0.48);
    final reached = value >= goal && goal > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 11, 11),
        // The card carries no colour of its own. A pastel gradient fill with a
        // tinted border and a coloured shadow made two small metrics the
        // loudest surface on the screen; the accent now lives only in the
        // ring, where it means something.
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFEDE9E1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // A ring, not a bar: it echoes the calorie gauge above and the
            // macro rings between, so the dashboard reads as one system.
            _WellnessRing(
              progress: progress,
              accent: accent,
              icon: icon,
              isDark: isDark,
              reached: reached,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (onAdd != null) ...[
                        const SizedBox(width: 4),
                        _QuickAddButton(
                          accent: accent,
                          isDark: isDark,
                          onTap: onAdd!,
                          onUndo: onUndo,
                          semanticLabel: addSemanticLabel,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _formatNumber(context, value),
                          style: AppTypography.titleLarge.copyWith(
                            color: value > 0 ? ink : ink.withValues(alpha: 0.32),
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: AppTypography.labelSmall.copyWith(
                            color: ink.withValues(alpha: 0.42),
                            fontSize: 10.5,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // The trailing stat replaces the target where one exists:
                    // calories burned says more than "of 10,000 steps" once
                    // the ring already shows the ratio.
                    trailingStat ??
                        AppLocalizations.of(context)!.home_metric_of_goal(
                          _formatNumber(context, goal),
                          unit,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color:
                          trailingStat != null
                              ? accent.withValues(alpha: isDark ? 0.9 : 0.85)
                              : muted,
                      fontSize: 10.5,
                      fontWeight: trailingStat != null
                          ? FontWeight.w700
                          : FontWeight.w600,
                      letterSpacing: 0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

/// The metric's progress as a ring around its own icon.
///
/// Sized to sit beside two lines of type without dominating them; the icon in
/// the middle keeps the card readable at a glance without a second label.
class _WellnessRing extends StatelessWidget {
  const _WellnessRing({
    required this.progress,
    required this.accent,
    required this.icon,
    required this.isDark,
    required this.reached,
  });

  final double progress;
  final Color accent;
  final IconData icon;
  final bool isDark;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(
            painter: _WellnessRingPainter(
              progress: value,
              accent: accent,
              track: accent.withValues(alpha: isDark ? 0.18 : 0.13),
              reached: reached,
            ),
            child: Center(
              child: Icon(
                reached ? LucideIcons.check : icon,
                size: 16,
                color: accent.withValues(alpha: reached ? 1 : 0.9),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WellnessRingPainter extends CustomPainter {
  const _WellnessRingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.reached,
  });

  final double progress;
  final Color accent;
  final Color track;
  final bool reached;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.5;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final swept = progress.clamp(0.0, 1.0);
    if (swept <= 0) return;

    final rect = Rect.fromCircle(center: centre, radius: radius);
    const from = -math.pi / 2;
    final sweep = 2 * math.pi * swept;

    canvas.drawArc(
      rect,
      from,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [accent.withValues(alpha: 0.75), accent],
          transform: const GradientRotation(from),
        ).createShader(rect),
    );

    // A cap dot marks where the day has got to, unless the ring is closed.
    if (swept < 1) {
      final angle = from + sweep;
      canvas.drawCircle(
        centre + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        stroke * 0.62,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WellnessRingPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.track != track ||
      old.reached != reached;
}

/// Tap adds, long-press takes it back.
class _QuickAddButton extends StatefulWidget {
  const _QuickAddButton({
    required this.accent,
    required this.isDark,
    required this.onTap,
    this.onUndo,
    this.semanticLabel,
  });

  final Color accent;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onUndo;
  final String? semanticLabel;

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onLongPress: widget.onUndo,
        // The 22px circle was the entire hit area, and it sits on top of a
        // card that is itself tappable -- so a near miss on "+1 glass" opened
        // the hydration sheet instead of adding water. Padding widens what
        // you can hit to 44px without moving or resizing the circle.
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: AnimatedScale(
            scale: _pressed ? 0.86 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.accent.withValues(
                  alpha: widget.isDark ? 0.26 : 0.15,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(LucideIcons.plus, size: 13, color: widget.accent),
            ),
          ),
        ),
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
      accentColor: colorScheme.primary,
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
                  foregroundColor: colorScheme.primary,
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
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              LucideIcons.utensilsCrossed,
              color: colorScheme.primary,
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
              backgroundColor: colorScheme.primary,
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
        accentColor: colorScheme.primary,
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
                    color: _scoreColor(context, dailyScore),
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

  Color _scoreColor(BuildContext context, int score) {
    if (score >= 75) return Theme.of(context).colorScheme.primary;
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
    final color = _statusColor(context);
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

  Color _statusColor(BuildContext context) {
    if (calories == 0) return AppColors.lightTextSecondary;
    final ratio = calories / math.max(goal, 1);
    if (ratio >= 0.75 && ratio <= 1.08) {
      return Theme.of(context).colorScheme.primary;
    }
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
    required this.liquidFill,
    required this.motionTrail,
    required this.motionActive,
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
              color.withValues(alpha: isDark ? 0.16 : 0.12),
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
          Paint()..color = color.withValues(alpha: footAlpha);

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
