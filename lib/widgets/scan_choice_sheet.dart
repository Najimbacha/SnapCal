import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../l10n/generated/app_localizations.dart';

enum ScanChoice { food, barcode }

Future<void> showScanChoiceSheet({
  required BuildContext context,
  required VoidCallback onFoodScan,
  required VoidCallback onBarcodeScan,
}) async {
  final choice = await showModalBottomSheet<ScanChoice>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _ScanChoiceSheet(),
  );

  if (!context.mounted || choice == null) return;

  switch (choice) {
    case ScanChoice.food:
      onFoodScan();
      break;
    case ScanChoice.barcode:
      onBarcodeScan();
      break;
  }
}

class _ScanChoiceSheet extends StatefulWidget {
  const _ScanChoiceSheet();

  @override
  State<_ScanChoiceSheet> createState() => _ScanChoiceSheetState();
}

class _ScanChoiceSheetState extends State<_ScanChoiceSheet> {
  bool _isChoosing = false;

  void _select(ScanChoice choice) {
    if (_isChoosing) return;
    _isChoosing = true;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottomPadding),
        decoration: BoxDecoration(
          color: d ? const Color(0xFF16171C) : const Color(0xFFFEFCF7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: d ? 0.08 : 0),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: (d ? Colors.white : Colors.black).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scan_choice_title,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: d ? Colors.white : const Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.scan_choice_subtitle,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (d ? Colors.white : const Color(0xFF1C1917))
                              .withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CloseButton(
                  isDark: d,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ScanOption(
              key: const ValueKey('scan-choice-food'),
              icon: LucideIcons.camera,
              highlighted: true,
              title: l10n.scan_choice_food_title,
              subtitle: l10n.scan_choice_food_subtitle,
              isDark: d,
              onTap: () => _select(ScanChoice.food),
            ),
            const SizedBox(height: 8),
            _ScanOption(
              key: const ValueKey('scan-choice-barcode'),
              icon: LucideIcons.scanLine,
              title: l10n.scan_choice_barcode_title,
              subtitle: l10n.scan_choice_barcode_subtitle,
              isDark: d,
              onTap: () => _select(ScanChoice.barcode),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _CloseButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('scan-choice-close'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // The dot stays 32; the padding around it is what makes the target 44.
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.06,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.x,
            size: 15,
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool highlighted;
  final VoidCallback onTap;

  const _ScanOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlighted ? AppColors.primary : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  highlighted
                      ? AppColors.primary.withValues(
                        alpha: isDark ? 0.30 : 0.22,
                      )
                      : (isDark ? Colors.white : Colors.black).withValues(
                        alpha: isDark ? 0.07 : 0.06,
                      ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: highlighted ? AppColors.primaryGradient : null,
                    color:
                        highlighted
                            ? null
                            : AppColors.primary.withValues(
                              alpha: isDark ? 0.14 : 0.09,
                            ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: highlighted ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1917),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.labelSmall.copyWith(
                          color: (isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1917))
                              .withValues(alpha: 0.42),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color:
                      accent ??
                      (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.22,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
