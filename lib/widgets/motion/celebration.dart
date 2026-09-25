import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../wazn_icons.dart';

/// The moment a daily goal is reached: a buzz, a small burst of confetti from
/// [origin] (a global position, usually the end of the bar that just filled)
/// and a note sliding down from the top.
///
/// With reduced motion there is no confetti and the note fades in and out.
void celebrateGoal(
  BuildContext context, {
  required Offset origin,
  required String title,
  required String subtitle,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  HapticFeedback.mediumImpact();
  if (!reduce) {
    late final OverlayEntry burst;
    burst = OverlayEntry(
      builder:
          (_) => _ConfettiBurst(origin: origin, onDone: () => burst.remove()),
    );
    overlay.insert(burst);
  }
  late final OverlayEntry note;
  note = OverlayEntry(
    builder:
        (_) => _GoalNote(
          title: title,
          subtitle: subtitle,
          reduce: reduce,
          onDone: () => note.remove(),
        ),
  );
  overlay.insert(note);
}

/// Just the burst of confetti from [origin], a global position, with no
/// note: for a screen that says its own words.
void burstConfetti(BuildContext context, Offset origin) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
  late final OverlayEntry burst;
  burst = OverlayEntry(
    builder:
        (_) => _ConfettiBurst(origin: origin, onDone: () => burst.remove()),
  );
  overlay.insert(burst);
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.origin, required this.onDone});

  final Offset origin;
  final VoidCallback onDone;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..forward().whenComplete(widget.onDone);

  late final List<_Piece> _pieces = () {
    final random = math.Random();
    const colors = [
      AppColors.primary,
      AppColors.protein,
      AppColors.carbs,
      AppColors.fat,
      AppColors.warning,
    ];
    return List.generate(64, (i) {
      // Mostly upwards, fanned about 100 degrees either side.
      final angle = -math.pi / 2 + (random.nextDouble() - .5) * math.pi * 1.1;
      final speed = 260 + random.nextDouble() * 360;
      return _Piece(
        velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
        spin: (random.nextDouble() - .5) * 14,
        size: Size(5 + random.nextDouble() * 4, 8 + random.nextDouble() * 5),
        color: colors[i % colors.length],
      );
    });
  }();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(
          animation: _controller,
          origin: widget.origin,
          pieces: _pieces,
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.velocity,
    required this.spin,
    required this.size,
    required this.color,
  });

  final Offset velocity;
  final double spin;
  final Size size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.animation,
    required this.origin,
    required this.pieces,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Offset origin;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = animation.value * 1.7;
    // Air drag slows each piece; gravity pulls it back down.
    const drag = 2.2, gravity = 900.0;
    final decay = (1 - math.exp(-drag * seconds)) / drag;
    final fade = animation.value < .7 ? 1.0 : 1 - (animation.value - .7) / .3;
    for (final p in pieces) {
      final position =
          origin +
          p.velocity * decay +
          Offset(0, gravity * seconds * seconds / 2 * .55);
      final angle = p.spin * seconds;
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(angle);
      // Tumbling: the piece's height flips as it turns.
      final h = p.size.height * math.cos(angle * 1.7).abs() + 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size.width, height: h),
          const Radius.circular(1.5),
        ),
        Paint()..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}

class _GoalNote extends StatefulWidget {
  const _GoalNote({
    required this.title,
    required this.subtitle,
    required this.reduce,
    required this.onDone,
  });

  final String title, subtitle;
  final bool reduce;
  final VoidCallback onDone;

  @override
  State<_GoalNote> createState() => _GoalNoteState();
}

class _GoalNoteState extends State<_GoalNote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : const Color(0xFF16181D);
    final muted = dark ? Colors.white60 : const Color(0xFF6F6F68);
    final top = MediaQuery.paddingOf(context).top + 10;
    return Positioned(
      top: top,
      left: 14,
      right: 14,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final v = _controller.value;
            // In over the first eighth, hold, out over the last eighth.
            final inT = AppMotion.springCurve.transform(
              (v / .125).clamp(0.0, 1.0),
            );
            final outT = Curves.easeInCubic.transform(
              ((v - .875) / .125).clamp(0.0, 1.0),
            );
            final shown = (inT - outT).clamp(0.0, 1.0);
            return Opacity(
              opacity: (v < .5 ? (v / .06) : (1 - outT)).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, widget.reduce ? 0 : -90 * (1 - shown)),
                child: child,
              ),
            );
          },
          // Transparent material: the overlay has no text style of its own.
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF181B19) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      dark ? const Color(0xFF2A2E2B) : const Color(0xFFE8E6E0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? .4 : .10),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        WaznIcons.check,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontSize: 12.5),
                          ),
                        ],
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
