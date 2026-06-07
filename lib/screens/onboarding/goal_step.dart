import 'package:flutter/material.dart';
import 'package:snapcal/widgets/app_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import 'onboarding_draft.dart';

class GoalStep extends StatelessWidget {
  final GoalType? selected;
  final ValueChanged<GoalType> onChanged;

  const GoalStep({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          l10n.onboarding_goal_title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 18),
        _GoalCard(
          icon: AppSymbols.trendingDown,
          title: l10n.onboarding_goal_lose,
          subtitle: l10n.onboarding_goal_lose_desc,
          selected: selected == GoalType.loseWeight,
          onTap: () => onChanged(GoalType.loseWeight),
        ),
        _GoalCard(
          icon: AppSymbols.minus,
          title: l10n.onboarding_goal_maintain,
          subtitle: l10n.onboarding_goal_maintain_desc,
          selected: selected == GoalType.maintainWeight,
          onTap: () => onChanged(GoalType.maintainWeight),
        ),
        _GoalCard(
          icon: AppSymbols.trendingUp,
          title: l10n.onboarding_goal_build,
          subtitle: l10n.onboarding_goal_build_desc,
          selected: selected == GoalType.buildMuscle,
          onTap: () => onChanged(GoalType.buildMuscle),
        ),
        _GoalCard(
          icon: AppSymbols.clipboardList,
          title: l10n.onboarding_goal_track,
          subtitle: l10n.onboarding_goal_track_desc,
          selected: selected == GoalType.trackNutrition,
          onTap: () => onChanged(GoalType.trackNutrition),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = context.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color:
              selected
                  ? accent.withValues(alpha: isDark ? 0.12 : 0.07)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.white.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected
                    ? accent.withValues(alpha: 0.76)
                    : context.cardBorderColor,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.10 : 0.025,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
        ),
        child: Stack(
          children: [
            if (selected)
              PositionedDirectional(
                start: 0,
                top: 16,
                bottom: 16,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.055)
                                : Colors.black.withValues(alpha: 0.035)),
                    gradient: selected ? AppColors.primaryGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: selected ? Colors.white : context.textMutedColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.24,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? AppSymbols.checkCircle2 : AppSymbols.circle,
                  color:
                      selected
                          ? accent
                          : context.textMutedColor.withValues(alpha: 0.50),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
