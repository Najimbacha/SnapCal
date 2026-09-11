import 'package:flutter/material.dart';
import 'package:snapcal/widgets/app_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import 'onboarding_draft.dart';
import 'onboarding_ui.dart';

/// Four activity levels.
///
/// The third was labelled with the "Very Active, 3-5 days/week" string, so
/// two of the four options were both called "Very active"; and a note below
/// them said one was already chosen and the step would move on by itself,
/// neither of which was so.
class ActivityStep extends StatelessWidget {
  final ActivityLevel? selected;
  final ValueChanged<ActivityLevel> onChanged;

  const ActivityStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levels = <(ActivityLevel, IconData, Color, String, String)>[
      (
        ActivityLevel.mostlySitting,
        AppSymbols.armchair,
        const Color(0xFF64748B),
        l10n.onboarding_activity_sitting,
        l10n.onboarding_activity_sitting_desc,
      ),
      (
        ActivityLevel.lightlyActive,
        AppSymbols.footprints,
        AppColors.sky,
        l10n.onboarding_activity_light,
        l10n.onboarding_activity_light_desc,
      ),
      (
        ActivityLevel.active,
        AppSymbols.run,
        AppColors.primary,
        l10n.onboarding_activity_moderate,
        l10n.onboarding_activity_moderate_desc,
      ),
      (
        ActivityLevel.veryActive,
        AppSymbols.flame,
        AppColors.fat,
        l10n.onboarding_activity_very,
        l10n.onboarding_activity_very_desc,
      ),
    ];

    return Column(
      children: [
        for (final (level, icon, tint, title, subtitle) in levels)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OnbChoiceTile(
              icon: icon,
              tint: tint,
              title: title,
              subtitle: subtitle,
              selected: selected == level,
              onTap: () => onChanged(level),
            ),
          ),
      ],
    );
  }
}
