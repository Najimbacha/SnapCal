import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:snapcal/widgets/app_icon.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_draft.dart';
import 'onboarding_pace_calculator.dart';
import 'onboarding_ui.dart';

/// The plan: a ring for the day's calories, the macros as shares of it, and
/// when the goal will be reached.
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
    if (recommendation == null) return const SizedBox.shrink();

    final goal = draft.goalType;
    final system = draft.measurementSystem;
    final reduceMotion = AppMotion.reduceMotion(context);
    final locale = Localizations.localeOf(context).toString();
    final zeroProgress =
        recommendation.weeklyRateKg <= 0.001 &&
        (goal == GoalType.loseWeight || goal == GoalType.buildMuscle);
    final calories = recommendation.dailyCalories;

    int share(int grams, int kcalPerGram) =>
        calories <= 0 ? 0 : (grams * kcalPerGram / calories * 100).round();

    final reachDate = _reachDate(recommendation, zeroProgress);

    Widget enter(Widget child, int delayMs) {
      if (reduceMotion) return child;
      return child
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 450.ms, curve: AppMotion.entranceCurve)
          .slideY(
            begin: 0.08,
            end: 0,
            duration: 450.ms,
            curve: AppMotion.entranceCurve,
          );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        _Medallion(reduceMotion: reduceMotion),
        const SizedBox(height: 14),
        enter(
          Text(
            l10n.onboarding_plan_title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          80,
        ),
        const SizedBox(height: 6),
        enter(
          Text(
            l10n.onboarding_plan_explanation,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          120,
        ),
        const SizedBox(height: 24),
        enter(
          _CalorieRing(
            calories: calories,
            label: l10n.onboarding_plan_kcal_day,
            locale: locale,
            animate: !reduceMotion,
          ),
          160,
        ),
        const SizedBox(height: 24),
        enter(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MacroTile(
                    label: l10n.onboarding_plan_protein,
                    grams: recommendation.proteinGrams,
                    percent: share(recommendation.proteinGrams, 4),
                    color: AppColors.protein,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroTile(
                    label: l10n.onboarding_plan_carbs,
                    grams: recommendation.carbGrams,
                    percent: share(recommendation.carbGrams, 4),
                    color: AppColors.carbs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroTile(
                    label: l10n.onboarding_plan_fat,
                    grams: recommendation.fatGrams,
                    percent: share(recommendation.fatGrams, 9),
                    color: AppColors.fat,
                  ),
                ),
              ],
            ),
          ),
          240,
        ),
        if (goal != null) ...[
          const SizedBox(height: 12),
          enter(
            _GoalCard(
              summary: _goalSummaryText(
                l10n,
                goal,
                recommendation,
                system,
                zeroProgress,
              ),
              reachLine:
                  reachDate == null
                      ? null
                      : l10n.onboarding_result_reach_by(
                        DateFormat.yMMMd(locale).format(reachDate),
                      ),
              adjustedLabel:
                  recommendation.paceAdjusted && !zeroProgress
                      ? l10n.onboarding_adjusted_badge
                      : null,
            ),
            300,
          ),
        ],
        if (recommendation.paceAdjusted) ...[
          const SizedBox(height: 12),
          _SafetyNote(
            text: _adjustedDetail(
              l10n,
              goal,
              recommendation,
              system,
              zeroProgress,
            ),
          ),
        ],
        const SizedBox(height: 24),
        OnbPrimaryButton(
          key: const ValueKey('onboarding-start-plan'),
          label: l10n.onboarding_plan_start,
          loading: completing,
          onTap: completing ? null : onStart,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: completing ? null : onAdjust,
          child: Text(
            l10n.onboarding_plan_adjust,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  DateTime? _reachDate(OnboardingRecommendation rec, bool zeroProgress) {
    if (!draft.needsPaceStep || zeroProgress || rec.weeklyRateKg <= 0) {
      return null;
    }
    final current = draft.currentWeightKg;
    final target = draft.targetWeightKg;
    if (current == null || target == null) return null;
    return OnboardingPaceCalculator.estimatedTargetDate(
      current,
      target,
      rec.weeklyRateKg,
    );
  }

  String _goalSummaryText(
    AppLocalizations l10n,
    GoalType goal,
    OnboardingRecommendation rec,
    MeasurementSystem system,
    bool zeroProgress,
  ) {
    if (zeroProgress) return l10n.onboarding_plan_maintenance_estimate;

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

  String _adjustedDetail(
    AppLocalizations l10n,
    GoalType? goal,
    OnboardingRecommendation rec,
    MeasurementSystem system,
    bool zeroProgress,
  ) {
    if (zeroProgress) {
      return goal == GoalType.loseWeight
          ? l10n.onboarding_safety_zero_loss
          : l10n.onboarding_safety_zero_gain;
    }
    if (draft.needsPaceStep && draft.pace != null && goal != null) {
      final originalKg = OnboardingPaceCalculator.weeklyRateKgFor(
        goal,
        draft.pace!,
      );
      return l10n.onboarding_safety_adjusted_detail(
        OnboardingPaceCalculator.formatWeeklyRateValue(originalKg, system),
        OnboardingPaceCalculator.weeklyRateUnit(system),
        OnboardingPaceCalculator.formatWeeklyRateValue(rec.weeklyRateKg, system),
      );
    }
    return l10n.onboarding_safety_adjusted_fallback;
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final medallion = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(AppSymbols.check, size: 32, color: Colors.white),
    );
    if (reduceMotion) return medallion;
    return medallion
        .animate()
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 250.ms);
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.calories,
    required this.label,
    required this.locale,
    required this.animate,
  });

  final int calories;
  final String label;
  final String locale;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final track = accent.withValues(alpha: context.isDarkMode ? 0.18 : 0.12);
    final format = NumberFormat.decimalPattern(locale);

    Widget ring(double t) => SizedBox(
      width: 210,
      height: 210,
      child: CustomPaint(
        painter: _RingPainter(progress: t, track: track),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                format.format((calories * t).round()),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!animate) return ring(1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: 1100.ms,
      curve: Curves.easeOutCubic,
      builder: (_, t, _) => ring(t),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track});

  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final arcRect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669), Color(0xFF34D399)],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(arcRect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.track != track;
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
  });

  final String label;
  final int grams;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.16),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${grams}g',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.summary,
    required this.reachLine,
    required this.adjustedLabel,
  });

  final String summary;
  final String? reachLine;
  final String? adjustedLabel;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(AppSymbols.flag, size: 21, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      summary,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (adjustedLabel != null) OnbBadge(label: adjustedLabel!),
                  ],
                ),
                if (reachLine != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    reachLine!,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppSymbols.info, size: 18, color: AppColors.warningAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
