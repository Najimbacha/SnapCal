import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HeroActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isActive;

  const HeroActionButton({
    super.key,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<HeroActionButton> createState() => _HeroActionButtonState();
}

class _HeroActionButtonState extends State<HeroActionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _showScanIcon = false;
  bool _iconToggledThisCycle = false;
  late final AnimationController _breatheController;
  late final Animation<double> _breatheGlow;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _breatheController.addListener(_syncIconWithBreathCycle);
    _breatheGlow = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  void _syncIconWithBreathCycle() {
    if (_breatheController.status == AnimationStatus.forward &&
        _breatheController.value > 0.92 &&
        !_iconToggledThisCycle) {
      setState(() {
        _showScanIcon = !_showScanIcon;
        _iconToggledThisCycle = true;
      });
      return;
    }

    if (_breatheController.status == AnimationStatus.reverse &&
        _breatheController.value < 0.12) {
      _iconToggledThisCycle = false;
    }
  }

  @override
  void dispose() {
    _breatheController.removeListener(_syncIconWithBreathCycle);
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = Color(0xFF1A3D2B);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isPressed ? 0.92 : 1.0,
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _breatheGlow,
          builder: (context, child) {
            return Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: _isPressed ? 62 : 68,
                  height: _isPressed ? 62 : 68,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green,
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : const Color(0xFFF9F8F5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.30 : 0.14,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle Shimmer
                      _ShimmerOverlay(animation: _breatheController),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final rotate = Tween<double>(
                            begin: math.pi / 2,
                            end: 0,
                          ).animate(animation);
                          final scale = Tween<double>(
                            begin: 0.82,
                            end: 1.0,
                          ).animate(animation);

                          return AnimatedBuilder(
                            animation: animation,
                            child: child,
                            builder: (context, child) {
                              return Transform(
                                alignment: Alignment.center,
                                transform:
                                    Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateY(rotate.value),
                                child: ScaleTransition(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
                        child: Icon(
                          _showScanIcon
                              ? LucideIcons.scanLine
                              : LucideIcons.camera,
                          key: ValueKey(_showScanIcon),
                          color: const Color(0xFFF0FDF4),
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerOverlay extends StatelessWidget {
  final Animation<double> animation;
  const _ShimmerOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            -80 + (animation.value * 160),
            -80 + (animation.value * 160),
          ),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 100,
              height: 25,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
