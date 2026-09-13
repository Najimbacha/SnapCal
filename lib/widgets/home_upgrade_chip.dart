import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../l10n/generated/app_localizations.dart';

/// The free-user upgrade affordance for the home top bar: a compact premium
/// pill that opens the paywall. Paid users see the Pro gem instead, so this is
/// only ever shown when there is something to upgrade to.
class HomeUpgradeChip extends StatelessWidget {
  const HomeUpgradeChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: l10n.home_upgrade_chip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(
                    alpha: isDark ? 0.38 : 0.28,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(11, 7, 13, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.crown,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.home_upgrade_chip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
