import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class AuthModal extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthModal({
    super.key,
    this.title = 'Save Your Progress',
    this.subtitle =
        'Create an account to backup your meals, streaks, and settings securely.',
  });

  static void show(BuildContext context, {String? title, String? subtitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AuthModal(
            title: title ?? 'Save Your Progress',
            subtitle:
                subtitle ??
                'Create an account to backup your meals, streaks, and settings securely.',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                size: 32,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title & Subtitle
          Text(
            title,
            style: AppTypography.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Google Button
          _SocialButton(
            icon: LucideIcons.chrome,
            label: 'Continue with Google',
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            onPressed: () async {
              Navigator.pop(context); // Close modal first
              await context.read<AuthProvider>().signInWithGoogle();
            },
          ),
          const SizedBox(height: 16),

          // Facebook Button
          _SocialButton(
            icon: LucideIcons.facebook,
            label: 'Continue with Facebook',
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signInWithFacebook();
            },
          ),
          const SizedBox(height: 16),

          // Email Link
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(
                '/auth',
              ); // Go to full screen for email/phone complexity
            },
            child: const Text('Continue with Email or Phone'),
          ),

          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not Now',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
