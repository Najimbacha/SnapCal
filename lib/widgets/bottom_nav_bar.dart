import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_utils.dart';
import 'ui_blocks.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: BottomAppBar(
          elevation: 0,
          notchMargin: 10,
          height: navHeight,
          color: colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.7),
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
        ),
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

    return AppScaleTap(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isSelected ? 1.1 : 1.0,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected 
                  ? colorScheme.primary.withValues(alpha: 0.12) 
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ] : [],
              ),
              child: Icon(
                icon, 
                color: color, 
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: -0.2,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
