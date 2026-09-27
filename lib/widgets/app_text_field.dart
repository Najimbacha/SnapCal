import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_field_theme.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_typography.dart';

/// Wazn's text field: a small grey label above a white box of one height,
/// a unit such as "kcal" in quiet grey on the right, and a soft green glow
/// around the edge while it is being typed in. A mistake turns the edge red
/// with a short line under it.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.fieldKey,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.unit,
    this.icon,
    this.trailing,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.validator,
  });

  /// Checks the text when its form is validated, as on sign-in; the
  /// message it returns shows under the box like [errorText].
  final FormFieldValidator<String>? validator;

  /// The key of the [TextField] itself, for finding it in tests.
  final Key? fieldKey;
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// A unit shown on the right: "kcal", "kg", "g".
  final String? unit;

  /// An icon at the start of the box, as in search.
  final IconData? icon;

  /// Something tappable at the end of the box, as a show-password eye.
  final Widget? trailing;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  bool _focused = false;
  TextEditingController? _ownController;
  TextEditingController get _text =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (_focus.hasFocus != _focused) setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validator = widget.validator;
    if (validator == null) return _body(context, widget.errorText);
    // On a form, the check's message is shown once, under the box, the
    // same way as [AppTextField.errorText].
    return FormField<String>(
      validator: (_) => validator(_text.text),
      builder: (state) => _body(context, widget.errorText ?? state.errorText),
    );
  }

  Widget _body(BuildContext context, String? error) {
    final c = AppFieldColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasError = error != null;
    final ring =
        hasError
            ? scheme.error.withValues(alpha: dark ? .16 : .12)
            : scheme.primary.withValues(alpha: dark ? .18 : .14);

    final field = TextField(
      key: widget.fieldKey,
      controller: _text,
      focusNode: _focus,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTapOutside: widget.onTapOutside,
      cursorColor: scheme.primary,
      style: AppTypography.bodyLarge.copyWith(
        color: c.text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        // The message goes under the box (below), so the glow stays around
        // the box alone; the edge turns red here.
        enabledBorder: hasError ? _edge(scheme.error) : null,
        focusedBorder: hasError ? _edge(scheme.error, 1.5) : null,
        counterText: widget.maxLength == null ? null : '',
        prefixIcon:
            widget.icon == null
                ? null
                : Icon(widget.icon, size: 19, color: c.unit),
        suffixText: widget.unit,
        suffixIcon: widget.trailing,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: c.label,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        // The soft glow sits behind the box while it is being typed in, or
        // while it holds a mistake.
        AnimatedContainer(
          duration: AppMotion.maybeZero(
            context,
            const Duration(milliseconds: 150),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(appFieldRadius),
            boxShadow: [
              if (_focused || hasError) BoxShadow(color: ring, spreadRadius: 4),
            ],
          ),
          child: field,
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.error,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _edge(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(appFieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
}
