import 'package:flutter/material.dart';
import 'package:snapcal/widgets/app_icon.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_draft.dart';
import 'onboarding_ui.dart';

/// The four goals as a two-by-two grid, each with its own colour.
class GoalStep extends StatelessWidget {
  final GoalType? selected;
  final ValueChanged<GoalType> onChanged;

  const GoalStep({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goals = <(GoalType, IconData, Color, String, String)>[
      (
        GoalType.loseWeight,
        AppSymbols.trendingDown,
        AppColors.primary,
        l10n.onboarding_goal_lose,
        l10n.onboarding_goal_lose_desc,
      ),
      (
        GoalType.maintainWeight,
        AppSymbols.balance,
        AppColors.sky,
        l10n.onboarding_goal_maintain,
        l10n.onboarding_goal_maintain_desc,
      ),
      (
        GoalType.buildMuscle,
        AppSymbols.dumbbell,
        AppColors.fat,
        l10n.onboarding_goal_build,
        l10n.onboarding_goal_build_desc,
      ),
      (
        GoalType.trackNutrition,
        AppSymbols.listChecks,
        AppColors.violet,
        l10n.onboarding_goal_track,
        l10n.onboarding_goal_track_desc,
      ),
    ];

    Widget tile((GoalType, IconData, Color, String, String) goal) {
      final (type, icon, tint, title, subtitle) = goal;
      return OnbChoiceTile(
        stacked: true,
        icon: icon,
        tint: tint,
        title: title,
        subtitle: subtitle,
        selected: selected == type,
        onTap: () => onChanged(type),
      );
    }

    Widget pair(int first, int second) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(goals[first])),
          const SizedBox(width: 12),
          Expanded(child: tile(goals[second])),
        ],
      ),
    );

    return Column(children: [pair(0, 1), const SizedBox(height: 12), pair(2, 3)]);
  }
}
