import 'package:flutter/widgets.dart';

/// SnapCal spacing and shape tokens.
///
/// Keep layout rhythm on this scale unless a measured component, safe-area
/// inset, or platform affordance needs a specific size.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets page = EdgeInsets.fromLTRB(md, sm, md, xl);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardCompact = EdgeInsets.all(sm);
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(lg, sm, lg, xl);
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
}
