import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/generated/app_localizations.dart';

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
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.3,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.5,
              ),
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
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(
                              alpha: isDark ? 0.055 : 0.035,
                            ),
                            AppColors.violet.withValues(
                              alpha: isDark ? 0.060 : 0.040,
                            ),
                            Colors.white.withValues(
                              alpha: isDark ? 0.015 : 0.0,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .shimmer(
                      duration: 7.seconds,
                      color: Colors.white.withValues(alpha: 0.025),
                    ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: isDark ? 0.08 : 0.055,
                    ),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          AppColors.violet.withValues(
                            alpha: isDark ? 0.14 : 0.08,
                          ),
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.08 : 0.05,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.10),
                            blurRadius: 6,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 16)
                          .animate(
                            onPlay:
                                (controller) =>
                                    controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.06, 1.06),
                            duration: 3.seconds,
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
                              letterSpacing: 0,
                              fontSize: 12,
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            style: AppTypography.bodySmall.copyWith(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: isDark ? 0.58 : 0.52),
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _CtaButton(text: buttonText, onTap: onTap, isMini: true),
                  ],
                ),
              ),

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
                        Colors.white.withValues(alpha: isDark ? 0.22 : 0.30),
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
          duration: 6.seconds,
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.025 * value),
                    blurRadius: 14 * value,
                    spreadRadius: -2,
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
            color: (isDark ? AppColors.darkCard : Colors.white).withValues(
              alpha: 0.7,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.5,
                  ),
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
                    AppLocalizations.of(context)!.common_maybe_later,
                    style: AppTypography.labelLarge.copyWith(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.4,
                      ),
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
        gradient:
            isMini
                ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(isMini ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: (isMini ? AppColors.violet : AppColors.primary).withValues(
              alpha: isMini ? 0.12 : 0.3,
            ),
            blurRadius: isMini ? 6 : 15,
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
              horizontal: isMini ? 13 : 24,
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
                    letterSpacing: isMini ? 0 : 0.5,
                    fontSize: isMini ? 11 : 13,
                  ),
                ),
                if (!isMini)
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
