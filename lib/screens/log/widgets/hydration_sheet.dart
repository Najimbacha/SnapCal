import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/water_provider.dart';

void showHydrationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HydrationSheet(),
  );
}

class _HydrationSheet extends ConsumerStatefulWidget {
  const _HydrationSheet();
  @override
  ConsumerState<_HydrationSheet> createState() => _HydrationSheetState();
}

class _HydrationSheetState extends ConsumerState<_HydrationSheet> with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _riseCtrl;
  late Animation<double> _riseAnim;

  int _selectedMl = 250;
  bool _isAdding = false;
  int _fromMl = 0;
  int? _lastAddMl;
  Timer? _undoTimer;
  DateTime? _lastDrinkTime;
  Timer? _clockTimer;
  String _timeAgo = '';

  static const _presets = [100, 250, 500];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _riseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _riseAnim = CurvedAnimation(parent: _riseCtrl, curve: Curves.easeOutCubic);
    final waterState = ref.read(waterProvider).valueOrNull;
    _fromMl = waterState?.todayTotal ?? 0;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTimeAgo());
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _riseCtrl.dispose();
    _clockTimer?.cancel();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _updateTimeAgo() {
    if (_lastDrinkTime == null) return;
    final diff = DateTime.now().difference(_lastDrinkTime!);
    if (!mounted) return;
    setState(() => _timeAgo = diff.inMinutes < 1 ? 'Just now' : diff.inMinutes < 60 ? '${diff.inMinutes}min ago' : '${diff.inMinutes ~/ 60}h ago');
  }

  Future<void> _addWater() async {
    if (_isAdding) return;
    HapticFeedback.mediumImpact();
    final state = ref.read(waterProvider).valueOrNull;
    setState(() { _isAdding = true; _fromMl = state?.todayTotal ?? 0; });
    await ref.read(waterProvider.notifier).addWater(_selectedMl);
    if (!mounted) return;
    _lastDrinkTime = DateTime.now();
    _updateTimeAgo();
    _riseCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isAdding = false);
    _undoTimer?.cancel();
    _lastAddMl = _selectedMl;
    _undoTimer = Timer(const Duration(seconds: 6), () { if (mounted) setState(() => _lastAddMl = null); });
    if (mounted) setState(() {});
    final newState = ref.read(waterProvider).valueOrNull;
    if (newState != null && newState.todayTotal >= newState.goal) HapticFeedback.heavyImpact();
  }

  Future<void> _undoAdd() async {
    if (_lastAddMl == null || _isAdding) return;
    _undoTimer?.cancel();
    _lastAddMl = null;
    HapticFeedback.lightImpact();
    final state = ref.read(waterProvider).valueOrNull;
    setState(() { _isAdding = true; _fromMl = state?.todayTotal ?? 0; });
    await ref.read(waterProvider.notifier).removeWater(0);
    if (!mounted) return;
    final newState = ref.read(waterProvider).valueOrNull;
    if (newState != null && newState.todayTotal <= 0) { _lastDrinkTime = null; _timeAgo = ''; }
    _riseCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final b = MediaQuery.of(context).viewInsets.bottom;
    final d = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (ctx, ref, _) {
        final waterState = ref.watch(waterProvider).valueOrNull ?? const WaterState(todayTotal: 0);
        final actual = waterState.todayTotal;
        final goal = waterState.goal;
        final display = _riseCtrl.isAnimating ? _fromMl + (actual - _fromMl) * _riseAnim.value : actual.toDouble();
        final p = (display / goal.clamp(1, goal)).clamp(0.0, 1.0);

        return Container(
          height: 520,
          decoration: BoxDecoration(
            color: d ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_waveCtrl, _riseCtrl]),
                builder: (context, _) => CustomPaint(
                  painter: _WaterWavePainter(progress: p, wavePhase: _waveCtrl.value),
                  size: Size.infinite,
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 36, height: 4, decoration: BoxDecoration(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                            child: Icon(LucideIcons.x, size: 16, color: d ? Colors.white54 : const Color(0xFF8E8E93)),
                          ),
                        ),
                        const Spacer(),
                        Text('Hydration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: d ? Colors.white : const Color(0xFF1C1C1E))),
                        const Spacer(),
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('${display.round()} ml', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: d ? Colors.white : const Color(0xFF1C1C1E), letterSpacing: -2)),
                  Text('of $goal ml', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 80, height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: p, strokeWidth: 4, backgroundColor: (d ? Colors.white : Colors.black).withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
                        Text('${(p * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + b),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: (d ? Colors.white : Colors.black).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.12), width: 0.5),
                          ),
                          child: Row(
                            children: _presets.map((ml) => Expanded(
                              child: GestureDetector(
                                onTap: () { setState(() => _selectedMl = ml); HapticFeedback.selectionClick(); },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.all(2),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedMl == ml ? (d ? const Color(0xFF2C2C2E) : Colors.white) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _selectedMl == ml ? [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text('$ml ml',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedMl == ml
                                            ? (d ? Colors.white : const Color(0xFF1C1C1E))
                                            : (d ? Colors.white38 : const Color(0xFF8E8E93)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                              child: ElevatedButton(
                              onPressed: _isAdding ? null : () => _addWater(),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: _isAdding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Add $_selectedMl ml', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        if (_lastAddMl != null) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _undoAdd(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.undo2, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text('Undo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(_timeAgo.isEmpty ? 'Start tracking your water intake' : 'Last drink $_timeAgo', style: TextStyle(fontSize: 11, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  _WaterWavePainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final fillH = size.height * (1 - progress);
    final blue = AppColors.primary;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [blue.withValues(alpha: 0.08), blue.withValues(alpha: 0.16), blue.withValues(alpha: 0.10)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, fillH, size.width, size.height - fillH));

    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final s = math.sin((x / size.width * 3 * math.pi) + wavePhase * 2 * math.pi) * 6 +
                math.sin((x / size.width * 5 * math.pi) + wavePhase * 3 * math.pi) * 3;
      path.lineTo(x, fillH + s);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = blue.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final glow = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final s = math.sin((x / size.width * 3 * math.pi) + wavePhase * 2 * math.pi) * 6 +
                math.sin((x / size.width * 5 * math.pi) + wavePhase * 3 * math.pi) * 3;
      if (x == 0) { glow.moveTo(x, fillH + s); } else { glow.lineTo(x, fillH + s); }
    }
    canvas.drawPath(glow, glowPaint);
  }

  @override
  bool shouldRepaint(_WaterWavePainter old) => old.progress != progress || old.wavePhase != wavePhase;
}


