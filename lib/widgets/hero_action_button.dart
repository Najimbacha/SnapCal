import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme/app_colors.dart';

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
      duration: const Duration(milliseconds: 1000),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface.withValues(
                  alpha: isDark ? 0.82 : 0.95,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  // Breathing glow (restrained)
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: _breatheGlow.value,
                    ),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: _isPressed ? 52 : 58,
                  height: _isPressed ? 52 : 58,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
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
                          color: colorScheme.onPrimary,
                          size: 36,
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
