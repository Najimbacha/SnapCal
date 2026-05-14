import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

enum PremiumPromptStyle { inline, glass, bento, mini }

class PremiumPromptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData icon;
  final PremiumPromptStyle style;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const PremiumPromptCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
    this.style = PremiumPromptStyle.inline,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (settings.isPro) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (style == PremiumPromptStyle.glass) {
      return _buildGlassPrompt(context, isDark);
    }
    
    if (style == PremiumPromptStyle.mini) {
      return _buildMiniPrompt(context, isDark);
    }
    
    return _buildInlinePrompt(context, isDark);
  }

  Widget _buildInlinePrompt(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(LucideIcons.x, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _CtaButton(text: buttonText, onTap: onTap),
        ],
      ),
    );
  }

  Widget _buildMiniPrompt(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // 1. The Aurora Mesh Gradient (Animated)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                    const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.08 : 0.05), // Violet
                    const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.08 : 0.05), // Sky
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .shimmer(duration: 5.seconds, color: Colors.white.withValues(alpha: 0.05)),
          ),

          // 2. The Card Content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with Neural Glow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 16)
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        duration: 2.seconds,
                        curve: Curves.easeInOut,
                      ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 9,
                          color: AppColors.primary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        style: AppTypography.bodySmall.copyWith(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _CtaButton(
                  text: buttonText, 
                  onTap: onTap,
                  isMini: true,
                ),
              ],
            ),
          ),
          
          // 3. Top Reflection (Glossy Edge)
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .custom(
          duration: 4.seconds,
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05 * value),
                    blurRadius: 20 * value,
                    spreadRadius: 1 * value,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
  }

  Widget _buildGlassPrompt(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 40)
                        .animate(
                          onPlay: (controller) => controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 2.seconds,
                          curve: Curves.easeInOut,
                        ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _CtaButton(text: buttonText, onTap: onTap, fullWidth: true),
              if (onDismiss != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Maybe Later',
                    style: AppTypography.labelLarge.copyWith(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool isMini;

  const _CtaButton({
    required this.text,
    required this.onTap,
    this.fullWidth = false,
    this.isMini = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(isMini ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: isMini ? 8 : 15,
            offset: Offset(0, isMini ? 2 : 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMini ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMini ? 14 : 24, 
              vertical: isMini ? 8 : 14,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: isMini ? 11 : 13,
                  ),
                ),
                // The Neural Glint
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        delay: 3.seconds,
                        duration: 1500.ms,
                        color: Colors.white.withValues(alpha: 0.2),
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
