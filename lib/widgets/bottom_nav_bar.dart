import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_utils.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navHeight = Responsive.navBarHeight(context);

    return BottomAppBar(
      elevation: 8,
      notchMargin: 10,
      height: navHeight,
      color: colorScheme.surface,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, LucideIcons.home, AppLocalizations.of(context)!.nav_home),
          _buildNavItem(context, 1, LucideIcons.clipboardList, AppLocalizations.of(context)!.nav_log),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(context, 2, LucideIcons.barChart3, AppLocalizations.of(context)!.nav_stats),
          _buildNavItem(context, 3, LucideIcons.user, AppLocalizations.of(context)!.nav_profile),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
