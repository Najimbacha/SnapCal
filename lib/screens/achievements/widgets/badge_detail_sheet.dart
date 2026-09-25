import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_motion.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/motion/count_up_text.dart';
import 'package:snapcal/widgets/motion/reveal.dart';

import 'badge_card.dart';

/// A closer look at one badge: a ring that fills to how far along it is,
/// the count, and what is left -- or when it was earned.
Future<void> showBadgeDetail(BuildContext context, Achievement achievement) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => BadgeDetailSheet(achievement: achievement),
  );
}

class BadgeDetailSheet extends StatelessWidget {
  const BadgeDetailSheet({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final earned = achievement.isUnlocked;
    final ring = earned ? badgeGold : AppColors.primary;
    final when = achievement.unlockedAt;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 150,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: earned ? 1 : achievement.progressPercent,
                ),
                duration: AppMotion.maybeZero(
                  context,
                  const Duration(milliseconds: 1100),
                ),
                curve: Curves.easeOutCubic,
                builder:
                    (context, value, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            key: const ValueKey('badge-detail-ring'),
                            value: value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: ring,
                            backgroundColor: scheme.outlineVariant.withValues(
                              alpha: .3,
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                child: Reveal(
                  delay: const Duration(milliseconds: 150),
                  offset: Offset.zero,
                  scale: .5,
                  curve: AppMotion.springCurve,
                  child: Opacity(
                    opacity: earned ? 1 : .55,
                    child: Text(
                      achievement.emoji,
                      style: const TextStyle(fontSize: 58),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Rise(
              delay: 250,
              child: Text(
                badgeTitle(context, achievement.titleKey),
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _Rise(
              delay: 330,
              child: Text(
                badgeDescription(context, achievement.descriptionKey),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (earned)
              _Rise(
                delay: 410,
                child: Text(
                  when == null
                      ? l10n.achievement_unlocked_label
                      : l10n.achievement_earned_on(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).format(DateTime.fromMillisecondsSinceEpoch(when)),
                      ),
                  style: AppTypography.labelLarge.copyWith(
                    color: badgeGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else ...[
              _Rise(
                delay: 410,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    CountUpText(
                      value: achievement.currentProgress,
                      from: 0,
                      duration: const Duration(milliseconds: 1100),
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' / ${achievement.targetValue}',
                      style: AppTypography.titleMedium.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              _Rise(
                delay: 490,
                child: Text(
                  l10n.achievement_to_go(
                    '${(achievement.targetValue - achievement.currentProgress).clamp(0, achievement.targetValue)}',
                  ),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
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

class _Rise extends StatelessWidget {
  const _Rise({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) => Reveal(
    delay: Duration(milliseconds: delay),
    offset: const Offset(0, 10),
    child: child,
  );
}
