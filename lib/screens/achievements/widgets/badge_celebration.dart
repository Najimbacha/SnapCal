import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/core/theme/app_motion.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/motion/celebration.dart';
import 'package:snapcal/widgets/motion/reveal.dart';
import 'package:snapcal/widgets/motion/shine_sweep.dart';

import 'badge_card.dart';

/// Shows a newly earned badge over the Achievements screen.
///
/// The badge lifts out of its place on the grid, turns about with light
/// behind it and confetti around it, and flies back into its place when
/// dismissed. Returns once it has gone.
Future<void> celebrateBadge(BuildContext context, Achievement achievement) {
  final reduce = AppMotion.reduceMotion(context);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: Duration(milliseconds: reduce ? 0 : 520),
      reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 480),
      pageBuilder:
          (context, animation, _) =>
              _BadgeCelebration(achievement: achievement, route: animation),
    ),
  );
}

class _BadgeCelebration extends StatefulWidget {
  const _BadgeCelebration({required this.achievement, required this.route});

  final Achievement achievement;
  final Animation<double> route;

  @override
  State<_BadgeCelebration> createState() => _BadgeCelebrationState();
}

class _BadgeCelebrationState extends State<_BadgeCelebration>
    with TickerProviderStateMixin {
  final _disc = GlobalKey();

  /// The turn and swell once the badge has landed.
  late final AnimationController _turn;

  /// The light behind the badge, slowly going round.
  late final AnimationController _rays;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rays = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    widget.route.addStatusListener(_arrived);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.route.isCompleted && !_turn.isAnimating && _turn.value == 0) {
      _arrived(AnimationStatus.completed);
    }
  }

  void _arrived(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    widget.route.removeStatusListener(_arrived);
    HapticFeedback.heavyImpact();
    if (AppMotion.reduceMotion(context)) {
      _turn.value = 1;
      return;
    }
    _turn.forward();
    _rays.repeat();
    final box = _disc.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      burstConfetti(context, box.localToGlobal(box.size.center(Offset.zero)));
    }
  }

  @override
  void dispose() {
    widget.route.removeStatusListener(_arrived);
    _turn.dispose();
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final achievement = widget.achievement;
    final card = CurvedAnimation(
      parent: widget.route,
      curve: AppMotion.springCurve,
      reverseCurve: Curves.easeIn,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: widget.route,
          child: ScaleTransition(
            scale: Tween(begin: .88, end: 1.0).animate(card),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Rays fade up and turn slowly behind the badge.
                          AnimatedBuilder(
                            animation: Listenable.merge([_turn, _rays]),
                            builder:
                                (context, _) => Opacity(
                                  opacity: Curves.easeOut.transform(
                                    _turn.value,
                                  ),
                                  child: Transform.rotate(
                                    angle: _rays.value * 2 * math.pi,
                                    child: CustomPaint(
                                      size: const Size.square(200),
                                      painter: _RaysPainter(badgeGold),
                                    ),
                                  ),
                                ),
                          ),
                          Hero(
                            tag: badgeHeroTag(achievement),
                            // On the way back the gold badge is the one that
                            // flies, not the grey one waiting on the grid.
                            flightShuttleBuilder:
                                (_, _, direction, from, to) =>
                                    ((direction == HeroFlightDirection.push
                                                    ? to
                                                    : from)
                                                .widget
                                            as Hero)
                                        .child,
                            child: AnimatedBuilder(
                              animation: _turn,
                              builder: (context, child) {
                                final t = _turn.value;
                                final swell = 1 + 0.15 * math.sin(t * math.pi);
                                return Transform(
                                  alignment: Alignment.center,
                                  transform:
                                      Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(
                                          Curves.easeOutCubic.transform(t) *
                                              2 *
                                              math.pi,
                                        )
                                        ..scaleByDouble(swell, swell, 1, 1),
                                  child: child,
                                );
                              },
                              child: ShineSweep(
                                key: _disc,
                                borderRadius: BorderRadius.circular(99),
                                delay: const Duration(milliseconds: 1200),
                                child: Container(
                                  width: 112,
                                  height: 112,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.alphaBlend(
                                      badgeGold.withValues(alpha: .16),
                                      scheme.surface,
                                    ),
                                    border: Border.all(
                                      color: badgeGold,
                                      width: 3,
                                    ),
                                  ),
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Text(
                                      achievement.emoji,
                                      style: const TextStyle(fontSize: 54),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Line(
                      delay: 650,
                      child: Text(
                        l10n.feature_achievements_unlocked_title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTypography.labelMedium.copyWith(
                          color: badgeGold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _Line(
                      delay: 740,
                      child: Text(
                        badgeTitle(context, achievement.titleKey),
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _Line(
                      delay: 830,
                      child: Text(
                        badgeDescription(context, achievement.descriptionKey),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Line(
                      delay: 920,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('badge-celebration-done'),
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(l10n.common_done),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) => Reveal(
    delay: Duration(milliseconds: delay),
    offset: const Offset(0, 12),
    child: child,
  );
}

class _RaysPainter extends CustomPainter {
  const _RaysPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: .35), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius));
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final path =
          Path()
            ..moveTo(centre.dx, centre.dy)
            ..lineTo(
              centre.dx + radius * math.cos(a - .12),
              centre.dy + radius * math.sin(a - .12),
            )
            ..lineTo(
              centre.dx + radius * math.cos(a + .12),
              centre.dy + radius * math.sin(a + .12),
            )
            ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}
