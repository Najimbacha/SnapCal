import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class AmbientMeshBackground extends StatelessWidget {
  const AmbientMeshBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        Positioned(
          top: -50,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.08),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(end: 1.3, duration: 4.seconds, curve: Curves.easeInOutSine),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violet.withValues(alpha: isDark ? 0.35 : 0.08),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(end: 1.4, duration: 5.seconds, curve: Curves.easeInOutSine),
        ),
        Positioned(
          bottom: 200,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sky.withValues(alpha: isDark ? 0.30 : 0.05),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(end: 1.2, duration: 3.5.seconds, curve: Curves.easeInOutSine),
        ),
        // Blur layer for glassmorphism
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
