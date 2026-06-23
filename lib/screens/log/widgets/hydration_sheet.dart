import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_animation/water_animation.dart';

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
  late AnimationController _riseCtrl;
  late Animation<double> _riseAnim;
  late AnimationController _springCtrl;
  late Animation<double> _springAnim;

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
    _riseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _riseAnim = CurvedAnimation(parent: _riseCtrl, curve: Curves.easeOutCubic);
    _springCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _springAnim = CurvedAnimation(parent: _springCtrl, curve: Curves.elasticOut);
    _springCtrl.forward();
    final waterState = ref.read(waterProvider).valueOrNull;
    _fromMl = waterState?.todayTotal ?? 0;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTimeAgo());
  }

  @override
  void dispose() {
    _riseCtrl.dispose();
    _springCtrl.dispose();
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
    _springCtrl.forward(from: 0);
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
          height: 560,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: d
                  ? [const Color(0xFF0D0D1A), const Color(0xFF1A1A2E)]
                  : [const Color(0xFFFEFCF7), const Color(0xFFF8F6F0)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 420,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: WaterAnimation(
                    width: MediaQuery.of(context).size.width,
                    height: 420,
                    waterFillFraction: p,
                    fillTransitionDuration: const Duration(milliseconds: 700),
                    fillTransitionCurve: Curves.easeOutCubic,
                    amplitude: 14,
                    frequency: 1.2,
                    speed: 2.5,
                    waterColor: AppColors.primary.withValues(alpha: d ? 0.3 : 0.15),
                    gradientColors: d
                        ? [AppColors.primary.withValues(alpha: 0.2), const Color(0xFF8B5CF6).withValues(alpha: 0.1)]
                        : [AppColors.primary.withValues(alpha: 0.12), const Color(0xFF8B5CF6).withValues(alpha: 0.06)],
                    enableRipple: true,
                    enableShader: true,
                    enableSecondWave: true,
                    secondWaveColor: AppColors.primary.withValues(alpha: d ? 0.15 : 0.08),
                    secondWaveAmplitude: 8,
                    secondWaveFrequency: 1.8,
                    secondWaveSpeed: 1.5,
                    realisticWave: true,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _springAnim,
                builder: (context, _) => Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          Text('Hydration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: d ? Colors.white : const Color(0xFF1C1917), letterSpacing: -0.3)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: (d ? Colors.white : const Color(0xFF1C1917)).withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(LucideIcons.x, size: 16, color: d ? Colors.white38 : const Color(0xFF78716C)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Transform.scale(
                      scale: 0.9 + (0.1 * _springAnim.value),
                      child: Column(
                        children: [
                          Text('${display.round()} ml', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: d ? Colors.white : const Color(0xFF1C1917), letterSpacing: -3, height: 1.0)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('of $goal ml', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: d ? Colors.white38 : const Color(0xFFB4AFA8))),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary.withValues(alpha: d ? 0.2 : 0.1), AppColors.primary.withValues(alpha: d ? 0.1 : 0.05)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('${(p * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary.withValues(alpha: d ? 0.9 : 1))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: _presets.map((ml) {
                          final selected = _selectedMl == ml;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: ml == _presets.first ? 0 : 8, right: ml == _presets.last ? 0 : 8),
                              child: GestureDetector(
                                onTap: () { setState(() => _selectedMl = ml); HapticFeedback.selectionClick(); },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.primary.withValues(alpha: d ? 0.2 : 0.15) : (d ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected ? AppColors.primary.withValues(alpha: d ? 0.6 : 0.4) : (d ? Colors.white : Colors.black).withValues(alpha: 0.06),
                                      width: selected ? 1.5 : 1,
                                    ),
                                    boxShadow: selected ? [
                                      BoxShadow(color: AppColors.primary.withValues(alpha: d ? 0.3 : 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                                    ] : (d ? null : [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                    ]),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('$ml', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: selected ? AppColors.primary : (d ? Colors.white70 : const Color(0xFF1C1917)))),
                                      Text('ml', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2, color: selected ? AppColors.primary.withValues(alpha: 0.7) : (d ? Colors.white38 : const Color(0xFFB4AFA8)))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + b),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity, height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: d
                                      ? [AppColors.primary.withValues(alpha: 0.9), const Color(0xFF8B5CF6).withValues(alpha: 0.9)]
                                      : [AppColors.primary, const Color(0xFF7C3AED)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(color: AppColors.primary.withValues(alpha: d ? 0.4 : 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                                  BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: d ? 0.2 : 0.1), blurRadius: 24, offset: const Offset(0, 0)),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isAdding ? null : () => _addWater(),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Center(
                                    child: _isAdding
                                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 22, height: 22,
                                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                                                child: Icon(LucideIcons.plus, size: 14, color: Colors.white),
                                              ),
                                              const SizedBox(width: 10),
                                              Text('Add $_selectedMl ml', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2)),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_lastAddMl != null) ...[
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => _undoAdd(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (d ? Colors.white : Colors.black).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.06)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.undo2, size: 14, color: d ? Colors.white38 : const Color(0xFFB4AFA8)),
                                    const SizedBox(width: 6),
                                    Text('Undo $_lastAddMl ml', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: d ? Colors.white38 : const Color(0xFFB4AFA8))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 16,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _timeAgo.isEmpty ? 'Start tracking' : 'Last drink $_timeAgo',
                                key: ValueKey(_timeAgo),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: d ? Colors.white24 : const Color(0xFFB4AFA8), letterSpacing: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}