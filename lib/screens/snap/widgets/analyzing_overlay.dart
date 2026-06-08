import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../snap_controller.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class AnalyzingOverlay extends StatefulWidget {
  final VoidCallback? onManualEntry;
  const AnalyzingOverlay({super.key, this.onManualEntry});

  @override
  State<AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<AnalyzingOverlay>
    with TickerProviderStateMixin {
  int _messageIndex = 0;
  Timer? _messageTimer;
  Timer? _timeoutHintTimer;
  bool _showTimeoutHint = false;
  List<String> _statusMessages = [];
  late AnimationController _pulseController;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        if (_statusMessages.isEmpty) return;
        setState(() {
          _messageIndex = (_messageIndex + 1) % _statusMessages.length;
        });
      }
    });

    _timeoutHintTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showTimeoutHint = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      _statusMessages = [
        l10n.scan_step_uploading,
        l10n.scan_step_scanning,
        l10n.scan_step_ingredients,
        l10n.scan_step_calories,
        l10n.scan_step_finalizing,
      ];
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _timeoutHintTimer?.cancel();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapController>();
    final imageBytes = controller.capturedImageBytes;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo background
          if (imageBytes != null)
            Positioned.fill(child: Image.memory(imageBytes, fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.55),
                    const Color(0xFF0A0A0A),
                  ],
                  stops: const [0, 0.35, 0.7],
                ),
              ),
            ),
          ),

          // Close button
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.30),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Premium analyzing UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated scanning icon
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring pulse
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                      ).animate(controller: _pulseController).scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.08, 1.08),
                        curve: Curves.easeInOut,
                      ),
                      // Middle ring
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      // Scanning arc
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _scanController.value * 2 * pi,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: CustomPaint(
                            painter: _ScanArcPainter(),
                          ),
                        ),
                      ),
                      // Inner icon
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.brain,
                          color: Colors.white,
                          size: 24,
                        ),
                      ).animate(controller: _pulseController).scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.05, 1.05),
                        curve: Curves.easeInOut,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Analyzing text
                const Text(
                  'AI Analyzing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Identifying food & estimating nutrition',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Bottom status bar
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
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
                    _statusMessages.isNotEmpty ? _statusMessages[_messageIndex] : '',
                    key: ValueKey<int>(_messageIndex),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Timeout hint (Case D)
                AnimatedOpacity(
                  opacity: _showTimeoutHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: _showTimeoutHint
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            "Can't identify? Try Manual Search.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Manual entry link
                if (widget.onManualEntry != null)
                  GestureDetector(
                    onTap: widget.onManualEntry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.scan_overlay_manual.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // Full subtle ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ringPaint);

    // Scanning arc (120 degrees)
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi / 3,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
