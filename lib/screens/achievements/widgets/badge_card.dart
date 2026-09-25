import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_motion.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/motion/reveal.dart';
import 'package:snapcal/widgets/motion/shine_sweep.dart';

/// The badge's name in the reader's language.
String badgeTitle(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'achievement_first_flame':
      return l10n.achievement_first_flame;
    case 'achievement_consistency_king':
      return l10n.achievement_consistency_king;
    case 'achievement_iron_will':
      return l10n.achievement_iron_will;
    case 'achievement_unstoppable':
      return l10n.achievement_unstoppable;
    case 'achievement_bullseye':
      return l10n.achievement_bullseye;
    case 'achievement_precision_pro':
      return l10n.achievement_precision_pro;
    case 'achievement_macro_master':
      return l10n.achievement_macro_master;
    case 'achievement_perfect_week':
      return l10n.achievement_perfect_week;
    case 'achievement_first_sip':
      return l10n.achievement_first_sip;
    case 'achievement_hydration_hero':
      return l10n.achievement_hydration_hero;
    case 'achievement_ocean_mode':
      return l10n.achievement_ocean_mode;
    case 'achievement_first_snap':
      return l10n.achievement_first_snap;
    case 'achievement_snap_master':
      return l10n.achievement_snap_master;
    case 'achievement_snap_legend':
      return l10n.achievement_snap_legend;
    case 'achievement_first_checkin':
      return l10n.achievement_first_checkin;
    case 'achievement_transformation':
      return l10n.achievement_transformation;
    default:
      return key;
  }
}

/// What earns the badge, in the reader's language.
String badgeDescription(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'achievement_first_flame_desc':
      return l10n.achievement_first_flame_desc;
    case 'achievement_consistency_king_desc':
      return l10n.achievement_consistency_king_desc;
    case 'achievement_iron_will_desc':
      return l10n.achievement_iron_will_desc;
    case 'achievement_unstoppable_desc':
      return l10n.achievement_unstoppable_desc;
    case 'achievement_bullseye_desc':
      return l10n.achievement_bullseye_desc;
    case 'achievement_precision_pro_desc':
      return l10n.achievement_precision_pro_desc;
    case 'achievement_macro_master_desc':
      return l10n.achievement_macro_master_desc;
    case 'achievement_perfect_week_desc':
      return l10n.achievement_perfect_week_desc;
    case 'achievement_first_sip_desc':
      return l10n.achievement_first_sip_desc;
    case 'achievement_hydration_hero_desc':
      return l10n.achievement_hydration_hero_desc;
    case 'achievement_ocean_mode_desc':
      return l10n.achievement_ocean_mode_desc;
    case 'achievement_first_snap_desc':
      return l10n.achievement_first_snap_desc;
    case 'achievement_snap_master_desc':
      return l10n.achievement_snap_master_desc;
    case 'achievement_snap_legend_desc':
      return l10n.achievement_snap_legend_desc;
    case 'achievement_first_checkin_desc':
      return l10n.achievement_first_checkin_desc;
    case 'achievement_transformation_desc':
      return l10n.achievement_transformation_desc;
    default:
      return key;
  }
}

/// The gold behind an earned badge.
const badgeGold = Color(0xFFE29200);

/// The hero tag shared by a badge on the grid and in its celebration.
String badgeHeroTag(Achievement achievement) => 'badge-${achievement.id}';

/// One badge on the Achievements grid.
///
/// Badges rise in turn by [index]; an earned one pops its emoji and catches
/// the light, and a locked one's bar fills to how close it is. A badge
/// [pending] its celebration still looks locked, then turns over to gold
/// once the celebration hands it back.
class BadgeCard extends StatelessWidget {
  final Achievement achievement;
  final int index;
  final bool pending;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.achievement,
    this.index = 0,
    this.pending = false,
    this.onTap,
  });

  Duration get _delay => Duration(milliseconds: 150 + 70 * index);

  @override
  Widget build(BuildContext context) {
    final showUnlocked = achievement.isUnlocked && !pending;
    return Reveal(
      delay: _delay,
      offset: const Offset(0, 18),
      scale: .94,
      child: Semantics(
        button: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedSwitcher(
            duration: AppMotion.maybeZero(
              context,
              const Duration(milliseconds: 620),
            ),
            transitionBuilder: _flip,
            layoutBuilder:
                (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, if (current != null) current],
                ),
            child: _Face(
              key: ValueKey(showUnlocked),
              achievement: achievement,
              unlocked: showUnlocked,
              delay: _delay,
            ),
          ),
        ),
      ),
    );
  }

  /// The card turns over: the old face away in the first half, the new one
  /// round in the second.
  static Widget _flip(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final leaving = animation.status == AnimationStatus.reverse;
        final t = animation.value;
        // Each face is only seen on its own half of the turn.
        final half = (t - .5) * 2;
        if (half <= 0) return const SizedBox.shrink();
        final angle = (1 - Curves.easeOutBack.transform(half)) * math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(leaving ? -angle : angle),
          child: child,
        );
      },
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.delay,
  });

  final Achievement achievement;
  final bool unlocked;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final emoji = Hero(
      tag: badgeHeroTag(achievement),
      child: Material(
        type: MaterialType.transparency,
        child: Text(
          achievement.emoji,
          style: TextStyle(
            fontSize: 40,
            foreground:
                unlocked
                    ? null
                    : (Paint()..color = Colors.grey.withValues(alpha: 0.5)),
            shadows:
                unlocked
                    ? const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
        ),
      ),
    );
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            unlocked
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              unlocked
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: unlocked ? 2 : 1,
        ),
        boxShadow:
            unlocked
                ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (unlocked)
            // An earned badge's emoji pops in with a little spin.
            Reveal(
              delay: delay + const Duration(milliseconds: 120),
              offset: Offset.zero,
              scale: .4,
              curve: AppMotion.springCurve,
              child: emoji,
            )
          else
            emoji,
          const SizedBox(height: 8),
          Text(
            badgeTitle(context, achievement.titleKey),
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  unlocked
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badgeDescription(context, achievement.descriptionKey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color:
                  unlocked
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const Spacer(),
          if (!unlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              // Fills to how close the badge is, once the card has landed.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: achievement.progressPercent),
                duration: AppMotion.maybeZero(
                  context,
                  delay + const Duration(milliseconds: 1200),
                ),
                curve: Interval(
                  (delay.inMilliseconds + 300) / (delay.inMilliseconds + 1200),
                  1,
                  curve: Curves.easeOutCubic,
                ),
                builder:
                    (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
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
              AppLocalizations.of(context)!.achievement_unlocked_label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
    if (!unlocked) return card;
    return ShineSweep(
      borderRadius: BorderRadius.circular(24),
      delay: delay + const Duration(milliseconds: 500),
      sweep: const Duration(milliseconds: 900),
      child: card,
    );
  }
}
