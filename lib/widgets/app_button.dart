import 'package:flutter/material.dart';

import '../core/theme/app_button_theme.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_typography.dart';
import 'wazn_icons.dart';

enum AppButtonKind { primary, secondary, text, danger }

/// Wazn's button. One main kind in the app's green, full width and 52 tall
/// with the text fields' corners, plus three quieter kinds: an outlined
/// second choice, plain green text, and red text for anything that removes
/// data. It shrinks a touch while pressed. Pass a null [onPressed] and it
/// turns warm grey until it can be used.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.done = false,
    this.expand = true,
  }) : kind = AppButtonKind.primary,
       quiet = false;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.done = false,
    this.expand = true,
  }) : kind = AppButtonKind.secondary,
       quiet = false;

  /// Plain text. A [quiet] one is grey, for Cancel and Back.
  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.quiet = false,
    this.expand = false,
  }) : kind = AppButtonKind.text,
       loading = false,
       done = false;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  }) : kind = AppButtonKind.danger,
       quiet = false,
       loading = false,
       done = false;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;
  final bool quiet;

  /// Shows a small spinner in place of the label; taps are ignored.
  final bool loading;

  /// Shows a tick in place of the label, once the job is done.
  final bool done;

  /// Fills the width it is given.
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busy = widget.loading || widget.done;
    final enabled = widget.onPressed != null;
    // While busy the button keeps its colour but ignores taps.
    final VoidCallback? onPressed =
        enabled ? (busy ? () {} : widget.onPressed) : null;

    final Widget button = switch (widget.kind) {
      AppButtonKind.primary => FilledButton(
        style: appPrimaryButtonStyle(scheme),
        onPressed: onPressed,
        child: _content(context, scheme.onPrimary),
      ),
      AppButtonKind.secondary => OutlinedButton(
        style: appSecondaryButtonStyle(scheme),
        onPressed: onPressed,
        child: _content(context, scheme.primary),
      ),
      AppButtonKind.text => TextButton(
        style: appTextButtonStyle(scheme).copyWith(
          foregroundColor:
              widget.quiet
                  ? WidgetStatePropertyAll(AppButtonColors.of(context).quiet)
                  : null,
          textStyle:
              widget.quiet
                  ? WidgetStatePropertyAll(
                    AppTypography.labelLarge.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  : null,
        ),
        onPressed: onPressed,
        child: _content(context, null),
      ),
      AppButtonKind.danger => TextButton(
        style: appTextButtonStyle(scheme).copyWith(
          foregroundColor: WidgetStatePropertyAll(scheme.error),
          overlayColor: WidgetStatePropertyAll(
            scheme.error.withValues(alpha: .08),
          ),
        ),
        onPressed: onPressed,
        child: _content(context, null),
      ),
    };

    final scaled = Listener(
      onPointerDown: enabled && !busy ? (_) => _press(true) : null,
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _pressed ? .98 : 1,
        duration: AppMotion.maybeZero(context, AppMotion.instant),
        curve: AppMotion.standardCurve,
        child: button,
      ),
    );
    return widget.expand
        ? SizedBox(width: double.infinity, child: scaled)
        : scaled;
  }

  Widget _content(BuildContext context, Color? ink) {
    final Widget child;
    if (widget.loading) {
      child = SizedBox(
        key: const ValueKey('loading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: ink ?? IconTheme.of(context).color,
        ),
      );
    } else if (widget.done) {
      child = const Icon(WaznIcons.check, key: ValueKey('done'), size: 22);
    } else {
      child = Row(
        key: const ValueKey('label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return AnimatedSwitcher(
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 200)),
      switchInCurve: AppMotion.standardCurve,
      child: child,
    );
  }
}
