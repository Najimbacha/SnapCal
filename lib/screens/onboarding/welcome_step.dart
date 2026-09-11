import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_state_provider.dart';
import 'onboarding_ui.dart';
import 'welcome_scan_demo.dart';

/// The first screen.
///
/// The words and the button used to stay hidden until the demo scan had
/// played out: a blank lower half for the first two seconds, and no way to
/// sign in meanwhile. Everything is on screen from the start now; the demo
/// plays above it.
class WelcomeStep extends ConsumerWidget {
  final VoidCallback onGetStarted;

  const WelcomeStep({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = AppMotion.reduceMotion(context);
    final lines = l10n.onboarding_welcome_headline.split('\n');

    Widget enter(Widget child, int delayMs) {
      if (reduceMotion) return child;
      return child
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 450.ms, curve: AppMotion.entranceCurve)
          .slideY(
            begin: 0.08,
            end: 0,
            duration: 450.ms,
            curve: AppMotion.entranceCurve,
          );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        enter(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppSymbols.scan,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'SnapCal',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          0,
        ),
        const SizedBox(height: 18),
        enter(WelcomeScanDemo(onScanComplete: () {}), 80),
        const SizedBox(height: 26),
        enter(
          Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < lines.length; i++)
                  TextSpan(
                    text: i < lines.length - 1 ? '${lines[i]}\n' : lines[i],
                    style: TextStyle(
                      color:
                          lines.length > 1 && i == lines.length - 1
                              ? context.primaryColor
                              : context.textPrimaryColor,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.14,
              letterSpacing: -0.8,
            ),
          ),
          160,
        ),
        const SizedBox(height: 10),
        enter(
          Text(
            l10n.onboarding_welcome_body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 15.5,
              height: 1.42,
            ),
          ),
          220,
        ),
        const SizedBox(height: 18),
        enter(
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Feature(icon: AppSymbols.camera, label: l10n.onboarding_feat_scan),
              _Feature(
                icon: AppSymbols.target,
                label: l10n.onboarding_feature_target,
              ),
              _Feature(
                icon: AppSymbols.protein,
                label: l10n.onboarding_feature_macros,
              ),
            ],
          ),
          280,
        ),
        const SizedBox(height: 26),
        enter(
          OnbPrimaryButton(
            key: const ValueKey('onboarding-get-started'),
            label: l10n.onboarding_get_started,
            onTap: onGetStarted,
          ),
          340,
        ),
        if (ref.watch(isAnonymousProvider)) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => context.push('/auth'),
            child: Text(
              l10n.onboarding_already_account,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(
          alpha: context.isDarkMode ? 0.16 : 0.09,
        ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
