import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:snapcal/l10n/generated/app_localizations.dart';

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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.72,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _RoundButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: widget.onCancel,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.snap_scan_barcode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.snap_barcode_hint,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 28,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundButton(
                  icon: LucideIcons.zap,
                  label: AppLocalizations.of(context)!.snap_torch,
                  onTap: _controller.toggleTorch,
                ),
                const SizedBox(width: 16),
                _RoundButton(
                  icon: LucideIcons.refreshCw,
                  label: AppLocalizations.of(context)!.snap_flip,
                  onTap: _controller.switchCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(label!, style: const TextStyle(color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}
