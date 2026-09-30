import 'package:flutter/material.dart';

import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_draft.dart';
import 'onboarding_kit.dart';
import 'widgets/onb_art.dart';

/// The goal: four tiles, an icon and a few words each.
class GoalStep extends StatelessWidget {
  const GoalStep({super.key, required this.selected, required this.onChanged});

  final GoalType? selected;
  final ValueChanged<GoalType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget tile(GoalType goal, String label) {
      final on = selected == goal;
      return OnbOption(
        key: ValueKey('onboarding-goal-${goal.name}'),
        entranceIndex: GoalType.values.indexOf(goal),
        selected: on,
        onTap: () => onChanged(goal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnbGoalArt(goal: goal, selected: on),
            const SizedBox(height: 18),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      ),
    );

    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(l10n.onb_q_goal),
          const SizedBox(height: 22),
          row(
            tile(GoalType.loseWeight, l10n.onboarding_goal_lose),
            tile(GoalType.maintainWeight, l10n.onboarding_goal_maintain),
          ),
          const SizedBox(height: 12),
          row(
            tile(GoalType.buildMuscle, l10n.onboarding_goal_build),
            tile(GoalType.trackNutrition, l10n.onboarding_goal_track),
          ),
        ],
      ),
    );
  }
}

/// Female or male: the calorie formula differs between the two.
class SexStep extends StatelessWidget {
  const SexStep({super.key, required this.selected, required this.onChanged});

  final BiologicalSex? selected;
  final ValueChanged<BiologicalSex> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget tile(BiologicalSex sex, String label) {
      final on = selected == sex;
      return OnbOption(
        key: ValueKey('onboarding-sex-${sex.name}'),
        entranceIndex: sex == BiologicalSex.female ? 0 : 1,
        selected: on,
        showTick: false,
        padding: const EdgeInsets.fromLTRB(12, 26, 12, 22),
        onTap: () => onChanged(sex),
        child: Column(
          children: [
            OnbSexArt(sex: sex, selected: on),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(l10n.onb_q_sex),
          const SizedBox(height: 22),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: tile(BiologicalSex.female, l10n.onboarding_female),
                ),
                const SizedBox(width: 12),
                Expanded(child: tile(BiologicalSex.male, l10n.onboarding_male)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How active a normal week is: a meter, a label and a short example.
class ActivityStep extends StatelessWidget {
  const ActivityStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ActivityLevel? selected;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levels = [
      (
        ActivityLevel.mostlySitting,
        l10n.onb_act_sitting,
        l10n.onb_act_sitting_hint,
      ),
      (
        ActivityLevel.lightlyActive,
        l10n.onb_act_light,
        l10n.onb_act_light_hint,
      ),
      (ActivityLevel.active, l10n.onb_act_active, l10n.onb_act_active_hint),
      (ActivityLevel.veryActive, l10n.onb_act_very, l10n.onb_act_very_hint),
    ];
    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(l10n.onb_q_activity),
          const SizedBox(height: 22),
          for (var i = 0; i < levels.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ActivityRow(
              index: i,
              level: levels[i].$1,
              title: levels[i].$2,
              hint: levels[i].$3,
              selected: selected == levels[i].$1,
              onTap: () => onChanged(levels[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.index,
    required this.level,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final ActivityLevel level;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnbOption(
      key: ValueKey('onboarding-activity-${level.name}'),
      entranceIndex: index,
      selected: selected,
      showTick: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          OnbActivityArt(level: level, selected: selected),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OnbTick(selected: selected),
        ],
      ),
    );
  }
}
