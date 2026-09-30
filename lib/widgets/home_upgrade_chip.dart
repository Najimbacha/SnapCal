import 'package:flutter/material.dart';
import 'wazn_icons.dart';

import '../core/theme/theme_colors.dart';
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

    // The same solid green as every other button in the app, not the
    // green-to-gold gradient the paywall uses.
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
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(11, 7, 13, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(WaznIcons.pro, color: context.onPrimaryColor, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    l10n.home_upgrade_chip,
                    style: TextStyle(
                      color: context.onPrimaryColor,
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
