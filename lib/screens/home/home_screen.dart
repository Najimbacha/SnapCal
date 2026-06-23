import 'dart:math' as math;

// ignore_for_file: unused_element

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_slot.dart';
import 'widgets/smart_meal_planner_card.dart';
import 'widgets/activity_health_connect_sheet.dart';
import '../log/widgets/hydration_sheet.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/scan_choice_sheet.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/recent_meal_tile.dart';
import '../../widgets/premium_prompt_modal.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/auth_notifier_provider.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/activity_service.dart';

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
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          final todaysMealsAsync = ref.read(todaysMealsProvider);
          final hasAiMeal = (todaysMealsAsync.valueOrNull ?? []).any(
            (m) => m.scanSource == 'ai_scan',
          );

          if (hasAiMeal) {
            final l10n = AppLocalizations.of(context)!;
            PremiumPromptModal.show(
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
          }
        }
      });
    });
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
    final totalCalories =
        todaysMeals.fold<int>(0, (sum, m) => sum + m.calories);
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

    final activitySummary =
        ref.watch(activityProvider).valueOrNull;
    final activitySteps = activitySummary?.steps ?? 0;
    final activeCalories = activitySummary?.activeCalories.round() ?? 0;
    final healthConnected = activitySummary?.healthConnected ?? false;

    final waterState = ref.watch(waterProvider).valueOrNull;
    final waterTotal = waterState?.todayTotal ?? 0;
    final waterGoal = waterState?.goal ?? 2500;

    final isLoading = todaysMealsAsync.isLoading || todaysMealsAsync.isRefreshing;
    final isRefreshing = todaysMealsAsync.isRefreshing;

    final adjustedGoal =
        isPro ? calorieGoal + activeCalories : calorieGoal;
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
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF14130F)
              : const Color(0xFFF9F8F5),
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
                ),
          ),
          const SizedBox(height: 2),
          if (isPro) ...[
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
                burnedCalories: activeCalories,
                caloriesEstimated: !healthConnected,
                stepsUnit: 'steps',
                activityLive: healthConnected,
                onWaterTap: () => showHydrationSheet(context),
                onWaterAdd: () => _addWater(ref),
                onWaterRemove: () => _removeWater(ref),
                onActivityTap: () => showActivityHealthConnectSheet(context),
              ),
            ),
          ] else ...[
            _staggeredSlide(
              _itemAnims[2],
              _SecondaryDashboardGrid(
                waterTotal: waterTotal,
                waterGoal: waterGoal,
                steps: activitySteps,
                burnedCalories: activeCalories,
                caloriesEstimated: !healthConnected,
                stepsUnit: 'steps',
                activityLive: healthConnected,
                onWaterTap: () => showHydrationSheet(context),
                onWaterAdd: () => _addWater(ref),
                onWaterRemove: () => _removeWater(ref),
                onActivityTap: () => showActivityHealthConnectSheet(context),
              ),
            ),
            const SizedBox(height: 2),
            _staggeredSlide(
              _itemAnims[3],
              _MinimalMacroSection(
                macros: macros,
                proteinGoal: proteinGoal,
                carbGoal: carbGoal,
                fatGoal: fatGoal,
                isPro: isPro,
              ),
            ),
          ],
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
    ref.read(waterProvider.notifier).addWater(250);
  }

  void _removeWater(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(waterProvider.notifier).removeWater(250);
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
const _minimalGreen = Color(0xFF1A3D2B);
const _minimalGreenText = Color(0xFF16733A);

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
                Icon(
                  LucideIcons.flame,
                  color: Colors.orange,
                  size: 14,
                ),
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
          // Pro Badge / Go Pro
          AppScaleTap(
            onTap: isPro ? onSettingsTap : onProTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPro ? LucideIcons.gem : LucideIcons.crown,
                  color: isPro ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isPro
                      ? AppLocalizations.of(context)!.home_pro_badge
                      : AppLocalizations.of(context)!.home_go_pro,
                  style: TextStyle(
                    color: isPro ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Settings button
          GestureDetector(
            onTap: onSettingsTap,
            child: Icon(
              LucideIcons.settings,
              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
              size: 20,
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

  const _MinimalCalorieHero({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.mealCount,
    required this.progress,
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
                        _formatNumber(remaining.abs()),
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_calories_eaten,
                  value: _formatNumber(consumed),
                  unit: 'kcal',
                ),
              ),
              _MinimalDivider(isDark: isDark),
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_metric_goal,
                  value: _formatNumber(goal),
                  unit: 'kcal',
                  valueColor: _minimalGreenText,
                ),
              ),
              _MinimalDivider(isDark: isDark),
              Expanded(
                child: _MinimalHeroStat(
                  label: l10n.home_metric_meals,
                  value: _formatNumber(mealCount),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MinimalSectionLabel(text: l10n.home_section_macros_today),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A029), Color(0xFFE29200)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPro) ...[
            Row(
              children: [
                _MacroCard(label: l10n.result_protein, value: macros.protein, goal: proteinGoal, color: AppColors.protein, isDark: isDark),
                const SizedBox(width: 6),
                _MacroCard(label: l10n.result_carbs, value: macros.carbs, goal: carbGoal, color: AppColors.carbs, isDark: isDark),
                const SizedBox(width: 6),
                _MacroCard(label: l10n.result_fat, value: macros.fat, goal: fatGoal, color: AppColors.fat, isDark: isDark),
              ],
            ),
          ] else
            const _MacroPreviewCard(),
          const SizedBox(height: 14),
          const _MinimalSectionDivider(),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final Color color;
  final bool isDark;

  const _MacroCard({required this.label, required this.value, required this.goal, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = (value / math.max(goal, 1)).clamp(0.0, 1.0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFEFCF7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8E4DC),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : const Color(0xFF8E8E93))),
            const SizedBox(height: 3),
            Text('${value}g', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color, height: 1.1)),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                width: 36, height: 3,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E4DC),
                child: FractionallySizedBox(
                  widthFactor: pct,
                  heightFactor: 1,
                  child: Container(color: color),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text('${goal}g', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w500, color: isDark ? Colors.white24 : const Color(0xFFC7C7CC))),
          ],
        ),
      ),
    );
  }
}

class _MacroPreviewCard extends StatelessWidget {
  const _MacroPreviewCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final cardBg = isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFEFCF7);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8E4DC);
    final muted = isDark ? Colors.white38 : const Color(0xFFB4AFA8);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF78716C);

    final items = [
      (l10n.result_protein, const Color(0xFF7C9A6D), 0.65),
      (l10n.result_carbs, const Color(0xFF4F8CC9), 0.50),
      (l10n.result_fat, const Color(0xFFD18B47), 0.40),
    ];

    return GestureDetector(
      onTap:
          () => PremiumConversionService().openPaywall(
            context,
            PaywallEntryPoint.macroDetails,
            featureName: 'home_macros',
          ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Three macro rows
            ...items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: item == items.last ? 0 : 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        item.$1,
                        style: AppTypography.labelSmall.copyWith(
                          color: mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 4,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: item.$2.withValues(
                            alpha: isDark ? 0.10 : 0.15,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: item.$3,
                          heightFactor: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: item.$2.withValues(
                                alpha: isDark ? 0.35 : 0.40,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(LucideIcons.lock, size: 12, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      '—g',
                      style: AppTypography.labelMedium.copyWith(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.macro_unlock_card_title,
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalMacroRow extends StatelessWidget {
  final String label;
  final int value;
  final int goal;

  const _MinimalMacroRow({
    required this.label,
    required this.value,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _minimalInk;
    final muted = isDark ? Colors.white60 : const Color(0xFF78716C);
    final progress = (value / math.max(goal, 1)).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 3,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.10) : _minimalLine,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, animated, child) {
                  return FractionallySizedBox(
                    widthFactor: animated,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _minimalGreen,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 42,
          child: Text(
            '${_formatNumber(value)}g',
            style: AppTypography.labelMedium.copyWith(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MinimalSectionLabel(text: 'Plan and coach'),
          const SizedBox(height: 10),
          Row(
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
                  subtitle: 'Personalized AI advice',
                  isPro: isPro,
                  onTap: onCoachTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFEFCF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8E4DC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 13, color: AppColors.primary),
                ),
                const Spacer(),
                if (!isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('PRO', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5, height: 1)),
                  ),
              ],
            ),
            const Spacer(),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: isDark ? Colors.white38 : const Color(0xFF8E8E93))),
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
                  foregroundColor: _minimalGreenText,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  viewAllLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: _minimalGreenText,
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
            const _MinimalLockedMealRow(label: 'Lunch'),
            const _MinimalLockedMealRow(label: 'Dinner'),
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
              decoration: const BoxDecoration(
                color: _minimalGreenText,
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
              _formatNumber(meal.calories),
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

class _MinimalLockedMealRow extends StatelessWidget {
  final String label;

  const _MinimalLockedMealRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.032)
                    : const Color(0xFFECEAE6).withValues(alpha: 0.40),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.lock,
            color: isDark ? Colors.white.withValues(alpha: 0.24) : const Color(0xFF78716C).withValues(alpha: 0.40),
            size: 14,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.40) : _minimalInk.withValues(alpha: 0.40),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '· · · · ·',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.216) : _minimalMuted.withValues(alpha: 0.40),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.216) : const Color(0xFFC4BEB5).withValues(alpha: 0.40),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

String _formatNumber(int value) {
  if (value < 10000) return '$value';
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
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
      child: Container(
        width: 36, height: 36,
        child: Center(child: Icon(Icons.settings_rounded, size: 20, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
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
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Icon(LucideIcons.sparkles, size: 16, color: Colors.white)),
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
                Text('SnapCal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: d ? Colors.white : const Color(0xFF1C1C1E), letterSpacing: -0.5)),
                if (isRefreshing)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: d ? Colors.white38 : const Color(0xFFC7C7CC))),
                  ),
              ],
            ),
          ),
          _HomeCoachButton(onTap: () {
              if (isPro) { context.push('/assistant'); }
              else { PremiumConversionService().openPaywall(context, PaywallEntryPoint.aiCoachLimit, featureName: 'ai_coach'); }
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
        decoration: BoxDecoration(color: const Color(0xFFFFD700).withValues(alpha: d ? 0.15 : 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.gem, color: const Color(0xFFE29200), size: 11),
            const SizedBox(width: 4),
            Text(AppLocalizations.of(context)!.home_pro_badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFE29200))),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); context.push('/paywall'); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: d ? 0.15 : 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, color: AppColors.primary, size: 11),
            const SizedBox(width: 4),
            Text(AppLocalizations.of(context)!.home_go_pro, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ),
    );
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
          Text('$streak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: d ? Colors.white : const Color(0xFF1C1C1E))),
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
  final bool caloriesEstimated;
  final String stepsUnit;
  final bool activityLive;
  final VoidCallback onWaterTap;
  final VoidCallback onWaterAdd;
  final VoidCallback onWaterRemove;
  final VoidCallback onActivityTap;

  const _SecondaryDashboardGrid({
    required this.waterTotal,
    required this.waterGoal,
    required this.steps,
    required this.burnedCalories,
    required this.caloriesEstimated,
    required this.stepsUnit,
    required this.activityLive,
    required this.onWaterTap,
    required this.onWaterAdd,
    required this.onWaterRemove,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepsProgress = (steps / 10000).clamp(0.0, 1.0);
    final caloriesText =
        caloriesEstimated
            ? '$burnedCalories estimated kcal'
            : '$burnedCalories active kcal';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinimalSectionLabel(text: l10n.home_daily_wellness),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WaterFillCard(
                    total: waterTotal,
                    goal: waterGoal,
                    onTap: onWaterTap,
                    onAdd: onWaterAdd,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MinimalWellnessCard(
                    icon: LucideIcons.footprints,
                    color: Theme.of(context).colorScheme.primary,
                    title: l10n.home_metric_activity,
                    value: steps == 0 ? '0 steps' : '$steps',
                    subtitle: steps == 0 ? 'Start walking' : caloriesText,
                    progress: stepsProgress,
                    onTap: onActivityTap,
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

class _WaterFillCard extends StatefulWidget {
  final int total;
  final int goal;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _WaterFillCard({
    required this.total,
    required this.goal,
    required this.onTap,
    required this.onAdd,
  });

  @override
  State<_WaterFillCard> createState() => _WaterFillCardState();
}

class _WaterFillCardState extends State<_WaterFillCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blue = const Color(0xFF3B82F6);
    final progress = (widget.total / widget.goal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFEFCF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE8E4DC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WellnessCardHeader(
              icon: LucideIcons.droplets,
              color: blue,
              title: 'Hydration',
              isDark: isDark,
            ),
            const Spacer(),
            Text(
              widget.total == 0 ? '0 ml' : '${widget.total} ml',
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? Colors.white : const Color(0xFF1C1917),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.total == 0
                  ? 'Tap to open'
                  : 'of ${widget.goal} ml',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  height: 3,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: blue.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: blue.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalWellnessCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final VoidCallback onTap;

  const _MinimalWellnessCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFEFCF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE8E4DC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WellnessCardHeader(
              icon: icon,
              color: color,
              title: title,
              isDark: isDark,
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? Colors.white : const Color(0xFF1C1917),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  height: 3,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WellnessCardHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool isDark;

  const _WellnessCardHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white54 : const Color(0xFFB4AFA8),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
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
