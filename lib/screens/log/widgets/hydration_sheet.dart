import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_typography.dart';
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

/// The hydration sheet.
///
/// The sheet is the glass: water occupies the whole lower half and rises as
/// the day fills. Everything animated here is driven by two controllers — one
/// endless phase for the surface, one spring for the level — so adding a glass
/// reads as liquid arriving rather than as a progress bar jumping.
class _HydrationSheet extends ConsumerStatefulWidget {
  const _HydrationSheet();

  @override
  ConsumerState<_HydrationSheet> createState() => _HydrationSheetState();
}

class _HydrationSheetState extends ConsumerState<_HydrationSheet>
    with TickerProviderStateMixin {
  /// Endless: drives the wave phase and the bubbles.
  late final AnimationController _phase;

  /// One shot per add: the level travels, overshoots slightly, settles.
  late final AnimationController _level;

  /// The splash the moment water lands.
  late final AnimationController _splash;

  late Animation<double> _levelAnim;

  static const _presets = [100, 250, 500];

  int _selectedMl = 250;
  bool _busy = false;
  double _fromProgress = 0;
  double _toProgress = 0;
  int _fromMl = 0;
  int _toMl = 0;
  int? _lastAddMl;
  Timer? _undoTimer;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _level = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _splash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _levelAnim = AlwaysStoppedAnimation(0);

    final state = ref.read(waterProvider).valueOrNull;
    final total = state?.todayTotal ?? 0;
    final goal = math.max(state?.goal ?? 2500, 1);
    _fromMl = _toMl = total;
    _fromProgress = _toProgress = (total / goal).clamp(0.0, 1.0);
    _celebrated = _toProgress >= 1;
    _levelAnim = AlwaysStoppedAnimation(_toProgress);
  }

  @override
  void dispose() {
    _phase.dispose();
    _level.dispose();
    _splash.dispose();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _animateTo(int ml, int goal) {
    _fromProgress = _levelAnim.value;
    _fromMl = _toMl;
    _toMl = ml;
    _toProgress = (ml / math.max(goal, 1)).clamp(0.0, 1.0);
    _levelAnim = Tween<double>(
      begin: _fromProgress,
      end: _toProgress,
    ).animate(CurvedAnimation(parent: _level, curve: Curves.easeOutBack));
    _level.forward(from: 0);
  }

  Future<void> _add() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    final before = ref.read(waterProvider).valueOrNull;
    await ref.read(waterProvider.notifier).addWater(_selectedMl);
    if (!mounted) return;

    final after = ref.read(waterProvider).valueOrNull;
    final goal = after?.goal ?? before?.goal ?? 2500;
    _splash.forward(from: 0);
    _animateTo(after?.todayTotal ?? 0, goal);

    if (!_celebrated && (after?.todayTotal ?? 0) >= goal) {
      _celebrated = true;
      HapticFeedback.heavyImpact();
    }

    _undoTimer?.cancel();
    setState(() {
      _busy = false;
      _lastAddMl = _selectedMl;
    });
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _lastAddMl = null);
    });
  }

  Future<void> _undo() async {
    if (_busy || _lastAddMl == null) return;
    HapticFeedback.lightImpact();
    _undoTimer?.cancel();
    setState(() {
      _busy = true;
      _lastAddMl = null;
    });

    await ref.read(waterProvider.notifier).removeWater(0);
    if (!mounted) return;
    final after = ref.read(waterProvider).valueOrNull;
    _celebrated = false;
    _animateTo(after?.todayTotal ?? 0, after?.goal ?? 2500);
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final height = math.min(media.size.height * 0.78, 620.0);

    final state =
        ref.watch(waterProvider).valueOrNull ??
        const WaterState(todayTotal: 0);
    final goal = math.max(state.goal, 1);

    // Keep the painted level in step with changes made elsewhere (the Home
    // card's quick add, a sync) without animating on every rebuild.
    if (!_level.isAnimating && state.todayTotal != _toMl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateTo(state.todayTotal, goal);
      });
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: isDark ? const Color(0xFF101418) : const Color(0xFFF7FBFD),
            ),
            // ── The water ──
            AnimatedBuilder(
              animation: Listenable.merge([_phase, _level, _splash]),
              builder:
                  (context, _) => CustomPaint(
                    painter: _WaterPainter(
                      progress: _levelAnim.value.clamp(0.0, 1.0),
                      phase: _phase.value,
                      splash: _splash.value,
                      isDark: isDark,
                    ),
                  ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                child: Column(
                  children: [
                    _Grabber(isDark: isDark),
                    const SizedBox(height: 14),
                    _Header(
                      title: l10n.water_hydration,
                      isDark: isDark,
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(flex: 2),
                    AnimatedBuilder(
                      animation: _level,
                      builder: (context, _) {
                        final ml =
                            (_fromMl + (_toMl - _fromMl) * _level.value)
                                .round();
                        return _Readout(
                          ml: _level.isAnimating ? ml : _toMl,
                          goal: goal,
                          unit: l10n.water_unit_ml,
                          isDark: isDark,
                        );
                      },
                    ),
                    const Spacer(flex: 3),
                    _PresetRow(
                      presets: _presets,
                      selected: _selectedMl,
                      unit: l10n.water_unit_ml,
                      isDark: isDark,
                      onSelect: (ml) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMl = ml);
                      },
                    ),
                    const SizedBox(height: 16),
                    _AddButton(
                      label: l10n.water_add_amount(_selectedMl),
                      busy: _busy,
                      onTap: _add,
                    ),
                    SizedBox(
                      height: 34,
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _lastAddMl == null ? 0 : 1,
                          child: TextButton(
                            onPressed: _lastAddMl == null ? null : _undo,
                            child: Text(
                              l10n.water_undo,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark
                                        ? Colors.white70
                                        : const Color(0xFF3B6E8F),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chrome ───────────────────────────────────────────────────────────────────

class _Grabber extends StatelessWidget {
  const _Grabber({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 4,
    decoration: BoxDecoration(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.isDark,
    required this.onClose,
  });

  final String title;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : const Color(0xFF10222E);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          // Padding, not a bigger circle: the drawn dot stays 30px, the
          // target becomes 44. This is the only tap-to-dismiss on the sheet.
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.06,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 15,
                color: ink.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The day, as one number over the water.
class _Readout extends StatelessWidget {
  const _Readout({
    required this.ml,
    required this.goal,
    required this.unit,
    required this.isDark,
  });

  final int ml;
  final int goal;
  final String unit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : const Color(0xFF0E2230);
    final pct = ((ml / math.max(goal, 1)) * 100).clamp(0, 999).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$ml',
              style: AppTypography.displayLarge.copyWith(
                color: ink,
                fontSize: 62,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -2.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                unit,
                style: AppTypography.titleMedium.copyWith(
                  color: ink.withValues(alpha: 0.45),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'of $goal $unit',
              style: AppTypography.bodySmall.copyWith(
                color: ink.withValues(alpha: 0.42),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2E9BD6).withValues(
                  alpha: isDark ? 0.24 : 0.13,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$pct%',
                style: AppTypography.labelSmall.copyWith(
                  color:
                      isDark
                          ? const Color(0xFF8ED0F5)
                          : const Color(0xFF1B6F9E),
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.presets,
    required this.selected,
    required this.unit,
    required this.isDark,
    required this.onSelect,
  });

  final List<int> presets;
  final int selected;
  final String unit;
  final bool isDark;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < presets.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _PresetChip(
              ml: presets[i],
              unit: unit,
              selected: presets[i] == selected,
              isDark: isDark,
              onTap: () => onSelect(presets[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.ml,
    required this.unit,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final int ml;
  final String unit;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2E9BD6);
    final ink = isDark ? Colors.white : const Color(0xFF0E2230);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              selected
                  ? accent.withValues(alpha: isDark ? 0.26 : 0.13)
                  : (isDark ? Colors.white : Colors.white).withValues(
                    alpha: isDark ? 0.05 : 0.72,
                  ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? accent.withValues(alpha: 0.55)
                    : (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.07,
                    ),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$ml',
              style: AppTypography.titleMedium.copyWith(
                color: selected ? accent : ink.withValues(alpha: 0.8),
                fontSize: 19,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              unit,
              style: AppTypography.labelSmall.copyWith(
                color: (selected ? accent : ink).withValues(alpha: 0.55),
                fontSize: 10.5,
                height: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.busy ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3FAEE8), Color(0xFF1E7FC2)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E7FC2).withValues(alpha: 0.34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.busy ? LucideIcons.loader : LucideIcons.plus,
                size: 17,
                color: Colors.white,
              ),
              const SizedBox(width: 9),
              Text(
                widget.label,
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── The water itself ─────────────────────────────────────────────────────────

/// Two sine waves, a surface highlight, and rising bubbles.
///
/// One wave alone reads as a graphic; two at different wavelengths and speeds,
/// slightly out of phase, is what makes a surface look like liquid. The splash
/// term briefly raises the amplitude where water just landed.
class _WaterPainter extends CustomPainter {
  _WaterPainter({
    required this.progress,
    required this.phase,
    required this.splash,
    required this.isDark,
  });

  final double progress;
  final double phase;
  final double splash;
  final bool isDark;

  /// Fixed field, so bubbles do not jump around between frames.
  static final List<_Bubble> _bubbles = List.generate(
    18,
    (i) => _Bubble(
      x: (i * 0.137 + 0.05) % 1,
      radius: 1.4 + (i % 4) * 0.9,
      speed: 0.22 + (i % 5) * 0.06,
      offset: (i * 0.19) % 1,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    // The water occupies the lower 62% of the sheet at full, so a finished day
    // still leaves the controls on dry ground.
    final band = size.height * 0.62;
    final surfaceY = size.height - band * progress.clamp(0.0, 1.0);
    if (progress <= 0.001) return;

    final t = phase * 2 * math.pi;
    // Settles back within a second of landing.
    final kick =
        splash <= 0 ? 0.0 : (1 - Curves.easeOutCubic.transform(splash)) * 7;

    final deep =
        isDark ? const Color(0xFF10456B) : const Color(0xFF9FD6F2);
    final shallow =
        isDark ? const Color(0xFF1D6F9E) : const Color(0xFFCDEBFA);

    // Back wave: longer, slower, dimmer — depth comes from the pair.
    _fillWave(
      canvas,
      size,
      surfaceY: surfaceY + 6,
      amplitude: 7 + kick * 0.6,
      wavelength: size.width * 1.35,
      travel: t * 0.6,
      colors: [shallow.withValues(alpha: 0.55), deep.withValues(alpha: 0.42)],
    );

    // Front wave carries the real surface line.
    final frontPath = _fillWave(
      canvas,
      size,
      surfaceY: surfaceY,
      amplitude: 10 + kick,
      wavelength: size.width * 0.95,
      travel: -t,
      colors: [shallow.withValues(alpha: 0.9), deep.withValues(alpha: 0.86)],
    );

    canvas.drawPath(
      frontPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: isDark ? 0.16 : 0.55),
    );

    _paintBubbles(canvas, size, surfaceY: surfaceY, band: band, t: phase);
  }

  Path _fillWave(
    Canvas canvas,
    Size size, {
    required double surfaceY,
    required double amplitude,
    required double wavelength,
    required double travel,
    required List<Color> colors,
  }) {
    final path = Path()..moveTo(0, surfaceY);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y =
          surfaceY +
          math.sin((x / wavelength) * 2 * math.pi + travel) * amplitude;
      path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(
          Rect.fromLTWH(0, surfaceY, size.width, size.height - surfaceY),
        ),
    );
    return path;
  }

  void _paintBubbles(
    Canvas canvas,
    Size size, {
    required double surfaceY,
    required double band,
    required double t,
  }) {
    final depth = size.height - surfaceY;
    if (depth <= 12) return;

    for (final bubble in _bubbles) {
      final travel = (t * bubble.speed * 4 + bubble.offset) % 1;
      final y = size.height - travel * depth;
      if (y < surfaceY + 4) continue;
      // Fade out as they approach the surface, and in as they leave the floor.
      final nearSurface = ((y - surfaceY) / math.max(depth * 0.35, 1)).clamp(
        0.0,
        1.0,
      );
      final alpha = 0.30 * nearSurface;
      if (alpha <= 0.01) continue;
      canvas.drawCircle(
        Offset(bubble.x * size.width, y),
        bubble.radius,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.splash != splash ||
      old.isDark != isDark;
}

class _Bubble {
  const _Bubble({
    required this.x,
    required this.radius,
    required this.speed,
    required this.offset,
  });

  final double x;
  final double radius;
  final double speed;
  final double offset;
}
