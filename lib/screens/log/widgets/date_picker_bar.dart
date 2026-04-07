import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart' as app_date;

import '../../../widgets/glass_container.dart';

/// Date picker bar with navigation arrows
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

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderRadius: 24,
      backgroundColor: context.surfaceColor.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          _NavButton(icon: LucideIcons.chevronLeft, onPressed: onPrevious),

          // Date display
          Expanded(
            child: GestureDetector(
              onTap: !isToday ? onToday : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    app_date.DateUtils.getDateLabel(selectedDate),
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 10,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Return to Today',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                              textBaseline: TextBaseline.alphabetic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Next button
          _NavButton(
            icon: LucideIcons.chevronRight,
            onPressed: isFuture ? null : onNext,
            isDisabled: isFuture,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDisabled;

  const _NavButton({
    required this.icon,
    this.onPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              isDisabled
                  ? context.cardSoftColor.withValues(alpha: 0.5)
                  : context.cardSoftColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color:
              isDisabled
                  ? context.textMutedColor.withOpacity(0.5)
                  : context.textSecondaryColor,
          size: 20,
        ),
      ),
    );
  }
}
