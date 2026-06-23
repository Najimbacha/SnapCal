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
    final settings = ref.read(settingsProvider).valueOrNull;
    final conversion = PremiumConversionService();
    final canShow = await conversion.maybeShowAhaPrompt(
      context,
      entryPoint: entryPoint,
      isPro: settings?.isPro ?? false,
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
