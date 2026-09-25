import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_motion.dart';

/// Wraps the whole app so a theme change can spread out in a circle from the
/// finger that asked for it.
///
/// [ThemeReveal.run] takes a picture of the screen as it is, lays it over
/// the app, makes the change underneath, and then opens a growing hole in
/// the picture: the new look shows through from the tap outwards.
class ThemeRevealHost extends StatefulWidget {
  const ThemeRevealHost({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeRevealHost> createState() => _ThemeRevealHostState();
}

class ThemeReveal {
  ThemeReveal._();

  /// Runs [change] -- which switches the theme -- revealed from [origin], a
  /// global position. Without a host, or with reduced motion, or if the
  /// picture cannot be taken, the change simply happens.
  static Future<void> run(
    BuildContext context, {
    required Offset origin,
    required VoidCallback change,
  }) async {
    final host = context.findAncestorStateOfType<_ThemeRevealHostState>();
    if (host == null || AppMotion.reduceMotion(context)) {
      change();
      return;
    }
    await host._reveal(origin, change);
  }
}

class _ThemeRevealHostState extends State<ThemeRevealHost>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _controller;
  ui.Image? _picture;
  Offset _origin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  Future<void> _reveal(Offset origin, VoidCallback change) async {
    final boundary =
        _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (_picture != null || boundary == null || !boundary.hasSize) {
      change();
      return;
    }
    ui.Image picture;
    try {
      picture = await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      change();
      return;
    }
    if (!mounted) {
      picture.dispose();
      change();
      return;
    }
    final local = (context.findRenderObject() as RenderBox?)?.globalToLocal(
      origin,
    );
    setState(() {
      _picture = picture;
      _origin = local ?? origin;
    });
    // The switch happens under the picture, after it is on screen.
    await WidgetsBinding.instance.endOfFrame;
    change();
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposed mid-reveal; the picture goes with it.
    }
    if (!mounted) return;
    setState(() => _picture = null);
    picture.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    _picture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final picture = _picture;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (picture != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder:
                    (context, _) => CustomPaint(
                      painter: _RevealPainter(
                        picture: picture,
                        origin: _origin,
                        progress: Curves.easeInOutCubic.transform(
                          _controller.value,
                        ),
                      ),
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealPainter extends CustomPainter {
  const _RevealPainter({
    required this.picture,
    required this.origin,
    required this.progress,
  });

  final ui.Image picture;
  final Offset origin;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Far enough to reach the furthest corner from the tap.
    final reach = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - origin).distance).reduce(math.max);
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    paintImage(
      canvas: canvas,
      rect: bounds,
      image: picture,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
    canvas.drawCircle(
      origin,
      reach * progress,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.progress != progress ||
      old.picture != picture ||
      old.origin != origin;
}
