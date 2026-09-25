import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration expansion = Duration(milliseconds: 300);
  static const Duration pageEntry = Duration(milliseconds: 380);
  static const Duration reveal = Duration(milliseconds: 450);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOutQuart;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Overshoots a little and settles: for things that arrive, like the tab
  /// pill landing or a tick popping in.
  static const Curve springCurve = Cubic(0.34, 1.45, 0.55, 1);

  /// A number rolling to a new value, or a bar filling to it.
  static const Duration count = Duration(milliseconds: 900);

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  static Duration maybeZero(BuildContext context, Duration duration) {
    return reduceMotion(context) ? Duration.zero : duration;
  }
}
