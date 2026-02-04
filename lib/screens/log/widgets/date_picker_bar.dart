import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart' as app_date;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          _NavButton(icon: LucideIcons.chevronLeft, onPressed: onPrevious),

          // Date display
          GestureDetector(
            onTap: !isToday ? onToday : null,
            child: Column(
              children: [
                Text(
                  app_date.DateUtils.getDateLabel(selectedDate),
                  style: AppTypography.heading3,
                ),
                if (!isToday)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.arrowRight,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Go to Today',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
          color: isDisabled
              ? AppColors.surfaceLight.withAlpha(50)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? AppColors.textMuted.withAlpha(100)
              : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
