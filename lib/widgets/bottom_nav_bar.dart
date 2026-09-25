import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'wazn_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

/// The four tabs, in the order the bar lays them out: two to the left of the
/// scan button's notch, two to its right.
enum NavTab { home, log, stats, profile }

const _navIcons = <NavTab, IconData>{
  NavTab.home: WaznIcons.home,
  NavTab.log: WaznIcons.log,
  NavTab.stats: WaznIcons.stats,
  NavTab.profile: WaznIcons.profile,
};

/// The selected tab shows the filled version of its icon.
const _navIconsSelected = <NavTab, IconData>{
  NavTab.home: WaznIcons.homeFilled,
  NavTab.log: WaznIcons.logFilled,
  NavTab.stats: WaznIcons.statsFilled,
  NavTab.profile: WaznIcons.profileFilled,
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
/// moves, the pill slides across to the new tab, stretching a little as it
/// travels and landing with a small overshoot, and the new tab's icon gives a
/// bounce. One movement for the eye to follow, not a blink off and on.
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
    duration: const Duration(milliseconds: 480),
    vsync: this,
    value: 1,
  );

  /// The pill's travel so far, overshooting 1 briefly as it lands.
  double get _travel => AppMotion.springCurve.transform(_controller.value);

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
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
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
            child: LayoutBuilder(
              builder:
                  (context, constraints) => AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      // The notch sits in the middle, so each side of the bar
                      // has to keep half the width or the tabs drift
                      // off-centre.
                      final tabWidth = (constraints.maxWidth - _notchGap) / 4;
                      return Row(
                        children: [
                          _side(
                            const [NavTab.home, NavTab.log],
                            navHeight,
                            tabWidth,
                          ),
                          const SizedBox(width: _notchGap),
                          _side(
                            const [NavTab.stats, NavTab.profile],
                            navHeight,
                            tabWidth,
                          ),
                        ],
                      );
                    },
                  ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.18);
  }

  static const double _notchGap = 76;

  /// Where tab [index]'s centre sits, from the bar's leading edge.
  static double _centre(int index, double tabWidth) =>
      index < 2 ? tabWidth * (index + .5) : tabWidth * (index + .5) + _notchGap;

  Widget _side(List<NavTab> tabs, double navHeight, double tabWidth) =>
      Expanded(
        child: Row(
          children: [
            for (final tab in tabs)
              Expanded(child: _buildNavItem(context, tab, navHeight, tabWidth)),
          ],
        ),
      );

  Widget _buildNavItem(
    BuildContext context,
    NavTab tab,
    double navHeight,
    double tabWidth,
  ) {
    final index = tab.index;
    final colorProgress = Curves.easeOutCubic.transform(_controller.value);
    // 1 when this tab is the selection, 0 when it is not, in between while the
    // colour hands over.
    final selection =
        (index == _to ? colorProgress : 0.0) +
        (index == _from ? 1 - colorProgress : 0.0);
    final isSelected = index == widget.currentIndex;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The pill belongs to the arriving tab and is drawn shifted back towards
    // the tab it left, closing the gap as it travels.
    final gap =
        (_centre(_from, tabWidth) - _centre(_to, tabWidth)) * (rtl ? -1 : 1);
    final travel = _travel;
    final pillShift = _from == _to ? 0.0 : gap * (1 - travel);
    final stretch =
        1 + .32 * math.sin(math.pi * _controller.value.clamp(0.0, 1.0));
    // The arriving icon bounces: up past full size, a touch under, settled.
    final bounce =
        index == _to && _from != _to && _controller.value < 1
            ? TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 1, end: 1.2), weight: 30),
              TweenSequenceItem(tween: Tween(begin: 1.2, end: .94), weight: 30),
              TweenSequenceItem(tween: Tween(begin: .94, end: 1), weight: 40),
            ]).transform(_controller.value)
            : 1.0;

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
                  clipBehavior: Clip.none,
                  children: [
                    if (index == _to)
                      Transform.translate(
                        offset: Offset(pillShift, 0),
                        child: Container(
                          width: 44 * stretch,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.22 : 0.13,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 44, height: 30),
                    Transform.translate(
                      offset: Offset(0, -2 * selection),
                      child: Transform.scale(
                        scale: bounce,
                        child: Icon(
                          selection > 0.5
                              ? _navIconsSelected[tab]
                              : _navIcons[tab],
                          color: tabColor,
                          size: 23,
                        ),
                      ),
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
