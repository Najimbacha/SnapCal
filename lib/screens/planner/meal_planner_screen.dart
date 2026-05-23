import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_plan.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/optimize_plan_button.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/day_summary_bar.dart';
import 'widgets/meal_card.dart';
import 'widgets/meal_preferences_sheet.dart';

const _plannerInk = Color(0xFF1C1917);
const _plannerMuted = Color(0xFFA8A29E);
const _plannerLine = Color(0xFFE8E4DC);
const _plannerGreen = Color(0xFF1A3D2B);
const _plannerGreenText = Color(0xFF16733A);
const _plannerBg = Color(0xFFF9F8F5);

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDay = 0;
  int _activeTab = 0; // 0 = Weekly Plan, 1 = Grocery List
  late final AnimationController _animController;
  final List<Animation<double>> _itemAnims = [];

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
        return '${labels[i]} ${date.day}';
      });
    }
    return labels;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < 8; i++) {
      _itemAnims.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1, (i * 0.1) + 0.4, curve: Curves.easeOutQuart),
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
    final l10n = AppLocalizations.of(context)!;

    return AppPageScaffold(
      title: l10n.planner_smart_title,
      subtitle: null,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF14130F)
              : _plannerBg,
      headerDecoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14130F)
                : _plannerBg,
      ),
      trailing: _buildTrailingActions(context),
      child: Consumer2<PlannerProvider, SettingsProvider>(
        builder: (context, planner, settings, _) {
          // 1. Generating state
          if (planner.isGenerating && planner.currentPlan == null) {
            return _buildGeneratingState();
          }

          // 2. Error state
          if (planner.error != null && planner.currentPlan == null) {
            return _buildErrorState(planner);
          }

          // 3. Empty state
          if (planner.currentPlan == null) return _buildEmptyState(settings);

          // 4. Plan exists
          return AppAsyncOverlay(
            state: planner.uiState,
            child: _buildPlanView(planner, settings),
          );
        },
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (planner.currentPlan == null || planner.isGenerating) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_activeTab == 0 && settings.isPro && planner.canRegenerate)
          _ScaleTap(
            onTap: () => _confirmRegenerate(context, planner),
            child: _PlannerHeaderButton(
              icon: LucideIcons.refreshCw,
              isDark: isDark,
            ),
          ),
        const SizedBox(width: 8),
        _ScaleTap(
          onTap: () => _showPreferences(context),
          child: _PlannerHeaderButton(
            icon: LucideIcons.slidersHorizontal,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _plannerInk;
    final muted = isDark ? Colors.white54 : _plannerMuted;

    return Stack(
      children: [
        // Immersive blurred background
        Positioned.fill(
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulse animation container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _plannerGreen.withValues(
                        alpha: 0.05 + (0.05 * math.sin(value * math.pi)),
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _plannerGreen.withValues(
                            alpha: 0.1 * math.sin(value * math.pi),
                          ),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _plannerGreen,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                AppLocalizations.of(context)!.planner_creating,
                style: AppTypography.heading3.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              _GeneratingMessages(color: muted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(PlannerProvider planner) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: AppEmptyState(
        icon: LucideIcons.alertTriangle,
        title: l10n.error_generic,
        body: planner.error ?? l10n.error_generic,
        actionLabel: l10n.common_try_again,
        onAction: () => planner.generateWeeklyPlan(),
      ),
    );
  }

  Widget _buildEmptyState(SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _plannerInk;
    final muted = isDark ? Colors.white54 : const Color(0xFF78716C);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFEFF8EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarDays,
                color: _plannerGreenText,
                size: 34,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.planner_title,
              style: AppTypography.displaySmall.copyWith(
                color: ink,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.planner_setup_body,
              style: AppTypography.bodyMedium.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
                height: 1.35,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => _showPreferences(context),
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: Text(l10n.planner_generate),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _plannerGreen,
                foregroundColor: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanView(PlannerProvider planner, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fallback notice: shown when AI failed and a standard plan was used
        if (planner.fallbackNotice != null)
          _FallbackNoticeBanner(
            onDismiss: planner.clearFallbackNotice,
            isDark: isDark,
          ),
        _PlannerOverviewHeader(planner: planner, settings: settings),
        const SizedBox(height: 14),
        const OptimizePlanButton(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF0EEE9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : _plannerLine,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: AppLocalizations.of(context)!.planner_tab_weekly,
                  selected: _activeTab == 0,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _activeTab = 0);
                  },
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _TabButton(
                  label: AppLocalizations.of(context)!.planner_tab_grocery,
                  selected: _activeTab == 1,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _activeTab = 1);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_activeTab == 0) ...[
          // Day tabs
          _buildDayTabs(),
          const SizedBox(height: 12),
          // Meals for selected day
          Expanded(child: _buildDayMeals(planner, settings)),
        ] else ...[
          Expanded(child: _buildGroceryTab(planner, settings)),
        ],
      ],
    );
  }

  // ========================
  //  DAY TABS
  // ========================
  Widget _buildDayTabs() {
    return _staggeredSlide(
      _itemAnims[1],
      SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _selectedDay == index;
              final plan = context.read<PlannerProvider>().currentPlan;
              return _ScaleTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDay = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? _plannerGreen
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected
                              ? _plannerGreen
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : _plannerLine,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getDayLabels(context, plan: plan)[index],
                      style: AppTypography.labelLarge.copyWith(
                        color:
                            isSelected
                                ? Colors.white
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white54
                                    : const Color(0xFF78716C),
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    );
  }

  // ========================
  //  DAY MEALS
  // ========================
  Widget _buildDayMeals(PlannerProvider planner, SettingsProvider settings) {
    final meals = planner.currentPlan?.weeklyMeals[_selectedDay] ?? [];
    final isPro = settings.isPro;
    final isLocked = !isPro && _selectedDay >= 2;

    if (meals.isEmpty && !isLocked) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.utensils,
          title: AppLocalizations.of(
            context,
          )!.planner_no_meals(_getDayLabels(context)[_selectedDay]),
          body: AppLocalizations.of(context)!.planner_no_meals_body,
        ),
      );
    }

    final totalCalories = meals.fold<int>(0, (sum, m) => sum + m.calories);

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final startDelay = ((index + 2) % 10) * 0.1;
            final endDelay = (startDelay + 0.4).clamp(0.0, 1.0);

            final anim = CurvedAnimation(
              parent: _animController,
              curve: Interval(startDelay, endDelay, curve: Curves.easeOutQuart),
            );

            return _staggeredSlide(
              anim,
              MealCard(
                meal: meals[index],
                isLocked: isLocked,
                onLogMeal:
                    isLocked ? null : () => _logPlannedMeal(meals[index]),
              ),
            );
          },
        ),
        // Blur overlay for locked days
        if (isLocked) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          Center(
            child: AppSectionCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.crown,
                    color: AppColors.warning,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.planner_unlock_week,
                    style: AppTypography.heading3,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.planner_free_limit_body,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed:
                        () => _showPaywall(
                          context,
                          PaywallEntryPoint.plannerLockedDay,
                        ),
                    child: Text(
                      AppLocalizations.of(context)!.planner_upgrade_pro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Regenerating overlay
        if (planner.isRegenerating)
          Positioned.fill(
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        // Bottom summary bar (only for unlocked days)
        if (!isLocked)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _staggeredSlide(
              _itemAnims[4],
              DaySummaryBar(
                totalCalories: totalCalories,
                targetCalories: settings.dailyCalorieGoal,
              ),
            ),
          ),
      ],
    );
  }

  // ========================
  //  GROCERY TAB
  // ========================
  Widget _buildGroceryTab(PlannerProvider provider, SettingsProvider settings) {
    // Pro gate FIRST — free users see upgrade prompt, not empty state
    if (!settings.isPro) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.crown,
          title: AppLocalizations.of(context)!.planner_grocery_pro,
          body: AppLocalizations.of(context)!.planner_grocery_pro_body,
          actionLabel: AppLocalizations.of(context)!.planner_upgrade_pro,
          onAction: () => _showPaywall(context, PaywallEntryPoint.groceryList),
        ),
      );
    }

    if (provider.groceryList.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.shoppingBag,
          title: AppLocalizations.of(context)!.planner_grocery_empty,
          body: AppLocalizations.of(context)!.planner_grocery_empty_body,
        ),
      );
    }

    final grouped = <String, List<dynamic>>{};
    for (final item in provider.groceryList) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
          children:
              grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: AppTypography.labelMedium.copyWith(
                          color: _plannerGreenText,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    ...entry.value.map((item) {
                      return _GroceryItemTile(
                        item: item,
                        onToggle: () => provider.toggleGroceryItem(item.id),
                      );
                    }),
                  ],
                );
              }).toList(),
        ),
        Positioned(
          right: 0,
          bottom: 8,
          child: FloatingActionButton.extended(
            onPressed: () {
              final text = provider.getFormattedGroceryList();
              if (text.isNotEmpty) {
                // ignore: deprecated_member_use
                Share.share(text);
              }
            },
            icon: const Icon(LucideIcons.share2, size: 18),
            label: Text(AppLocalizations.of(context)!.planner_share),
            backgroundColor: _plannerGreen,
            foregroundColor: const Color(0xFFF0FDF4),
          ),
        ),
      ],
    );
  }

  // ========================
  //  ACTIONS
  // ========================
  void _showPreferences(BuildContext context) {
    final isPro = context.read<SettingsProvider>().isPro;
    if (!isPro) {
      _showPaywall(context, PaywallEntryPoint.plannerPreferences);
      return;
    }

    final hasPlan = context.read<PlannerProvider>().currentPlan != null;
    if (hasPlan) {
      _showOverwriteDialogThenPreferences(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => MealPreferencesSheet(
            onGenerate:
                () => context.read<PlannerProvider>().generateWeeklyPlan(),
          ),
    );
  }

  Future<void> _showOverwriteDialogThenPreferences(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final plannerProvider = context.read<PlannerProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.planner_regenerate),
        content: Text(
          l10n.planner_regenerate_body(l10n.planner_day_mon).replaceAll(
            l10n.planner_day_mon,
            l10n.planner_smart_title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.planner_generate),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showModalBottomSheet(
        context: navigator.context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MealPreferencesSheet(
          onGenerate: () => plannerProvider.generateWeeklyPlan(),
        ),
      );
    }
  }



  void _showPaywall(BuildContext context, PaywallEntryPoint entryPoint) {
    PremiumConversionService().openPaywall(
      context,
      entryPoint,
      featureName: 'planner',
    );
  }

  Future<void> _logPlannedMeal(Meal meal) async {
    HapticFeedback.mediumImpact();
    final mealProvider = context.read<MealProvider>();
    final settings = context.read<SettingsProvider>();
    await mealProvider.addMeal(
      foodName: meal.foodName,
      calories: meal.calories,
      protein: meal.macros.protein,
      carbs: meal.macros.carbs,
      fat: meal.macros.fat,
      portion: meal.portion,
      settings: settings,
      scanSource: 'meal_planner',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.assistant_added_to_diary),
      ),
    );
  }

  void _confirmRegenerate(BuildContext context, PlannerProvider planner) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              AppLocalizations.of(
                context,
              )!.planner_regenerate_day(_getDayLabels(context)[_selectedDay]),
            ),
            content: Text(
              AppLocalizations.of(
                context,
              )!.planner_regenerate_body(_getDayLabels(context)[_selectedDay]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.common_cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  planner.regenerateDay(_selectedDay);
                },
                child: Text(AppLocalizations.of(context)!.planner_regenerate),
              ),
            ],
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
          offset: Offset(0, 15 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}

class _FallbackNoticeBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final bool isDark;

  const _FallbackNoticeBanner({
    required this.onDismiss,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A1F0A)
            : const Color(0xFFFEF9EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7C5A10)
              : const Color(0xFFE8C96A),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.info,
            size: 16,
            color: Color(0xFFB48A0F),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.planner_ai_disclaimer,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? const Color(0xFFD4A830)
                    : const Color(0xFF7C5A10),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              LucideIcons.x,
              size: 16,
              color: isDark
                  ? const Color(0xFFD4A830)
                  : const Color(0xFF7C5A10),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerHeaderButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;

  const _PlannerHeaderButton({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFF0EEE9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : _plannerLine,
        ),
      ),
      child: Icon(icon, size: 17, color: isDark ? Colors.white70 : _plannerInk),
    );
  }
}

class _PlannerOverviewHeader extends StatelessWidget {
  final PlannerProvider planner;
  final SettingsProvider settings;

  const _PlannerOverviewHeader({
    required this.planner,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _plannerInk;
    final muted = isDark ? Colors.white54 : const Color(0xFF78716C);
    final meals =
        planner.currentPlan?.weeklyMeals.values
            .expand((dayMeals) => dayMeals)
            .toList() ??
        [];
    final totalCalories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final dailyAverage = meals.isEmpty ? 0 : (totalCalories / 7).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFD8ECDD),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.planner_title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _plannerGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${settings.mealsPerDay} meals/day',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFFF0FDF4),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${settings.dietaryRestriction} - ${settings.cuisinePreference}',
            style: AppTypography.bodySmall.copyWith(
              color: muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PlannerHeaderStat(
                  label: l10n.planner_daily_goal,
                  value: '${settings.dailyCalorieGoal}',
                  unit: 'kcal',
                  ink: ink,
                  muted: muted,
                ),
              ),
              Expanded(
                child: _PlannerHeaderStat(
                  label: 'Avg plan',
                  value: '$dailyAverage',
                  unit: 'kcal',
                  ink: ink,
                  muted: muted,
                ),
              ),
              Expanded(
                child: _PlannerHeaderStat(
                  label: l10n.planner_tab_grocery,
                  value: '${planner.groceryList.length}',
                  unit: 'items',
                  ink: ink,
                  muted: muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlannerHeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color ink;
  final Color muted;

  const _PlannerHeaderStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.ink,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTypography.titleLarge.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: AppTypography.labelSmall.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
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
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _GroceryItemTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onToggle;

  const _GroceryItemTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isChecked = item.isChecked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color:
                isChecked
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                    : colorScheme.surface.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Custom Animated Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isChecked ? _plannerGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isChecked
                            ? _plannerGreen
                            : colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child:
                    isChecked
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                        color:
                            isChecked
                                ? context.textMutedColor
                                : context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      item.amount,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textMutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================
//  SUPPORT WIDGETS
// ========================
class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _plannerGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color:
                  selected
                      ? Colors.white
                      : isDark
                          ? Colors.white54
                          : const Color(0xFF78716C),
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
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
  int _index = 0;
  List<String> _getMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.planner_msg_calories,
      l10n.planner_msg_meals,
      l10n.planner_msg_macros,
      l10n.planner_msg_grocery,
      l10n.planner_msg_ready,
    ];
  }

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        HapticFeedback.selectionClick();
        setState(() => _index = (_index + 1) % 5);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        _getMessages(context)[_index],
        key: ValueKey(_index),
        style: AppTypography.bodyMedium.copyWith(
          color: widget.color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
