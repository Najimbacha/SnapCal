import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

/// The four tabs, in the order the bar lays them out: two to the left of the
/// scan button's notch, two to its right.
enum NavTab { home, log, stats, profile }

const _navIcons = <NavTab, IconData>{
  NavTab.home: LucideIcons.home,
  NavTab.log: LucideIcons.clipboardList,
  NavTab.stats: LucideIcons.barChart2,
  NavTab.profile: LucideIcons.user,
};

String _navLabel(BuildContext context, NavTab tab) {
  final l10n = AppLocalizations.of(context)!;
  return switch (tab) {
    NavTab.home => l10n.nav_home,
    NavTab.log => l10n.nav_log,
    NavTab.stats => l10n.nav_stats,
    NavTab.profile => l10n.nav_profile,
  };
}

/// The docked bottom bar.
///
/// The selected tab wears a tinted pill behind its icon. When the selection
/// moves, the pill does not blink off and on: it fades and shrinks away on the
/// tab being left while it grows in on the tab arriving, so the eye follows
/// one movement rather than seeing two separate changes.
class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 260),
    vsync: this,
    value: 1,
  );

  /// The tab the pill is leaving, and the one it is arriving at.
  late int _from = widget.currentIndex;
  late int _to = widget.currentIndex;

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == oldWidget.currentIndex) return;
    // Hand the pill over from wherever it currently is, so a tap mid-flight
    // carries on from the position on screen instead of jumping.
    _from = _controller.isAnimating ? _to : oldWidget.currentIndex;
    _to = widget.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navHeight = Responsive.navBarHeight(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColor = Theme.of(
      context,
    ).scaffoldBackgroundColor.withValues(alpha: isDark ? 0.94 : 0.96);

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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // The notch sits in the middle, so each side of the bar has to
                // keep half the width or the tabs drift off-centre.
                return Row(
                  children: [
                    _side(const [NavTab.home, NavTab.log], navHeight),
                    const SizedBox(width: 76),
                    _side(const [NavTab.stats, NavTab.profile], navHeight),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.18);
  }

  Widget _side(List<NavTab> tabs, double navHeight) => Expanded(
    child: Row(
      children: [
        for (final tab in tabs)
          Expanded(child: _buildNavItem(context, tab, navHeight)),
      ],
    ),
  );

  Widget _buildNavItem(BuildContext context, NavTab tab, double navHeight) {
    final index = tab.index;
    final progress = Curves.easeOutCubic.transform(_controller.value);
    // 1 when this tab holds the pill, 0 when it has none, and in between while
    // the pill is handing over.
    final selection =
        (index == _to ? progress : 0.0) + (index == _from ? 1 - progress : 0.0);
    final isSelected = index == widget.currentIndex;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? Colors.white.withValues(alpha: 0.34) : const Color(0xFFA8A29E);
    final tabColor =
        Color.lerp(inactiveColor, AppColors.primary, selection) ??
        inactiveColor;
    final label = _navLabel(context, tab);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap(index);
          },
          child: SizedBox(
            height: navHeight,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: selection,
                      child: Transform.scale(
                        scale: 0.82 + 0.18 * selection,
                        child: Container(
                          width: 44,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.22 : 0.13,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -2 * selection),
                      child: Icon(_navIcons[tab], color: tabColor, size: 23),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0,
                    fontWeight:
                        selection > 0.5 ? FontWeight.w800 : FontWeight.w700,
                    color: tabColor,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
