import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_plan.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/auth_notifier_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/models/user_settings.dart';

import '../../widgets/app_page_scaffold.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/ui_blocks.dart';
import '../../data/services/gemini_service.dart';
import 'widgets/meal_card.dart';
import 'widgets/day_summary_bar.dart';
import 'meal_preferences_screen.dart';

enum _PlannerAction { grocery, preferences, regenerateWeek, optimize }

final plannerNotifierProvider = ChangeNotifierProvider<PlannerProvider>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull ?? UserSettings.defaults();
  return PlannerProvider(AIService(), settings);
});

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  late final PlannerProvider _plannerProvider;
  bool _listeningToPlanner = false;
  bool _isOptimizing = false;
  int? _selectedDayIndex;

  List<String> _getDayLabels(BuildContext context, {MealPlan? plan}) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.planner_day_mon,
      l10n.planner_day_tue,
      l10n.planner_day_wed,
      l10n.planner_day_thu,
      l10n.planner_day_fri,
      l10n.planner_day_sat,
      l10n.planner_day_sun,
    ];
    if (plan != null) {
      return List.generate(7, (i) {
        final date = plan.startDate.add(Duration(days: i));
        final weekdayIndex = date.weekday - 1; // 0-indexed Monday
        return '${labels[weekdayIndex]} ${date.day}';
      });
    }
    return labels;
  }

  @override
  void initState() {
    super.initState();
    _plannerProvider = ref.read(plannerNotifierProvider);

    // Guard against non-pro users accessing the screen directly
    if (!(ref.read(settingsProvider).valueOrNull?.isPro ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/');
          }
          PremiumConversionService().openPaywall(
            context,
            PaywallEntryPoint.plannerLockedDay,
            featureName: 'meal_planner',
          );
        }
      });
      return;
    }

    _plannerProvider.addListener(_onPlannerChange);
    _listeningToPlanner = true;
  }

  @override
  void dispose() {
    if (_listeningToPlanner) {
      _plannerProvider.removeListener(_onPlannerChange);
    }
    super.dispose();
  }

  void _onPlannerChange() {
    if (_plannerProvider.error != null &&
        _plannerProvider.currentPlan != null) {
      final errorMsg = _plannerProvider.error!;
      _plannerProvider.clearError();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMsg)),
                ],
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService();
    final isOnline = connectivity.hasInternetAccess;

    return AppPageScaffold(
      title: '', // Custom large Apple header inside body
      scrollable: false,
      padding: EdgeInsets.zero,
      showHeader: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.primaryColor.withValues(alpha: 0.05),
              context.backgroundColor,
            ],
            stops: const [0.0, 0.40],
          ),
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final planner = ref.watch(plannerNotifierProvider);
            // 1. Generating state
            if (planner.isGenerating && planner.currentPlan == null) {
              return _buildGeneratingState();
            }

            // 2. Offline state (no internet and no current plan)
            if (!isOnline && planner.currentPlan == null) {
              return _buildOfflineState();
            }

            // 3. Error state
            if (planner.error != null && planner.currentPlan == null) {
              return _buildErrorState();
            }

            // 4. Empty state
            if (planner.currentPlan == null) return _buildEmptyState();

            // 5. Plan exists
            return AppAsyncOverlay(
              state: planner.uiState,
              child: _buildPlanView(),
            );
          },
        ),
      ),
    );
  }

  int? _todayIndexForPlan(MealPlan? plan) {
    if (plan == null) return null;
    final today = DateTime.now();
    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (todayOnly.isBefore(start) || todayOnly.isAfter(end)) return null;
    return todayOnly.difference(start).inDays.clamp(0, 6);
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              AppLocalizations.of(context)!.planner_creating,
              style: AppTypography.titleMedium.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            _GeneratingMessages(color: context.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: AppEmptyState(
        icon: LucideIcons.alertTriangle,
        title: l10n.error_generic,
        body: _plannerProvider.error ?? l10n.error_generic,
        actionLabel: l10n.common_try_again,
        onAction: () {
          final isOnline =
              ConnectivityService().hasInternetAccess;
          if (!isOnline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      LucideIcons.wifiOff,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.error_offline)),
                  ],
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
          _plannerProvider.generateWeeklyPlan();
        },
      ),
    );
  }

  Widget _buildOfflineState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: AppEmptyState(
        icon: LucideIcons.wifiOff,
        title: l10n.common_offline_mode,
        body: l10n.error_offline,
        actionLabel: l10n.common_try_again,
        onAction: () async {
          await ConnectivityService().refreshReachability(
            force: true,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.calendarDays,
                color: context.primaryColor,
                size: 40,
              ),
              const SizedBox(height: 22),
              Text(
                l10n.planner_empty_headline,
                style: AppTypography.headlineSmall.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.planner_empty_body,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton(
                key: const ValueKey('planner-empty-generate'),
                onPressed: () => _showPreferences(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.planner_generate_plan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanView() {
    final planner = ref.watch(plannerNotifierProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isDark = context.isDarkMode;
    final plan = planner.currentPlan;
    final todayIndex = _todayIndexForPlan(plan);
    final activeIndex = _selectedDayIndex ?? todayIndex ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (planner.fallbackNotice != null)
          _FallbackNoticeBanner(
            notice: planner.fallbackNotice!,
            onDismiss: planner.clearFallbackNotice,
            isDark: isDark,
          ),
        if (planner.rebalanceNotice != null)
          _RebalanceNoticeBanner(
            notice: planner.rebalanceNotice!,
            onDismiss: planner.clearRebalanceNotice,
            isDark: isDark,
          ),
        if (planner.isCurrentPlanExpired)
          _ExpiredPlanBanner(
            onGenerate:
                (settings?.isPro ?? false)
                    ? () => _confirmRegenerate(context)
                    : () => _showPaywall(
                      context,
                      PaywallEntryPoint.plannerPreferences,
                    ),
            isDark: isDark,
          ),
        _PlannerHeader(
          planner: planner,
          onGroceryTap: () => _showGrocerySheet(),
          onAction: (action) => _handlePlannerAction(action),
          isOptimizing: _isOptimizing,
        ),
        if (plan != null)
          _buildWeekDatePicker(
            plan: plan,
            activeIndex: activeIndex,
            isPro: settings?.isPro ?? false,
            todayIndex: todayIndex,
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final position = Tween<Offset>(
                begin: const Offset(0.04, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: position, child: child),
              );
            },
            child: _buildActiveDayView(activeIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDatePicker({
    required MealPlan plan,
    required int activeIndex,
    required bool isPro,
    required int? todayIndex,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.planner_day_mon,
      l10n.planner_day_tue,
      l10n.planner_day_wed,
      l10n.planner_day_thu,
      l10n.planner_day_fri,
      l10n.planner_day_sat,
      l10n.planner_day_sun,
    ];

    return Container(
      height: 86,
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = plan.startDate.add(Duration(days: index));
          final weekdayIndex = date.weekday - 1; // Monday = 0
          final isSelected = activeIndex == index;
          final isToday = todayIndex == index;
          final isLocked = !isPro && index >= 2;

          // Limit weekday name to 3 chars
          final label =
              labels[weekdayIndex].length > 3
                  ? labels[weekdayIndex].substring(0, 3)
                  : labels[weekdayIndex];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    key: ValueKey('planner-day-$index'),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? context.primaryColor
                              : (isToday
                                  ? context.primaryColor.withValues(alpha: 0.05)
                                  : Colors.transparent),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          isToday && !isSelected
                              ? Border.all(
                                color: context.primaryColor.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.5,
                              )
                              : null,
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: context.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                              : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedDayIndex = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : (isToday
                                            ? context.primaryColor
                                            : context.textMutedColor),
                                fontWeight:
                                    isSelected || isToday
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${date.day}',
                              style: AppTypography.bodyMedium.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : context.textPrimaryColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(height: 3),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : context.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ] else
                              const SizedBox(height: 7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        LucideIcons.lock,
                        size: 9,
                        color:
                            isSelected
                                ? Colors.white70
                                : context.textMutedColor,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveDayView(int activeIndex) {
    final planner = ref.watch(plannerNotifierProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final plan = planner.currentPlan;
    if (plan == null) return const SizedBox.shrink();
    final todayIndex = _todayIndexForPlan(plan);
    final isLocked = !(settings?.isPro ?? false) && activeIndex >= 2;
    final meals = plan.weeklyMeals[activeIndex] ?? const <Meal>[];
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final targetCalories = settings?.dailyCalorieGoal ?? 2000;
    final l10n = AppLocalizations.of(context)!;

    final date = plan.startDate.add(Duration(days: activeIndex));
    final weekdayLabel = _getDayLabels(context)[date.weekday - 1];
    final dateLabel = DateFormat.MMMd(l10n.localeName).format(date);
    final dateHeaderStr = '$weekdayLabel, $dateLabel';

    return Stack(
      key: ValueKey('planner-active-day-stack-$activeIndex'),
      children: [
        ListView(
          key: ValueKey('planner-active-day-$activeIndex'),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            // Active Day Header Info
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
                left: 4,
                right: 4,
                top: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dateHeaderStr,
                              style: AppTypography.titleMedium.copyWith(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (todayIndex == activeIndex) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.common_today,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${meals.length} ${l10n.planner_meals_unit}',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.textMutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((settings?.isPro ?? false) && planner.canRegenerate && !isLocked)
                    TextButton.icon(
                      onPressed:
                          () => _confirmRegenerateDay(
                            context,
                            activeIndex,
                          ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        backgroundColor: context.cardSoftColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: context.cardBorderColor),
                        ),
                      ),
                      icon: Icon(
                        LucideIcons.refreshCw,
                        size: 12,
                        color: context.primaryColor,
                      ),
                      label: Text(
                        l10n.planner_regenerate,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (!isLocked) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DaySummaryBar(
                  totalCalories: totalCalories,
                  targetCalories: targetCalories,
                ),
              ),
            ],

            // Meals list or Lock indicator
            if (isLocked)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.cardBorderColor,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.lock,
                        color: context.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.planner_unlock_week,
                      style: AppTypography.titleMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.planner_grocery_pro_body,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed:
                          () => _showPaywall(
                            context,
                            PaywallEntryPoint.plannerLockedDay,
                          ),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(200, 48),
                      ),
                      child: Text(
                        l10n.planner_upgrade_pro,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              )
            else if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.utensilsCrossed,
                        size: 38,
                        color: context.textMutedColor,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.planner_no_meals_body,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...meals.map(
                (meal) => MealCard(
                  meal: meal,
                  isLogged: planner.loggedPlannedMealIds.contains(meal.id),
                  onLogMeal:
                      planner.loggedPlannedMealIds.contains(meal.id)
                          ? null
                          : () => _logPlannedMeal(meal),
                  onSwapMeal:
                      () =>
                          _confirmSwapMeal(context, meal, activeIndex),
                ),
              ),
          ],
        ),
        if (planner.isRegenerating)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.60),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  void _showGrocerySheet() {
    final planner = ref.read(plannerNotifierProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            expand: false,
            builder:
                (context, scrollController) => _GrocerySheet(
                  provider: planner,
                  settings: settings,
                  scrollController: scrollController,
                  onUpgrade:
                      () =>
                          _showPaywall(context, PaywallEntryPoint.groceryList),
                ),
          ),
    );
  }

  void _handlePlannerAction(_PlannerAction action) {
    final settings = ref.read(settingsProvider).valueOrNull;
    switch (action) {
      case _PlannerAction.grocery:
        _showGrocerySheet();
        break;
      case _PlannerAction.preferences:
        _showPreferences(context);
        break;
      case _PlannerAction.regenerateWeek:
        if (!(settings?.isPro ?? false)) {
          _showPaywall(context, PaywallEntryPoint.plannerPreferences);
          return;
        }
        _confirmRegenerate(context);
        break;
      case _PlannerAction.optimize:
        _optimizePlan();
        break;
    }
  }

  Future<void> _optimizePlan() async {
    if (_isOptimizing) return;
    final metricsProvider = ref.read(bodyMetricsProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentWeight = metricsProvider.currentWeight;
    final l10n = AppLocalizations.of(context)!;
    final todaysMeals = ref.watch(todaysMealsProvider).valueOrNull ?? [];
    final totalCalories = todaysMeals.fold<int>(0, (s, m) => s + m.calories);

    if (currentWeight == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settings_log_weight_first)));
      return;
    }

    setState(() => _isOptimizing = true);
    final success = await settingsNotifier.recalculatePlan(
      currentWeightKg: currentWeight,
    );

    if (!mounted) return;
    setState(() => _isOptimizing = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_complete_profile_first)),
      );
      return;
    }

    context.push('/assistant');
    ref.read(assistantProvider.notifier).fetchRecommendations(
      l10n.settings_recalculate_query,
      currentCalories: totalCalories,
    );
  }

  void _logPlannedMeal(Meal meal) async {
    final mealNotifier = ref.read(mealLogProvider.notifier);

    HapticFeedback.mediumImpact();
    await mealNotifier.addMeal(meal);

    // TODO: mark planned meal as logged
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.result_save_success),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmRegenerate(BuildContext context) {
    final planner = _plannerProvider;
    final isOnline = ConnectivityService().hasInternetAccess;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.wifiOff, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppLocalizations.of(context)!.error_offline),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.planner_regenerate),
            content: Text(AppLocalizations.of(context)!.planner_setup_body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.common_cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  planner.generateWeeklyPlan();
                },
                child: Text(AppLocalizations.of(context)!.planner_regenerate),
              ),
            ],
          ),
    );
  }

  void _confirmRegenerateDay(
    BuildContext context,
    int dayIndex,
  ) {
    final planner = _plannerProvider;
    final isOnline = ConnectivityService().hasInternetAccess;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.wifiOff, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppLocalizations.of(context)!.error_offline),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final dayLabel =
        _getDayLabels(context, plan: planner.currentPlan)[dayIndex];
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.planner_regenerate),
            content: Text(
              AppLocalizations.of(context)!.planner_regenerate_body(dayLabel),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.common_cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  planner.regenerateDay(dayIndex);
                },
                child: Text(AppLocalizations.of(context)!.planner_regenerate),
              ),
            ],
          ),
    );
  }

  void _confirmSwapMeal(
    BuildContext context,
    Meal meal,
    int dayIndex,
  ) async {
    final planner = _plannerProvider;
    // Check connectivity
    final isOnline = ConnectivityService().hasInternetAccess;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.wifiOff, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppLocalizations.of(context)!.error_offline),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Check Pro status
    final settings = ref.read(settingsProvider).valueOrNull;
    if (!(settings?.isPro ?? false)) {
      _showPaywall(context, PaywallEntryPoint.plannerPreferences);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _SwapPreferencesSheet(
            meal: meal,
            onSwap: (swapIntent, note) async {
              // Show inline loading spinner/modal
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (loadingCtx) => BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Center(
                        child: AppSectionCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.planner_swap_loading,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              );

              try {
                await planner.swapMeal(
                  dayIndex,
                  meal,
                  craving: note,
                  swapIntent: swapIntent,
                );
                if (!context.mounted) return;
                Navigator.pop(context); // Dismiss loading dialog

                if (planner.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(planner.error!)));
                  planner.clearError();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.planner_swap_success,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                debugPrint('Error swapping meal: $e');
              }
            },
          ),
    );
  }

  void _showPreferences(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => MealPreferencesScreen(
              onGenerate: () {
                final isOnline =
                    ConnectivityService().hasInternetAccess;
                if (!isOnline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            LucideIcons.wifiOff,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.error_offline,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                _plannerProvider.generateWeeklyPlan();
              },
            ),
      ),
    );
  }

  void _showPaywall(BuildContext context, PaywallEntryPoint entryPoint) {
    PremiumConversionService().openPaywall(
      context,
      entryPoint,
      featureName: 'meal_planner',
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  final PlannerProvider planner;
  final VoidCallback onGroceryTap;
  final ValueChanged<_PlannerAction> onAction;
  final bool isOptimizing;

  const _PlannerHeader({
    required this.planner,
    required this.onGroceryTap,
    required this.onAction,
    required this.isOptimizing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planner_title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                _HeaderRangeLabel(plan: planner.currentPlan),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('planner-grocery-button'),
            tooltip: l10n.planner_tab_grocery,
            onPressed: onGroceryTap,
            style: IconButton.styleFrom(
              backgroundColor: context.cardSoftColor,
              foregroundColor: context.textPrimaryColor,
              fixedSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: context.cardBorderColor),
              ),
            ),
            icon: Icon(LucideIcons.shoppingBag, size: 18),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<_PlannerAction>(
            key: const ValueKey('planner-overflow-menu'),
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: onAction,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: _PlannerAction.preferences,
                    child: _MenuRow(
                      icon: LucideIcons.slidersHorizontal,
                      label: l10n.planner_meal_preferences,
                    ),
                  ),
                  PopupMenuItem(
                    value: _PlannerAction.grocery,
                    child: _MenuRow(
                      icon: LucideIcons.shoppingBag,
                      label: l10n.planner_tab_grocery,
                    ),
                  ),
                  PopupMenuItem(
                    value: _PlannerAction.regenerateWeek,
                    child: _MenuRow(
                      icon: LucideIcons.refreshCw,
                      label: l10n.planner_regenerate,
                    ),
                  ),
                  PopupMenuItem(
                    value: _PlannerAction.optimize,
                    child: _MenuRow(
                      icon: LucideIcons.sparkles,
                      label:
                          isOptimizing
                              ? l10n.settings_optimizing
                              : l10n.settings_optimize_btn,
                    ),
                  ),
                ],
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.cardSoftColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.cardBorderColor),
              ),
              child: Icon(LucideIcons.moreHorizontal, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRangeLabel extends StatelessWidget {
  final MealPlan? plan;

  const _HeaderRangeLabel({required this.plan});

  @override
  Widget build(BuildContext context) {
    final currentPlan = plan;
    if (currentPlan == null) return const SizedBox.shrink();
    final localeName = AppLocalizations.of(context)!.localeName;
    final startStr = DateFormat.MMMd(localeName).format(currentPlan.startDate);
    final endStr = DateFormat.MMMd(localeName).format(currentPlan.endDate);
    return Text(
      '$startStr - $endStr',
      style: AppTypography.bodySmall.copyWith(
        color: context.textSecondaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _GrocerySheet extends StatelessWidget {
  final PlannerProvider provider;
  final UserSettings? settings;
  final ScrollController scrollController;
  final VoidCallback onUpgrade;

  const _GrocerySheet({
    required this.provider,
    required this.settings,
    required this.scrollController,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(top: BorderSide(color: context.cardBorderColor)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textMutedColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.planner_tab_grocery,
                        style: AppTypography.titleLarge.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if ((settings?.isPro ?? false) && provider.groceryList.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text: provider.getFormattedGroceryList(),
                            ),
                          );
                        },
                        icon: Icon(LucideIcons.share2, size: 16),
                        label: Text(l10n.planner_share),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildContent(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!(settings?.isPro ?? false)) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.crown,
          title: l10n.planner_grocery_pro,
          body: l10n.planner_grocery_pro_body,
          actionLabel: l10n.planner_upgrade_pro,
          onAction: onUpgrade,
        ),
      );
    }

    if (provider.groceryList.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.shoppingBag,
          title: l10n.planner_grocery_empty,
          body: l10n.planner_grocery_empty_body,
        ),
      );
    }

    final grouped = <String, List<dynamic>>{};
    for (final item in provider.groceryList) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final checkedCount =
        provider.groceryList.where((item) => item.isChecked).length;

    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _GroceryProgressHeader(
          checked: checkedCount,
          total: provider.groceryList.length,
        ),
        ...grouped.entries.map(
          (entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
                child: Text(
                  entry.key.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textMutedColor,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...entry.value.map(
                (item) => _GroceryItemTile(
                  item: item,
                  onToggle: () => provider.toggleGroceryItem(item.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Fallback Notice Banner ──────────────────────────────────────────────────
class _FallbackNoticeBanner extends StatelessWidget {
  final String notice;
  final VoidCallback onDismiss;
  final bool isDark;

  const _FallbackNoticeBanner({
    required this.notice,
    required this.onDismiss,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notice,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.orange[200] : Colors.orange[900],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(LucideIcons.x, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Rebalance Notice Banner ─────────────────────────────────────────────────
class _RebalanceNoticeBanner extends StatelessWidget {
  final String notice;
  final VoidCallback onDismiss;
  final bool isDark;

  const _RebalanceNoticeBanner({
    required this.notice,
    required this.onDismiss,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.success.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: AppColors.success, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notice,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.green[200] : Colors.green[900],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(LucideIcons.x, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Expired Plan Banner ─────────────────────────────────────────────────────
class _ExpiredPlanBanner extends StatelessWidget {
  final VoidCallback onGenerate;
  final bool isDark;

  const _ExpiredPlanBanner({required this.onGenerate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: AppColors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.planner_week_complete_title,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.indigo[200] : Colors.indigo[900],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onGenerate,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppLocalizations.of(context)!.planner_generate_current_week,
              style: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Grocery Item Checklist Row ──────────────────────────────────────────────
class _GroceryItemTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onToggle;

  const _GroceryItemTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _ScaleTap(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorderColor, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      item.isChecked ? AppColors.success : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        item.isChecked
                            ? Colors.transparent
                            : context.textMutedColor,
                    width: 1.5,
                  ),
                ),
                child:
                    item.isChecked
                        ? const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 14,
                        )
                        : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color:
                        item.isChecked
                            ? context.textMutedColor
                            : context.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                    decoration:
                        item.isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Text(
                item.amount,
                style: AppTypography.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroceryProgressHeader extends StatelessWidget {
  final int checked;
  final int total;

  const _GroceryProgressHeader({required this.checked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? checked / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardSoftColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.planner_tab_grocery,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$checked/$total',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: context.cardColor,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratingMessages extends StatefulWidget {
  final Color color;

  const _GeneratingMessages({required this.color});

  @override
  State<_GeneratingMessages> createState() => _GeneratingMessagesState();
}

class _GeneratingMessagesState extends State<_GeneratingMessages> {
  int _msgIdx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) setState(() => _msgIdx = (_msgIdx + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final msgs = [
      l10n.planner_msg_calories,
      l10n.planner_msg_meals,
      l10n.planner_msg_macros,
      l10n.planner_msg_grocery,
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: Text(
        msgs[_msgIdx],
        key: ValueKey(msgs[_msgIdx]),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: widget.color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SwapPreferencesSheet extends StatefulWidget {
  final Meal meal;
  final void Function(String swapIntent, String note) onSwap;

  const _SwapPreferencesSheet({required this.meal, required this.onSwap});

  @override
  State<_SwapPreferencesSheet> createState() => _SwapPreferencesSheetState();
}

class _SwapPreferencesSheetState extends State<_SwapPreferencesSheet> {
  final TextEditingController _cravingController = TextEditingController();
  String _selectedIntent = 'higher_protein';
  bool _showNote = false;

  @override
  void dispose() {
    _cravingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final Color sheetBg = context.cardColor;
    final Color borderColor = context.cardBorderColor;
    final Color headerTitleColor = context.textPrimaryColor;
    final Color subtitleColor = context.textSecondaryColor;
    final Color inputBg = context.cardSoftColor;
    final l10n = AppLocalizations.of(context)!;
    final intents = [
      ('lower_calorie', LucideIcons.flame, l10n.planner_swap_lower_calorie),
      (
        'higher_protein',
        LucideIcons.dumbbell,
        l10n.planner_swap_higher_protein,
      ),
      ('faster_prep', LucideIcons.clock3, l10n.planner_swap_faster_prep),
      ('cheaper', LucideIcons.wallet, l10n.planner_swap_cheaper),
    ];

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        36 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.refreshCw,
                    color: context.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.planner_swap_title,
                        style: AppTypography.heading3.copyWith(
                          color: headerTitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.planner_swap_replacing(widget.meal.foodName),
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              l10n.planner_swap_intent.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  intents.map((intent) {
                    final selected = _selectedIntent == intent.$1;
                    return InkWell(
                      onTap: () => setState(() => _selectedIntent = intent.$1),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? context.primaryColor.withValues(alpha: 0.15)
                                  : inputBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selected ? context.primaryColor : borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              intent.$2,
                              size: 16,
                              color:
                                  selected
                                      ? context.primaryColor
                                      : subtitleColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                intent.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color:
                                      selected
                                          ? context.primaryColor
                                          : subtitleColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _showNote = !_showNote),
              icon: Icon(
                _showNote ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
              ),
              label: Text(l10n.planner_swap_custom_note),
            ),
            if (_showNote) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _cravingController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.planner_swap_note_hint,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: context.textMutedColor,
                    ),
                    border: InputBorder.none,
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _cravingController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: Icon(LucideIcons.x, size: 16),
                          onPressed: () => _cravingController.clear(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)!.common_cancel,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _cravingController,
                    builder: (context, value, child) {
                      final hasCraving = value.text.trim().isNotEmpty;
                      final btnBg = context.primaryColor;
                      final btnFg = Colors.white;

                      return FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: btnBg,
                          foregroundColor: btnFg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSwap(
                            _selectedIntent,
                            _cravingController.text.trim(),
                          );
                        },
                        child: Text(
                          hasCraving
                              ? l10n.planner_swap_with_note
                              : l10n.planner_swap_generate,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

