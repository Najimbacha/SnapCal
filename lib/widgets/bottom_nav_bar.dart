import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reimagined bottom navigation bar - Floating Glass Dock
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Stack(
        clipBehavior: Clip.none, // Allow scan button to overflow
        alignment: Alignment.bottomCenter,
        children: [
          // Glass Background Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: context.surfaceColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: context.glassBorderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Home
                    _NavItem(
                      icon: LucideIcons.home,
                      isSelected: currentIndex == 0,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(0);
                      },
                    ),
                    // Log
                    _NavItem(
                      icon: LucideIcons.clipboardList,
                      isSelected: currentIndex == 1,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(1);
                      },
                    ),
                    // Placeholder for center button (keeps spacing)
                    const SizedBox(width: 72),
                    // Stats
                    _NavItem(
                      icon: LucideIcons.barChart3,
                      isSelected: currentIndex == 3,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(3);
                      },
                    ),
                    // Profile (Settings)
                    _NavItem(
                      icon: LucideIcons.user,
                      isSelected: currentIndex == 4,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(4);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating Scan Button (Overlaid)
          Positioned(
            top: -16, // Float above the bar
            child: _ScanHeroButton(
              isSelected: currentIndex == 2,
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap(2);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppColors.primary : context.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            // Selection indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHeroButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _ScanHeroButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: context.textPrimaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              LucideIcons.camera,
              color: Colors.black,
              size: 32,
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 1500.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
