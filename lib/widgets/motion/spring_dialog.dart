import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Shows a dialog that grows out of [from], the widget that was tapped, with
/// a little spring, instead of fading in at the centre. Without [from] it
/// grows from the centre.
Future<T?> showSpringDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  BuildContext? from,
  bool barrierDismissible = true,
}) {
  final calm = AppMotion.reduceMotion(context);
  var origin = Alignment.center;
  final box = from?.findRenderObject() as RenderBox?;
  final screen = MediaQuery.sizeOf(context);
  if (box != null && box.attached && screen.width > 0 && screen.height > 0) {
    final c = box.localToGlobal(box.size.center(Offset.zero));
    origin = Alignment(
      (c.dx / screen.width * 2 - 1).clamp(-1.0, 1.0),
      (c.dy / screen.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Duration(milliseconds: calm ? 0 : 480),
    transitionBuilder:
        (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, .5, curve: Curves.easeOut),
          ),
          child: ScaleTransition(
            alignment: origin,
            scale: Tween(begin: .3, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.springCurve,
                reverseCurve: Curves.easeIn,
              ),
            ),
            child: child,
          ),
        ),
    pageBuilder: (context, _, _) => builder(context),
  );
}

/// The icon at the top of a confirmation, in a soft tinted square. With
/// [shake] it wobbles once after the dialog lands, for the question that
/// cannot be undone.
class DialogBadge extends StatelessWidget {
  const DialogBadge({
    super.key,
    required this.icon,
    required this.color,
    this.shake = false,
  });

  final IconData icon;
  final Color color;
  final bool shake;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
    // AlertDialog stretches its icon to the dialog's width; keep the square.
    if (!shake) return Center(child: badge);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 900),
        ),
        builder:
            (context, t, child) => Transform.rotate(
              // Starts once the dialog has landed, then dies away.
              angle:
                  t < .45
                      ? 0
                      : math.sin((t - .45) / .55 * math.pi * 3) *
                          .2 *
                          (1 - (t - .45) / .55),
              child: child,
            ),
        child: badge,
      ),
    );
  }
}
