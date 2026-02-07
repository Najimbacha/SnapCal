import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _handlePurchase(BuildContext context) async {
    setState(() => _isLoading = true);

    // Quick mock service instantiation since it's stateless wrapper around repo
    final settingsRepo =
        context.read<SettingsProvider>().repository; // Need access to repo
    final subService = SubscriptionService(settingsRepo);

    final success = await subService.purchasePro();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.read<SettingsProvider>().refresh(); // Ensure UI updates
        context.pop(); // Close Paywall
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to SnapCal Pro! 🌟'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    context.isDarkMode
                        ? AppColors.premiumDarkGradient
                        : AppColors.premiumLightGradient,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Close Button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.surfaceLightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.x,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.crown,
                          size: 64,
                          color: AppColors.primary,
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SnapCal PRO',
                          style: AppTypography.displayMedium.copyWith(
                            color: context.textPrimaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unlock your full potential',
                          style: AppTypography.bodyLarge.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Features List
                  _buildFeatureRow(
                    LucideIcons.chefHat,
                    'Smart Meal Planner',
                    'Generate weekly plans & grocery lists',
                  ),
                  _buildFeatureRow(
                    LucideIcons.brainCircuit,
                    'Advanced AI Models',
                    'More accurate food analysis',
                  ),
                  _buildFeatureRow(
                    LucideIcons.history,
                    'Unlimited History',
                    'Access your full calorie log',
                  ),
                  _buildFeatureRow(
                    LucideIcons.zap,
                    'Priority Support',
                    'Get help faster',
                  ),

                  const Spacer(flex: 2),

                  // CTA Button
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _handlePurchase(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF34D399)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Unlock Pro for \$4.99/mo',
                            style: TextStyle(
                              color:
                                  context.isDarkMode
                                      ? Colors.black
                                      : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ).animate().shimmer(
                        delay: 2.seconds,
                        duration: 1.5.seconds,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Restore Purchase
                  Center(
                    child: TextButton(
                      onPressed:
                          () => _handlePurchase(context), // Same mock logic
                      child: Text(
                        'Restore Purchase',
                        style: AppTypography.labelMedium.copyWith(
                          color: context.textMutedColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceLightColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.glassBorderColor),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: context.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
