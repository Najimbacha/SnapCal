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
          // ── Semi-Clear Source Image ──
          if (imageBytes != null)
            Positioned.fill(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              ),
            ),
          
          // Subtle Dark Overlay (No heavy blur)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // ── Neural Scan Layer (Points & Laser) ──
          const Positioned.fill(
            child: _NeuralScanEffects(),
          ),

          // ── Premium Content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── AI Scanner Animation ──
                _ScannerStatus().animate().fadeIn(duration: 600.ms),
                
                const SizedBox(height: 40),
                
                // ── Dynamic Text (Glass Card for visibility) ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        children: [
                          Text(
                            'AI VISION SCANNING',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .shimmer(duration: 2.seconds, color: AppColors.primary),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            'Detecting ingredients and calculating\nnutritional density with Gemini...',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.6,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Manual Fallback (Subtle) ──
                if (onManualEntry != null)
                  _ManualFallbackButton(onTap: onManualEntry!)
                      .animate().fadeIn(delay: 1500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const Icon(LucideIcons.scan, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

class _NeuralScanEffects extends StatelessWidget {
  const _NeuralScanEffects();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── The Laser Sweep ──
        const _LaserSweep(),
        
        // ── Neural Detection Nodes ──
        ...List.generate(6, (index) => _NeuralNode(
          delay: (index * 400).ms,
          alignment: Alignment(
            (index % 3 == 0) ? -0.4 : (index % 2 == 0 ? 0.3 : -0.1),
            (index % 2 == 0) ? -0.2 : (index % 3 == 0 ? 0.4 : -0.5),
          ),
        )),
      ],
    );
  }
}

class _LaserSweep extends StatelessWidget {
  const _LaserSweep();

  @override
  Widget build(BuildContext context) {
    return Container().animate(onPlay: (c) => c.repeat()).custom(
      duration: 2.5.seconds,
      builder: (context, value, child) {
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * value,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NeuralNode extends StatelessWidget {
  final Duration delay;
  final Alignment alignment;
  
  const _NeuralNode({required this.delay, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat())
       .scale(delay: delay, duration: 1.seconds, begin: const Offset(0, 0), end: const Offset(1, 1))
       .fadeOut(delay: delay + 600.ms, duration: 400.ms),
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          'LOG MANUALLY',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
