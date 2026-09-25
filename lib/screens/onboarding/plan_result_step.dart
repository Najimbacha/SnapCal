import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_body.dart';
import 'onboarding_draft.dart';
import 'onboarding_kit.dart';
import 'onboarding_units.dart';

/// The plan: the day's calories, the macros as shares of them, and a few
/// plain facts. Everything shown is what gets saved.
class PlanResultStep extends StatelessWidget {
  const PlanResultStep({super.key, required this.draft, this.today});

  final OnboardingDraft draft;

  /// For tests; defaults to now.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = draft.recommendation;
    if (plan == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toString();
    final numbers = NumberFormat.decimalPattern(locale);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final system = draft.weightSystem;
    final calories = plan.dailyCalories;
    final hasTarget = draft.needsPaceStep && draft.targetWeightKg != null;
    final minor = isMinorAge(draft.age ?? 30);

    int share(int grams, int kcalPerGram) =>
        calories <= 0 ? 0 : (grams * kcalPerGram / calories * 100).round();

    final maintenance = (plan.tdee / 10).round() * 10;
    final diff = calories - maintenance;
    final days =
        hasTarget
            ? daysToTarget(
              currentKg: draft.currentWeightKg!,
              targetKg: draft.targetWeightKg!,
              weeklyRateKg: plan.weeklyRateKg,
            )
            : null;
    final finish =
        days == null ? null : dateAfterDays(today ?? DateTime.now(), days);

    final facts = <(String, String)>[
      (
        l10n.onb_plan_maintenance,
        l10n.onb_plan_kcal(numbers.format(maintenance)),
      ),
      (
        l10n.onb_plan_this_plan,
        diff == 0
            ? l10n.onb_plan_matches
            : (diff < 0
                ? l10n.onb_plan_below(numbers.format(diff.abs()))
                : l10n.onb_plan_above(numbers.format(diff))),
      ),
      if (finish != null)
        (
          l10n.onb_plan_reach(
            formatWeight(l10n, draft.targetWeightKg!, system),
          ),
          DateFormat.yMMMd(locale).format(finish),
        )
      else if (!hasTarget)
        (
          l10n.onb_plan_stay,
          formatWeight(l10n, draft.currentWeightKg ?? 0, system),
        ),
    ];

    final note =
        plan.safetyNote.isNotEmpty
            ? (plan.safetyNote, OnbTone.warn)
            : (minor ? (l10n.onb_plan_teen, OnbTone.neutral) : null);

    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (draft.goalType == GoalType.trackNutrition
                    ? l10n.onb_plan_daily_guide
                    : l10n.onb_plan_daily_target)
                .toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0.6, end: 1),
            duration: Duration(milliseconds: reduceMotion ? 0 : 700),
            curve: Curves.easeOutCubic,
            builder:
                (context, t, _) => Text(
                  numbers.format((calories * t).round()),
                  key: const ValueKey('onboarding-plan-calories'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 68,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -2.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.onb_plan_calories_a_day,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondaryColor, fontSize: 15),
          ),
          const SizedBox(height: 22),
          OnbCard(
            child: Column(
              children: [
                _MacroRow(
                  label: l10n.onboarding_plan_protein,
                  grams: plan.proteinGrams,
                  percent: share(plan.proteinGrams, 4),
                  color: AppColors.protein,
                  animate: !reduceMotion,
                ),
                const SizedBox(height: 14),
                _MacroRow(
                  label: l10n.onboarding_plan_carbs,
                  grams: plan.carbGrams,
                  percent: share(plan.carbGrams, 4),
                  color: AppColors.carbs,
                  animate: !reduceMotion,
                ),
                const SizedBox(height: 14),
                _MacroRow(
                  label: l10n.onboarding_plan_fat,
                  grams: plan.fatGrams,
                  percent: share(plan.fatGrams, 9),
                  color: AppColors.fat,
                  animate: !reduceMotion,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OnbCard(
            child: Column(
              children: [
                for (var i = 0; i < facts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          facts[i].$1,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        facts[i].$2,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            OnbNote(text: note.$1, tone: note.$2),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.onb_plan_change_later,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textMutedColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
    required this.animate,
  });

  final String label;
  final int grams;
  final int percent;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: context.onbFill)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: animate ? 0 : 1, end: 1),
                    duration: Duration(milliseconds: animate ? 600 : 0),
                    curve: Curves.easeOutCubic,
                    builder:
                        (context, t, _) => FractionallySizedBox(
                          heightFactor: 1,
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: (percent / 100 * t).clamp(0.0, 1.0),
                          child: ColoredBox(color: color),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 84,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: AppLocalizations.of(
                    context,
                  )!.onboarding_plan_grams(grams),
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $percent%',
                  style: TextStyle(color: context.textMutedColor, fontSize: 12),
                ),
              ],
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
