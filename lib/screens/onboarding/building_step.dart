import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';

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
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        child: const Icon(AppSymbols.check, size: 15, color: Colors.white),
      ),
      _LineState.running => SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
      ),
      _LineState.waiting => Container(
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
        marker,
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color:
                  state == _LineState.waiting
                      ? context.textMutedColor
                      : context.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
