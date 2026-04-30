import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/theme_colors.dart';
import '../data/services/ad_service.dart';
import '../providers/settings_provider.dart';

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
        height: _bannerAd!.size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    // Fallback placeholder while ad is loading
    return Container(
      width: double.infinity,
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: context.backgroundColor.withValues(alpha: 0.5),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ADVERTISEMENT',
              style: AppTypography.labelSmall.copyWith(
                color: context.textMutedColor,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Remove ads — Go Pro',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
