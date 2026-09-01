import 'dart:async';

import 'package:flutter/material.dart';
import 'premium_prompt_card.dart';
import '../data/services/premium_conversion_service.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumPromptModal {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    PaywallEntryPoint entryPoint = PaywallEntryPoint.homeAha,
    String? featureName,
    bool hasCompletedValueAction = true,
  }) async {
    // Never sell Pro to a user whose Pro status we do not know yet.
    //
    // This used to read `settings?.isPro ?? false`, which answers "free" while
    // the settings provider is still loading — and the callers fire on a
    // 1.5s/2s timer from initState, and again right after the paywall
    // refreshes the provider. That is how paying users were shown "Unlock
    // SnapCal Pro".
    //
    // Waiting is better than guessing: settle the status first, then decide.
    // A free user still gets the prompt, a moment later than before.
    var access = ref.read(proAccessProvider);
    if (access.isUnknown) {
      try {
        await ref.read(settingsProvider.future).timeout(
          const Duration(seconds: 6),
        );
      } catch (_) {
        return; // Still unknown, and unknown never sells.
      }
      if (!context.mounted) return;
      access = ref.read(proAccessProvider);
    }
    if (!access.isFree) return;

    final conversion = PremiumConversionService();
    final canShow = await conversion.maybeShowAhaPrompt(
      context,
      entryPoint: entryPoint,
      isPro: access.isPro,
      hasCompletedValueAction: hasCompletedValueAction,
      featureName: featureName,
    );

    if (!canShow || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PremiumPromptCard(
                style: PremiumPromptStyle.glass,
                title: title,
                subtitle: subtitle,
                buttonText: buttonText,
                icon: icon,
                onTap: () {
                  Navigator.pop(dialogContext);
                  conversion.openPaywall(
                    context,
                    entryPoint,
                    featureName: featureName,
                  );
                },
                onDismiss: () {
                  conversion.recordPromptDismissed(
                    entryPoint,
                    featureName: featureName,
                  );
                  Navigator.pop(dialogContext);
                },
              ),
            ),
          ),
    );
  }
}
