import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_kit.dart';

/// A short beat between the last answer and the plan: three lines tick off,
/// then [onDone]. The plan itself is already worked out; this is the moment
/// that says the answers were used.
class BuildingStep extends StatefulWidget {
  const BuildingStep({super.key, required this.onDone});

  final VoidCallback onDone;

  /// How long each line takes; the whole screen is about two seconds.
  static const lineDuration = Duration(milliseconds: 550);

  @override
  State<BuildingStep> createState() => _BuildingStepState();
}

class _BuildingStepState extends State<BuildingStep> {
  final _timers = <Timer>[];
  int _done = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timers.isNotEmpty) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final step =
        reduce ? const Duration(milliseconds: 200) : BuildingStep.lineDuration;
    for (var i = 1; i <= 3; i++) {
      _timers.add(
        Timer(step * i, () {
          if (!mounted) return;
          HapticFeedback.lightImpact();
          setState(() => _done = i);
        }),
      );
    }
    _timers.add(
      Timer(step * 3 + const Duration(milliseconds: 300), () {
        if (mounted) widget.onDone();
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = [
      l10n.onb_building_needs,
      l10n.onb_building_pace,
      l10n.onb_building_macros,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A ring that keeps filling towards the next line's tick.
              Center(
                child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ((_done + 1) / 3).clamp(0, 1)),
                    duration: AppMotion.maybeZero(
                      context,
                      BuildingStep.lineDuration,
                    ),
                    curve: Curves.easeInOut,
                    builder:
                        (context, t, _) => _Ring(
                          key: const ValueKey('onboarding-building-ring'),
                          progress: t,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  l10n.onb_building_title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 18),
                _BuildLine(
                  text: lines[i],
                  state:
                      i < _done
                          ? _LineState.done
                          : (i == _done
                              ? _LineState.running
                              : _LineState.waiting),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _LineState { waiting, running, done }

class _BuildLine extends StatelessWidget {
  const _BuildLine({required this.text, required this.state});

  final String text;
  final _LineState state;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final marker = switch (state) {
      _LineState.done => Container(
        key: const ValueKey('done'),
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        child: const Icon(AppSymbols.check, size: 15, color: Colors.white),
      ),
      _LineState.running => SizedBox(
        key: const ValueKey('running'),
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
      ),
      _LineState.waiting => Container(
        key: const ValueKey('waiting'),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.cardBorderColor, width: 2),
        ),
      ),
    };
    return Row(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          // Each tick pops in a little past full size as its line finishes.
          child: AnimatedSwitcher(
            duration: AppMotion.maybeZero(
              context,
              const Duration(milliseconds: 420),
            ),
            transitionBuilder:
                (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.springCurve,
                    reverseCurve: Curves.easeIn,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
            child: marker,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.maybeZero(context, AppMotion.expansion),
            // Merged onto the inherited style, which carries the app's font.
            style: DefaultTextStyle.of(context).style.merge(
              TextStyle(
                color:
                    state == _LineState.waiting
                        ? context.textMutedColor
                        : context.textPrimaryColor,
                fontSize: 16,
                fontWeight:
                    state == _LineState.running
                        ? FontWeight.w700
                        : FontWeight.w500,
              ),
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }
}

/// The progress ring above the lines, with the share done in its middle.
class _Ring extends StatelessWidget {
  const _Ring({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: context.primaryColor,
              backgroundColor: context.onbFill,
            ),
          ),
          Text(
            NumberFormat.percentPattern(locale).format(progress),
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
