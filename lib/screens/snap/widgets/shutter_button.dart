import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class ShutterButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const ShutterButton({super.key, this.onPressed, this.isLoading = false});

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final primaryColor = AppColors.primary;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _pressController.forward() : null,
      onTapUp: isEnabled
          ? (_) {
              HapticFeedback.heavyImpact();
              _pressController.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressScale, _pulseAnim, _glowAnim]),
        builder: (context, child) {
          final scale = _pressScale.value * (isEnabled ? _pulseAnim.value : 1.0);
          final glowOpacity = isEnabled ? _glowAnim.value : 0.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEnabled
                    ? LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.9),
                          primaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEnabled ? null : Colors.grey.shade700,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35 * glowOpacity),
                          blurRadius: 20 + (10 * glowOpacity),
                          spreadRadius: 2 * glowOpacity,
                        ),
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15 * glowOpacity),
                          blurRadius: 40,
                          spreadRadius: 5 * glowOpacity,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
