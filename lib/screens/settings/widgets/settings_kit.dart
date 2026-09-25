import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user_settings.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_notifier_provider.dart';
import '../../../providers/metrics_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/ui_blocks.dart';
import '../../../widgets/wazn_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../widgets/motion/rolling_number.dart';
import '../../../widgets/motion/theme_reveal.dart';
import '../../../widgets/motion/visible_gate.dart';

// Shared building blocks for the Settings area: one visual language for
// sections, rows, switches, sheets and dialogs across the root screen and
// every sub-screen.

const kSettingsBgLight = Color(0xFFF9F8F5);
const kSettingsBgDark = Color(0xFF14130F);
const kSettingsInk = Color(0xFF1C1917);
const kSettingsMuted = Color(0xFFA8A29E);
const kSettingsLine = Color(0xFFE8E4DC);
const kSettingsGreen = Color(0xFF1A3D2B);
const kSettingsGreenText = Color(0xFF16733A);

Color settingsBg(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? kSettingsBgDark
      : kSettingsBgLight;
}

Color settingsText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : kSettingsInk;
}

Color settingsSubtext(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white54
      : kSettingsMuted;
}

String? settingsLanguageName(String? code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'ar':
      return 'العربية';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    default:
      return null;
  }
}

/// Opens the value editor for a whole number.
///
/// Kept as a function so the twenty-odd call sites across Settings did not all
/// have to change when the presentation moved from a centred dialog to a
/// bottom sheet. [min] and [max] are shown as a slider rather than described
/// in a sentence; the old `value > 0` check accepted an age of 500 and a
/// height of 3.
void showSettingsNumberDialog(
  BuildContext context, {
  required String title,
  required int currentValue,
  required String unit,
  required Future<void> Function(int) onSave,
  int? min,
  int? max,
  int? step,
  String? helperText,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (sheetContext) => SettingsValueSheet(
          title: title,
          initialValue: currentValue.toDouble(),
          unit: unit,
          min: min?.toDouble(),
          max: max?.toDouble(),
          step: step?.toDouble(),
          helperText: helperText,
          onSave: (value) => onSave(value.round()),
        ),
  );
}

/// Opens the value editor for a value with a fractional part.
///
/// Weight is the case that needs it: the whole-number editor forced a round
/// trip through integers, so a 70kg target displayed in pounds became 154,
/// saved back as 69.85kg, and drifted a little further on every visit.
void showSettingsDecimalDialog(
  BuildContext context, {
  required String title,
  required double currentValue,
  required String unit,
  required Future<void> Function(double) onSave,
  double? min,
  double? max,
  double? step,
  int decimals = 1,
  String? helperText,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (sheetContext) => SettingsValueSheet(
          title: title,
          initialValue: currentValue,
          unit: unit,
          min: min,
          max: max,
          step: step,
          decimals: decimals,
          helperText: helperText,
          onSave: onSave,
        ),
  );
}

void showSettingsNameDialog(
  BuildContext context,
  WidgetRef ref,
  String currentName,
) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (sheetContext) => SettingsTextSheet(
          title: l10n.settings_display_name,
          subtitle: l10n.settings_how_to_call,
          initialValue: currentName,
          hintText: l10n.settings_set_name,
          // A failed rename used to vanish without a word.
          onSave: (name) async {
            await ref
                .read(authNotifierProvider.notifier)
                .updateDisplayName(name);
            if (!context.mounted) return;
            if (ref.read(authNotifierProvider).hasError) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.settings_name_failed)),
              );
            }
          },
        ),
  );
}

/// Text entry as a bottom sheet, matching [SettingsValueSheet].
///
/// The number editors moved to sheets and this one was left behind as an alert
/// box with a filled slab of a field in it — the same look the whole redesign
/// was replacing, still sitting on Body Profile.
///
/// The field is a single underline that thickens and takes the accent on
/// focus, rather than a heavy filled well. A well is a box drawn around
/// something that is already the only thing on screen; the underline says
/// "type here" with one stroke and lets the value itself carry the weight.
class SettingsTextSheet extends StatefulWidget {
  const SettingsTextSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onSave,
    this.subtitle,
    this.hintText,
    this.maxLength = 40,
    this.textCapitalization = TextCapitalization.words,
  });

  final String title;
  final String? subtitle;
  final String initialValue;
  final String? hintText;
  final int maxLength;
  final TextCapitalization textCapitalization;
  final ValueChanged<String> onSave;

  @override
  State<SettingsTextSheet> createState() => _SettingsTextSheetState();
}

class _SettingsTextSheetState extends State<SettingsTextSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    // Select the existing value rather than parking the caret at the end:
    // renaming is usually replacing, not appending.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _trimmed => _controller.text.trim();
  bool get _isValid => _trimmed.isNotEmpty;

  void _submit() {
    if (!_isValid) return;
    Navigator.pop(context);
    if (_trimmed == widget.initialValue.trim()) return;
    widget.onSave(_trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: settingsBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: settingsSubtext(context).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: AppTypography.heading3.copyWith(
                color: settingsText(context),
                fontSize: 20,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subtitle!,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12,
                  color: settingsSubtext(context),
                ),
              ),
            ],
            const SizedBox(height: 22),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              maxLength: widget.maxLength,
              textCapitalization: widget.textCapitalization,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) => setState(() {}),
              cursorColor: kSettingsGreenText,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 26,
                letterSpacing: -0.5,
                color: settingsText(context),
              ),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: widget.hintText,
                hintStyle: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 26,
                  letterSpacing: -0.5,
                  color: settingsSubtext(context).withValues(alpha: 0.45),
                ),
                contentPadding: const EdgeInsets.only(bottom: 10),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : kSettingsLine,
                    width: 1.5,
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: kSettingsGreenText, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isValid ? _submit : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: kSettingsGreen,
                  disabledBackgroundColor: kSettingsGreen.withValues(
                    alpha: 0.35,
                  ),
                  foregroundColor: const Color(0xFFF0FDF4),
                ),
                child: Text(l10n.common_save),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.common_cancel,
                  style: TextStyle(color: settingsSubtext(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showGenderSelector(
  BuildContext context,
  WidgetRef ref,
  UserSettings settings,
) {
  final currentWeightKg = ref.read(bodyMetricsProvider.notifier).currentWeight;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) => SettingsSelectionSheet(
          title: AppLocalizations.of(context)!.settings_gender,
          options: const ['male', 'female', 'other'],
          currentValue: settings.gender ?? 'male',
          onSelect:
              (value) => ref
                  .read(settingsProvider.notifier)
                  .updateBodyProfile(
                    gender: value,
                    currentWeightKg: currentWeightKg,
                  ),
        ),
  );
}

void showUnitSelector(
  BuildContext context,
  UserSettings settings,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsSelectionSheet(
              title: AppLocalizations.of(context)!.settings_weight_unit,
              options: ['kg', 'lb'],
              currentValue: settings.weightUnit ?? 'kg',
              onSelect:
                  (value) => ref
                      .read(settingsProvider.notifier)
                      .updateUnits(weightUnit: value),
            ),
            const SizedBox(height: 12),
            SettingsSelectionSheet(
              title: AppLocalizations.of(context)!.settings_height_unit,
              // Heights are kept in inches for imperial users. "ft" was
              // offered here, and nothing else in the app understood it.
              options: ['cm', 'in'],
              currentValue: isImperialHeight(settings.heightUnit) ? 'in' : 'cm',
              onSelect:
                  (value) => ref
                      .read(settingsProvider.notifier)
                      .updateUnits(heightUnit: value),
            ),
          ],
        ),
  );
}

Future<void> selectTime(
  BuildContext context,
  UserSettings settings,
  WidgetRef ref,
  String type,
) async {
  final current =
      type == 'breakfast'
          ? settings.breakfastTime
          : type == 'lunch'
          ? settings.lunchTime
          : settings.dinnerTime;

  final parts = current.split(':');
  final initial = TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 8,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
  );

  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
    switchToInputEntryModeIcon: const Icon(WaznIcons.edit),
    switchToTimerEntryModeIcon: const Icon(WaznIcons.clock),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: kSettingsGreenText),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (type == 'breakfast') {
      await ref
          .read(settingsProvider.notifier)
          .updateReminderTimes(breakfast: timeStr);
    } else if (type == 'lunch') {
      await ref
          .read(settingsProvider.notifier)
          .updateReminderTimes(lunch: timeStr);
    } else {
      await ref
          .read(settingsProvider.notifier)
          .updateReminderTimes(dinner: timeStr);
    }
  }
}

class SettingsSelectionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String currentValue;
  final Function(String) onSelect;

  const SettingsSelectionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: settingsBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading3),
          const SizedBox(height: 20),
          ...options.map(
            (opt) => ListTile(
              title: Text(
                localizeOption(context, opt),
                style: AppTypography.titleMedium.copyWith(
                  color: settingsText(context),
                ),
              ),
              trailing:
                  opt == currentValue
                      ? Icon(WaznIcons.check, color: kSettingsGreenText)
                      : null,
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A value editor as a bottom sheet, replacing the centred alert dialog.
///
/// The old dialog was a modal box with a large bare text field and nothing
/// else: no sense of scale, no way to nudge a number, the keyboard covering
/// half the screen, and the whole thing floating in the middle of the display
/// where no thumb reaches. It also looked nothing like the rest of Settings,
/// which already uses bottom sheets for its pickers.
///
/// This is the same surface as [SettingsSelectionSheet] — same radius, same
/// ground, same padding — with three ways to reach a value rather than one:
///
///  * the steppers, for the small correction that is most edits;
///  * the slider, which makes the allowed range something you can see instead
///    of a sentence you have to read;
///  * the field itself, for when you know the number.
///
/// [decimals] switches between whole numbers and one decimal place, so weight
/// and calories can share an implementation rather than drifting apart as two.
class SettingsValueSheet extends StatefulWidget {
  const SettingsValueSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.unit,
    required this.onSave,
    this.min,
    this.max,
    this.step,
    this.decimals = 0,
    this.helperText,
  });

  final String title;
  final double initialValue;
  final String unit;
  final ValueChanged<double> onSave;
  final double? min;
  final double? max;

  /// How much one tap of a stepper moves the value. Defaults to something
  /// sensible for the range: nudging calories by 1 would be absurd, and
  /// nudging age by 25 equally so.
  final double? step;
  final int decimals;
  final String? helperText;

  @override
  State<SettingsValueSheet> createState() => _SettingsValueSheetState();
}

class _SettingsValueSheetState extends State<SettingsValueSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late String _initialText;
  late double _step;

  /// The number is shown rolling between values while it is stepped or slid,
  /// and as a text field once it is tapped to type.
  final _focus = FocusNode();
  bool _typing = false;
  bool _sliding = false;

  /// Save draws in to a tick before the sheet closes.
  bool _saving = false;
  late final AnimationController _saveTick;

  @override
  void initState() {
    super.initState();
    _initialText = widget.initialValue.toStringAsFixed(widget.decimals);
    _controller = TextEditingController(text: _initialText);
    _step = widget.step ?? _defaultStep();
    _saveTick = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _focus.addListener(() {
      if (mounted) setState(() => _typing = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _saveTick.dispose();
    super.dispose();
  }

  Future<void> _confirm(double value) async {
    if (_saving) return;
    // Confirming an unchanged value is not an edit. Compared as displayed:
    // 154.0 lb never equals its own round trip as a double, but is the same
    // answer.
    if (value.toStringAsFixed(widget.decimals) == _initialText) {
      Navigator.pop(context);
      return;
    }
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    setState(() => _saving = true);
    if (AppMotion.reduceMotion(context)) {
      _saveTick.value = 1;
    } else {
      await _saveTick.forward();
    }
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSave(value);
  }

  /// A step proportional to the span being edited: 1% of the range, rounded to
  /// something a person would actually choose.
  double _defaultStep() {
    final min = widget.min;
    final max = widget.max;
    if (min == null || max == null) return widget.decimals > 0 ? 0.5 : 1;
    final span = max - min;
    if (widget.decimals > 0) return 0.5;
    // Take the largest step that still leaves ~40 taps across the range. At a
    // looser threshold, macros (0-800g) picked 25g jumps, which is coarser
    // than anyone adjusts protein by.
    for (final candidate in [100.0, 50.0, 25.0, 10.0, 5.0, 1.0]) {
      if (span / candidate >= 40) return candidate;
    }
    return 1;
  }

  double? get _value => double.tryParse(_controller.text.replaceAll(',', '.'));

  bool get _isValid {
    final value = _value;
    if (value == null) return false;

    // With no bounds given, fall back to "must be positive" — the rule the
    // dialog this replaced applied. Dropping it silently let any unbounded
    // call site accept 0 and negatives, which is a regression the range-aware
    // call sites hid because they never take this branch.
    if (widget.min == null && widget.max == null) return value > 0;

    if (widget.min != null && value < widget.min!) return false;
    if (widget.max != null && value > widget.max!) return false;
    return true;
  }

  void _nudge(double delta) {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    final current = _value ?? widget.initialValue;
    var next = current + delta;
    if (widget.min != null) next = math.max(widget.min!, next);
    if (widget.max != null) next = math.min(widget.max!, next);
    setState(() {
      _controller.text = next.toStringAsFixed(widget.decimals);
    });
  }

  String _bound(double? v) =>
      v == null ? '' : v.toStringAsFixed(widget.decimals);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = _value;
    final showError = _controller.text.isNotEmpty && !_isValid;
    final hasRange = widget.min != null && widget.max != null;

    return Padding(
      // Lift the sheet above the keyboard rather than letting it cover the
      // field the user is typing into.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: settingsBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: settingsSubtext(context).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: AppTypography.heading3.copyWith(
                color: settingsText(context),
                fontSize: 20,
              ),
            ),
            if (widget.helperText != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.helperText!,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12,
                  color: settingsSubtext(context),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Value row: nudge down, the number itself, nudge up.
            Row(
              children: [
                _StepButton(icon: WaznIcons.minus, onTap: () => _nudge(-_step)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: IntrinsicWidth(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: _typing || value == null ? 1 : 0,
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focus,
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: widget.decimals > 0,
                                  ),
                                  textAlign: TextAlign.center,
                                  onChanged: (_) => setState(() {}),
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 40,
                                    color:
                                        showError
                                            ? const Color(0xFFE05A47)
                                            : kSettingsGreenText,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              // Rolls to each value as it is stepped or slid;
                              // tapping it opens the field for typing.
                              if (!_typing && value != null)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _focus.requestFocus,
                                    child: Center(
                                      child: RollingNumber(
                                        value:
                                            (value *
                                                    math.pow(
                                                      10,
                                                      widget.decimals,
                                                    ))
                                                .round(),
                                        duration: const Duration(
                                          milliseconds: 420,
                                        ),
                                        format:
                                            (v) => (v /
                                                    math.pow(
                                                      10,
                                                      widget.decimals,
                                                    ))
                                                .toStringAsFixed(
                                                  widget.decimals,
                                                ),
                                        style: AppTypography.headlineSmall
                                            .copyWith(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 40,
                                              color: kSettingsGreenText,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localizeOption(context, widget.unit),
                        style: AppTypography.titleMedium.copyWith(
                          color: settingsSubtext(context),
                        ),
                      ),
                    ],
                  ),
                ),
                _StepButton(icon: WaznIcons.plus, onTap: () => _nudge(_step)),
              ],
            ),

            if (hasRange) ...[
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: kSettingsGreenText,
                  inactiveTrackColor: settingsSubtext(
                    context,
                  ).withValues(alpha: 0.18),
                  thumbColor: kSettingsGreenText,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                // Glides to a stepped or typed value; follows the finger
                // exactly while dragged.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: (value ?? widget.initialValue).clamp(
                      widget.min!,
                      widget.max!,
                    ),
                  ),
                  duration:
                      _sliding
                          ? Duration.zero
                          : AppMotion.maybeZero(
                            context,
                            const Duration(milliseconds: 280),
                          ),
                  curve: Curves.easeOutCubic,
                  builder:
                      (context, shown, _) => Slider(
                        value: shown.clamp(widget.min!, widget.max!),
                        min: widget.min!,
                        max: widget.max!,
                        onChangeStart: (_) {
                          _focus.unfocus();
                          setState(() => _sliding = true);
                        },
                        onChangeEnd: (_) => setState(() => _sliding = false),
                        onChanged:
                            (v) => setState(() {
                              _controller.text = v.toStringAsFixed(
                                widget.decimals,
                              );
                            }),
                      ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _bound(widget.min),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      color: settingsSubtext(context),
                    ),
                  ),
                  Text(
                    _bound(widget.max),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      color: settingsSubtext(context),
                    ),
                  ),
                ],
              ),
            ],

            if (showError) ...[
              const SizedBox(height: 8),
              Text(
                l10n.settings_value_out_of_range(
                  _bound(widget.min),
                  _bound(widget.max),
                ),
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12,
                  color: const Color(0xFFE05A47),
                ),
              ),
            ],

            const SizedBox(height: 24),
            // On confirm the button draws in to a round tick, then the sheet
            // closes and the row it came from shows the new value.
            LayoutBuilder(
              builder:
                  (context, constraints) => Center(
                    child: AnimatedContainer(
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 300),
                      ),
                      curve: Curves.easeOutCubic,
                      width: _saving ? 54 : constraints.maxWidth,
                      height: 54,
                      child: FilledButton(
                        onPressed: _isValid ? () => _confirm(value!) : null,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(54, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _saving ? 27 : 16,
                            ),
                          ),
                          backgroundColor:
                              _saving ? AppColors.primary : kSettingsGreen,
                          disabledBackgroundColor: kSettingsGreen.withValues(
                            alpha: 0.35,
                          ),
                          foregroundColor: const Color(0xFFF0FDF4),
                        ),
                        child:
                            _saving
                                ? ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: _saveTick,
                                    curve: const Interval(
                                      .35,
                                      1,
                                      curve: AppMotion.springCurve,
                                    ),
                                  ),
                                  child: const Icon(WaznIcons.check, size: 24),
                                )
                                : Text(
                                  l10n.common_confirm,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                ),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.common_cancel,
                  style: TextStyle(color: settingsSubtext(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: settingsSubtext(context).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 20, color: settingsText(context)),
        ),
      ),
    );
  }
}

String getLanguageName(String code) {
  switch (code) {
    case 'ar':
      return 'العربية';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    default:
      return 'English';
  }
}

void showLanguageSelector(
  BuildContext context,
  UserSettings settings,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: settingsBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : kSettingsLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.settings_select_language,
                  style: AppTypography.heading3.copyWith(
                    color: settingsText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.settings_language_desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: settingsSubtext(context),
                  ),
                ),
                const SizedBox(height: 24),
                LanguageTile(
                  title: 'English',
                  subtitle: AppLocalizations.of(context)!.settings_lang_en_desc,
                  code: 'en',
                  selected: settings.languageCode == 'en',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                LanguageTile(
                  title: 'العربية',
                  subtitle: AppLocalizations.of(context)!.settings_lang_ar_desc,
                  code: 'ar',
                  selected: settings.languageCode == 'ar',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('ar');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                LanguageTile(
                  title: 'Español',
                  subtitle: AppLocalizations.of(context)!.settings_lang_es_desc,
                  code: 'es',
                  selected: settings.languageCode == 'es',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('es');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                LanguageTile(
                  title: 'Français',
                  subtitle: AppLocalizations.of(context)!.settings_lang_fr_desc,
                  code: 'fr',
                  selected: settings.languageCode == 'fr',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('fr');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const LanguageTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected
                  ? kSettingsGreenText.withValues(alpha: isDark ? 0.16 : 0.09)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0x00FFFFFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? kSettingsGreenText.withValues(alpha: 0.24)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : kSettingsLine),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    selected
                        ? kSettingsGreenText
                        : kSettingsMuted.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Text(
                code.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          selected ? kSettingsGreenText : settingsText(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: settingsSubtext(context),
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(WaznIcons.success, color: kSettingsGreenText),
          ],
        ),
      ),
    );
  }
}

/// The standard Settings row: icon, title, optional trailing value, chevron.
/// [value] carries live state ("2,000 kcal", "Connected") — never decorative
/// copy. [destructive] renders the row in the error color with no chevron.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;

  /// A second line under the title, for the one thing a row cannot say with
  /// its name alone — what a setting affects, or what a number is a share of.
  /// Rows that need no explanation do not get one; a subtitle on every row is
  /// noise, and noise is what makes the one that matters invisible.
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? trailing;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.destructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : kSettingsGreenText;

    return _ValueFlash(
      value: value,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              onTap == null
                  ? null
                  : () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                // A bare glyph, not a tinted well. Every row carrying the same
                // mint square made the icons read as a texture down the left
                // edge rather than as signposts — colour that marks everything
                // marks nothing. The accent is kept for the destructive row,
                // where it actually means something.
                SizedBox(
                  width: 32,
                  child: Icon(
                    icon,
                    size: 19,
                    color:
                        destructive
                            ? accent
                            : settingsText(context).withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color:
                              destructive
                                  ? AppColors.error
                                  : settingsText(context),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: AppTypography.labelSmall.copyWith(
                              color: settingsSubtext(context),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null && value!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  // A new value slides up into place of the old.
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 380),
                      ),
                      switchInCurve: AppMotion.springCurve,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder:
                          (current, previous) => Stack(
                            alignment: AlignmentDirectional.centerEnd,
                            children: [
                              ...previous,
                              if (current != null) current,
                            ],
                          ),
                      transitionBuilder: (child, animation) {
                        final incoming = child.key == ValueKey(value);
                        return ClipRect(
                          child: SlideTransition(
                            position: Tween(
                              begin: Offset(0, incoming ? .9 : -.9),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        value!,
                        key: ValueKey(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: settingsSubtext(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (!destructive) ...[
                  const SizedBox(width: 8),
                  Icon(
                    WaznIcons.chevronRight,
                    size: 14,
                    color: settingsSubtext(context).withValues(alpha: 0.55),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A brief green wash over a row whose value just changed, so an edit made
/// in a sheet is seen landing back on the row it came from.
class _ValueFlash extends StatefulWidget {
  const _ValueFlash({required this.value, required this.child});

  final String? value;
  final Widget child;

  @override
  State<_ValueFlash> createState() => _ValueFlashState();
}

class _ValueFlashState extends State<_ValueFlash>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: 1,
  );

  @override
  void didUpdateWidget(_ValueFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value ||
        oldWidget.value == null ||
        widget.value == null) {
      return;
    }
    runWhenVisible(() {
      if (!AppMotion.reduceMotion(context)) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final v = _controller.value;
        final strength = v >= 1 ? 0.0 : (v < .2 ? v / .2 : 1 - (v - .2) / .8);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: kSettingsGreenText.withValues(alpha: .14 * strength),
          ),
          child: child,
        );
      },
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = kSettingsGreenText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: accent, size: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: settingsText(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: settingsSubtext(context),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.3,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (next) {
              HapticFeedback.selectionClick();
              onChanged(next);
            },
            activeThumbColor: kSettingsGreenText,
          ),
        ],
      ),
    );
  }
}

class SettingsThemeRow extends ConsumerWidget {
  final String currentMode;

  const SettingsThemeRow({super.key, required this.currentMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      (
        'system',
        AppLocalizations.of(context)!.settings_theme_system,
        WaznIcons.smartphone,
      ),
      (
        'light',
        AppLocalizations.of(context)!.settings_theme_light,
        WaznIcons.lunch,
      ),
      (
        'dark',
        AppLocalizations.of(context)!.settings_theme_dark,
        WaznIcons.dinner,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Label row ───
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kSettingsGreenText.withValues(
                    alpha: isDark ? 0.14 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    WaznIcons.theme,
                    color: kSettingsGreenText,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                AppLocalizations.of(context)!.settings_appearance,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: settingsText(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ─── Segmented picker — full width below, indented past icon ───
          // One thumb slides to the option picked, and the new look spreads
          // out in a circle from the tap.
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : kSettingsLine.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedAlign(
                      alignment: switch (options.indexWhere(
                        (o) => o.$1 == currentMode,
                      )) {
                        0 => AlignmentDirectional.centerStart,
                        1 => AlignmentDirectional.center,
                        _ => AlignmentDirectional.centerEnd,
                      },
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 420),
                      ),
                      curve: AppMotion.springCurve,
                      child: FractionallySizedBox(
                        widthFactor: 1 / 3,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.09)
                                    : kSettingsBgLight,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.15 : 0.05,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children:
                        options.map((opt) {
                          final isSelected = currentMode == opt.$1;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) {
                                if (isSelected) return;
                                HapticFeedback.selectionClick();
                                ThemeReveal.run(
                                  context,
                                  origin: details.globalPosition,
                                  change:
                                      () =>
                                          settingsNotifier.setThemeMode(opt.$1),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    opt.$3,
                                    size: 13,
                                    color:
                                        isSelected
                                            ? kSettingsGreenText
                                            : settingsSubtext(context),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    opt.$2,
                                    style: AppTypography.labelMedium.copyWith(
                                      fontSize: 12,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? kSettingsGreenText
                                              : settingsSubtext(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsAuthSnapshot {
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoURL;

  const SettingsAuthSnapshot({
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoURL,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAuthSnapshot &&
          isAnonymous == other.isAnonymous &&
          displayName == other.displayName &&
          email == other.email &&
          photoURL == other.photoURL;

  @override
  int get hashCode => Object.hash(isAnonymous, displayName, email, photoURL);
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? Colors.white54 : const Color(0xFFB4AFA8),
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
        ),
        SettingsSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children:
                children
                    .expand(
                      (child) => [
                        child,
                        if (child != children.last)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : kSettingsLine,
                            indent: 62,
                            endIndent: 16,
                          ),
                      ],
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }
}

class SettingsSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SettingsSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFFEFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : kSettingsLine,
          width: 0.8,
        ),
      ),
      child: child,
    );
  }
}

String localizeGender(BuildContext context, String gender) {
  final l10n = AppLocalizations.of(context)!;
  switch (gender.toLowerCase()) {
    case 'male':
      return l10n.settings_gender_male;
    case 'female':
      return l10n.settings_gender_female;
    case 'other':
      return l10n.settings_gender_other;
    default:
      return gender;
  }
}

String localizeUnit(BuildContext context, String unit) {
  final l10n = AppLocalizations.of(context)!;
  switch (unit.toLowerCase()) {
    case 'kg':
      return l10n.settings_unit_kg;
    case 'lb':
      return l10n.settings_unit_lb;
    case 'cm':
      return l10n.settings_unit_cm;
    case 'in':
    case 'ft':
      return l10n.settings_unit_in;
    default:
      return unit;
  }
}

String localizeOption(BuildContext context, String option) {
  final l10n = AppLocalizations.of(context)!;
  final normalized = option.toLowerCase();
  if (normalized == 'male' || normalized == 'female' || normalized == 'other') {
    return localizeGender(context, normalized);
  }
  if (normalized == 'kg' ||
      normalized == 'lb' ||
      normalized == 'cm' ||
      normalized == 'in') {
    return localizeUnit(context, normalized);
  }
  if (normalized == 'yrs') {
    return l10n.settings_age_unit;
  }
  if (normalized == 'ml') {
    return l10n.settings_unit_ml;
  }
  if (normalized == 'steps') {
    return l10n.settings_unit_steps;
  }
  if (normalized == 'kcal') {
    return l10n.settings_kcal_unit;
  }
  if (normalized == 'g') {
    return l10n.settings_grams_unit;
  }
  return option;
}

/// A number as typed, with either decimal mark: "70,5" is how French,
/// Spanish and Arabic keyboards write 70.5.
double? parseDecimalInput(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// Whether a stored height unit means feet and inches. Imperial heights are
/// kept in inches; "ft" is what an older units picker saved.
bool isImperialHeight(String? unit) => unit == 'in' || unit == 'ft';

/// How much is left toward [target], in the goal's own direction. Zero or
/// less means reached or passed: it used to be the plain distance, so going
/// past a weight-loss goal read as "2 kg left to reach target".
double weightLeftToGoal({
  required double start,
  required double current,
  required double target,
}) => target < start ? current - target : target - current;

/// A stored "19:30" as this phone tells the time: "7:30 PM" on a 12-hour
/// phone, in the app's language.
String formatReminderTime(BuildContext context, String hhmm) {
  final parts = hhmm.split(':');
  final hour = int.tryParse(parts.first);
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (hour == null || minute == null) return hhmm;
  return TimeOfDay(hour: hour, minute: minute).format(context);
}
