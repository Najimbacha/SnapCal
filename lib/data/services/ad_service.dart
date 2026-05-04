import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized service for managing Google AdMob ads.
/// Pro users are never shown ads.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;

  // ── Ad Unit IDs ──────────────────────────────────────────────
  // Production banner ID
  static const String _prodBannerAndroid = 'ca-app-pub-9095390056353710/5681833011';

  // Google-provided test IDs (used in debug builds)
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos     = 'ca-app-pub-3940256099942544/2934735716';

  /// Returns the correct banner ad unit ID based on platform and build mode.
  static String get bannerAdUnitId {
    // Forced to production as requested by user
    return _prodBannerAndroid;
  }

  /// Initialize the Mobile Ads SDK. Call once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('📢 AdService: Google Mobile Ads initialized');
    } catch (e) {
      debugPrint('❌ AdService: Failed to initialize ads: $e');
    }
  }

  /// Create and return a new BannerAd ready to load.
  BannerAd createBannerAd({
    AdSize size = AdSize.banner,
    Function(Ad)? onAdLoaded,
    Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('📢 Banner ad loaded');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('📢 Banner ad failed to load: ${error.message}');
          ad.dispose();
          onAdFailedToLoad?.call(ad, error);
        },
        onAdOpened: (ad) => debugPrint('📢 Banner ad opened'),
        onAdClosed: (ad) => debugPrint('📢 Banner ad closed'),
      ),
    );
  }
}
