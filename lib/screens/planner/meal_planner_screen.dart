import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/grocery_item.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_plan.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import 'meal_planner_setup.dart';
import 'meal_planner_widgets.dart';

final plannerNotifierProvider = ChangeNotifierProvider<PlannerProvider>((ref) {
  final settings =
      ref.read(settingsProvider).valueOrNull ?? UserSettings.defaults();
  final planner = PlannerProvider(AIService(), settings);
  ref.listen<AsyncValue<UserSettings>>(settingsProvider, (previous, next) {
    final updated = next.valueOrNull;
    if (updated == null || previous?.valueOrNull == updated) return;
    planner.updateSettings(updated);
  });
  return planner;
});

enum _PlannerTab { plan, grocery }

enum _GroceryFilter { all, needed, checked }

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  _PlannerTab _tab = _PlannerTab.plan;
  _GroceryFilter _groceryFilter = _GroceryFilter.all;
  int? _selectedDayIndex;
  bool _editingSetup = false;
  bool _shoppingMode = false;

  PlannerProvider get _planner => ref.read(plannerNotifierProvider);

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(proAccessProvider);
    final planner = ref.watch(plannerNotifierProvider);
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? UserSettings.defaults();

    ref.listen<PlannerProvider>(plannerNotifierProvider, (_, next) {
      final error = next.error;
      if (error == null || next.currentPlan == null) return;
      next.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    });

    if (access.isUnknown) {
      return AppPageScaffold(
        title: '',
        showHeader: false,
        padding: EdgeInsets.zero,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (access.isPro &&
        (_editingSetup ||
            (planner.currentPlan == null && !planner.isGenerating))) {
      return MealPlannerSetup(
        settings: settings,
        initialPrepTime: planner.prepTimePreference,
        initialBudget: planner.budgetPreference,
        editingExistingPlan: _editingSetup,
        onClose: () {
          if (_editingSetup && planner.currentPlan != null) {
            setState(() => _editingSetup = false);
          } else {
            context.pop();
          }
        },
        onGenerate: _savePreferencesAndGenerate,
      );
    }

    if (access.isPro && planner.isGenerating && planner.currentPlan == null) {
      return PlannerGeneratingScreen(onLeave: () => context.pop());
    }

    final plan =
        access.isPro
            ? planner.currentPlan!
            : _buildFreePreviewPlan(settings, context);
    final selectedIndex = _resolveSelectedIndex(plan, access.isPro);
    final meals = plan.weeklyMeals[selectedIndex] ?? const <Meal>[];

    return AppPageScaffold(
      title: '',
      showHeader: false,
      scrollable: false,
      padding: EdgeInsets.zero,
      backgroundColor: context.backgroundColor,
      bottomBar:
          _tab == _PlannerTab.plan
              ? PlannerBottomActions(
                isPro: access.isPro,
                onAdjust:
                    access.isPro
                        ? () => setState(() => _editingSetup = true)
                        : _openPaywall,
                onGrocery: () {
                  if (!access.isPro) {
                    _openPaywall();
                    return;
                  }
                  setState(() => _tab = _PlannerTab.grocery);
                },
              )
              : null,
      child: Column(
        children: [
          PlannerTopBar(
            groceryCount: planner.groceryList.length,
            isPro: access.isPro,
            onBack: () => context.pop(),
            onGrocery: () {
              if (!access.isPro) {
                _openPaywall();
                return;
              }
              setState(() => _tab = _PlannerTab.grocery);
            },
            onPreferences:
                access.isPro
                    ? () => setState(() => _editingSetup = true)
                    : _openPaywall,
            onRegenerate: access.isPro ? _confirmRegenerateWeek : _openPaywall,
          ),
          PlannerTabs(
            grocerySelected: _tab == _PlannerTab.grocery,
            onPlan: () => setState(() => _tab = _PlannerTab.plan),
            onGrocery: () {
              if (!access.isPro) {
                _openPaywall();
                return;
              }
              setState(() => _tab = _PlannerTab.grocery);
            },
          ),
          WeekNavigator(plan: plan),
          PlannerDayStrip(
            plan: plan,
            selectedIndex: selectedIndex,
            lockedAfterIndex: access.isPro ? null : 0,
            onSelected: (index) {
              if (!access.isPro && index > 0) {
                _openPaywall();
                return;
              }
              HapticFeedback.selectionClick();
              setState(() => _selectedDayIndex = index);
            },
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child:
                  _tab == _PlannerTab.plan
                      ? _buildPlanTab(
                        key: ValueKey('plan-$selectedIndex-${access.isPro}'),
                        plan: plan,
                        dayIndex: selectedIndex,
                        meals: meals,
                        settings: settings,
                        planner: planner,
                        isPro: access.isPro,
                      )
                      : _buildGroceryTab(
                        key: ValueKey(
                          'grocery-${_groceryFilter.name}-$_shoppingMode',
                        ),
                        planner: planner,
                      ),
            ),
          ),
          if (planner.isGenerating || planner.isRegenerating)
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  int _resolveSelectedIndex(MealPlan plan, bool isPro) {
    final requested = _selectedDayIndex;
    if (requested != null) return isPro ? requested.clamp(0, 6) : 0;
    final now = DateTime.now();
    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final index = today.difference(start).inDays;
    return isPro && index >= 0 && index <= 6 ? index : 0;
  }

  Widget _buildPlanTab({
    required Key key,
    required MealPlan plan,
    required int dayIndex,
    required List<Meal> meals,
    required UserSettings settings,
    required PlannerProvider planner,
    required bool isPro,
  }) {
    final date = plan.startDate.add(Duration(days: dayIndex));
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );

    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        if (!isPro)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlannerPreviewLabel(),
          ),
        PlannerDayHeading(
          date: date,
          mealCount: meals.length,
          calories: totalCalories,
          showRegenerate: isPro && planner.canRegenerate,
          onRegenerate: () => _confirmRegenerateDay(dayIndex),
        ),
        const SizedBox(height: 12),
        PlannerNutritionBand(
          meals: meals,
          calorieGoal: settings.dailyCalorieGoal,
          proteinGoal: settings.dailyProteinGoal,
          carbGoal: settings.dailyCarbGoal,
          fatGoal: settings.dailyFatGoal,
        ),
        const SizedBox(height: 20),
        PlannerSectionTitle(
          label: AppLocalizations.of(context)!.planner_today_plan,
        ),
        const SizedBox(height: 10),
        if (meals.isEmpty)
          PlannerEmptyMeals(onRegenerate: () => _confirmRegenerateDay(dayIndex))
        else
          ...List.generate(meals.length, (index) {
            final meal = meals[index];
            final isLogged = planner.loggedPlannedMealIds.contains(meal.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlannerMealRow(
                meal: meal,
                isNext: index == 0 && !isLogged,
                isLogged: isLogged,
                interactive: isPro,
                onOpen: () => _openMealDetails(meal, dayIndex, isPro),
                onLog: isLogged ? null : () => _logPlannedMeal(meal),
                onSwap:
                    isPro ? () => _showSwapSheet(meal, dayIndex) : _openPaywall,
              ),
            );
          }),
        if (!isPro) ...[
          const SizedBox(height: 6),
          PlannerLockedWeekCard(onUpgrade: _openPaywall),
        ],
        if (planner.fallbackNotice != null) ...[
          const SizedBox(height: 12),
          PlannerNotice(
            message: planner.fallbackNotice!,
            onDismiss: planner.clearFallbackNotice,
          ),
        ],
      ],
    );
  }

  Widget _buildGroceryTab({
    required Key key,
    required PlannerProvider planner,
  }) {
    final all = planner.groceryList;
    final visible = switch (_groceryFilter) {
      _GroceryFilter.all => all,
      _GroceryFilter.needed => all.where((item) => !item.isChecked).toList(),
      _GroceryFilter.checked => all.where((item) => item.isChecked).toList(),
    };
    final grouped = <String, List<GroceryItem>>{};
    for (final item in visible) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return GroceryPlannerView(
      key: key,
      items: all,
      groupedItems: grouped,
      selectedFilter: _groceryFilter.index,
      shoppingMode: _shoppingMode,
      onFilterChanged:
          (index) =>
              setState(() => _groceryFilter = _GroceryFilter.values[index]),
      onToggle: planner.toggleGroceryItem,
      onClearChecked: planner.removeCheckedGroceryItems,
      onShoppingMode: () {
        setState(() {
          _shoppingMode = !_shoppingMode;
          if (_shoppingMode) _groceryFilter = _GroceryFilter.needed;
        });
      },
      onShare:
          all.isEmpty
              ? null
              : () => SharePlus.instance.share(
                ShareParams(text: planner.getFormattedGroceryList()),
              ),
    );
  }

  Future<void> _savePreferencesAndGenerate(PlannerSetupResult result) async {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    await settingsNotifier.updatePlannerPreferences(
      mealsPerDay: result.mealsPerDay,
      dietaryRestriction: result.dietaryRestriction,
      cuisinePreference: result.cuisines.join(', '),
    );
    await settingsNotifier.updateCoachProfile(
      foodDislikes: result.foodsToAvoid,
      recalculateNutrition: false,
    );
    _planner.setPlanningPreferences(
      prepTimePreference: result.prepTime,
      budgetPreference: result.budget,
      planningNotes: [
        'Plan style: ${result.planStyle}',
        if (result.usePantry) 'reuse common pantry staples',
        if (result.planLeftovers) 'plan smart leftovers across meals',
        if (result.repeatBreakfasts) 'repeat easy breakfasts when useful',
        if (result.foodsToAvoid.isNotEmpty) 'avoid: ${result.foodsToAvoid}',
      ].join('; '),
    );
    if (!mounted) return;
    setState(() => _editingSetup = false);
    if (!ConnectivityService().hasInternetAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error_offline)),
      );
      return;
    }
    unawaited(_planner.generateWeeklyPlan());
  }

  Future<void> _logPlannedMeal(Meal meal) async {
    HapticFeedback.mediumImpact();
    final logged = meal.copyWith(scanSource: 'meal_planner');
    await ref.read(mealLogProvider.notifier).addMeal(logged);
    _planner.markPlannedMealLogged(meal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.result_save_success),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _openMealDetails(Meal meal, int dayIndex, bool isPro) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => PlannerMealDetailScreen(
              meal: meal,
              isPro: isPro,
              onLog: _logPlannedMeal,
              onSwap: () {
                if (!isPro) {
                  _openPaywall();
                  return;
                }
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _showSwapSheet(meal, dayIndex),
                );
              },
            ),
      ),
    );
  }

  Future<void> _showSwapSheet(Meal meal, int dayIndex) async {
    if (!ConnectivityService().hasInternetAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error_offline)),
      );
      return;
    }
    final result = await showModalBottomSheet<PlannerSwapResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlannerSwapSheet(meal: meal),
    );
    if (result == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PlannerWorkingDialog(
            label: AppLocalizations.of(context)!.planner_swap_loading,
          ),
    );
    await _planner.swapMeal(
      dayIndex,
      meal,
      craving: result.note,
      swapIntent: result.intent,
    );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final error = _planner.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? AppLocalizations.of(context)!.planner_swap_success,
        ),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
    if (error != null) _planner.clearError();
  }

  void _confirmRegenerateWeek() {
    _showRegenerateDialog(
      body: AppLocalizations.of(context)!.planner_setup_body,
      onConfirm: _planner.generateWeeklyPlan,
    );
  }

  void _confirmRegenerateDay(int dayIndex) {
    final plan = _planner.currentPlan;
    if (plan == null) return;
    final date = plan.startDate.add(Duration(days: dayIndex));
    _showRegenerateDialog(
      body: AppLocalizations.of(context)!.planner_regenerate_body(
        DateFormat.EEEE(AppLocalizations.of(context)!.localeName).format(date),
      ),
      onConfirm: () => _planner.regenerateDay(dayIndex),
    );
  }

  void _showRegenerateDialog({
    required String body,
    required Future<void> Function() onConfirm,
  }) {
    if (!ConnectivityService().hasInternetAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error_offline)),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.planner_regenerate),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.common_cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  unawaited(onConfirm());
                },
                child: Text(AppLocalizations.of(context)!.planner_regenerate),
              ),
            ],
          ),
    );
  }

  void _openPaywall() {
    PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.plannerLockedDay,
      featureName: 'meal_planner',
    );
  }
}

MealPlan _buildFreePreviewPlan(UserSettings settings, BuildContext context) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final language = AppLocalizations.of(context)!.localeName.split('_').first;
  final names = switch (language) {
    'ar' => ['شوفان بالتوت', 'وعاء دجاج وأرز', 'زبادي وفاكهة', 'سلمون وخضار'],
    'es' => [
      'Avena con frutos rojos',
      'Bowl de pollo y arroz',
      'Yogur y fruta',
      'Salmón con verduras',
    ],
    'fr' => [
      'Avoine aux fruits rouges',
      'Bol poulet et riz',
      'Yaourt et fruits',
      'Saumon aux légumes',
    ],
    _ => [
      'Berry overnight oats',
      'Grilled chicken rice bowl',
      'Yogurt and fresh fruit',
      'Salmon with vegetables',
    ],
  };
  final types = switch (language) {
    'ar' => ['الإفطار', 'الغداء', 'وجبة خفيفة', 'العشاء'],
    'es' => ['Desayuno', 'Almuerzo', 'Merienda', 'Cena'],
    'fr' => ['Petit-déjeuner', 'Déjeuner', 'Collation', 'Dîner'],
    _ => ['Breakfast', 'Lunch', 'Snack', 'Dinner'],
  };
  final ingredients = switch (language) {
    'ar' => ['حصة بروتين', 'كوب خضار', 'حصة حبوب كاملة', 'توابل حسب الرغبة'],
    'es' => [
      '1 porción de proteína',
      '1 taza de verduras',
      '1 porción de cereales integrales',
      'Condimentos al gusto',
    ],
    'fr' => [
      '1 portion de protéines',
      '1 tasse de légumes',
      '1 portion de céréales complètes',
      'Assaisonnement au goût',
    ],
    _ => [
      '1 serving protein',
      '1 cup vegetables',
      '1 serving whole grains',
      'Seasoning to taste',
    ],
  };
  final portion = switch (language) {
    'ar' => 'حصة واحدة',
    'es' => '1 porción',
    'fr' => '1 portion',
    _ => '1 serving',
  };
  final calories = [410, 610, 240, 590];
  final macros = [
    Macros(protein: 24, carbs: 56, fat: 11),
    Macros(protein: 46, carbs: 64, fat: 18),
    Macros(protein: 17, carbs: 29, fat: 6),
    Macros(protein: 43, carbs: 48, fat: 22),
  ];
  final prep = [8, 25, 3, 28];
  final meals = List.generate(4, (index) {
    final timestamp =
        start
            .add(Duration(hours: [8, 13, 16, 19][index]))
            .millisecondsSinceEpoch;
    return Meal(
      id: 'free-preview-$index',
      timestamp: timestamp,
      dateString: DateFormat('yyyy-MM-dd').format(start),
      foodName: names[index],
      calories: calories[index],
      macros: macros[index],
      mealType: types[index],
      prepTimeMins: prep[index],
      portion: portion,
      ingredients: ingredients,
      scanSource: 'meal_planner_preview',
    );
  });
  final weekly = <int, List<Meal>>{0: meals};
  for (var day = 1; day < 7; day++) {
    weekly[day] = const <Meal>[];
  }
  return MealPlan(
    id: 'free-preview',
    startDate: start,
    endDate: start.add(const Duration(days: 6)),
    weeklyMeals: weekly,
  );
}
