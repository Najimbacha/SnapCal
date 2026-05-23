import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../core/theme/app_typography.dart';
import '../providers/assistant_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/metrics_provider.dart';
import '../providers/settings_provider.dart';

class OptimizePlanButton extends StatefulWidget {
  const OptimizePlanButton({super.key});

  @override
  State<OptimizePlanButton> createState() => _OptimizePlanButtonState();
}

class _OptimizePlanButtonState extends State<OptimizePlanButton> {
  bool _isLoading = false;

  Future<void> _recalculate() async {
    final metricsProvider = context.read<MetricsProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final currentWeight = metricsProvider.currentWeight;

    if (currentWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.settings_log_weight_first,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await settingsProvider.recalculatePlan(
      currentWeightKg: currentWeight,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      // Navigate to Assistant to explain the new plan
      context.push('/assistant');
      context.read<AssistantProvider>().fetchRecommendations(
        currentCalories: context.read<MealProvider>().todaysTotalCalories,
        targetCalories: context.read<SettingsProvider>().dailyCalorieGoal,
        currentMacros: {
          'protein': context.read<MealProvider>().todaysTotalMacros.protein,
          'carbs': context.read<MealProvider>().todaysTotalMacros.carbs,
          'fat': context.read<MealProvider>().todaysTotalMacros.fat,
        },
        targetMacros: {
          'protein': context.read<SettingsProvider>().dailyProteinGoal,
          'carbs': context.read<SettingsProvider>().dailyCarbGoal,
          'fat': context.read<SettingsProvider>().dailyFatGoal,
        },
        mealNames:
            context
                .read<MealProvider>()
                .recentMeals
                .map((m) => m.foodName)
                .toList(),
        dietaryRestriction: context.read<SettingsProvider>().dietaryRestriction,
        userQuery: AppLocalizations.of(context)!.settings_recalculate_query,
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.settings_complete_profile_first,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A3D2B),
            Color(0xFF2C6B4E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3D2B).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _recalculate,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                : const Icon(LucideIcons.sparkles, size: 20, color: Color(0xFF86EFAC)),
        label: Text(
          _isLoading
              ? AppLocalizations.of(context)!.settings_optimizing
              : AppLocalizations.of(context)!.settings_optimize_btn,
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
