import 'package:flutter/material.dart';

import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'body_steps.dart';
import 'onboarding_body.dart';
import 'onboarding_draft.dart';
import 'onboarding_kit.dart';
import 'onboarding_units.dart';

/// The target weight, with how far it is and whether it is a healthy one.
class TargetStep extends StatelessWidget {
  const TargetStep({
    super.key,
    required this.goal,
    required this.currentKg,
    required this.targetKg,
    required this.heightCm,
    required this.system,
    required this.onChanged,
  });

  final GoalType goal;
  final double currentKg;
  final double targetKg;
  final double heightCm;
  final MeasurementSystem system;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = weightUnitLabel(l10n, system);
    final shown = weightOnRuler(targetKg, system);
    final delta = shown - weightOnRuler(currentKg, system);
    final percent = ((targetKg - currentKg).abs() / currentKg * 100).round();
    final (note, tone) = targetMessage(
      l10n,
      checkTarget(
        goal: goal,
        currentKg: currentKg,
        targetKg: targetKg,
        heightCm: heightCm,
      ),
      currentKg: currentKg,
      heightCm: heightCm,
      system: system,
    );

    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(
            goal == GoalType.buildMuscle
                ? l10n.onb_q_target_gain
                : l10n.onb_q_target,
          ),
          const SizedBox(height: 22),
          OnbReadout(value: shown.toStringAsFixed(1), unit: unit),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: WeightRuler(
              key: ValueKey('onboarding-target-ruler-${system.name}'),
              valueKg: targetKg,
              system: system,
              semanticLabel:
                  goal == GoalType.buildMuscle
                      ? l10n.onb_q_target_gain
                      : l10n.onb_q_target,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${delta < 0 ? '−' : '+'}${delta.abs().toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OnbNote(
            key: const ValueKey('onboarding-target-note'),
            text: note,
            tone: tone,
          ),
        ],
      ),
    );
  }
}

/// The line shown under the target, and its tone.
(String, OnbTone) targetMessage(
  AppLocalizations l10n,
  TargetCheck check, {
  required double currentKg,
  required double heightCm,
  required MeasurementSystem system,
}) {
  final issue = check.issue;
  if (issue != null) {
    final text = switch (issue) {
      TargetIssue.mustBeLower => l10n.onb_target_lower(
        formatWeight(l10n, currentKg, system),
      ),
      TargetIssue.mustBeHigher => l10n.onb_target_higher(
        formatWeight(l10n, currentKg, system),
      ),
      TargetIssue.tooFar => l10n.onb_target_too_far,
      TargetIssue.alreadyBelowHealthy => l10n.onb_target_already_below(
        l10n.onboarding_goal_maintain,
      ),
      TargetIssue.belowHealthy => l10n.onb_target_lowest(
        '${kgToDisplay(healthyWeightRangeKg(heightCm).low, system).ceil()} '
        '${weightUnitLabel(l10n, system)}',
      ),
    };
    return (text, OnbTone.bad);
  }
  return switch (check.note!) {
    TargetNote.healthy => (l10n.onb_target_healthy, OnbTone.good),
    TargetNote.milestone => (l10n.onb_target_milestone, OnbTone.good),
    TargetNote.aboveHealthyForMuscle => (l10n.onb_target_muscle, OnbTone.warn),
  };
}
