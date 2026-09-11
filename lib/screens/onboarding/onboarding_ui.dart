import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import 'onboarding_draft.dart';

// The onboarding's shared parts: one header, one kind of choice, one kind of
// value and one button, so every step reads as the same product. Each step
// used to draw its own cards, with a tinted "selected" wash that read as
// grey-green and a title with nothing under it to say why it was asked.

/// Eyebrow, title and one line of why.
class OnbHeader extends StatelessWidget {
  const OnbHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: TextStyle(
              color: context.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.6,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 15.5,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// One segment per question, filled as they are answered.
class OnbProgress extends StatelessWidget {
  const OnbProgress({super.key, required this.count, required this.current});

  final int count;

  /// The question on screen, from 1.
  final int current;

  @override
  Widget build(BuildContext context) {
    final track =
        context.isDarkMode
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08);
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              height: 6,
              margin: EdgeInsetsDirectional.only(end: i == count - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i < current ? context.primaryColor : track,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}

class OnbBackButton extends StatelessWidget {
  const OnbBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Transform.flip(
            flipX: rtl,
            child: Icon(
              AppSymbols.chevronLeft,
              size: 24,
              color: context.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A choice: a white card with a coloured icon, and a green border and tick
/// when chosen.
class OnbChoiceTile extends StatelessWidget {
  const OnbChoiceTile({
    super.key,
    this.icon,
    this.tint,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    this.footer,
    required this.selected,
    required this.onTap,
    this.stacked = false,
  });

  final IconData? icon;
  final Color? tint;
  final String title;
  final String? subtitle;
  final String? badge;
  final Widget? trailing;

  /// Under the words: room for a detail that would squeeze them if it sat
  /// beside them on a narrow phone.
  final Widget? footer;
  final bool selected;
  final VoidCallback onTap;

  /// Icon above the words, for the two-by-two grid.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final isDark = context.isDarkMode;
    final color = tint ?? accent;

    final iconBubble =
        icon == null
            ? null
            : AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    selected
                        ? color
                        : color.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : color,
              ),
            );
    final check = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.transparent,
        border: Border.all(
          color:
              selected ? accent : context.textMutedColor.withValues(alpha: 0.5),
          width: 1.6,
        ),
      ),
      child:
          selected
              ? const Icon(AppSymbols.check, size: 16, color: Colors.white)
              : null,
    );
    final titleText = Text(
      title,
      style: TextStyle(
        color: context.textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
    final titleRow =
        badge == null
            ? titleText
            : Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [titleText, OnbBadge(label: badge!)],
            );
    final subtitleText =
        subtitle == null
            ? null
            : Text(
              subtitle!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 13,
                height: 1.3,
              ),
            );

    final Widget content;
    if (stacked) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (iconBubble != null) iconBubble,
              const Spacer(),
              check,
            ],
          ),
          const SizedBox(height: 16),
          titleRow,
          if (subtitleText != null) ...[
            const SizedBox(height: 4),
            subtitleText,
          ],
        ],
      );
    } else {
      content = Row(
        children: [
          if (iconBubble != null) ...[iconBubble, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleRow,
                if (subtitleText != null) ...[
                  const SizedBox(height: 3),
                  subtitleText,
                ],
                if (footer != null) ...[const SizedBox(height: 10), footer!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          const SizedBox(width: 12),
          check,
        ],
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : context.cardBorderColor,
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    selected
                        ? accent.withValues(alpha: isDark ? 0.28 : 0.16)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: selected ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}

class OnbBadge extends StatelessWidget {
  const OnbBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A value the user sets by tapping: label on one side, the number large on
/// the other, and a pencil so it reads as editable rather than as an answer
/// already given.
class OnbValueTile extends StatelessWidget {
  const OnbValueTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    this.unit,
    required this.onTap,
    this.hasError = false,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String? unit;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Semantics(
      button: true,
      label: '$label $value ${unit ?? ''}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasError ? AppColors.dangerRed : context.cardBorderColor,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: tint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(AppSymbols.edit, size: 18, color: context.textMutedColor),
            ],
          ),
        ),
      ),
    );
  }
}

class OnbPrimaryButton extends StatelessWidget {
  const OnbPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    final isDark = context.isDarkMode;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fg =
        enabled
            ? Colors.white
            : (isDark
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.3));

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: enabled || loading ? AppColors.primaryGradient : null,
          color:
              enabled || loading
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(18),
          boxShadow:
              enabled
                  ? [
                    BoxShadow(
                      color: context.primaryColor.withValues(
                        alpha: isDark ? 0.35 : 0.28,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child:
                  loading
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (showArrow) ...[
                            const SizedBox(width: 8),
                            Transform.flip(
                              flipX: rtl,
                              child: Icon(
                                AppSymbols.arrowRight,
                                size: 20,
                                color: fg,
                              ),
                            ),
                          ],
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnbUnitToggle extends StatelessWidget {
  const OnbUnitToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.metricLabel,
    required this.imperialLabel,
  });

  final MeasurementSystem value;
  final ValueChanged<MeasurementSystem> onChanged;
  final String metricLabel;
  final String imperialLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    Widget segment(MeasurementSystem system, String label) {
      final active = value == system;
      return GestureDetector(
        onTap: () => onChanged(system),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? context.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            boxShadow:
                active
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  active ? context.textPrimaryColor : context.textSecondaryColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(MeasurementSystem.metric, metricLabel),
          segment(MeasurementSystem.imperial, imperialLabel),
        ],
      ),
    );
  }
}

class OnbSectionLabel extends StatelessWidget {
  const OnbSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecondaryColor,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class OnbErrorText extends StatelessWidget {
  const OnbErrorText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppSymbols.alertCircle,
            size: 16,
            color: AppColors.dangerRed,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.dangerRed,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
