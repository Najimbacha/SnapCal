import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_typography.dart';
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
    final navHeight = Responsive.navBarHeight(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColor =
        isDark
            ? const Color(0xFF14130F).withValues(alpha: 0.94)
            : const Color(0xFFF9F8F5).withValues(alpha: 0.96);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: BottomAppBar(
          height: navHeight + 8,
          elevation: 0,
          notchMargin: 12,
          shape: const CircularNotchedRectangle(),
          color: navColor,
          surfaceTintColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE8E4DC),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    context,
                    0,
                    LucideIcons.home,
                    AppLocalizations.of(context)!.nav_home,
                    navHeight,
                  ),
                ),
                const SizedBox(width: 96),
                Expanded(
                  child: _buildNavItem(
                    context,
                    1,
                    LucideIcons.clipboardList,
                    AppLocalizations.of(context)!.nav_log,
                    navHeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.18);
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    double navHeight,
  ) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF1A3D2B);
    final inactiveColor =
        isDark ? Colors.white.withValues(alpha: 0.34) : const Color(0xFFA8A29E);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap(index);
          },
          child: SizedBox(
            height: navHeight,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  scale: isSelected ? 1.06 : 1.0,
                  child: Icon(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 11,
                    letterSpacing: 0,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 82),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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
