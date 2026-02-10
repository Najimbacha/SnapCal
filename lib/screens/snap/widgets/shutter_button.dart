import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Premium shutter button with emerald gradient and pulsing glow
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
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // Idle pulse glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
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

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _pressController.forward() : null,
      onTapUp:
          isEnabled
              ? (_) {
                _pressController.reverse();
                widget.onPressed!();
              }
              : null,
      onTapCancel: () => _pressController.reverse(),
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing glow ring (behind the button)
            if (isEnabled)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseScale.value,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(
                            _pulseOpacity.value,
                          ),
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Main button
            AnimatedBuilder(
              animation: _pressScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pressScale.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          isEnabled
                              ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : null,
                      color: isEnabled ? null : Colors.grey.shade700,
                      boxShadow:
                          isEnabled
                              ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child:
                          widget.isLoading
                              ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
