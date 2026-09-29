import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../../../widgets/wazn_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_button_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/water_provider.dart';
import '../../../widgets/motion/celebration.dart';
import '../../../widgets/motion/count_up_text.dart';
import '../../../widgets/motion/water_glass.dart';

const _hydrationAccent = Color(0xFF3B9BE8);
const _hydrationInk = Color(0xFF1C1917);
const _hydrationMuted = Color(0xFF777370);
const _hydrationLine = Color(0xFFEDE9E1);
const _hydrationPaper = Color(0xFFFBFCFA);

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

class _HydrationSheetState extends ConsumerState<_HydrationSheet> {
  static const _presets = [100, 250, 500];

  static const _undoWindow = Duration(seconds: 6);

  int _selectedMl = 250;
  int? _lastAddMl;
  bool _busy = false;
  Timer? _undoTimer;

  /// Counts additions, so each one floats its own "+250 ml".
  int _adds = 0;

  /// Today's goal was just reached here: the chip shows and the bar greens.
  bool _goalJustReached = false;
  final _glassKey = GlobalKey();

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    final before = ref.read(waterProvider).valueOrNull;
    final wasBelowGoal =
        before != null && before.goal > 0 && before.todayTotal < before.goal;
    setState(() => _busy = true);

    await ref.read(waterProvider.notifier).addWater(_selectedMl);
    if (!mounted) return;

    final after = ref.read(waterProvider).valueOrNull;
    final reached =
        wasBelowGoal && after != null && after.todayTotal >= after.goal;

    _undoTimer?.cancel();
    setState(() {
      _busy = false;
      _lastAddMl = _selectedMl;
      _adds++;
      if (reached) _goalJustReached = true;
    });
    _undoTimer = Timer(_undoWindow, () {
      if (mounted) setState(() => _lastAddMl = null);
    });
    if (reached) _celebrate();
  }

  /// Confetti from the glass once the drop has landed.
  void _celebrate() {
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final box = _glassKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;
      burstConfetti(context, box.localToGlobal(box.size.center(Offset.zero)));
    });
  }

  Future<void> _undo() async {
    final lastAdd = _lastAddMl;
    if (_busy || lastAdd == null) return;
    HapticFeedback.lightImpact();
    _undoTimer?.cancel();
    setState(() {
      _busy = true;
      _lastAddMl = null;
    });

    await ref.read(waterProvider.notifier).removeWater(lastAdd);
    if (mounted) {
      final now = ref.read(waterProvider).valueOrNull;
      if (now == null || now.todayTotal < now.goal) _goalJustReached = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = math.min(media.size.height * 0.72, 560.0);
    final state =
        ref.watch(waterProvider).valueOrNull ?? const WaterState(todayTotal: 0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        height: height,
        color: isDark ? Colors.black : _hydrationPaper,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _Grabber()),
                const SizedBox(height: 14),
                _Header(onClose: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 18),
                _ProgressCard(
                  state: state,
                  glassKey: _glassKey,
                  adds: _adds,
                  lastAddMl: _lastAddMl,
                  goalJustReached: _goalJustReached,
                ),
                const SizedBox(height: 14),
                _PresetRow(
                  presets: _presets,
                  selected: _selectedMl,
                  unit: l10n.water_unit_ml,
                  onSelect: (ml) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMl = ml);
                  },
                ),
                const SizedBox(height: 14),
                _AddButton(
                  label: l10n.water_add_amount(_selectedMl),
                  busy: _busy,
                  onTap: _add,
                ),
                SizedBox(
                  height: 48,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 280),
                      ),
                      switchInCurve: AppMotion.springCurve,
                      transitionBuilder:
                          (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween(
                                begin: .7,
                                end: 1.0,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                      child:
                          _lastAddMl == null
                              ? const SizedBox.shrink(key: ValueKey('none'))
                              : _UndoPill(
                                key: ValueKey('undo-$_adds'),
                                label: l10n.water_undo,
                                window: _undoWindow,
                                onTap: _undo,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _hydrationInk;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hydrationAccent.withValues(alpha: isDark ? 0.22 : 0.13),
            shape: BoxShape.circle,
          ),
          child: const Icon(WaznIcons.water, color: _hydrationAccent, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.water_hydration,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: appMinimumTapTarget,
            height: appMinimumTapTarget,
            child: Center(
              child: Icon(
                WaznIcons.close,
                size: 20,
                color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.state,
    required this.glassKey,
    required this.adds,
    required this.lastAddMl,
    required this.goalJustReached,
  });

  final WaterState state;
  final GlobalKey glassKey;

  /// How many glasses were added in this sheet; each floats its amount.
  final int adds;
  final int? lastAddMl;
  final bool goalJustReached;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _hydrationInk;
    final muted = isDark ? Colors.white60 : _hydrationMuted;
    final goal = math.max(state.goal, 1);
    final progress = (state.todayTotal / goal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final goalText = numberFormat.format(goal);
    final reached = state.todayTotal >= goal;
    final barColor = reached ? const Color(0xFF16A34A) : _hydrationAccent;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : _hydrationLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // A drop falls in and the water rises each time a glass is
              // added below.
              SizedBox(
                key: glassKey,
                child: WaterGlass(
                  level: progress,
                  color: _hydrationAccent,
                  outline: muted,
                  size: const Size(34, 46),
                  showDrop: true,
                  fillFromEmpty: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      CountUpText(
                        value: state.todayTotal,
                        format: numberFormat.format,
                        duration: const Duration(milliseconds: 700),
                        style: AppTypography.displayLarge.copyWith(
                          color: ink,
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        ' ${l10n.water_unit_ml}',
                        style: AppTypography.titleSmall.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _hydrationAccent.withValues(
                    alpha: isDark ? 0.24 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pct%',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? const Color(0xFF9BD6FF) : _hydrationAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.home_metric_of_goal(goalText, l10n.water_unit_ml),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: barColor),
                    duration: const Duration(milliseconds: 500),
                    builder:
                        (context, color, _) => LinearProgressIndicator(
                          minHeight: 8,
                          value: value,
                          backgroundColor: _hydrationAccent.withValues(
                            alpha: isDark ? 0.18 : 0.11,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            color ?? barColor,
                          ),
                        ),
                  ),
                ),
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        // "+250 ml" rising from the glass as it lands.
        if (adds > 0 && lastAddMl != null)
          // Over the glass, inside the card.
          PositionedDirectional(
            start: 6,
            top: 4,
            child: _PlusFloat(
              key: ValueKey('plus-$adds'),
              text: '+${numberFormat.format(lastAddMl)} ${l10n.water_unit_ml}',
            ),
          ),
        if (goalJustReached)
          Positioned(
            top: -14,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppMotion.maybeZero(
                  context,
                  const Duration(milliseconds: 520),
                ),
                curve: AppMotion.springCurve,
                builder:
                    (context, t, child) => Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.scale(scale: .7 + .3 * t, child: child),
                    ),
                child: Container(
                  key: const ValueKey('water-goal-chip'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${l10n.water_goal_complete} 🎉',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The amount just added, floating up off the glass and fading.
class _PlusFloat extends StatelessWidget {
  const _PlusFloat({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (AppMotion.reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1300),
        builder: (context, t, child) {
          // In over the first quarter, drifts up, gone by the end.
          final opacity = t < .25 ? t / .25 : (t > .7 ? (1 - t) / .3 : 1.0);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 6 - 20 * Curves.easeOut.transform(t)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A33) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? const Color(0xFF9BD6FF) : _hydrationAccent,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Undo, as a pill with a ring running down over the time left for it.
class _UndoPill extends StatelessWidget {
  const _UndoPill({
    super.key,
    required this.label,
    required this.window,
    required this.onTap,
  });

  final String label;
  final Duration window;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _hydrationInk;
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.08) : _hydrationLine,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: window,
                builder:
                    (context, left, _) => SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomPaint(
                        painter: _RingPainter(left: left, color: ink),
                        child: Center(
                          child: Text(
                            '${(left * window.inSeconds).ceil()}',
                            style: AppTypography.labelSmall.copyWith(
                              color: ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.left, required this.color});

  final double left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (left <= 0) return;
    canvas.drawArc(
      (Offset.zero & size).deflate(1.5),
      -math.pi / 2,
      math.pi * 2 * left,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.left != left || old.color != color;
}

/// The three amounts. A highlight slides to the one picked, and each has a
/// small glass filled to match.
class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.presets,
    required this.selected,
    required this.unit,
    required this.onSelect,
  });

  static const _gap = 10.0;

  final List<int> presets;
  final int selected;
  final String unit;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final index = math.max(0, presets.indexOf(selected));
    final largest = presets.reduce(math.max);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - _gap * (presets.length - 1)) /
            presets.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final offset = index * (width + _gap);
        return Stack(
          children: [
            AnimatedPositioned(
              key: const ValueKey('water-preset-highlight'),
              duration: AppMotion.maybeZero(
                context,
                const Duration(milliseconds: 450),
              ),
              curve: AppMotion.springCurve,
              top: 0,
              bottom: 0,
              left: rtl ? null : offset,
              right: rtl ? offset : null,
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _hydrationAccent.withValues(
                    alpha: isDark ? 0.24 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _hydrationAccent, width: 1.6),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < presets.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: _PresetChip(
                      ml: presets[i],
                      fill: .15 + .75 * presets[i] / largest,
                      unit: unit,
                      selected: presets[i] == selected,
                      onTap: () => onSelect(presets[i]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.ml,
    required this.fill,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  final int ml;

  /// How full its little glass is drawn.
  final double fill;
  final String unit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _hydrationInk;
    final color = selected ? _hydrationAccent : ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // The sliding highlight draws the picked one's edge.
          border: Border.all(
            color:
                selected
                    ? Colors.transparent
                    : isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : _hydrationLine,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The glass's water bobs up when this amount is picked.
            TweenAnimationBuilder<double>(
              key: ValueKey(selected),
              tween: Tween(begin: selected ? 0 : 1, end: 1),
              duration: AppMotion.maybeZero(
                context,
                const Duration(milliseconds: 420),
              ),
              curve: AppMotion.springCurve,
              builder:
                  (context, t, _) => CustomPaint(
                    size: const Size(18, 23),
                    painter: _MiniGlassPainter(
                      fill: fill * (.75 + .25 * t),
                      color: _hydrationAccent,
                    ),
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              '$ml $unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: color,
                fontSize: 14.5,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniGlassPainter extends CustomPainter {
  const _MiniGlassPainter({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final glass =
        Path()
          ..moveTo(w * .06, h * .06)
          ..lineTo(w * .94, h * .06)
          ..lineTo(w * .82, h * .94)
          ..lineTo(w * .18, h * .94)
          ..close();
    canvas.save();
    canvas.clipPath(glass);
    final top = h * .94 - (h * .88) * fill.clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTRB(0, top, w, h),
      Paint()..color = color.withValues(alpha: 0.85),
    );
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_MiniGlassPainter old) =>
      old.fill != fill || old.color != color;
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
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hydrationAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child:
                widget.busy
                    ? const SizedBox(
                      key: ValueKey('busy'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Row(
                      key: const ValueKey('ready'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          WaznIcons.plus,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
