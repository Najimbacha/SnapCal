import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';

class MacroCard extends StatefulWidget {
  final String label;
  final int consumed;
  final int goal;
  final Color color;
  final IconData? icon;

  const MacroCard({
    super.key,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    this.icon,
  });

  @override
  State<MacroCard> createState() => _MacroCardState();
}

class _MacroCardState extends State<MacroCard> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.goal > 0 ? (widget.consumed / widget.goal).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon ?? Icons.circle, color: widget.color, size: 18),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.consumed}g',
              style: AppTypography.titleLarge.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            Text(
              widget.label,
              style: AppTypography.labelSmall.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Liquid Macro Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(color: context.dividerColor.withValues(alpha: 0.5)),
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 8),
                          painter: _BarWavePainter(
                            animationValue: _waveController.value,
                            progress: progress,
                            color: widget.color,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarWavePainter extends CustomPainter {
  final double animationValue;
  final double progress;
  final Color color;

  _BarWavePainter({
    required this.animationValue,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillWidth = size.width * progress;
    final path = Path();
    
    path.moveTo(0, size.height);
    
    // Create wave at the end of the progress
    for (double i = 0; i <= fillWidth; i++) {
      final double waveHeight = math.sin((i / 20) + (animationValue * 2 * math.pi)) * 1.5;
      path.lineTo(i, (size.height / 2) + waveHeight - (size.height * 0.1));
    }

    path.lineTo(fillWidth, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
    
    // Add a solid block behind to ensure zero gaps if the wave is shallow
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.4, fillWidth, size.height * 0.6), paint);
  }

  @override
  bool shouldRepaint(covariant _BarWavePainter oldDelegate) => true;
}
