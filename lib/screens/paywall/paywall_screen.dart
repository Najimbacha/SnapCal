import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/subscription_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _handlePurchase(BuildContext context) async {
    setState(() => _isLoading = true);
    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final subService = SubscriptionService(settingsProvider.repository);
    final success = await subService.purchasePro();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!success) return;
    settingsProvider.refresh();
    router.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Welcome to SnapCal Pro')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'SnapCal Pro',
      subtitle: 'Unlock planning, deeper insights, and unlimited AI support.',
      trailing: ActionChipButton(
        icon: LucideIcons.x,
        label: 'Close',
        onTap: () => context.pop(),
      ),
      bottomBar: BottomActionBar(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                  onPressed: () => _handlePurchase(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Unlock Pro for \$4.99/mo'),
                ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    LucideIcons.crown,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Built for people who want more guidance and less friction.',
                  style: AppTypography.heading2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your core tracking simple, then unlock planning and smarter coaching when you need it.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...const [
            _FeatureRow(
              icon: LucideIcons.chefHat,
              title: 'Smart Meal Planner',
              subtitle:
                  'Generate weekly plans and grocery lists around your targets.',
            ),
            _FeatureRow(
              icon: LucideIcons.brainCircuit,
              title: 'Smarter AI support',
              subtitle:
                  'Get richer coaching, better recipe suggestions, and faster guidance.',
            ),
            _FeatureRow(
              icon: LucideIcons.history,
              title: 'Deeper tracking history',
              subtitle: 'Keep more of your nutrition story in one place.',
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSectionCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
