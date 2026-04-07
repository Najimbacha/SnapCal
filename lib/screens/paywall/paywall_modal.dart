import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/ui_blocks.dart';

class PaywallModal extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onCancel;

  const PaywallModal({
    super.key,
    required this.onUpgrade,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        100 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    LucideIcons.crown,
                    color: AppColors.warning,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upgrade to Pro', style: AppTypography.heading3),
                      const SizedBox(height: 4),
                      Text(
                        'You have reached the free limit of 3 snaps per day.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Benefit(text: 'Unlimited daily snaps'),
          const _Benefit(text: 'Smart meal planner and grocery list'),
          const _Benefit(text: 'Priority AI processing'),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onUpgrade,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text('Unlock Pro'),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onCancel,
              child: const Text('Maybe later'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;

  const _Benefit({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(LucideIcons.check, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
