import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/planner_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/day_summary_bar.dart';
import 'widgets/meal_card.dart';
import 'widgets/meal_preferences_sheet.dart';

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

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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


    return AppPageScaffold(
      title: 'Smart Planner',
      subtitle: null,
      trailing: _buildTrailingActions(context),
      child: Consumer2<PlannerProvider, SettingsProvider>(
        builder: (context, planner, settings, _) {
          // 1. Generating state
          if (planner.isGenerating) return _buildGeneratingState();

          // 2. Error state
          if (planner.error != null) return _buildErrorState(planner);

          // 3. Empty state
          if (planner.currentPlan == null) return _buildEmptyState(settings);

          // 4. Plan exists
          return _buildPlanView(planner, settings);
        },
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (planner.currentPlan == null || planner.isGenerating) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_activeTab == 0 && settings.isPro && planner.canRegenerate)
          _ScaleTap(
            onTap: () => _confirmRegenerate(context, planner),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.refreshCw, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Regen', style: AppTypography.labelLarge.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),
        _ScaleTap(
          onTap: () => _showPreferences(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text('New', style: AppTypography.labelLarge.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Creating your plan',
            style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _GeneratingMessages(),
        ],
      ),
    );
  }

  Widget _buildErrorState(PlannerProvider planner) {
    return Center(
      child: AppEmptyState(
        icon: LucideIcons.alertTriangle,
        title: 'Planning error',
        body: planner.error ?? 'Something went wrong while building your plan.',
        actionLabel: 'Try Again',
        onAction: () => planner.generateWeeklyPlan(),
      ),
    );
  }

  Widget _buildEmptyState(SettingsProvider settings) {
    return Center(
      child: AppEmptyState(
        icon: LucideIcons.sparkles,
        title: 'Your personalized plan',
        body: 'Tell us your goals and we\'ll build a custom 7-day meal plan for you.',
        actionLabel: 'Generate Plan',
        onAction: () => _showPreferences(context),
      ),
    );
  }

  Widget _buildPlanView(PlannerProvider planner, SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Tab bar (Weekly plan / Grocery)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _TabButton(
                label: 'Weekly Plan',
                selected: _activeTab == 0,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _activeTab = 0);
                },
              ),
              const SizedBox(width: 4),
              _TabButton(
                label: 'Grocery List',
                selected: _activeTab == 1,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _activeTab = 1);
                },
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
          Expanded(
            child: _buildDayMeals(planner, settings),
          ),
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
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isSelected = _selectedDay == index;
            return _ScaleTap(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDay = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _dayLabels[index],
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected ? Colors.white : context.textSecondaryColor,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
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

    if (meals.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.utensils,
          title: 'No meals for ${_dayLabels[_selectedDay]}',
          body: 'Try regenerating this day.',
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
            final anim = CurvedAnimation(
              parent: _animController,
              curve: Interval(
                ((index + 2) % 10) * 0.1, 
                (((index + 2) % 10) * 0.1) + 0.4, 
                curve: Curves.easeOutQuart
              ),
            );

            return _staggeredSlide(
              anim,
              MealCard(meal: meals[index], isLocked: isLocked),
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
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
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
                  const Icon(LucideIcons.crown, color: AppColors.warning, size: 36),
                  const SizedBox(height: 12),
                  Text('Unlock full week', style: AppTypography.heading3),
                  const SizedBox(height: 6),
                  Text(
                    'Free users can view Mon & Tue only.',
                    style: AppTypography.bodySmall.copyWith(color: context.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _showPaywall(context),
                    child: const Text('Upgrade to Pro'),
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
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        // Bottom summary bar (only for unlocked days)
        if (!isLocked)
          Positioned(
            left: 0, right: 0, bottom: 0,
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
    if (provider.groceryList.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.shoppingBag,
          title: 'No grocery list yet',
          body: 'Generate a weekly plan first and your grocery list will appear here.',
        ),
      );
    }

    if (!settings.isPro) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.crown,
          title: 'Grocery list is Pro',
          body: 'Upgrade to view and manage your weekly grocery list.',
          actionLabel: 'Upgrade to Pro',
          onAction: () => _showPaywall(context),
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
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w900,
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
          right: 0, bottom: 8,
          child: FloatingActionButton.extended(
            onPressed: () {
              final text = provider.getFormattedGroceryList();
              if (text.isNotEmpty) {
                // ignore: deprecated_member_use
                Share.share(text);
              }
            },
            icon: const Icon(LucideIcons.share2, size: 18),
            label: const Text('Share'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ========================
  //  ACTIONS
  // ========================
  void _showPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealPreferencesSheet(
        onGenerate: () => context.read<PlannerProvider>().generateWeeklyPlan(),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    context.push('/paywall');
  }

  void _confirmRegenerate(BuildContext context, PlannerProvider planner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Regenerate ${_dayLabels[_selectedDay]}?'),
        content: Text(
          'This will replace ${_dayLabels[_selectedDay]}\'s meals with fresh options. '
          '${planner.canRegenerate ? '' : 'You\'ve used all 3 regenerations this week.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              planner.regenerateDay(_selectedDay);
            },
            child: const Text('Regenerate'),
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

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
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
            color: isChecked 
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
                  color: isChecked ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isChecked ? AppColors.primary : colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: isChecked
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
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? context.textMutedColor : context.textPrimaryColor,
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
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: selected ? Colors.white : context.textSecondaryColor,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratingMessages extends StatefulWidget {
  @override
  State<_GeneratingMessages> createState() => _GeneratingMessagesState();
}

class _GeneratingMessagesState extends State<_GeneratingMessages> {
  int _index = 0;
  static const _messages = [
    'Calculating your calorie needs...',
    'Picking the best meals for your goal...',
    'Balancing your macros...',
    'Building your grocery list...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  void _cycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _index = (_index + 1) % _messages.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        _messages[_index],
        key: ValueKey(_index),
        style: AppTypography.bodyMedium.copyWith(color: context.textSecondaryColor),
      ),
    );
  }
}
