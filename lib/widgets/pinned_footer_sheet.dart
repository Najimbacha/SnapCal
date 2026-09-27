import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/theme_colors.dart';

/// A panel's fields over its main button. With room to spare the two sit
/// one under the other as usual; when the keyboard leaves too little room
/// the fields scroll and the button stays in sight, right above the
/// keyboard, with a thin line between them.
class PinnedFooterSheet extends StatelessWidget {
  const PinnedFooterSheet({
    super.key,
    required this.body,
    required this.footer,
    this.horizontalPadding = 20,
    this.topPadding = 8,
  });

  final Widget body;
  final Widget footer;
  final double horizontalPadding;
  final double topPadding;

  /// Whether the keyboard is up, for panels that tuck away extras while
  /// typing.
  static bool keyboardOpen(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0;

  @override
  Widget build(BuildContext context) {
    final typing = keyboardOpen(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              typing ? 12 : 16,
            ),
            child: body,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border:
                typing
                    ? Border(top: BorderSide(color: context.dividerColor))
                    : null,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              typing ? 10 : 0,
              horizontalPadding,
              typing ? 10 : math.max(20, safeBottom + 12),
            ),
            child: footer,
          ),
        ),
      ],
    );
  }
}
