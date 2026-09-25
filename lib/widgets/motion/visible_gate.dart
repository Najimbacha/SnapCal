import 'package:flutter/widgets.dart';

/// Holds an animation back until its widget is on screen.
///
/// The tabs live in an indexed stack, so Home keeps building while the camera
/// is up: a meal saved from the scan screen changes Home's numbers before Home
/// is visible. Started there, an animation would run muted and be finished by
/// the time anyone looks. Anything started through [runWhenVisible] waits for
/// the surrounding [TickerMode] to turn on instead.
mixin VisibleGate<T extends StatefulWidget> on State<T> {
  bool _visible = false;
  VoidCallback? _pending;

  /// Whether tickers are enabled here, i.e. whether this is on screen.
  bool get isVisible => _visible;

  /// Runs [action] now if this is on screen, otherwise as soon as it is. A
  /// later call replaces one still waiting.
  void runWhenVisible(VoidCallback action) {
    if (_visible && mounted) {
      action();
    } else {
      _pending = action;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    final pending = _pending;
    if (_visible && pending != null) {
      _pending = null;
      // After this frame, so the animation starts from what was last painted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) pending();
      });
    }
  }
}
