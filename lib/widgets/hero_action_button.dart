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
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _outerPulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _outerPulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Far Outer Pulse Glow
              Container(
                width: 76 * _outerPulseAnimation.value,
                height: 76 * _outerPulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.05 * (1.0 - _controller.value)),
                ),
              ),
              // Inner Pulse Glow
              Container(
                width: 70 * _pulseAnimation.value,
                height: 70 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              // Main Circular Button
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary,
                      Color.lerp(colorScheme.primary, Colors.black, 0.1)!,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.camera,
                    color: colorScheme.onPrimary,
                    size: 32,
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
