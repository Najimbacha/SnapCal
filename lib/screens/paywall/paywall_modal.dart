import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';

/// Paywall modal for upgrading to Pro
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.textMutedColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Crown icon
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withAlpha(200),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withAlpha(80),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.crown,
                  size: 36,
                  color:
                      Colors
                          .white, // Crown icon should stay white/light on yellow
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 400.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          // Title
          Text('Upgrade to Pro', style: AppTypography.heading1),

          const SizedBox(height: 8),

          Text(
            'You\'ve reached the free limit of 3 snaps per day',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Benefits list
          _BenefitItem(
            icon: LucideIcons.infinity,
            title: 'Unlimited Daily Snaps',
            subtitle: 'Track as many meals as you want',
            delay: 100,
          ),
          _BenefitItem(
            icon: LucideIcons.trendingUp,
            title: 'Advanced Analytics',
            subtitle: 'Detailed macro breakdown & trends',
            delay: 200,
          ),
          _BenefitItem(
            icon: LucideIcons.zap,
            title: 'Priority AI Processing',
            subtitle: 'Faster, more accurate analysis',
            delay: 300,
          ),

          const SizedBox(height: 32),

          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$4.99',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/month',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Upgrade button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.sparkles, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Unlock Pro',
                    style: AppTypography.button.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Maybe later button
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Maybe later',
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Fine print
          Text(
            'Cancel anytime. Subscription auto-renews.',
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 300.ms).fadeIn(duration: 300.ms);
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Icon(LucideIcons.check, color: AppColors.primary, size: 20),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: delay.ms, duration: 300.ms)
        .slideX(begin: 0.05, delay: delay.ms, duration: 300.ms);
  }
}
