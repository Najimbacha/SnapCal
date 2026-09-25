import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_state_provider.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/motion/shine_sweep.dart';
import '../../widgets/motion/visible_gate.dart';
import '../../widgets/motion/word_rise.dart';
import 'onboarding_kit.dart';
import 'widgets/ruler_picker.dart';

/// The first screen: the name, one line of promise, and a still ruler that
/// shows what the next screens feel like.
class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The mark springs in, the name follows, then the promise
                // rises a word at a time.
                Row(
                  children: [
                    Reveal(
                      offset: Offset.zero,
                      scale: .4,
                      duration: const Duration(milliseconds: 700),
                      curve: AppMotion.springCurve,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          AppSymbols.ruler,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Reveal(
                      delay: const Duration(milliseconds: 180),
                      offset: const Offset(-8, 0),
                      child: Text(
                        'Wazn',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                WordRise(
                  l10n.onb_welcome_title,
                  delay: const Duration(milliseconds: 380),
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Reveal(
                  delay: const Duration(milliseconds: 900),
                  offset: const Offset(0, 10),
                  child: Text(
                    l10n.onb_welcome_body,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Reveal(
          delay: const Duration(milliseconds: 1000),
          offset: const Offset(0, 26),
          duration: const Duration(milliseconds: 640),
          child: ExcludeSemantics(
            child: _RollingScale(unit: l10n.settings_unit_kg),
          ),
        ),
        Reveal(
          delay: const Duration(milliseconds: 1200),
          offset: const Offset(0, 30),
          duration: const Duration(milliseconds: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: ShineSweep(
              borderRadius: BorderRadius.circular(99),
              delay: const Duration(milliseconds: 2900),
              sweep: const Duration(milliseconds: 900),
              child: OnbCta(
                key: const ValueKey('onboarding-get-started'),
                label: l10n.onboarding_get_started,
                onTap: onGetStarted,
              ),
            ),
          ),
        ),
        if (ref.watch(isAnonymousProvider))
          TextButton(
            onPressed: () => context.push('/auth'),
            child: Text(
              l10n.onboarding_already_account,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox(height: 16),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The still ruler on the welcome screen, which first rolls up to its
/// weight: a taste of how the weight question will feel.
class _RollingScale extends StatefulWidget {
  const _RollingScale({required this.unit});

  final String unit;

  @override
  State<_RollingScale> createState() => _RollingScaleState();
}

class _RollingScaleState extends State<_RollingScale>
    with SingleTickerProviderStateMixin, VisibleGate {
  static const _from = 60.0, _to = 72.4;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Waits for the card to land, then rolls and eases to a stop.
        final t = const Interval(
          .45,
          1,
          curve: Curves.easeOutQuart,
        ).transform(_controller.value);
        final value = ((_from + (_to - _from) * t) * 10).round() / 10;
        return Column(
          children: [
            OnbReadout(
              value: value.toStringAsFixed(1),
              unit: widget.unit,
              size: 44,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: RulerPicker(
                interactive: false,
                value: value,
                min: 30,
                max: 250,
                step: 0.1,
                majorEvery: 10,
                midEvery: 5,
                labelFor: (v) => v.toStringAsFixed(0),
                onChanged: (_) {},
                semanticLabel: '',
                semanticValueFor: (v) => '',
              ),
            ),
          ],
        );
      },
    );
  }
}
