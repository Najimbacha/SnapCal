import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../snap_controller.dart';

class AnalyzingOverlay extends StatelessWidget {
  final VoidCallback? onManualEntry;
  const AnalyzingOverlay({super.key, this.onManualEntry});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapController>();
    final imageBytes = controller.capturedImageBytes;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Blurred Source Image ──
          if (imageBytes != null)
            Positioned.fill(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              ).animate().fadeIn(duration: 800.ms),
            ),
          
          // Dark Glass Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),

          // ── Premium Content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── AI Scanner Animation ──
                _ScannerVisualizer().animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 60),
                
                // ── Dynamic Text ──
                Column(
                  children: [
                    Text(
                      'Identifying Food',
                      style: AppTypography.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .shimmer(duration: 2.seconds, color: Colors.white24),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Gemini AI is calculating portions\nand nutritional density...',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),

                const SizedBox(height: 80),
                
                // ── Shimmer Bento Preview ──
                _BentoSkeleton().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 60),

                // ── Manual Fallback (Subtle) ──
                if (onManualEntry != null)
                  _ManualFallbackButton(onTap: onManualEntry!)
                      .animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerVisualizer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.5, 1.5))
         .fadeOut(),

        // Inner glowing core
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(LucideIcons.sparkles, color: Colors.white, size: 32),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
      ],
    );
  }
}

class _BentoSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) => Container(
          width: 80, height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        )),
      ),
    );
  }
}

class _ManualFallbackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManualFallbackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          'Log manually instead',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
