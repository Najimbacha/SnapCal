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

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  static Duration maybeZero(BuildContext context, Duration duration) {
    return reduceMotion(context) ? Duration.zero : duration;
  }
}
