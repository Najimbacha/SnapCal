import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../providers/promo_offer_provider.dart';
import '../core/theme/app_typography.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../l10n/generated/app_localizations.dart';

enum PremiumPromptStyle { inline, glass, bento, mini }

class PremiumPromptCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Every upsell card in the app renders through here, so this is the one
    // place worth being strict: show it only when we positively know the user
    // is not subscribed. `isPro == true` used to let the card through while
    // status was still loading, which put "Unlock Pro" in front of paying
    // users on cold start and for a moment after every refresh.
    if (!ref.watch(proAccessProvider).isFree) {
      return const SizedBox.shrink();
    }

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
                  icon: Icon(LucideIcons.x, size: 18),
                  // padding: zero with constraints: BoxConstraints() strips
                  // IconButton's 48dp minimum entirely and leaves the 18px
                  // glyph as the hit area, so the card could not be
                  // dismissed in practice.
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
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

  /// The upgrade surface in Settings.
  ///
  /// Deliberately the one rich card on an otherwise plain screen — a ghost
  /// pill on a white card read as another settings row and disappeared. It
  /// follows the same row grammar as the account card above it (whole card
  /// tappable, chevron, no competing button) but wears the tier's colours, and
  /// it carries the live discount so the number here, the header pill and the
  /// paywall all say the same thing.
  Widget _buildMiniPrompt(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        AppColors.primary.withValues(alpha: 0.20),
                        AppColors.primary.withValues(alpha: 0.05),
                      ]
                      : [const Color(0xFFD9F2E7), const Color(0xFFF4FBF8)],
              stops: const [0.0, 0.85],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.26 : 0.22),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(child: Icon(icon, color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.3,
                              color:
                                  isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        // The live saving, from the same source as the header
                        // pill and the paywall.
                        Consumer(
                          builder: (context, ref, _) {
                            final offer =
                                ref.watch(promoOfferProvider).valueOrNull;
                            if (offer == null) return const SizedBox.shrink();
                            final l10n = AppLocalizations.of(context)!;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.premiumGradient,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.paywall_save_percent(
                                    '${offer.percentOff}',
                                  ),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9.5,
                                    height: 1,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.62 : 0.55),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
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

  const _CtaButton({
    required this.text,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                    fontSize: 13,
                  ),
                ),
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
