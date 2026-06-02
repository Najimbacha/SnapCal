import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

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
  int _messageIndex = 0;
  Timer? _messageTimer;
  List<String> _statusMessages = [];

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        if (_statusMessages.isEmpty) return;
        setState(() {
          _messageIndex = (_messageIndex + 1) % _statusMessages.length;
        });
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
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.50),
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

          // Result preview skeleton
            Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  _buildShimmerBar(width: 120, height: 18),
                  const SizedBox(height: 4),
                  _buildShimmerBar(width: 160, height: 12),
                  const SizedBox(height: 20),

                  // Calorie number skeleton
                  _buildShimmerBar(width: 100, height: 32),
                  const SizedBox(height: 4),
                  _buildShimmerBar(width: 80, height: 12),
                  const SizedBox(height: 20),

                  // Macro preview skeleton (3 columns)
                  Row(
                    children: [
                      _macroShimmer(),
                      const SizedBox(width: 8),
                      _macroShimmer(),
                      const SizedBox(width: 8),
                      _macroShimmer(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Food items skeleton (2 rows)
                  _foodRowShimmer(),
                  const SizedBox(height: 10),
                  _foodRowShimmer(),
                  const SizedBox(height: 20),

                  // Button skeleton
                  _buildShimmerBar(width: double.infinity, height: 50, radius: 12),
                  const SizedBox(height: 14),

                  // Status + manual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      if (widget.onManualEntry != null)
                        GestureDetector(
                          onTap: widget.onManualEntry,
                          child: Text(
                            AppLocalizations.of(context)!.scan_overlay_manual.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBar({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 1800.ms,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }

  Widget _macroShimmer() {
    return Expanded(
      child: Column(
        children: [
          _buildShimmerBar(width: double.infinity, height: 8),
          const SizedBox(height: 6),
          _buildShimmerBar(width: 30, height: 10),
        ],
      ),
    );
  }

  Widget _foodRowShimmer() {
    return Row(
      children: [
        _buildShimmerBar(width: 16, height: 16, radius: 8),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBar(width: 140, height: 14),
              const SizedBox(height: 4),
              _buildShimmerBar(width: 80, height: 10),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildShimmerBar(width: 50, height: 14),
      ],
    );
  }
}
