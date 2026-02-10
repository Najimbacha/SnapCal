import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Premium glassmorphic AuthModal with light/dark mode support.
class AuthModal extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthModal({
    super.key,
    this.title = 'Welcome to SnapCal',
    this.subtitle =
        'The next generation of AI calorie tracking. Precise, private, and premium.',
  });

  static void show(BuildContext context, {String? title, String? subtitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AuthModal(
            title: title ?? 'Welcome to SnapCal',
            subtitle:
                subtitle ??
                'The next generation of AI calorie tracking. Precise, private, and premium.',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme detection
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final bgColor =
        isDark
            ? Colors.black.withOpacity(0.85)
            : Colors.white.withOpacity(0.95);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B);
    final pullBarColor =
        isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFE2E8F0);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0);
    final buttonSecondaryBg =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);
    final buttonSecondaryText =
        isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B);
    final buttonSecondaryBorder =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final accentColor = AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              28,
              12,
              28,
              MediaQuery.of(context).padding.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pull Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: pullBarColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // App Icon
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon/icon.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.6,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),

                // Primary CTA: Email
                _AuthActionButton(
                  label: 'Get started with email',
                  icon: LucideIcons.mail,
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/auth');
                  },
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 16),

                // Secondary CTA: Google
                _AuthActionButton(
                  label: 'Continue with Google',
                  icon: FontAwesomeIcons.google,
                  onPressed: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().signInWithGoogle();
                  },
                  backgroundColor: buttonSecondaryBg,
                  foregroundColor: buttonSecondaryText,
                  borderColor: buttonSecondaryBorder,
                  isFaIcon: true,
                ),
                const SizedBox(height: 12),

                // Secondary CTA: Facebook
                _AuthActionButton(
                  label: 'Continue with Facebook',
                  icon: FontAwesomeIcons.facebook,
                  onPressed: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().signInWithFacebook();
                  },
                  backgroundColor: buttonSecondaryBg,
                  foregroundColor: buttonSecondaryText,
                  borderColor: buttonSecondaryBorder,
                  isFaIcon: true,
                ),

                const SizedBox(height: 38),

                // Member Login Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/auth');
                    },
                    child: Text(
                      'I already have an account',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Legal Note
                Opacity(
                  opacity: 0.25,
                  child: Text(
                    'Precision meets privacy. Your data remains yours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isFaIcon;

  const _AuthActionButton({
    required this.label,
    this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.isFaIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAccent = backgroundColor == AppColors.primary;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
          border:
              borderColor != null
                  ? Border.all(color: borderColor!, width: 0.8)
                  : null,
          boxShadow:
              isAccent
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              isFaIcon
                  ? FaIcon(icon, size: 16, color: foregroundColor)
                  : Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 14),
            ],
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
