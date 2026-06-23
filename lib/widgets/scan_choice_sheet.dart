import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    barrierColor: Colors.black.withValues(alpha: 0.45),
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomPadding),
        decoration: const BoxDecoration(
          color: Color(0xFFFEFCF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _ScanOption(
              icon: LucideIcons.camera,
              title: l10n.scan_choice_food_title,
              subtitle: l10n.scan_choice_food_subtitle,
              onTap: () => _select(ScanChoice.food),
            ),
            const SizedBox(height: 6),
            _ScanOption(
              icon: LucideIcons.scanLine,
              title: l10n.scan_choice_barcode_title,
              subtitle: l10n.scan_choice_barcode_subtitle,
              onTap: () => _select(ScanChoice.barcode),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF5C5FE0).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF5C5FE0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF1C1917),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFFB4AFA8),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
