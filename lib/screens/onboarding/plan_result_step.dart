import 'package:flutter/material.dart';
import 'package:snapcal/widgets/app_icon.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_draft.dart';
import 'onboarding_components.dart';
import 'onboarding_pace_calculator.dart';

class PlanResultStep extends StatelessWidget {
  final OnboardingDraft draft;
  final VoidCallback onStart;
  final VoidCallback onAdjust;
  final bool completing;

  const PlanResultStep({
    super.key,
    required this.draft,
    required this.onStart,
    required this.onAdjust,
    this.completing = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recommendation = draft.recommendation;
    final goal = draft.goalType;
    final system = draft.measurementSystem;

    if (recommendation == null) {
      return const SizedBox.shrink();
    }

    final actualRate = recommendation.weeklyRateKg;
    final zeroProgress =
        actualRate <= 0.001 &&
        (goal == GoalType.loseWeight || goal == GoalType.buildMuscle);

    return Column(
      children: [
        const SizedBox(height: 8),
        StepTitle(
          title: l10n.onboarding_plan_title,
          body: l10n.onboarding_plan_explanation,
        ),
        const SizedBox(height: 20),
        CalorieHero(calories: recommendation.dailyCalories),
        const SizedBox(height: 16),
        // Goal summary
        if (goal != null) ...[
          _GoalSummaryRow(
            text: _goalSummaryText(
              l10n,
              goal,
              recommendation,
              system,
              zeroProgress,
            ),
            paceAdjusted: recommendation.paceAdjusted && !zeroProgress,
          ),
          const SizedBox(height: 12),
        ],
        // Macros as list rows
        MacroRow(
          label: l10n.onboarding_plan_protein,
          grams: recommendation.proteinGrams,
          color: AppColors.protein,
        ),
        const SizedBox(height: 8),
        MacroRow(
          label: l10n.onboarding_plan_carbs,
          grams: recommendation.carbGrams,
          color: AppColors.carbs,
        ),
        const SizedBox(height: 8),
        MacroRow(
          label: l10n.onboarding_plan_fat,
          grams: recommendation.fatGrams,
          color: AppColors.fat,
        ),
        // Adjusted detail or zero-progress explanation
        if (recommendation.paceAdjusted) ...[
          const SizedBox(height: 12),
          _SafetyNote(
            detail: _buildAdjustedDetail(
              l10n,
              context,
              goal,
              recommendation,
              system,
              zeroProgress,
            ),
          ),
        ],
        const SizedBox(height: 22),
        PrimaryButton(
          text: l10n.onboarding_plan_start,
          loading: completing,
          onTap: completing ? null : onStart,
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          text: l10n.onboarding_plan_adjust,
          onTap: completing ? null : onAdjust,
        ),
      ],
    );
  }

  String _goalSummaryText(
    AppLocalizations l10n,
    GoalType goal,
    OnboardingRecommendation rec,
    MeasurementSystem system,
    bool zeroProgress,
  ) {
    if (zeroProgress) {
      return l10n.onboarding_plan_maintenance_estimate;
    }

    final rate = OnboardingPaceCalculator.formatWeeklyRateValue(
      rec.weeklyRateKg,
      system,
    );
    final unit = OnboardingPaceCalculator.weeklyRateUnit(system);

    switch (goal) {
      case GoalType.loseWeight:
        return l10n.onboarding_goal_summary_lose(rate, unit);
      case GoalType.maintainWeight:
        return l10n.onboarding_goal_summary_maintain;
      case GoalType.buildMuscle:
        return l10n.onboarding_goal_summary_build(rate, unit);
      case GoalType.trackNutrition:
        return l10n.onboarding_goal_summary_track;
    }
  }

  Widget _buildAdjustedDetail(
    AppLocalizations l10n,
    BuildContext context,
    GoalType? goal,
    OnboardingRecommendation rec,
    MeasurementSystem system,
    bool zeroProgress,
  ) {
    if (zeroProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal == GoalType.loseWeight
                ? l10n.onboarding_safety_zero_loss
                : l10n.onboarding_safety_zero_gain,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    // Calculate original selected pace
    final needsPace =
        goal == GoalType.loseWeight || goal == GoalType.buildMuscle;
    String originalRate;
    String actualRate;
    String unit;

    if (needsPace && draft.pace != null && goal != null) {
      final originalKg = OnboardingPaceCalculator.weeklyRateKgFor(
        goal,
        draft.pace!,
      );
      originalRate = OnboardingPaceCalculator.formatWeeklyRateValue(
        originalKg,
        system,
      );
      actualRate = OnboardingPaceCalculator.formatWeeklyRateValue(
        rec.weeklyRateKg,
        system,
      );
      unit = OnboardingPaceCalculator.weeklyRateUnit(system);

      // Recalculate goal date from actual rate
      if (rec.weeklyRateKg > 0 &&
          draft.currentWeightKg != null &&
          draft.targetWeightKg != null) {
        final date = OnboardingPaceCalculator.estimatedTargetDate(
          draft.currentWeightKg!,
          draft.targetWeightKg!,
          rec.weeklyRateKg,
        );
        final formatted = DateFormat.yMMMMd().format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.onboarding_safety_adjusted_detail(
                originalRate,
                unit,
                actualRate,
              ),
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  AppSymbols.calendar,
                  size: 14,
                  color: context.textMutedColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.onboarding_safety_updated_goal(formatted),
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
      }

      return Text(
        l10n.onboarding_safety_adjusted_detail(originalRate, unit, actualRate),
        style: TextStyle(
          color: context.textPrimaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      );
    }

    // Fallback
    return Text(
      l10n.onboarding_safety_adjusted_fallback,
      style: TextStyle(
        color: context.textPrimaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }
}

class _GoalSummaryRow extends StatelessWidget {
  final String text;
  final bool paceAdjusted;

  const _GoalSummaryRow({required this.text, required this.paceAdjusted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? context.primaryColor.withValues(alpha: 0.09)
                : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(
              alpha: context.isDarkMode ? 0.12 : 0.07,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(AppSymbols.flag, size: 16, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (paceAdjusted)
            Container(
              constraints: const BoxConstraints(maxWidth: 112),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context)!.onboarding_adjusted_badge,
                style: TextStyle(
                  color: context.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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

class _SafetyNote extends StatelessWidget {
  final Widget detail;

  const _SafetyNote({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppSymbols.info, size: 16, color: AppColors.warningAmber),
          const SizedBox(width: 8),
          Expanded(child: detail),
        ],
      ),
    );
  }
}
