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
    barrierColor: Colors.black.withValues(alpha: 0.4),
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
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  // Premium color palette — deep ocean blues
  static const _deepNavy = Color(0xFF0B1A2E);
  static const _surfaceBlue = Color(0xFF142D4C);
  static const _accentBlue = Color(0xFF3B82F6);
  static const _lightBlue = Color(0xFF60A5FA);
  static const _softCyan = Color(0xFF22D3EE);
  static const _textWhite = Color(0xFFF0F4F8);
  static const _textMuted = Color(0xFF8BA3BE);
  static const _glassWhite = Color(0x15FFFFFF);
  static const _glassBorder = Color(0x20FFFFFF);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _riseAnimation = CurvedAnimation(
      parent: _riseController,
      curve: Curves.easeOutCubic,
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    final water = context.read<WaterProvider>();
    _fromMl = water.todaysWaterMl;

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTimeAgo();
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _riseController.dispose();
    _entranceController.dispose();
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
    HapticFeedback.mediumImpact();

    setState(() {
      _isFilling = true;
      _fromMl = water.todaysWaterMl;
    });

    await water.addWater(_selectedMl);

    if (!mounted) return;
    _lastDrinkTime = DateTime.now();
    _updateTimeAgo();

    _riseController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));

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
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isFilling = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topSafe = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<WaterProvider>(
      builder: (context, water, _) {
        final actualMl = water.todaysWaterMl;
        final goalMl = water.goal;

        return AnimatedBuilder(
          animation: Listenable.merge([
            _waveController,
            _riseController,
            _entranceController,
          ]),
          builder: (context, _) {
            final displayMl = _riseController.isAnimating
                ? _fromMl + (actualMl - _fromMl) * _riseAnimation.value
                : actualMl.toDouble();
            final visualProgress =
                (displayMl / math.max(goalMl, 1)).clamp(0.0, 1.0);
            final isGoalReached = actualMl >= goalMl;

            return SafeArea(
              top: false,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                    child: Container(
                      height: screenHeight * 0.72,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _surfaceBlue,
                            _deepNavy,
                          ],
                        ),
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
                            top: (1 - visualProgress) * screenHeight * 0.72 - 80,
                            height: 200,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(0.5, 1),
                                    radius: 1.5,
                                    colors: [
                                      _accentBlue.withValues(
                                          alpha: 0.08 + visualProgress * 0.06),
                                      _accentBlue.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── Top shimmer line ──
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _accentBlue.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Success glow ──
                          if (isGoalReached)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 0.8,
                                      colors: [
                                        _softCyan.withValues(alpha: 0.06),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // ── Content overlay ──
                          Column(
                            children: [
                              // ── Top bar ──
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 8,
                                  right: 16,
                                  top: topSafe + 8,
                                ),
                                child: Row(
                                  children: [
                                    _GlassButton(
                                      icon: Icons.close_rounded,
                                      onTap: () => Navigator.of(context).pop(),
                                    ),
                                    const Spacer(),
                                    _TodayBadge(),
                                  ],
                                ),
                              ),

                              const Spacer(flex: 2),

                              // ── Main value display ──
                              Column(
                                children: [
                                  // Water drop icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _accentBlue.withValues(alpha: 0.2),
                                          _softCyan.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: _accentBlue.withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.water_drop_rounded,
                                      color: _lightBlue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _formatMl(displayMl),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w200,
                                      color: _textWhite,
                                      height: 0.95,
                                      letterSpacing: -2.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'of ${_formatMl(goalMl.toDouble())} daily goal',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _textMuted,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // Progress ring
                                  _ProgressRing(
                                    progress: visualProgress,
                                    isGoalReached: isGoalReached,
                                  ),
                                ],
                              ),

                              const Spacer(flex: 3),

                              // ── Bottom controls ──
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                    24, 0, 24, 12 + bottomInset),
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
                                                HapticFeedback.selectionClick();
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _CustomPill(
                                          isOpen: _isCustomOpen,
                                          selectedMl: _customOptions
                                                  .contains(_selectedMl)
                                              ? _selectedMl
                                              : null,
                                          onTap: () {
                                            setState(() =>
                                                _isCustomOpen = !_isCustomOpen);
                                          },
                                        ),
                                      ],
                                    ),

                                    // Custom picker
                                    if (_isCustomOpen) ...[
                                      const SizedBox(height: 8),
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

                                    const SizedBox(height: 16),

                                    // Add button
                                    GestureDetector(
                                      onTap: _isFilling
                                          ? null
                                          : () => _addWater(water),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        width: double.infinity,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _accentBlue,
                                              _accentBlue.withValues(alpha: 0.85),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _accentBlue
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: _isFilling
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.2),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.add_rounded,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Add $_selectedMl ml',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Helper text
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_timeAgo.isNotEmpty) ...[
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _lightBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          _timeAgo.isEmpty
                                              ? 'Start your hydration journey'
                                              : 'Last drink $_timeAgo',
                                          style: TextStyle(
                                            color: _textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (_lastAddMl != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: GestureDetector(
                                          onTap: _isFilling
                                              ? null
                                              : () => _undoAdd(water),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _accentBlue
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: _accentBlue
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.undo_rounded,
                                                  size: 13,
                                                  color: _lightBlue,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Undo +$_lastAddMl ml',
                                                  style: TextStyle(
                                                    color: _lightBlue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

// ── Glass button ──

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _HydrationSheetState._glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _HydrationSheetState._glassBorder,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: _HydrationSheetState._textWhite,
        ),
      ),
    );
  }
}

// ── Today badge ──

class _TodayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _HydrationSheetState._glassWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _HydrationSheetState._glassBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _HydrationSheetState._lightBlue,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Today',
            style: TextStyle(
              color: _HydrationSheetState._textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress ring ──

class _ProgressRing extends StatelessWidget {
  final double progress;
  final bool isGoalReached;

  const _ProgressRing({required this.progress, required this.isGoalReached});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          isGoalReached: isGoalReached,
        ),
        child: Center(
          child: Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isGoalReached
                  ? _HydrationSheetState._softCyan
                  : _HydrationSheetState._lightBlue,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isGoalReached;

  _RingPainter({required this.progress, required this.isGoalReached});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = _HydrationSheetState._glassWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: isGoalReached
            ? [
                _HydrationSheetState._softCyan,
                _HydrationSheetState._accentBlue,
              ]
            : [
                _HydrationSheetState._accentBlue,
                _HydrationSheetState._lightBlue,
              ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isGoalReached != isGoalReached;
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? _HydrationSheetState._accentBlue.withValues(alpha: 0.15)
              : _HydrationSheetState._glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _HydrationSheetState._accentBlue.withValues(alpha: 0.35)
                : _HydrationSheetState._glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _HydrationSheetState._accentBlue
                        .withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$ml',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? _HydrationSheetState._lightBlue
                  : _HydrationSheetState._textWhite,
              letterSpacing: -0.3,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 72,
        height: 42,
        decoration: BoxDecoration(
          color: isOpen
              ? _HydrationSheetState._accentBlue.withValues(alpha: 0.15)
              : _HydrationSheetState._glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen
                ? _HydrationSheetState._accentBlue.withValues(alpha: 0.35)
                : _HydrationSheetState._glassBorder,
            width: isOpen ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            selectedMl != null ? '$selectedMl' : 'Custom',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isOpen
                  ? _HydrationSheetState._lightBlue
                  : _HydrationSheetState._textMuted,
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
        color: _HydrationSheetState._glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _HydrationSheetState._glassBorder,
          width: 0.5,
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options
            .map(
              (ml) => GestureDetector(
                onTap: () => onSelect(ml),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: (MediaQuery.of(context).size.width - 120) / 6,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selectedMl == ml
                        ? _HydrationSheetState._accentBlue.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedMl == ml
                          ? _HydrationSheetState._accentBlue
                              .withValues(alpha: 0.3)
                          : _HydrationSheetState._glassBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$ml',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedMl == ml
                            ? _HydrationSheetState._lightBlue
                            : _HydrationSheetState._textMuted,
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

    // Water body gradient — deeper, richer blues
    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.06),
          const Color(0xFF3B82F6).withValues(alpha: 0.12),
          const Color(0xFF22D3EE).withValues(alpha: 0.15),
          const Color(0xFF3B82F6).withValues(alpha: 0.20),
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
          8;
      final s2 = math.sin((x / size.width * 5 * math.pi) +
              wavePhase * 3 * math.pi) *
          4;
      path.lineTo(x, fillH + s1 + s2);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, waterPaint);

    // Secondary wave layer for depth
    final wave2Paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF60A5FA).withValues(alpha: 0.03),
          const Color(0xFF60A5FA).withValues(alpha: 0.08),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
          Rect.fromLTWH(0, fillH + 10, size.width, size.height - fillH - 10));

    final wave2Path = Path();
    wave2Path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 4 * math.pi) +
              wavePhase * 2 * math.pi +
              1.5) *
          5;
      final s2 = math.sin((x / size.width * 7 * math.pi) +
              wavePhase * 3 * math.pi +
              0.8) *
          2.5;
      wave2Path.lineTo(x, fillH + 8 + s1 + s2);
    }
    wave2Path.lineTo(size.width, size.height);
    wave2Path.close();
    canvas.drawPath(wave2Path, wave2Paint);

    // Wave glow line — more prominent
    final glowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final glowPath = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 3 * math.pi) +
              wavePhase * 2 * math.pi) *
          8;
      final s2 = math.sin((x / size.width * 5 * math.pi) +
              wavePhase * 3 * math.pi) *
          4;
      if (x == 0) {
        glowPath.moveTo(x, fillH + s1 + s2);
      } else {
        glowPath.lineTo(x, fillH + s1 + s2);
      }
    }
    canvas.drawPath(glowPath, glowPaint);

    // Subtle bubbles in water
    if (progress > 0.05) {
      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12);
      for (int i = 0; i < 8; i++) {
        final dx = (i * 47.0 + wavePhase * 50) % size.width;
        final waterBottom = size.height;
        final waterTop = fillH;
        final dy =
            waterTop + (waterBottom - waterTop) * (0.15 + (i % 5) * 0.15);
        final r = 1.0 + (i % 3) * 0.6;
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
