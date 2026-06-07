import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/water_provider.dart';

void showHydrationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => const _HydrationSheet(),
  );
}

class _HydrationSheet extends StatefulWidget {
  const _HydrationSheet();

  @override
  State<_HydrationSheet> createState() => _HydrationSheetState();
}

class _HydrationSheetState extends State<_HydrationSheet>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _riseController;
  late Animation<double> _riseAnimation;

  int _selectedMl = 250;
  int _fromMl = 0;
  bool _isFilling = false;
  bool _isCustomOpen = false;

  DateTime? _lastDrinkTime;
  Timer? _clockTimer;
  String _timeAgo = '';

  int? _lastAddMl;
  Timer? _undoTimer;

  static const _presets = [100, 250, 500];
  static const _customOptions = [50, 100, 150, 200, 300, 750];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _riseAnimation = CurvedAnimation(
      parent: _riseController,
      curve: Curves.easeOutCubic,
    );

    final water = context.read<WaterProvider>();
    _fromMl = water.todaysWaterMl;

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTimeAgo();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _riseController.dispose();
    _clockTimer?.cancel();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _updateTimeAgo() {
    if (_lastDrinkTime == null) {
      if (mounted) setState(() => _timeAgo = '');
      return;
    }
    final diff = DateTime.now().difference(_lastDrinkTime!);
    final minutes = diff.inMinutes;
    String text;
    if (minutes < 1) {
      text = 'Just now';
    } else if (minutes < 60) {
      text = '$minutes min ago';
    } else {
      text = '${minutes ~/ 60}h ago';
    }
    if (mounted) setState(() => _timeAgo = text);
  }

  Future<void> _addWater(WaterProvider water) async {
    if (_isFilling) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isFilling = true;
      _fromMl = water.todaysWaterMl;
    });

    await water.addWater(_selectedMl);

    if (!mounted) return;
    _lastDrinkTime = DateTime.now();
    _updateTimeAgo();

    _riseController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isFilling = false);

    _undoTimer?.cancel();
    _lastAddMl = _selectedMl;
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _lastAddMl = null);
    });
    if (mounted) setState(() {});

    if (water.todaysWaterMl >= water.goal) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _undoAdd(WaterProvider water) async {
    if (_lastAddMl == null || _isFilling) return;
    _undoTimer?.cancel();
    _lastAddMl = null;

    HapticFeedback.lightImpact();
    setState(() {
      _isFilling = true;
      _fromMl = water.todaysWaterMl;
    });

    await water.removeWater(0);

    if (!mounted) return;
    if (water.todaysWaterMl <= 0) {
      _lastDrinkTime = null;
      _timeAgo = '';
    }
    _riseController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isFilling = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topSafe = MediaQuery.of(context).padding.top;

    return Consumer<WaterProvider>(
      builder: (context, water, _) {
        final actualMl = water.todaysWaterMl;
        final goalMl = water.goal;

        return AnimatedBuilder(
          animation: Listenable.merge([_waveController, _riseController]),
          builder: (context, _) {
            final displayMl = _riseController.isAnimating
                ? _fromMl +
                    (actualMl - _fromMl) * _riseAnimation.value
                : actualMl.toDouble();
            final visualProgress =
                (displayMl / math.max(goalMl, 1)).clamp(0.0, 1.0);
            final isGoalReached = actualMl >= goalMl;

            return SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28)),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.62,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCFCFA),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28)),
                  ),
                  child: Stack(
                    children: [
                      // ── Water fill layer ──
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WaterWavePainter(
                            progress: visualProgress,
                            wavePhase: _waveController.value,
                            isGoalReached: isGoalReached,
                          ),
                        ),
                      ),

                      // ── Ambient glow near water surface ──
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (1 - visualProgress) *
                                MediaQuery.of(context).size.height *
                                0.62 -
                            60,
                        height: 160,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0.5, 1),
                                radius: 1.5,
                                colors: [
                                  const Color(0xFF3B82F6).withOpacity(
                                      0.10 + visualProgress * 0.08),
                                  const Color(0xFF3B82F6).withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Success glow ──
                      if (isGoalReached)
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, _) {
                            final pulse =
                                0.3 + _waveController.value * 0.15;
                            return Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(pulse * 0.06),
                                ),
                              ),
                            );
                          },
                        ),

                      // ── Content overlay ──
                      Column(
                        children: [
                          // Top bar
                          Padding(
                            padding: EdgeInsets.only(
                              left: 4,
                              right: 12,
                              top: topSafe + 4,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  icon: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.04),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF1C1917),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _TodayBadge(),
                              ],
                            ),
                          ),

                          // ── Main value area ──
                          const Spacer(),

                          Text(
                            _formatMl(displayMl),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w200,
                              color: Color(0xFF1C1917),
                              height: 0.95,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'of ${_formatMl(goalMl.toDouble())}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFB4AFA8),
                            ),
                          ),

                          const Spacer(flex: 2),

                          // ── Bottom controls ──
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      20, 0, 20, 8 + bottomInset),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Preset row
                                      Row(
                                        children: [
                                          ..._presets.map(
                                            (ml) => Expanded(
                                              child: _PresetPill(
                                                ml: ml,
                                                isSelected: _selectedMl == ml,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedMl = ml;
                                                    _isCustomOpen = false;
                                                  });
                                                  HapticFeedback
                                                      .selectionClick();
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _CustomPill(
                                            isOpen: _isCustomOpen,
                                            selectedMl:
                                                _customOptions
                                                        .contains(_selectedMl)
                                                    ? _selectedMl
                                                    : null,
                                            onTap: () {
                                              setState(() =>
                                                  _isCustomOpen =
                                                      !_isCustomOpen);
                                            },
                                          ),
                                        ],
                                      ),

                                      // Custom picker
                                      if (_isCustomOpen) ...[
                                        const SizedBox(height: 6),
                                        _CustomPickerGrid(
                                          options: _customOptions,
                                          selectedMl: _selectedMl,
                                          onSelect: (ml) {
                                            setState(() {
                                              _selectedMl = ml;
                                              _isCustomOpen = false;
                                            });
                                            HapticFeedback.selectionClick();
                                          },
                                        ),
                                      ],

                                      const SizedBox(height: 12),

                                      // Add button
                                      GestureDetector(
                                        onTap: _isFilling
                                            ? null
                                            : () => _addWater(water),
                                        child: Container(
                                          width: double.infinity,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: _isFilling
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.2),
                                                          shape: BoxShape
                                                              .circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.add_rounded,
                                                          color: Colors.white,
                                                          size: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 6),
                                                      Text(
                                                        'Add $_selectedMl ml',
                                                        style:
                                                            const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      // Helper text
                                      Text(
                                        _timeAgo.isEmpty
                                            ? 'No water logged yet today'
                                            : 'Last drink $_timeAgo',
                                        style: const TextStyle(
                                          color: Color(0xFFB4AFA8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      if (_lastAddMl != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: GestureDetector(
                                            onTap: _isFilling
                                                ? null
                                                : () => _undoAdd(water),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.undo_rounded,
                                                  size: 12,
                                                  color: const Color(
                                                      0xFF3B82F6),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Undo +$_lastAddMl ml',
                                                  style: const TextStyle(
                                                    color: Color(0xFF3B82F6),
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatMl(double ml) {
    if (ml >= 1000) {
      return '${(ml / 1000).toStringAsFixed(1)}L';
    }
    return '${ml.round()} ml';
  }
}

// ── Today badge ──

class _TodayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Today',
            style: TextStyle(
              color: Color(0xFF78716C),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preset pill ──

class _PresetPill extends StatelessWidget {
  final int ml;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetPill({
    required this.ml,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6).withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$ml',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF1C1917),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom pill ──

class _CustomPill extends StatelessWidget {
  final bool isOpen;
  final int? selectedMl;
  final VoidCallback onTap;

  const _CustomPill({
    required this.isOpen,
    required this.selectedMl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 38,
        decoration: BoxDecoration(
          color: isOpen
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen
                ? const Color(0xFF3B82F6).withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            width: isOpen ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            selectedMl != null ? '$selectedMl' : 'Custom',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOpen
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF78716C),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom picker grid ──

class _CustomPickerGrid extends StatelessWidget {
  final List<int> options;
  final int selectedMl;
  final ValueChanged<int> onSelect;

  const _CustomPickerGrid({
    required this.options,
    required this.selectedMl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: options
            .map(
              (ml) => GestureDetector(
                onTap: () => onSelect(ml),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 108) / 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedMl == ml
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedMl == ml
                          ? const Color(0xFF3B82F6).withOpacity(0.3)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$ml',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selectedMl == ml
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF1C1917),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Water Wave Painter ──

class _WaterWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final bool isGoalReached;

  _WaterWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.isGoalReached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fillH = size.height * (1 - progress);

    // Water body gradient
    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF3B82F6).withOpacity(0.12),
          const Color(0xFF3B82F6).withOpacity(0.20),
          const Color(0xFF3B82F6).withOpacity(0.30),
          const Color(0xFF3B82F6).withOpacity(0.40),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
          Rect.fromLTWH(0, fillH, size.width, size.height - fillH));

    // Water body path
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 3 * math.pi) +
              wavePhase * 2 * math.pi) *
          6;
      final s2 = math.sin((x / size.width * 5 * math.pi) +
              wavePhase * 3 * math.pi) *
          3;
      path.lineTo(x, fillH + s1 + s2);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, waterPaint);

    // Wave glow line
    final glowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final glowPath = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 3 * math.pi) +
              wavePhase * 2 * math.pi) *
          6;
      final s2 = math.sin((x / size.width * 5 * math.pi) +
              wavePhase * 3 * math.pi) *
          3;
      if (x == 0) {
        glowPath.moveTo(x, fillH + s1 + s2);
      } else {
        glowPath.lineTo(x, fillH + s1 + s2);
      }
    }
    canvas.drawPath(glowPath, glowPaint);

    // Subtle bubbles in water
    if (progress > 0.05) {
      final bubblePaint =
          Paint()..color = Colors.white.withOpacity(0.18);
      for (int i = 0; i < 6; i++) {
        final dx = (i * 53.0 + wavePhase * 40) % size.width;
        final waterBottom = size.height;
        final waterTop = fillH;
        final dy = waterTop +
            (waterBottom - waterTop) * (0.2 + (i % 4) * 0.2);
        final r = 1.2 + (i % 3) * 0.8;
        canvas.drawCircle(
          Offset(dx, dy.clamp(waterTop + 2, waterBottom - 2)),
          r,
          bubblePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WaterWavePainter old) =>
      old.progress != progress ||
      old.wavePhase != wavePhase ||
      old.isGoalReached != isGoalReached;
}
