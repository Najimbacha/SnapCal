import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Background ad preloader — initialises the GMA SDK once and keeps a
/// [RewardedAd] ready so the user never waits for a network round-trip at the
/// moment of display.
///
/// Wiring:
///   1. Call [AdService().init()] from `AppInitializer._initBackgroundServices`.
///   2. When the scan quota is exhausted (free user), call
///      [showRewardedAdForBonusScan] — if the ad is already loaded it shows
///      immediately; if not it waits up to [_loadTimeout] before giving up.
///   3. Attach [bannerAd] to an [AdWidget] on the snap screen (free users
///      only).
///
/// **Ad unit IDs** — all IDs below are Google test IDs.
/// Replace them with your real AdMob unit IDs before going to production.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ── Ad unit IDs (test IDs — swap for production) ─────────────────────────

  static const String _androidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static String get _rewardedAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _iosRewardedId
          : _androidRewardedId;

  static String get _bannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _iosBannerId
          : _androidBannerId;

  // ── Internal state ────────────────────────────────────────────────────────

  bool _initialized = false;
  bool _sdkReady = false;

  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  BannerAd? _bannerAd;
  bool _bannerReady = false;

  static const Duration _loadTimeout = Duration(seconds: 10);
  static const int _maxReloadAttempts = 3;
  int _reloadAttempts = 0;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Whether a rewarded ad is preloaded and ready to show instantly.
  bool get isRewardedAdReady => _rewardedAd != null;

  /// The preloaded banner ad, or null if not yet loaded. Attach to [AdWidget].
  BannerAd? get bannerAd => _bannerReady ? _bannerAd : null;

  /// Initialise the SDK and begin background preloading.
  /// Safe to call multiple times — no-ops after the first call.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await MobileAds.instance.initialize().timeout(_loadTimeout);
      _sdkReady = true;
      debugPrint('📢 AdService: GMA SDK initialised');
      // Load ads in parallel — neither blocks the other.
      unawaited(_loadRewardedAd());
      unawaited(_loadBannerAd());
    } catch (e) {
      debugPrint('⚠️ AdService: SDK init failed — $e');
    }
  }

  /// Shows the preloaded rewarded ad. Waits up to [_loadTimeout] for the ad to
  /// load if it is not already ready.
  ///
  /// [onRewarded] is called when the user earns the reward (i.e. watched the
  /// ad to completion). It is NOT called if the user skips or the ad fails.
  ///
  /// Returns `true` if the ad was shown, `false` if it could not be displayed.
  Future<bool> showRewardedAdForBonusScan({
    required VoidCallback onRewarded,
  }) async {
    if (!_sdkReady) return false;

    // If not preloaded yet, wait a bit for the in-flight load.
    if (_rewardedAd == null) {
      debugPrint('📢 AdService: rewarded not ready — waiting for load…');
      if (!_isLoadingRewarded) unawaited(_loadRewardedAd());
      final loaded = await _waitForRewardedAd();
      if (!loaded) {
        debugPrint('📢 AdService: rewarded load timed out — skipping');
        return false;
      }
    }

    final ad = _rewardedAd;
    if (ad == null) return false;

    // Consume the cached ad — a fresh one will be preloaded afterwards.
    _rewardedAd = null;

    final completer = Completer<bool>();
    bool rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_loadRewardedAd()); // Preload next ad immediately.
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(_loadRewardedAd());
        debugPrint('⚠️ AdService: rewarded failed to show — ${error.message}');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) {
        rewarded = true;
        onRewarded();
      },
    );

    final shown = await completer.future;
    return shown && rewarded;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _loadRewardedAd() async {
    if (_isLoadingRewarded || !_sdkReady) return;
    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          _reloadAttempts = 0;
          debugPrint('📢 AdService: rewarded ad loaded and ready');
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          _reloadAttempts++;
          debugPrint(
            '⚠️ AdService: rewarded load failed '
            '(attempt $_reloadAttempts) — ${error.message}',
          );
          if (_reloadAttempts < _maxReloadAttempts) {
            // Back-off retry.
            Future.delayed(
              Duration(seconds: 5 * _reloadAttempts),
              _loadRewardedAd,
            );
          }
        },
      ),
    );
  }

  /// Polls until the rewarded ad is loaded or the timeout expires.
  Future<bool> _waitForRewardedAd() async {
    final deadline = DateTime.now().add(_loadTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_rewardedAd != null) return true;
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  Future<void> _loadBannerAd() async {
    if (!_sdkReady) return;
    try {
      final banner = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            _bannerReady = true;
            debugPrint('📢 AdService: banner ad loaded');
          },
          onAdFailedToLoad: (ad, error) {
            _bannerReady = false;
            ad.dispose();
            debugPrint('⚠️ AdService: banner load failed — ${error.message}');
          },
        ),
      );
      await banner.load();
      _bannerAd = banner;
    } catch (e) {
      debugPrint('⚠️ AdService: banner exception — $e');
    }
  }
}
