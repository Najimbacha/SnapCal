import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../snap_controller.dart';

/// The wait between shutter and result.
///
/// This is the screen that decides whether a scan is finished or abandoned, so
/// it is built around three things a spinner cannot do:
///
///  * **Their own photo is the subject.** The thing the user just made is the
///    most interesting object available; a scan sweep travelling over it makes
///    the machine look like it is reading their food rather than stalling.
///  * **Progress advances and never resets.** Five segments fill in sequence
///    on a decelerating curve, so later stages take longer — the wait feels
///    bounded even though the network is not.
///  * **The escape hatch appears late.** Manual entry stays out of the way for
///    the first ten seconds; offering it immediately invites the user to give
///    up on a scan that was about to succeed.
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
    with TickerProviderStateMixin {
  /// The curve is decelerating, so this is not a promise that the scan ends at
  /// 14s — it is the point past which progress creeps rather than moves.
  static const Duration _expected = Duration(seconds: 14);

  /// Manual entry and the "taking longer" line appear together, once the wait
  /// has stopped feeling normal.
  static const Duration _patience = Duration(seconds: 10);

  late final AnimationController _progress;
  late final AnimationController _sweep;
  late final AnimationController _breathe;

  Timer? _patienceTimer;
  bool _pastPatience = false;

  List<String> _steps = const [];
  int _stepShown = 0;

  @override
  void initState() {
    super.initState();

    _progress = AnimationController(vsync: this, duration: _expected)
      ..addListener(_onProgress)
      ..forward();

    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _patienceTimer = Timer(_patience, () {
      if (mounted) setState(() => _pastPatience = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      _steps = [
        l10n.scan_step_uploading,
        l10n.scan_step_ingredients,
        l10n.scan_step_portions,
        l10n.scan_step_calories,
        l10n.scan_step_finalizing,
      ];
    }
  }

  @override
  void dispose() {
    _patienceTimer?.cancel();
    _progress
      ..removeListener(_onProgress)
      ..dispose();
    _sweep.dispose();
    _breathe.dispose();
    super.dispose();
  }

  /// Eased so the bar decelerates instead of stopping dead, and capped short of
  /// full: the last sliver belongs to the real result, not to a timer.
  double get _value => Curves.easeOutCubic.transform(_progress.value) * 0.97;

  int get _stepIndex {
    if (_steps.isEmpty) return 0;
    final i = (_value * _steps.length).floor();
    return i.clamp(0, _steps.length - 1);
  }

  void _onProgress() {
    final i = _stepIndex;
    if (i != _stepShown) {
      // A tick as each stage lands. Waiting you can feel is waiting you sit
      // through.
      HapticFeedback.selectionClick();
      setState(() => _stepShown = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bytes = widget.controller.capturedImageBytes;
    final media = MediaQuery.of(context);

    return Scaffold(
        backgroundColor: const Color(0xFF07090A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null) _AmbientBackdrop(bytes: bytes),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF07090A).withValues(alpha: 0.72),
                      const Color(0xFF07090A).withValues(alpha: 0.90),
                      const Color(0xFF07090A),
                    ],
                    stops: const [0.0, 0.45, 0.85],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _topBar(context),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: _ScanStage(
                          bytes: bytes,
                          sweep: _sweep,
                          breathe: _breathe,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      26,
                      4,
                      26,
                      media.padding.bottom > 0 ? 8 : 20,
                    ),
                    child: _statusPanel(context, l10n),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: IconButton(
          key: const ValueKey('analyzing-close-button'),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          // The overlay is a layer inside the snap screen, not a route of
          // its own, so this leaves the camera the way the old X did.
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            foregroundColor: Colors.white,
            fixedSize: const Size(38, 38),
            shape: const CircleBorder(),
          ),
          icon: const Icon(LucideIcons.x, size: 18),
        ),
      ),
    );
  }

  // ── Status panel ───────────────────────────────────────────────────────────

  Widget _statusPanel(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.sparkles, size: 15, color: AppColors.primary),
            const SizedBox(width: 7),
            Text(
              l10n.scan_overlay_scanning,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Five segments, filled in order. A single bar hides which stage is
        // running; five make the pipeline legible at a glance.
        AnimatedBuilder(
          animation: _progress,
          builder: (context, _) => _SegmentedProgress(
            value: _value,
            segments: _steps.isEmpty ? 5 : _steps.length,
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 20,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            ),
            child: Text(
              _steps.isEmpty ? '' : _steps[_stepShown],
              key: ValueKey<int>(_stepShown),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),

        // Before ten seconds this reassures; after, it explains. Same slot, so
        // nothing jumps when it changes.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _pastPatience ? l10n.scan_wait_longer : l10n.scan_wait_stay,
            key: ValueKey<bool>(_pastPatience),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),

        // Held back for ten seconds: offering an exit to someone who is not yet
        // impatient only teaches them to take it.
        AnimatedSize(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: (_pastPatience && widget.onManualEntry != null)
              ? Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: OutlinedButton(
                    key: const ValueKey('analyzing-manual-entry'),
                    onPressed: widget.onManualEntry,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n.scan_overlay_manual,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ── Backdrop ─────────────────────────────────────────────────────────────────

/// The photo again, scaled up and pushed far back. Gives the screen the meal's
/// own colour instead of a flat black rectangle.
class _AmbientBackdrop extends StatelessWidget {
  final Uint8List bytes;
  const _AmbientBackdrop({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.35,
      child: Opacity(
        opacity: 0.5,
        child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}

// ── Scan stage ───────────────────────────────────────────────────────────────

/// The photo under a travelling scan line, framed by a reticle.
class _ScanStage extends StatelessWidget {
  final Uint8List? bytes;
  final Animation<double> sweep;
  final Animation<double> breathe;

  const _ScanStage({
    required this.bytes,
    required this.sweep,
    required this.breathe,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
        child: AnimatedBuilder(
          animation: Listenable.merge([sweep, breathe]),
          builder: (context, _) {
            final t = sweep.value;
            // Sweep down, then back up, so the line never teleports home.
            final travel = t < 0.5 ? t * 2 : (1 - t) * 2;
            final glow = 0.35 + 0.35 * Curves.easeInOut.transform(breathe.value);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16 * glow),
                    blurRadius: 44,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bytes != null)
                      Image.memory(
                        bytes!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    else
                      const ColoredBox(color: Color(0xFF14181A)),

                    // The band of light the line drags behind it.
                    Align(
                      alignment: Alignment(0, -1 + 2 * travel),
                      child: SizedBox(
                        height: 150,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0),
                                AppColors.primary.withValues(alpha: 0.22),
                                AppColors.primary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                          child: const SizedBox(width: double.infinity),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(0, -1 + 2 * travel),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0),
                              AppColors.emeraldLight.withValues(alpha: 0.95),
                              AppColors.primary.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.55),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reticle corners, breathing with the glow.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ReticlePainter(
                            color: Colors.white.withValues(alpha: 0.55 * glow + 0.2),
                          ),
                        ),
                      ),
                    ),

                    // Keeps the photo's own highlights from fighting the panel.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.10),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.34),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
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
      ),
    );
  }
}

/// Four corner brackets — the visual grammar of "something is being measured".
class _ReticlePainter extends CustomPainter {
  final Color color;
  const _ReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 16.0;
    const arm = 26.0;
    const radius = 12.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color;

    final l = inset, t = inset;
    final r = size.width - inset, b = size.height - inset;

    void corner(double x, double y, double dx, double dy) {
      final path = Path()
        ..moveTo(x + dx * arm, y)
        ..lineTo(x + dx * radius, y)
        ..quadraticBezierTo(x, y, x, y + dy * radius)
        ..lineTo(x, y + dy * arm);
      canvas.drawPath(path, paint);
    }

    corner(l, t, 1, 1);
    corner(r, t, -1, 1);
    corner(l, b, 1, -1);
    corner(r, b, -1, -1);
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.color != color;
}

// ── Progress ─────────────────────────────────────────────────────────────────

/// Five bars filled left to right. Reads as a pipeline rather than a spinner.
class _SegmentedProgress extends StatelessWidget {
  final double value;
  final int segments;

  const _SegmentedProgress({required this.value, required this.segments});

  @override
  Widget build(BuildContext context) {
    final each = 1 / segments;
    return Row(
      children: [
        for (var i = 0; i < segments; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.white.withValues(alpha: 0.10)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor:
                            ((value - i * each) / each).clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.emeraldLight,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
