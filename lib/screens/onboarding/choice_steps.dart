import 'package:flutter/material.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_draft.dart';
import 'onboarding_kit.dart';

/// The goal: four tiles, an icon and a few words each.
class GoalStep extends StatelessWidget {
  const GoalStep({super.key, required this.selected, required this.onChanged});

  final GoalType? selected;
  final ValueChanged<GoalType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget tile(GoalType goal, IconData icon, String label) {
      final on = selected == goal;
      return OnbOption(
        key: ValueKey('onboarding-goal-${goal.name}'),
        entranceIndex: GoalType.values.indexOf(goal),
        selected: on,
        onTap: () => onChanged(goal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnbIconWell(icon: icon, selected: on),
            const SizedBox(height: 36),
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
            tile(
              GoalType.loseWeight,
              AppSymbols.trendingDown,
              l10n.onboarding_goal_lose,
            ),
            tile(
              GoalType.maintainWeight,
              AppSymbols.balance,
              l10n.onboarding_goal_maintain,
            ),
          ),
          const SizedBox(height: 12),
          row(
            tile(
              GoalType.buildMuscle,
              AppSymbols.dumbbell,
              l10n.onboarding_goal_build,
            ),
            tile(
              GoalType.trackNutrition,
              AppSymbols.listChecks,
              l10n.onboarding_goal_track,
            ),
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
    Widget tile(BiologicalSex sex, IconData icon, String label) {
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
            AnimatedContainer(
              duration: AppMotion.maybeZero(context, AppMotion.expansion),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? context.cardColor : context.onbFill,
              ),
              child: Icon(icon, size: 30, color: context.textPrimaryColor),
            ),
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
                  child: tile(
                    BiologicalSex.female,
                    AppSymbols.female,
                    l10n.onboarding_female,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: tile(
                    BiologicalSex.male,
                    AppSymbols.male,
                    l10n.onboarding_male,
                  ),
                ),
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
              bars: i + 1,
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
    required this.bars,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final ActivityLevel level;
  final int bars;
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
          _LevelMeter(filled: bars, selected: selected),
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

/// Four rising bars, [filled] of them lit: how hard a week is.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.filled, required this.selected});

  final int filled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final on = selected ? context.primaryColor : context.textPrimaryColor;
    return ExcludeSemantics(
      child: SizedBox(
        width: 33,
        height: 24,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              // Lit bars change colour one after another, bottom to top.
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: i < filled ? on : context.onbFill),
                duration: AppMotion.maybeZero(
                  context,
                  Duration(milliseconds: 160 + 70 * i),
                ),
                curve: Interval(i * .18, 1, curve: Curves.easeOut),
                builder:
                    (context, color, _) => Container(
                      width: 6,
                      height: 8 + i * 5.33,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
