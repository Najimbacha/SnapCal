import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// A breathing AI orb — the visual identity of the AI Coach.
///
/// - Idle: gentle scale pulse + soft glow
/// - Thinking: faster pulse with a rotating ring of dots
/// - Speaking: orb settles, tiny spark on top
class AiOrb extends StatefulWidget {
  final bool isThinking;
  final double size;
  final Color? accent;

  const AiOrb({
    super.key,
    this.isThinking = false,
    this.size = 48,
    this.accent,
  });

  @override
  State<AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<AiOrb> with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _rotate;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.isThinking) _rotate.repeat();
  }

  @override
  void didUpdateWidget(covariant AiOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking && !_rotate.isAnimating) {
      _rotate.repeat();
    } else if (!widget.isThinking && _rotate.isAnimating) {
      _rotate.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _rotate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.homeCoachAccent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.size + 16,
      height: widget.size + 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _rotate]),
        builder: (context, _) {
          final breath = 0.96 + (_breath.value * 0.06);
          final ringRotation = _rotate.value * 2 * math.pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isThinking)
                Transform.rotate(
                  angle: ringRotation,
                  child: _OrbitDots(
                    size: widget.size + 12,
                    color: accent,
                  ),
                ),
              Transform.scale(
                scale: breath,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.3),
                      radius: 0.9,
                      colors: [
                        accent.withValues(alpha: 0.95),
                        accent.withValues(alpha: 0.6),
                        AppColors.secondary.withValues(alpha: 0.4),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(
                          alpha: isDark ? 0.35 : 0.25,
                        ),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 44,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: widget.size * 0.18,
                        height: widget.size * 0.18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitDots extends StatelessWidget {
  final double size;
  final Color color;
  const _OrbitDots({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (i) {
          final angle = (i / 3) * 2 * math.pi;
          return Transform.translate(
            offset: Offset(
              math.cos(angle) * size * 0.42,
              math.sin(angle) * size * 0.42,
            ),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Compact version of the orb used as a message avatar (24px).
class AiOrbMini extends StatelessWidget {
  final Color? accent;
  const AiOrbMini({super.key, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.homeCoachAccent;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 0.95,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.65),
            AppColors.secondary.withValues(alpha: 0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
      duration: 1800.ms,
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.05, 1.05),
      curve: Curves.easeInOut,
    );
  }
}
