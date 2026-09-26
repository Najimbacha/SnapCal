import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/wazn_mark.dart';

/// Shown while the app starts.
///
/// The app icon builds itself: the scanning corners draw in, the plate pops,
/// the green ring sweeps round it and a sparkle lands, then the name rises a
/// letter at a time. It is short on purpose -- starting never waits for it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF0B110E);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _between(double begin, double end, [Curve curve = Curves.linear]) =>
      curve.transform(
        ((_controller.value - begin) / (end - begin)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            const name = 'Wazn';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  key: const ValueKey('splash-mark'),
                  size: const Size.square(132),
                  painter: WaznMarkPainter(
                    corners: _between(0, .35, Curves.easeInOutCubic),
                    plate: _between(.18, .45, const Cubic(.34, 1.45, .55, 1)),
                    ring: _between(.3, .72, Curves.easeInOutCubic),
                    sparkle: _between(.62, .88, const Cubic(.34, 1.6, .55, 1)),
                  ),
                ),
                const SizedBox(height: 22),
                Semantics(
                  label: name,
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < name.length; i++)
                          Builder(
                            builder: (context) {
                              final t = _between(
                                .5 + i * .05,
                                .78 + i * .05,
                                Curves.easeOutCubic,
                              );
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(0, 14 * (1 - t)),
                                  child: Text(
                                    name[i],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: _between(.72, 1),
                  child: Text(
                    l10n?.splash_calorie_tracker ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
