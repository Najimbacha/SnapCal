import 'package:flutter/material.dart';

/// Holds the tab pages, keeping every one alive like an indexed stack, and
/// shows only the current one.
///
/// It used to glide between pages: the one being left faded out while the new
/// one faded in and drifted across. Each of those is an `Opacity` over a whole
/// screen, drawn into its own layer on every frame, with the busy Log page
/// being built and laid out at the same moment. On a mid-range phone that made
/// the bottom bar stutter, most often on the first tap of the Log tab. A tap
/// now switches at once.
class TabSwitcher extends StatelessWidget {
  const TabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          // Off screen pages keep their state, but do not paint, lay out
          // again, run animations or take taps.
          Offstage(
            offstage: i != currentIndex,
            child: TickerMode(
              enabled: i == currentIndex,
              child: IgnorePointer(
                ignoring: i != currentIndex,
                child: children[i],
              ),
            ),
          ),
      ],
    );
  }
}
