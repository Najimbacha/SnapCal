import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../snap_controller.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class AnalyzingOverlay extends StatefulWidget {
  final VoidCallback? onManualEntry;
  const AnalyzingOverlay({super.key, this.onManualEntry});

  @override
  State<AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<AnalyzingOverlay> {
  // Rotating message index
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    // Rotate messages every 2.2 seconds to keep user engaged
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          if (_messageIndex < 6) { // 7 steps total, index 0 to 6
            _messageIndex++;
          } else {
            // Keep looping the last couple of messages if API is extremely slow
            _messageIndex = 5;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapController>();
    final imageBytes = controller.capturedImageBytes;
    final l10n = AppLocalizations.of(context)!;
    final scanSteps = [
      l10n.scan_step_uploading,
      l10n.scan_step_scanning,
      l10n.scan_step_ingredients,
      l10n.scan_step_portions,
      l10n.scan_step_calories,
      l10n.scan_step_macros,
      l10n.scan_step_finalizing,
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Semi-Clear Source Image ──
          if (imageBytes != null)
            Positioned.fill(
              child: Image.memory(imageBytes, fit: BoxFit.cover),
            ),

          // Subtle Dark Overlay (No heavy blur to keep context of the food they snapped)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // ── Neural Scan Layer (Points & Laser) ──
          const Positioned.fill(child: _NeuralScanEffects()),

          // ── Premium Content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── AI Scanner Animation ──
                const _ScannerStatus().animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 40),

                // ── Dynamic Glass Card for visibility ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Core Header
                            Text(
                              l10n.scan_overlay_scanning.toUpperCase(),
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 2. Glowing Fake Progress Bar
                            _GlowingProgressBar(
                              duration: const Duration(seconds: 15),
                            ),
                            const SizedBox(height: 24),

                            // 3. Dynamic Rotating Text
                            Container(
                              height: 44, // Constant height to prevent layout shifts
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.2),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  scanSteps[_messageIndex],
                                  key: ValueKey<int>(_messageIndex),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white,
                                    height: 1.4,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Manual Fallback (Subtle button) ──
                if (widget.onManualEntry != null)
                  _ManualFallbackButton(
                    onTap: widget.onManualEntry!,
                  ).animate().fadeIn(delay: 2000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerStatus extends StatelessWidget {
  const _ScannerStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 1500.ms)
              .fadeOut(duration: 1500.ms),

          // Spinning Indicator
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          
          // Center Icon
          const Icon(LucideIcons.scan, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class _GlowingProgressBar extends StatelessWidget {
  final Duration duration;
  const _GlowingProgressBar({required this.duration});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 0.96),
      duration: duration,
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Column(
          children: [
            // Linear progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.5),
                            AppColors.primary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "${(value * 100).toInt()}%",
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
        ...List.generate(
          8,
          (index) => _NeuralNode(
            delay: (index * 300).ms,
            alignment: Alignment(
              (index % 4 == 0) ? -0.5 : (index % 3 == 0 ? 0.4 : (index % 2 == 0 ? -0.2 : 0.6)),
              (index % 3 == 0) ? -0.4 : (index % 2 == 0 ? 0.3 : (index % 4 == 0 ? -0.6 : 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LaserSweep extends StatelessWidget {
  const _LaserSweep();

  @override
  Widget build(BuildContext context) {
    return Container()
        .animate(onPlay: (c) => c.repeat())
        .custom(
          duration: 3.seconds,
          builder: (context, value, child) {
            return Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height * value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withValues(alpha: 0.5),
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.5),
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.8),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .scale(
            delay: delay,
            duration: 1200.ms,
            begin: const Offset(0.1, 0.1),
            end: const Offset(1.2, 1.2),
          )
          .fadeOut(delay: delay + 800.ms, duration: 400.ms),
    );
  }
}

class _ManualFallbackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManualFallbackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          l10n.scan_overlay_manual.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
