import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_motion.dart';
import '../../../widgets/motion/reveal.dart';
import '../../../widgets/wazn_icons.dart';

class BarcodeScannerView extends StatefulWidget {
  final Function(String barcode) onBarcodeDetected;
  final VoidCallback onCancel;

  const BarcodeScannerView({
    super.key,
    required this.onBarcodeDetected,
    required this.onCancel,
  });

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView>
    with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.all],
  );
  bool _isProcessing = false;

  /// The red line sweeping the frame while it looks for a code.
  late final AnimationController _laser;

  /// The frame turning green and swelling once a code is read.
  late final AnimationController _found;

  @override
  void initState() {
    super.initState();
    _laser = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _found = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _laser.value = .5;
    } else if (!_laser.isAnimating && !_isProcessing) {
      _laser.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _laser.dispose();
    _found.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code == null) return;
              HapticFeedback.mediumImpact();
              setState(() => _isProcessing = true);
              _laser.stop();
              _found.forward(from: 0);
              widget.onBarcodeDetected(code);
            },
          ),

          // Subtle gradient overlay
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0, 0.3, 1],
                  ),
                ),
              ),
            ),
          ),

          // Barcode guide brackets. They arrive tall, as the photo frame
          // was, and settle into a wide strip for a barcode.
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.maybeZero(
                context,
                const Duration(milliseconds: 620),
              ),
              curve: AppMotion.springCurve,
              builder: (context, settle, _) {
                final width = MediaQuery.of(context).size.width;
                return AnimatedBuilder(
                  animation: Listenable.merge([_laser, _found]),
                  builder: (context, _) {
                    final found = _found.value;
                    final swell = 1 + 0.06 * (found * (1 - found) * 4);
                    return Transform.scale(
                      scale: swell,
                      child: SizedBox(
                        key: const ValueKey('barcode-frame'),
                        width: width * (0.8 - 0.08 * settle),
                        height: 300 - 130 * settle,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _BarcodeBracketPainter(
                                  color:
                                      Color.lerp(
                                        Colors.white.withValues(alpha: 0.5),
                                        const Color(0xFF34D399),
                                        (found * 2).clamp(0.0, 1.0),
                                      )!,
                                  strokeWidth: 2 + found,
                                ),
                              ),
                            ),
                            if (!_isProcessing)
                              Positioned(
                                left: 14,
                                right: 14,
                                top:
                                    18 +
                                    (height(settle) - 36) *
                                        Curves.easeInOut.transform(
                                          _laser.value,
                                        ),
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5A4E),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF5A4E,
                                        ).withValues(alpha: 0.7),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.32),
            child: Reveal(
              delay: const Duration(milliseconds: 300),
              offset: const Offset(0, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  AppLocalizations.of(context)!.snap_barcode_hint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(WaznIcons.close, color: Colors.white, size: 18),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconButton(WaznIcons.flash, () => _controller.toggleTorch()),
                const SizedBox(width: 32),
                _iconButton(
                  WaznIcons.refresh,
                  () => _controller.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double height(double settle) => 300 - 130 * settle;

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _BarcodeBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _BarcodeBracketPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    const cl = 28.0;
    final w = size.width;
    final h = size.height;
    const r = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cl)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(cl, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cl, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, cl),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - cl)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(cl, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cl, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - cl),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BarcodeBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
