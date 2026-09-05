import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/water_provider.dart';

// This screen had no dark theme at all: every surface was a light constant
// and there was not one brightness check in the file, so opening the water
// tracker at night meant a full-screen white page between two dark ones.
// The light values are unchanged -- card surface and hairline are still the
// ones shared with the Log screen's tiles, so hydration does not read as a
// different app -- and each now has a dark counterpart.
Color _bg(bool d) => d ? const Color(0xFF0B0B0D) : const Color(0xFFF9F8F5);
Color _card(bool d) => d ? const Color(0xFF161619) : const Color(0xFFFFFFFF);
Color _line(bool d) => d ? const Color(0xFF2B2B30) : const Color(0xFFEDE9E1);
Color _ink(bool d) => d ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917);
Color _muted(bool d) => d ? const Color(0xFF8B8B90) : const Color(0xFFA8A29E);
const _blue = AppColors.sky;
const _blueLight = AppColors.skyLight;

class WaterTrackerScreen extends ConsumerStatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  ConsumerState<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends ConsumerState<WaterTrackerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMl = 250;
  int _lastAddedMl = 0;
  late final AnimationController _waveController;
  late final AnimationController _riseController;
  late final CurvedAnimation _riseCurve;
  int _fromMl = 0;
  int _targetMl = 0;
  bool _isFilling = false;

  static const _presets = [250, 350, 500, 1000];

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
    _riseCurve = CurvedAnimation(
      parent: _riseController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _riseController.dispose();
    _riseCurve.dispose();
    super.dispose();
  }

  Future<void> _addWater() async {
    if (_isFilling) return;
    setState(() => _isFilling = true);
    HapticFeedback.heavyImpact();

    final before = ref.read(waterProvider).valueOrNull?.todayTotal ?? 0;
    _fromMl = _targetMl = before;

    await ref.read(waterProvider.notifier).addWater(_selectedMl);

    _lastAddedMl = _selectedMl;
    _targetMl = ref.read(waterProvider).valueOrNull?.todayTotal ?? before;
    _riseController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isFilling = false);
    }
  }

  void _undo() {
    final total = ref.read(waterProvider).valueOrNull?.todayTotal ?? 0;
    final amount = math.min(_lastAddedMl, total);
    if (amount <= 0) return;
    HapticFeedback.lightImpact();
    ref.read(waterProvider.notifier).removeWater(amount);
    _lastAddedMl = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final d = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The status-bar icons have to flip too, or they disappear into the bar.
      value: (d ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: _bg(d),
          ),
      child: Scaffold(
        backgroundColor: _bg(d),
        body: SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final waterState = ref.watch(waterProvider).valueOrNull;
              final goal = math.max(waterState?.goal ?? 1, 1);
              final total = waterState?.todayTotal ?? 0;
              final reached = total >= goal;
              final canUndo = total > 0 && _lastAddedMl > 0 && !_isFilling;

              if (!_riseController.isAnimating && _targetMl != total) {
                _targetMl = total;
                _fromMl = total;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        _BackChip(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/log');
                            }
                          },
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _card(d),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _line(d)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.common_today,
                                style: TextStyle(
                                  color: _muted(d),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      l10n.water_hydration,
                      style: TextStyle(
                        color: _ink(d),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WaveTank(
                      wave: _waveController,
                      rise: _riseCurve,
                      fromMl: _fromMl,
                      targetMl: _targetMl,
                      total: total,
                      goal: goal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        for (var i = 0; i < _presets.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(
                            child: _PresetChip(
                              ml: _presets[i],
                              selected: _selectedMl == _presets[i],
                              onTap: () {
                                setState(() => _selectedMl = _presets[i]);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isFilling ? null : _addWater,
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          disabledBackgroundColor: _blue.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            _isFilling
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  l10n.water_add_amount(_selectedMl),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _QuickAction(
                          label: l10n.water_reset,
                          enabled: total > 0 && !_isFilling,
                          onTap:
                              () => _showResetDialog(
                                ref.read(waterProvider.notifier),
                              ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (reached) ...[
                                const Icon(
                                  LucideIcons.trophy,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  reached
                                      ? l10n.water_goal_complete
                                      : l10n.water_remaining(goal - total),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        reached
                                            ? AppColors.primary
                                            : _muted(d).withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _QuickAction(
                          label: l10n.water_undo,
                          enabled: canUndo,
                          onTap: _undo,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showResetDialog(Water water) {
    final l10n = AppLocalizations.of(context)!;
    final d = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: _card(d),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.water_reset_title,
              style: TextStyle(color: _ink(d), fontSize: 18),
            ),
            content: Text(
              l10n.water_reset_body,
              style: TextStyle(color: _muted(d), fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l10n.common_cancel,
                  style: TextStyle(color: _muted(d)),
                ),
              ),
              TextButton(
                onPressed: () {
                  water.resetToday();
                  _lastAddedMl = 0;
                  Navigator.pop(ctx);
                },
                child: Text(
                  l10n.water_reset,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }
}

class _BackChip extends StatelessWidget {
  final VoidCallback onTap;

  const _BackChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: _card(d),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _line(d)),
          ),
          child: Icon(LucideIcons.chevronLeft, color: _ink(d), size: 20),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int ml;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.ml,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 64,
        decoration: BoxDecoration(
          color:
              selected ? _blue.withValues(alpha: d ? 0.20 : 0.10) : _card(d),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _blue.withValues(alpha: 0.45) : _line(d),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$ml',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? _blue : _ink(d),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'ml',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _muted(d).withValues(alpha: selected ? 1 : 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _QuickAction({required this.label, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        // Was 13px text with 10px of vertical padding -- about 36dp tall,
        // and one of these is the destructive reset.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card(d),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _line(d).withValues(alpha: enabled ? 1 : 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? _ink(d) : _muted(d).withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _WaveTank extends StatelessWidget {
  final AnimationController wave;
  final CurvedAnimation rise;
  final int fromMl;
  final int targetMl;
  final int total;
  final int goal;

  const _WaveTank({
    required this.wave,
    required this.rise,
    required this.fromMl,
    required this.targetMl,
    required this.total,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([wave, rise]),
      builder: (context, _) {
        final displayMl =
            rise.isAnimating
                ? fromMl + (targetMl - fromMl) * rise.value
                : total.toDouble();
        final progress = (displayMl / math.max(goal, 1)).clamp(0.0, 1.0);

        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: _card(d),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line(d)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                CustomPaint(
                  painter: _WavePainter(progress: progress, phase: wave.value),
                  size: Size.infinite,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayMl.round().toString(),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: _ink(d),
                          height: 1,
                          letterSpacing: -2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.water_goal_progress(goal),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _ink(d).withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;

  _WavePainter({required this.progress, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final fillH = size.height * (1 - progress);

    final waterPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              _blue.withValues(alpha: 0.16),
              _blue.withValues(alpha: 0.38),
              _blue.withValues(alpha: 0.72),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(0, fillH, size.width, size.height - fillH),
          );

    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 3 * math.pi) + phase * 2) * 8;
      final s2 = math.sin((x / size.width * 5 * math.pi) + phase * 3) * 4;
      path.lineTo(x, fillH + s1 + s2);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, waterPaint);

    final crestPaint =
        Paint()
          ..color = _blueLight.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final crest = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 3 * math.pi) + phase * 2) * 8;
      final s2 = math.sin((x / size.width * 5 * math.pi) + phase * 3) * 4;
      if (x == 0) {
        crest.moveTo(x, fillH + s1 + s2);
      } else {
        crest.lineTo(x, fillH + s1 + s2);
      }
    }
    canvas.drawPath(crest, crestPaint);

    if (fillH > 1) {
      final bubblePaint = Paint()..color = _blueLight.withValues(alpha: 0.28);
      for (int i = 0; i < 8; i++) {
        final dx = (i * 47.0 + phase * 30) % size.width;
        final dy = fillH * (0.3 + (i % 3) * 0.2);
        if (!dy.isNaN && !dx.isNaN) {
          final r = 1.5 + (i % 3) * 0.8;
          canvas.drawCircle(Offset(dx, dy.clamp(0, fillH)), r, bubblePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.phase != phase;
}
