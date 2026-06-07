import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
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
      onTapUp: isEnabled
          ? (_) {
              HapticFeedback.heavyImpact();
              _pressController.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressScale, _pulseAnim]),
        builder: (context, child) {
          final scale =
              _pressScale.value * (isEnabled ? _pulseAnim.value : 1.0);
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isEnabled ? Colors.white : Colors.grey.shade600,
                      width: 4,
                    ),
                    color: Colors.transparent,
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
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isEnabled
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
