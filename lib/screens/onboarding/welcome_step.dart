import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_state_provider.dart';
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
                Row(
                  children: [
                    Container(
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
                    const SizedBox(width: 9),
                    Text(
                      'Wazn',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.onb_welcome_title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.onb_welcome_body,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        ExcludeSemantics(
          child: Column(
            children: [
              OnbReadout(value: '72.4', unit: l10n.settings_unit_kg, size: 44),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: RulerPicker(
                  interactive: false,
                  value: 72.4,
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: OnbCta(
            key: const ValueKey('onboarding-get-started'),
            label: l10n.onboarding_get_started,
            onTap: onGetStarted,
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
