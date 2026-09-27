import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/theme_colors.dart';
import 'wazn_icons.dart';

/// What a message is about, which sets its colour, icon and little motion.
enum ToastKind {
  /// Something worked: green, with a tick that draws itself.
  success,

  /// Something failed: red, and the icon gives a small shake.
  error,

  /// Something needs attention, like no internet: amber.
  warning,

  /// Plain news.
  info,

  /// Something was removed and can still be brought back: a ring runs down
  /// around the icon for as long as Undo is offered.
  undo,
}

/// Shows one Wazn message card above the tab bar, replacing any showing.
///
/// It rides on the [ScaffoldMessenger], so it queues, flicks away and sits
/// clear of the bottom bar the way a snack bar does. An [actionLabel] puts a
/// button in the card; tapping it closes the card with
/// [SnackBarClosedReason.action] before calling [onAction], so callers that
/// wait on `closed` (an undo, say) can tell.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppToast(
  ScaffoldMessengerState messenger, {
  required ToastKind kind,
  required String title,
  String? detail,
  String? actionLabel,
  VoidCallback? onAction,
  IconData? icon,
  Duration duration = const Duration(seconds: 4),
}) {
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      // The card draws its own shadow, which the snack bar would crop.
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      duration: duration,
      content: AppToastCard(
        kind: kind,
        title: title,
        detail: detail,
        actionLabel: actionLabel,
        onAction: onAction,
        icon: icon,
        duration: duration,
      ),
    ),
  );
}

/// The kind for a message that used to be told apart by its snack bar's
/// colour: the app's warning amber, error red and brand green.
ToastKind toastKindFor(Color color) {
  if (color == AppColors.error) return ToastKind.error;
  if (color == AppColors.warning) return ToastKind.warning;
  if (color == AppColors.primary || color == AppColors.success) {
    return ToastKind.success;
  }
  return ToastKind.info;
}

/// [showAppToast] from a context, doing nothing where there is no messenger.
void showAppToastOf(
  BuildContext context, {
  required ToastKind kind,
  required String title,
  String? detail,
  String? actionLabel,
  VoidCallback? onAction,
  IconData? icon,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  showAppToast(
    messenger,
    kind: kind,
    title: title,
    detail: detail,
    actionLabel: actionLabel,
    onAction: onAction,
    icon: icon,
    duration: duration,
  );
}

/// The card itself: a tinted icon, the message, an optional button, and a
/// thin line along the bottom that runs down while the card stays.
class AppToastCard extends StatefulWidget {
  const AppToastCard({
    super.key,
    required this.kind,
    required this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.duration = const Duration(seconds: 4),
  });

  final ToastKind kind;
  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final Duration duration;

  @override
  State<AppToastCard> createState() => _AppToastCardState();
}

class _AppToastCardState extends State<AppToastCard>
    with TickerProviderStateMixin {
  /// The card rising into place, then the icon's own moment.
  late final AnimationController _enter;

  /// Runs from full to empty over the card's life.
  late final AnimationController _life;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _life = AnimationController(vsync: this, duration: widget.duration);
    switch (widget.kind) {
      case ToastKind.success:
        HapticFeedback.lightImpact();
      case ToastKind.error:
        HapticFeedback.mediumImpact();
      case ToastKind.warning:
      case ToastKind.info:
      case ToastKind.undo:
        HapticFeedback.selectionClick();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.isAnimating || _enter.isCompleted) return;
    if (AppMotion.reduceMotion(context)) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
    // Accessible navigation keeps a snack bar open until it is dismissed;
    // the line would then say it is about to go when it is not.
    if (!(MediaQuery.maybeAccessibleNavigationOf(context) ?? false)) {
      _life.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _life.dispose();
    super.dispose();
  }

  (Color, Color) _tint(BuildContext context) {
    final dark = context.isDarkMode;
    switch (widget.kind) {
      case ToastKind.success:
        return (
          dark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
          AppColors.primary.withValues(alpha: dark ? 0.2 : 0.14),
        );
      case ToastKind.error:
        return (
          dark ? const Color(0xFFF97066) : AppColors.error,
          AppColors.error.withValues(alpha: dark ? 0.2 : 0.1),
        );
      case ToastKind.warning:
        return (
          dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
          AppColors.warning.withValues(alpha: dark ? 0.2 : 0.16),
        );
      case ToastKind.info:
      case ToastKind.undo:
        return (
          context.textPrimaryColor,
          context.textPrimaryColor.withValues(alpha: 0.08),
        );
    }
  }

  IconData get _icon =>
      widget.icon ??
      switch (widget.kind) {
        ToastKind.success => WaznIcons.check,
        ToastKind.error => WaznIcons.error,
        ToastKind.warning => WaznIcons.offline,
        ToastKind.info => WaznIcons.info,
        ToastKind.undo => WaznIcons.delete,
      };

  void _act() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.maybeOf(
      context,
    )?.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    widget.onAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final (tint, soft) = _tint(context);
    final surface = context.isDarkMode ? const Color(0xFF1E211F) : Colors.white;
    final detail = widget.detail;

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.4 : 0.14,
            ),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              children: [
                _ToastIcon(
                  kind: widget.kind,
                  icon: _icon,
                  tint: tint,
                  soft: soft,
                  enter: _enter,
                  life: _life,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          height: 1.3,
                        ),
                      ),
                      if (detail != null && detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.actionLabel != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: soft,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _act,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: AppTypography.labelLarge.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // How long is left.
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _life,
              builder:
                  (context, _) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: 1 - _life.value,
                      child: Container(
                        height: 3,
                        color: tint.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );

    // Rises into place with a little overshoot.
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(
          (_enter.value / .55).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 36 * (1 - t)),
          child: Transform.scale(scale: .96 + .04 * t, child: child),
        );
      },
      child: Semantics(liveRegion: true, child: card),
    );
  }
}

class _ToastIcon extends StatelessWidget {
  const _ToastIcon({
    required this.kind,
    required this.icon,
    required this.tint,
    required this.soft,
    required this.enter,
    required this.life,
  });

  final ToastKind kind;
  final IconData icon;
  final Color tint;
  final Color soft;
  final Animation<double> enter;
  final Animation<double> life;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([enter, life]),
      builder: (context, _) {
        final t = enter.value;
        // The tile pops a moment after the card starts rising.
        final pop = Curves.easeOutBack.transform(
          ((t - .15) / .45).clamp(0.0, 1.0),
        );
        // An error's icon shakes once the card has landed.
        final shakeT = ((t - .55) / .45).clamp(0.0, 1.0);
        final shake =
            kind == ToastKind.error && shakeT > 0 && shakeT < 1
                ? math.sin(shakeT * math.pi * 4) * 5 * (1 - shakeT)
                : 0.0;
        Widget glyph = Icon(icon, size: 19, color: tint);
        if (kind == ToastKind.success && icon == WaznIcons.check) {
          glyph = CustomPaint(
            size: const Size.square(20),
            painter: _TickPainter(
              progress: Curves.easeOutCubic.transform(
                ((t - .35) / .45).clamp(0.0, 1.0),
              ),
              color: tint,
            ),
          );
        }
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: .4 + .6 * pop,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  glyph,
                  if (kind == ToastKind.undo)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RingPainter(
                          left: 1 - life.value,
                          color: tint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path =
        Path()
          ..moveTo(size.width * .2, size.height * .53)
          ..lineTo(size.width * .41, size.height * .73)
          ..lineTo(size.width * .8, size.height * .3);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.progress != progress || old.color != color;
}

/// The time left to undo, as a ring that runs down around the icon.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.left, required this.color});

  final double left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (left <= 0) return;
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(1.5),
      -math.pi / 2,
      math.pi * 2 * left,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.left != left || old.color != color;
}
