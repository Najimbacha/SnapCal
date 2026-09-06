import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../snap_controller.dart';

class AnalyzingOverlay extends StatefulWidget {
  final SnapController controller;
  final VoidCallback? onManualEntry;
  const AnalyzingOverlay({
    super.key,
    required this.controller,
    this.onManualEntry,
  });
  @override
  State<AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<AnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  Timer? _patience;
  bool _longWait = false;
  bool _reducedMotion = false;
  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _patience = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _longWait = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _motion.stop();
      _motion.value = 0.35;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _patience?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF151918) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF17251F);
    final muted = dark ? const Color(0xFFB4C2BA) : const Color(0xFF56675D);
    return Scaffold(
      backgroundColor: surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Short screens and large accessibility text can scroll without clipping.
          final photoHeight = (constraints.maxHeight * 0.59).clamp(
            240.0,
            600.0,
          );
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(
                    height: photoHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0xFF101613)),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            MediaQuery.paddingOf(context).top + 72,
                            20,
                            32,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: _PhotoScan(
                                bytes: widget.controller.capturedImageBytes,
                                motion: _motion,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.paddingOf(context).top + 8,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.scanLine,
                                color: AppColors.emeraldLight,
                                size: 23,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: SizedBox(
                                  height: 32,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      'SnapCal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('analyzing-close-button'),
                                tooltip:
                                    MaterialLocalizations.of(
                                      context,
                                    ).closeButtonTooltip,
                                onPressed:
                                    () => Navigator.of(context).maybePop(),
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.10,
                                  ),
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: const Icon(LucideIcons.x, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      28,
                      28,
                      MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: _ActivityRibbon(motion: _motion),
                            ),
                            const SizedBox(height: 22),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                l10n.scan_overlay_scanning,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: Duration(
                                milliseconds: _reducedMotion ? 0 : 300,
                              ),
                              child: Text(
                                _longWait
                                    ? l10n.scan_wait_longer
                                    : l10n.scan_wait_stay,
                                key: ValueKey(_longWait),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 14,
                                  height: 1.5,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            if (_longWait && widget.onManualEntry != null) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                key: const ValueKey('analyzing-manual-entry'),
                                onPressed: widget.onManualEntry,
                                icon: const Icon(LucideIcons.pencil, size: 16),
                                label: Text(
                                  l10n.scan_overlay_manual,
                                  textAlign: TextAlign.center,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ink,
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoScan extends StatelessWidget {
  final Uint8List? bytes;
  final Animation<double> motion;
  const _PhotoScan({required this.bytes, required this.motion});
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (bytes != null)
        Image.memory(
          bytes!,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, error, stack) => const _PhotoPlaceholder(),
        )
      else
        const _PhotoPlaceholder(),
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ScanPainter(motion)),
          ),
        ),
      ),
    ],
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(LucideIcons.utensils, size: 64, color: AppColors.emeraldLight),
  );
}

// Decorative activity, not percentages or invented recognition milestones.
class _ScanPainter extends CustomPainter {
  final Animation<double> motion;
  _ScanPainter(this.motion) : super(repaint: motion);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(8);
    final paint =
        Paint()
          ..color = AppColors.emeraldLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
    for (final corner in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      final p = corner.$1;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy + 22 * corner.$3)
          ..lineTo(p.dx, p.dy + 6 * corner.$3)
          ..quadraticBezierTo(p.dx, p.dy, p.dx + 6 * corner.$2, p.dy)
          ..lineTo(p.dx + 22 * corner.$2, p.dy),
        paint,
      );
    }
    final travel = (1 - math.cos(motion.value * math.pi * 2)) / 2;
    final y = rect.top + rect.height * travel;
    canvas.save();
    canvas.clipRect(rect);
    final band = Rect.fromLTRB(rect.left, y - 45, rect.right, y + 45);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(rect.left + 8, y),
      Offset(rect.right - 8, y),
      Paint()
        ..color = AppColors.emeraldLight.withValues(alpha: 0.8)
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScanPainter oldDelegate) => oldDelegate.motion != motion;
}

class _ActivityRibbon extends StatelessWidget {
  final Animation<double> motion;
  const _ActivityRibbon({required this.motion});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: AnimatedBuilder(
      animation: motion,
      builder:
          (context, child) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(21, (i) {
              final wave =
                  (math.sin(i * 0.5 - motion.value * math.pi * 2) + 1) / 2;
              return Container(
                width: 4,
                height: 8 + wave * 26,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:
                      i < 7
                          ? AppColors.primary
                          : i < 14
                          ? AppColors.emeraldLight
                          : AppColors.warningAmber,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
    ),
  );
}
