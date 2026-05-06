import 'package:flutter/material.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class BadgeCard extends StatelessWidget {
  final Achievement achievement;

  const BadgeCard({super.key, required this.achievement});

  String _getLocalizedTitle(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'achievement_first_flame': return l10n.achievement_first_flame;
      case 'achievement_consistency_king': return l10n.achievement_consistency_king;
      case 'achievement_iron_will': return l10n.achievement_iron_will;
      case 'achievement_unstoppable': return l10n.achievement_unstoppable;
      case 'achievement_bullseye': return l10n.achievement_bullseye;
      case 'achievement_precision_pro': return l10n.achievement_precision_pro;
      case 'achievement_macro_master': return l10n.achievement_macro_master;
      case 'achievement_perfect_week': return l10n.achievement_perfect_week;
      case 'achievement_first_sip': return l10n.achievement_first_sip;
      case 'achievement_hydration_hero': return l10n.achievement_hydration_hero;
      case 'achievement_ocean_mode': return l10n.achievement_ocean_mode;
      case 'achievement_first_snap': return l10n.achievement_first_snap;
      case 'achievement_snap_master': return l10n.achievement_snap_master;
      case 'achievement_snap_legend': return l10n.achievement_snap_legend;
      case 'achievement_first_checkin': return l10n.achievement_first_checkin;
      case 'achievement_transformation': return l10n.achievement_transformation;
      case 'achievement_journey_video': return l10n.achievement_journey_video;
      default: return key;
    }
  }

  String _getLocalizedDesc(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'achievement_first_flame_desc': return l10n.achievement_first_flame_desc;
      case 'achievement_consistency_king_desc': return l10n.achievement_consistency_king_desc;
      case 'achievement_iron_will_desc': return l10n.achievement_iron_will_desc;
      case 'achievement_unstoppable_desc': return l10n.achievement_unstoppable_desc;
      case 'achievement_bullseye_desc': return l10n.achievement_bullseye_desc;
      case 'achievement_precision_pro_desc': return l10n.achievement_precision_pro_desc;
      case 'achievement_macro_master_desc': return l10n.achievement_macro_master_desc;
      case 'achievement_perfect_week_desc': return l10n.achievement_perfect_week_desc;
      case 'achievement_first_sip_desc': return l10n.achievement_first_sip_desc;
      case 'achievement_hydration_hero_desc': return l10n.achievement_hydration_hero_desc;
      case 'achievement_ocean_mode_desc': return l10n.achievement_ocean_mode_desc;
      case 'achievement_first_snap_desc': return l10n.achievement_first_snap_desc;
      case 'achievement_snap_master_desc': return l10n.achievement_snap_master_desc;
      case 'achievement_snap_legend_desc': return l10n.achievement_snap_legend_desc;
      case 'achievement_first_checkin_desc': return l10n.achievement_first_checkin_desc;
      case 'achievement_transformation_desc': return l10n.achievement_transformation_desc;
      case 'achievement_journey_video_desc': return l10n.achievement_journey_video_desc;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnlocked 
              ? AppColors.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.emoji,
            style: TextStyle(
              fontSize: 40,
              foreground: isUnlocked ? null : (Paint()..color = Colors.grey.withValues(alpha: 0.5)),
              shadows: isUnlocked ? [
                const Shadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ] : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getLocalizedTitle(context, achievement.titleKey),
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getLocalizedDesc(context, achievement.descriptionKey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isUnlocked ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const Spacer(),
          if (!isUnlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: achievement.progressPercent,
                minHeight: 4,
                backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(AppColors.primary.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${achievement.currentProgress} / ${achievement.targetValue}',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ] else
            Text(
              'Unlocked',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
