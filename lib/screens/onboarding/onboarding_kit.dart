import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/motion/reveal.dart';
import 'onboarding_draft.dart';

/// A quiet fill for switches, tracks and icon wells. Cards in this theme
/// share the page's colour and are marked by a border, so a fill has to be
/// ink at low strength to read on both the light and the black theme; the
/// divider colour is far too dark for it.
extension OnbColors on BuildContext {
  Color get onbFill =>
      textPrimaryColor.withValues(alpha: isDarkMode ? 0.12 : 0.06);
}

// The parts every onboarding screen is built from: one question per screen,
// big controls, and the Continue button always under the thumb. Words are
// kept to a title and, at most, one short line.

/// Back arrow, the section name, and one bar for how far along the
/// questions are.
class OnbTopBar extends StatelessWidget {
  const OnbTopBar({
    super.key,
    required this.section,
    required this.progress,
    required this.onBack,
  });

  final String section;

  /// 0 to 1.
  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: IconButton(
                    key: const ValueKey('onboarding-back'),
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: onBack,
                    icon: Icon(
                      rtl ? AppSymbols.chevronRight : AppSymbols.chevronLeft,
                      size: 26,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    section,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 6,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: context.primaryColor.withValues(
                          alpha: context.isDarkMode ? 0.22 : 0.16,
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: progress.clamp(0.0, 1.0)),
                      // Springs a touch past the new mark and settles.
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 600),
                      ),
                      curve: AppMotion.springCurve,
                      builder:
                          (context, value, _) => FractionallySizedBox(
                            heightFactor: 1,
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: value.clamp(0.0, 1.0),
                            child: ColoredBox(color: context.primaryColor),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The screen's one question.
class OnbQuestion extends StatelessWidget {
  const OnbQuestion(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Reveal(
        offset: const Offset(0, 10),
        duration: const Duration(milliseconds: 420),
        child: Text(
          text,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

/// The dark, full-width button at the bottom of every screen.
class OnbCta extends StatelessWidget {
  const OnbCta({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    final background = context.textPrimaryColor;
    final foreground = context.backgroundColor;
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled || loading ? 1 : 0.28,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap:
                enabled
                    ? () {
                      HapticFeedback.mediumImpact();
                      onTap!();
                    }
                    : null,
            child: SizedBox(
              height: 58,
              width: double.infinity,
              child: Center(
                child:
                    loading
                        ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: foreground,
                          ),
                        )
                        : Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two units side by side: [imperialLabel] then [metricLabel].
class OnbUnitSwitch extends StatelessWidget {
  const OnbUnitSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.imperialLabel,
    required this.metricLabel,
  });

  final MeasurementSystem value;
  final ValueChanged<MeasurementSystem> onChanged;
  final String imperialLabel;
  final String metricLabel;

  @override
  Widget build(BuildContext context) {
    Widget segment(MeasurementSystem system, String label) {
      final active = value == system;
      return Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: () {
            if (active) return;
            HapticFeedback.selectionClick();
            onChanged(system);
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minWidth: 84),
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: active ? context.cardColor : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
              boxShadow:
                  active
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                      : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color:
                    active
                        ? context.textPrimaryColor
                        : context.textSecondaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.onbFill,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment(MeasurementSystem.imperial, imperialLabel),
            segment(MeasurementSystem.metric, metricLabel),
          ],
        ),
      ),
    );
  }
}

/// A big number with its unit.
class OnbReadout extends StatelessWidget {
  const OnbReadout({super.key, required this.value, this.unit, this.size = 60});

  final String value;
  final String? unit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: -size * 0.035,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (unit != null && unit!.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
  }
}

/// A selectable card. The whole card is the target; a tick shows the choice.
///
/// Picking it floods the card with the accent from where the finger landed,
/// and the tick pops in and draws itself. With [entranceIndex] set, the card
/// also rises into place a beat after the one before it.
class OnbOption extends StatefulWidget {
  const OnbOption({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.showTick = true,
    this.enabled = true,
    this.minHeight = 0,
    this.entranceIndex,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showTick;
  final bool enabled;
  final double minHeight;
  final int? entranceIndex;

  @override
  State<OnbOption> createState() => _OnbOptionState();
}

class _OnbOptionState extends State<OnbOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wash;
  Offset? _origin;

  @override
  void initState() {
    super.initState();
    _wash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(OnbOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;
    if (widget.selected && !AppMotion.reduceMotion(context)) {
      _wash.forward(from: 0);
    } else if (widget.selected) {
      _wash.value = 1;
    } else {
      _wash.animateBack(
        0,
        duration: AppMotion.maybeZero(context, AppMotion.standard),
      );
    }
  }

  @override
  void dispose() {
    _wash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final tint = accent.withValues(alpha: context.isDarkMode ? 0.18 : 0.12);
    final card = Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      inMutuallyExclusiveGroup: true,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.42,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _origin = details.localPosition,
          onTap:
              widget.enabled
                  ? () {
                    HapticFeedback.selectionClick();
                    widget.onTap();
                  }
                  : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: BoxConstraints(minHeight: widget.minHeight),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.selected ? accent : context.cardBorderColor,
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: _WashPainter(
                progress: _wash,
                origin: _origin,
                color: tint,
              ),
              child: Padding(
                padding: widget.padding,
                child:
                    widget.showTick
                        ? Stack(
                          children: [
                            widget.child,
                            PositionedDirectional(
                              top: 0,
                              end: 0,
                              child: OnbTick(selected: widget.selected),
                            ),
                          ],
                        )
                        : widget.child,
              ),
            ),
          ),
        ),
      ),
    );
    final index = widget.entranceIndex;
    if (index == null) return card;
    return Reveal(
      delay: Duration(milliseconds: 90 + 60 * index),
      offset: const Offset(0, 18),
      duration: const Duration(milliseconds: 480),
      child: card,
    );
  }
}

/// The accent spreading out from the tap until it fills the card.
class _WashPainter extends CustomPainter {
  _WashPainter({
    required this.progress,
    required this.origin,
    required this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Offset? origin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress.value);
    if (t <= 0) return;
    final paint = Paint()..color = color;
    if (t >= 1) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    final from = origin ?? size.center(Offset.zero);
    final reach = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - from).distance).reduce((a, b) => a > b ? a : b);
    canvas.drawCircle(from, reach * t, paint);
  }

  @override
  bool shouldRepaint(_WashPainter old) =>
      old.origin != origin || old.color != color || old.progress != progress;
}

/// The round tick on a choice: it pops a little past full size and the
/// check draws itself in.
class OnbTick extends StatelessWidget {
  const OnbTick({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final border = context.cardBorderColor;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1 : 0),
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 420)),
      builder: (context, t, _) {
        final fill = (t / .35).clamp(0.0, 1.0);
        final scale =
            selected
                ? .6 + .4 * AppMotion.springCurve.transform(t)
                : .85 + .15 * t;
        return Transform.scale(
          scale: t == 0 || t == 1 ? 1 : scale,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(Colors.transparent, accent, fill),
              border: Border.all(
                color: Color.lerp(border, accent, fill)!,
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: _CheckPainter(((t - .3) / .7).clamp(0.0, 1.0)),
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path =
        Path()
          ..moveTo(size.width * .27, size.height * .52)
          ..lineTo(size.width * .44, size.height * .68)
          ..lineTo(size.width * .74, size.height * .36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(
        0,
        metric.length * Curves.easeOutCubic.transform(progress),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

/// A square icon well, used on choice cards.
class OnbIconWell extends StatelessWidget {
  const OnbIconWell({
    super.key,
    required this.icon,
    required this.selected,
    this.size = 52,
  });

  final IconData icon;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.maybeZero(context, AppMotion.expansion),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? context.cardColor : context.onbFill,
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: AnimatedScale(
        scale: selected ? 1.08 : 1,
        duration: AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 420),
        ),
        curve: AppMotion.springCurve,
        child: Icon(icon, size: size * 0.48, color: context.textPrimaryColor),
      ),
    );
  }
}

enum OnbTone { good, warn, bad, neutral }

/// One short line of feedback in a tinted box.
class OnbNote extends StatelessWidget {
  const OnbNote({super.key, required this.text, this.tone = OnbTone.good});

  final String text;
  final OnbTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final (Color fg, Color bg) = switch (tone) {
      OnbTone.good => (
        dark ? AppColors.emeraldLight : AppColors.primaryDark,
        context.primaryColor.withValues(alpha: dark ? 0.18 : 0.12),
      ),
      OnbTone.warn => (
        dark ? const Color(0xFFF5C451) : const Color(0xFF9A5B07),
        AppColors.warningAmber.withValues(alpha: dark ? 0.18 : 0.14),
      ),
      OnbTone.bad => (
        dark ? const Color(0xFFF7877C) : const Color(0xFFB42318),
        AppColors.dangerRed.withValues(alpha: dark ? 0.2 : 0.1),
      ),
      OnbTone.neutral => (context.textSecondaryColor, context.onbFill),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

/// A plain white card.
class OnbCard extends StatelessWidget {
  const OnbCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: child,
    );
  }
}

/// Side padding and the maximum width for a step's content.
class OnbPage extends StatelessWidget {
  const OnbPage({super.key, required this.child, this.scroll = true});

  final Widget child;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: child,
        ),
      ),
    );
    if (!scroll) return body;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: body,
    );
  }
}
