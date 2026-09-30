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

/// The first screen: the name, one line of promise, and a sample scan result
/// that shows what the app does. It is a picture, not a control, so nothing on
/// it asks to be touched.
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          key: const ValueKey('welcome-logo'),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
          child: const Padding(
            padding: EdgeInsets.only(bottom: 36),
            child: ExcludeSemantics(child: _MealCard()),
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

/// A sample scan result: photo in, calories out. The numbers are fixed
/// samples, not the user's data. It settles once and never asks to be touched.
class _MealCard extends StatefulWidget {
  const _MealCard();

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard>
    with SingleTickerProviderStateMixin, VisibleGate {
  static const _kcal = 520;
  // Grams of the sample meal, and the share of each bar they fill.
  static const _macros = [
    (28, .62, AppColors.protein),
    (64, .8, AppColors.carbs),
    (14, .34, AppColors.fat),
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.result_protein, l10n.result_carbs, l10n.result_fat];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Container(
        key: const ValueKey('welcome-meal-card'),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOutQuart.transform(_controller.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppSymbols.scan,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.onb_welcome_card_scanned,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.onb_welcome_card_food,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(_kcal * t).round()}',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                        height: 1.1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.settings_kcal_unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _macros.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _MacroBar(
                    label: labels[i],
                    grams: (_macros[i].$1 * t).round(),
                    fill: _macros[i].$2 * t,
                    color: _macros[i].$3,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.grams,
    required this.fill,
    required this.color,
  });

  final String label;
  final int grams;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 6, color: color.withValues(alpha: .16)),
                FractionallySizedBox(
                  widthFactor: fill.clamp(0.0, 1.0),
                  child: Container(height: 6, color: color),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${grams}g',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
