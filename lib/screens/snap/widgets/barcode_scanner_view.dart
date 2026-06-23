import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.all],
  );
  bool _isProcessing = false;

  @override
  void dispose() {
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
              setState(() => _isProcessing = true);
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

          // Barcode guide brackets
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.72,
              height: 170,
              child: CustomPaint(
                painter: _BarcodeBracketPainter(
                  color: Colors.white.withValues(alpha: 0.5),
                  strokeWidth: 2,
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
                child: Icon(LucideIcons.x, color: Colors.white, size: 18),
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
                _iconButton(LucideIcons.zap, () => _controller.toggleTorch()),
                const SizedBox(width: 32),
                _iconButton(LucideIcons.refreshCw, () => _controller.switchCamera()),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    final paint = Paint()
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
      Path()..moveTo(0, cl)..lineTo(0, r)..quadraticBezierTo(0, 0, r, 0)..lineTo(cl, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()..moveTo(w - cl, 0)..lineTo(w - r, 0)..quadraticBezierTo(w, 0, w, r)..lineTo(w, cl),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()..moveTo(0, h - cl)..lineTo(0, h - r)..quadraticBezierTo(0, h, r, h)..lineTo(cl, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()..moveTo(w - cl, h)..lineTo(w - r, h)..quadraticBezierTo(w, h, w, h - r)..lineTo(w, h - cl),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BarcodeBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}

