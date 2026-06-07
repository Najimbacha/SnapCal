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

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFA),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scan_choice_title,
                        style: AppTypography.titleMedium.copyWith(
                          color: const Color(0xFF1C1917),
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scan_choice_subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFFB4AFA8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFF78716C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Food scan
              _ScanOption(
                icon: LucideIcons.camera,
                title: l10n.scan_choice_food_title,
                subtitle: l10n.scan_choice_food_subtitle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _select(ScanChoice.food),
              ),
              const SizedBox(height: 10),

              // Barcode scan
              _ScanOption(
                icon: LucideIcons.scanLine,
                title: l10n.scan_choice_barcode_title,
                subtitle: l10n.scan_choice_barcode_subtitle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _select(ScanChoice.barcode),
              ),
            ],
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
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ScanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF1C1917),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFFB4AFA8),
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
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: const Color(0xFFD6D3D1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
