import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/theme_colors.dart';
import '../data/services/ad_service.dart';
import '../providers/settings_provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class AdBanner extends StatefulWidget {
  final double height;
  
  const AdBanner({
    super.key,
    this.height = 60.0,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // Don't load ads for Pro users
    final isPro = context.read<SettingsProvider>().isPro;
    if (isPro) return;

    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() => _isAdLoaded = true);
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
            _bannerAd = null;
          });
        }
      },
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<SettingsProvider, bool>((p) => p.isPro);
    
    // Pro users see absolutely no ads or placeholders
    if (isPro) {
      return const SizedBox.shrink();
    }

    // Show real ad if loaded
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.glassBorderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                AppLocalizations.of(context)!.ads_label.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                  fontSize: 8,
                ),
              ),
            ),
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: AdWidget(
                  key: ValueKey(_bannerAd.hashCode),
                  ad: _bannerAd!,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback placeholder while ad is loading
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/paywall');
      },
      child: Container(
        width: double.infinity,
        height: widget.height + 20, // Add space for the label
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: context.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.glassBorderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.ads_label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: context.textMutedColor.withValues(alpha: 0.4),
                letterSpacing: 2,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.ads_remove_prompt,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
