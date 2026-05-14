import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'premium_prompt_card.dart';
import '../data/services/premium_gate_service.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class PremiumPromptModal {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
  }) async {
    final settings = context.read<SettingsProvider>();
    final gate = PremiumGateService();

    if (!gate.canShowPopup(settings.isPro)) return;

    await gate.recordPopupShown();

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: PremiumPromptCard(
            style: PremiumPromptStyle.glass,
            title: title,
            subtitle: subtitle,
            buttonText: buttonText,
            icon: icon,
            onTap: () {
              gate.recordCtaClicked('modal');
              Navigator.pop(context);
              context.push('/paywall');
            },
            onDismiss: () {
              gate.recordPopupClosed();
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}
