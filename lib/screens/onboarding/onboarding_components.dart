import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/widgets/app_icon.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import 'onboarding_draft.dart';

class SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = context.primaryColor;
    final bg =
        selected
            ? accent.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark
                ? Colors.white.withValues(alpha: 0.035)
                : Colors.white.withValues(alpha: 0.82));
    final borderColor =
        selected
            ? accent.withValues(alpha: 0.72)
            : context.cardBorderColor.withValues(alpha: isDark ? 0.7 : 1.0);
    final borderWidth = selected ? 1.6 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    selected
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.035)),
                gradient: selected ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? Colors.white : context.textMutedColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? AppSymbols.checkCircle2 : AppSymbols.circle,
              color:
                  selected
                      ? accent
                      : context.textMutedColor.withValues(alpha: 0.55),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = loading || onTap == null;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              isDisabled
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06))
                  : null,
          gradient: isDisabled ? null : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isDisabled
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: isDark ? 0.14 : 0.22),
          ),
          boxShadow:
              isDisabled
                  ? null
                  : [
                    BoxShadow(
                      color: context.primaryColor.withValues(
                        alpha: isDark ? 0.34 : 0.24,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 13),
                    ),
                  ],
        ),
        child: Center(
          child:
              loading
                  ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.black : Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                  : Text(
                    text,
                    style: TextStyle(
                      color:
                          isDisabled
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.2))
                              : Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const SecondaryButton({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class MetricInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  const MetricInput({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            label,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color:
                context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.045)
                    : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: context.textMutedColor,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class MeasurementToggle extends StatelessWidget {
  final MeasurementSystem value;
  final ValueChanged<MeasurementSystem> onChanged;

  const MeasurementToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.14 : 0.035,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: 'Metric',
              active: value == MeasurementSystem.metric,
              onTap: () => onChanged(MeasurementSystem.metric),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Imperial',
              active: value == MeasurementSystem.imperial,
              onTap: () => onChanged(MeasurementSystem.imperial),
            ),
          ),
        ],
      ),
    );
  }
}

class AppleValuePickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Key? rowKey;

  const AppleValuePickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.rowKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      key: rowKey,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.055)
                  : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.cardBorderColor.withValues(alpha: isDark ? 0.7 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.028),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              AppSymbols.chevronRight,
              size: 18,
              color: context.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppleWheelPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required T value,
  required String Function(T value) labelBuilder,
  Key? pickerKey,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = context.isDarkMode;
  final selectedIndex = values.indexOf(value).clamp(0, values.length - 1);
  var tempValue = values[selectedIndex];

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.28),
    builder: (sheetContext) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(sheetContext).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? context.cardColor.withValues(alpha: 0.96)
                      : context.cardColor.withValues(alpha: 0.98),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.7),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.18,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(
                          l10n.common_cancel,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed:
                            () => Navigator.of(sheetContext).pop(tempValue),
                        child: Text(
                          l10n.common_done,
                          style: TextStyle(
                            color: context.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
                SizedBox(
                  height: 216,
                  child: CupertinoPicker.builder(
                    key: pickerKey,
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    itemExtent: 42,
                    diameterRatio: 1.55,
                    magnification: 1.08,
                    useMagnifier: true,
                    selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                      background: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.055 : 0.045),
                    ),
                    onSelectedItemChanged: (index) {
                      if (index < 0 || index >= values.length) return;
                      HapticFeedback.selectionClick();
                      tempValue = values[index];
                    },
                    childCount: values.length,
                    itemBuilder: (context, index) {
                      final item = values[index];
                      return Center(
                        child: Text(
                          labelBuilder(item),
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
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

class CompactWheelPicker<T> extends StatefulWidget {
  final List<T> values;
  final T value;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;
  final double height;
  final double itemExtent;
  final Key? wheelKey;

  const CompactWheelPicker({
    super.key,
    required this.values,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
    this.height = 78,
    this.itemExtent = 34,
    this.wheelKey,
  });

  @override
  State<CompactWheelPicker<T>> createState() => _CompactWheelPickerState<T>();
}

class _CompactWheelPickerState<T> extends State<CompactWheelPicker<T>> {
  late FixedExtentScrollController _controller;

  int get _selectedIndex {
    final index = widget.values.indexOf(widget.value);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(CompactWheelPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _selectedIndex;
    if (oldWidget.values != widget.values) {
      final oldController = _controller;
      _controller = FixedExtentScrollController(initialItem: nextIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    } else if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.jumpToItem(nextIndex);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.045)
                : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: widget.itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(
                alpha: isDark ? 0.12 : 0.08,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.22),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            key: widget.wheelKey,
            controller: _controller,
            itemExtent: widget.itemExtent,
            diameterRatio: 1.8,
            magnification: 1.06,
            useMagnifier: true,
            overAndUnderCenterOpacity: 0.36,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              if (index < 0 || index >= widget.values.length) return;
              HapticFeedback.selectionClick();
              widget.onChanged(widget.values[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.values.length,
              builder: (context, index) {
                final value = widget.values[index];
                final selected = value == widget.value;
                return Center(
                  child: Text(
                    widget.labelBuilder(value),
                    style: TextStyle(
                      color:
                          selected
                              ? context.textPrimaryColor
                              : context.textSecondaryColor,
                      fontSize: selected ? 18 : 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? null : Colors.transparent,
          gradient: active ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              active
                  ? [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : context.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyNote extends StatelessWidget {
  final String text;

  const PrivacyNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 8),
            child: Icon(
              AppSymbols.shield,
              size: 14,
              color: context.textMutedColor,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalorieHero extends StatelessWidget {
  final int calories;

  const CalorieHero({super.key, required this.calories});

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: context.isDarkMode ? 0.22 : 0.13),
            AppColors.tertiarySeed.withValues(
              alpha: context.isDarkMode ? 0.12 : 0.06,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: context.accentGlow(accent),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                calories.toString(),
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  AppLocalizations.of(context)!.onboarding_scan_kcal,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.onboarding_plan_kcal_day,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class MacroRow extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;

  const MacroRow({
    super.key,
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.045)
                : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.10 : 0.025,
            ),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${grams}g',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StepTitle extends StatelessWidget {
  final String title;
  final String? body;

  const StepTitle({super.key, required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class StepPageTransition extends StatelessWidget {
  final Widget child;

  const StepPageTransition({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0.0, 0.03),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}
