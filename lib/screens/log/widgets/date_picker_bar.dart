import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../widgets/ui_blocks.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

/// Elite Date picker bar with navigation and today shortcut
class DatePickerBar extends StatelessWidget {
  final String selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  const DatePickerBar({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = app_date.DateUtils.isToday(selectedDate);
    final isFuture = app_date.DateUtils.isFuture(selectedDate);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.glassBorderColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          _EliteNavButton(icon: LucideIcons.chevronLeft, onTap: onPrevious),

          // Date display
          Expanded(
            child: GestureDetector(
              onTap: !isToday ? onToday : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    app_date.DateUtils.getDateLabel(selectedDate, l10n: l10n),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.calendarClock,
                            size: 10,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.log_return_today,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: context.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                ],
              ),
            ),
          ),

          // Next button
          _EliteNavButton(
            icon: LucideIcons.chevronRight,
            onTap: isFuture ? null : onNext,
            isDisabled: isFuture,
          ),
        ],
      ),
    );
  }
}

class _EliteNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _EliteNavButton({
    required this.icon,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap:
          isDisabled
              ? null
              : () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color:
              isDisabled
                  ? context.textMutedColor.withValues(alpha: 0.05)
                  : context.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDisabled
                    ? Colors.transparent
                    : context.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color:
              isDisabled
                  ? context.textMutedColor.withValues(alpha: 0.3)
                  : context.primaryColor,
          size: 20,
        ),
      ),
    );
  }
}
