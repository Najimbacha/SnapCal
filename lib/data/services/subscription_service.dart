import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/promo_offer.dart';
import '../repositories/settings_repository.dart';
import 'scan_gate_service.dart';
import '../../core/services/config_service.dart';
import '../../core/network/api_client.dart';
import '../../core/resilience/retry_policy.dart';
import '../../core/resilience/safe_async.dart';
import '../../core/resilience/timeout_policy.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  SettingsRepository? _settingsRepository;
  StreamSubscription<User?>? _authSubscription;
  bool _purchaseInFlight = false;
  bool _restoreInFlight = false;
  bool _configured = false;
  bool _customerInfoListenerRegistered = false;
  Future<void>? _initFuture;
  EntitlementInfo? _currentEntitlement;
  CustomerInfo? _currentCustomerInfo;
  Offering? _currentOffering;
  String? _lastKnownUid;

  static const String _entitlementId = "pro";
  static const Set<String> _proProductIds = {
    "snapcal_pro_annual",
    "snapcal_pro_annual:annual-plan",
    "snapcal_pro_monthly",
    "snapcal_pro_monthly:monthly-plan",
  };

  void setRepository(SettingsRepository repository) {
    _settingsRepository = repository;
  }

  static Future<void> init(SettingsRepository repository) async {
    _instance.setRepository(repository);
    _instance._initFuture ??= _instance._initInternal();
    await _instance._initFuture;
  }

  Future<void> _initInternal() async {
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.info);
      }

      final appUserId = await _instance._getOrCreateFirebaseUserId();
      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        final googleApiKey = ConfigService().revenueCatGoogleApiKey;
        if (googleApiKey.isNotEmpty) {
          configuration = PurchasesConfiguration(googleApiKey)
            ..appUserID = appUserId;
        }
      } else if (Platform.isIOS) {
        final appleApiKey = ConfigService().revenueCatAppleApiKey;
        if (appleApiKey.isNotEmpty) {
          configuration = PurchasesConfiguration(appleApiKey)
            ..appUserID = appUserId;
        }
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
        _configured = true;

        await _instance._syncRevenueCatIdentity(
          FirebaseAuth.instance.currentUser,
        );

        // Listen for identity changes
        await _instance._authSubscription?.cancel();
        _instance._authSubscription = FirebaseAuth.instance
            .authStateChanges()
            .listen((user) {
              unawaited(_instance._syncRevenueCatIdentity(user));
            });

        // Initial check of entitlement status
        final customerInfo = await Purchases.getCustomerInfo();
        await _instance._processCustomerInfo(customerInfo);

        // Listen for customer info changes (renewals, expirations, etc.)
        if (!_customerInfoListenerRegistered) {
          _customerInfoListenerRegistered = true;
          Purchases.addCustomerInfoUpdateListener((customerInfo) {
            unawaited(_instance._processCustomerInfo(customerInfo));
          });
        }
      }
    } catch (e) {
      _configured = false;
      _initFuture = null;
      debugPrint("RevenueCat Init Error: $e");
    }
  }

  bool get isConfigured => _configured;
  bool get isPurchaseInFlight => _purchaseInFlight;

  Future<bool> hasActivePremiumEntitlement() async {
    return _hasProAccess();
  }

  Future<bool> hasValidCurrentOffering() async {
    return _currentOffering != null;
  }

  Future<void> _syncRevenueCatIdentity(User? user) async {
    if (!_configured) return;

    try {
      if (user != null) {
        _lastKnownUid = user.uid;
        final result = await Purchases.logIn(
          user.uid,
        ).timeout(TimeoutPolicy.revenueCat);
        debugPrint("RevenueCat App User ID: ${user.uid}");
        await _processCustomerInfo(result.customerInfo);
        return;
      }

      // `authStateChanges()` emits null in more cases than a real sign-out:
      // during cold start before the persisted session is restored, and around
      // token refresh failures. Acting on those wiped Pro locally *and* moved
      // the device onto a fresh anonymous RevenueCat ID with no entitlement,
      // so nothing could recover it. Wait for the emission to settle and
      // confirm against `currentUser` before treating it as a sign-out.
      if (_lastKnownUid != null) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (FirebaseAuth.instance.currentUser != null) {
          debugPrint("RevenueCat: ignoring transient null auth state");
          return;
        }
      }

      _lastKnownUid = null;
      final customerInfo = await Purchases.logOut().timeout(
        TimeoutPolicy.revenueCat,
      );
      // Downgrade only once the store has actually released the identity. A
      // failed logout must not leave the user stripped of Pro.
      await _settingsRepository?.updateProStatus(false);
      await _processCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint("RevenueCat identity sync warning: $e");
    }
  }

  Future<String?> _getOrCreateFirebaseUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) return currentUser.uid;

    try {
      final credential = await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(TimeoutPolicy.auth);
      return credential.user?.uid;
    } catch (e) {
      debugPrint("Firebase anonymous sign-in for RevenueCat failed: $e");
      return null;
    }
  }

  Future<void> _processCustomerInfo(CustomerInfo customerInfo) async {
    _currentCustomerInfo = customerInfo;
    _currentEntitlement = customerInfo.entitlements.all[_entitlementId];
    debugPrint("RevenueCat Customer ID: ${customerInfo.originalAppUserId}");
    debugPrint(
      "RevenueCat Active Entitlements: "
      "${customerInfo.entitlements.active.keys.join(", ")}",
    );
    debugPrint(
      "RevenueCat Active Subscriptions: "
      "${customerInfo.activeSubscriptions.join(", ")}",
    );
    final backendActive = await refreshBackendPremiumStatus();
    debugPrint("🏆 Server verified Pro Active: $backendActive");
  }

  /// Whether the cached [CustomerInfo] carries Pro access, by any of the three
  /// signals the store gives us: the configured entitlement, any other active
  /// entitlement, or an active subscription on a known Pro product.
  bool _hasProAccess([CustomerInfo? info]) {
    final customerInfo = info ?? _currentCustomerInfo;
    if (customerInfo == null) return _currentEntitlement?.isActive == true;

    final configuredEntitlementActive =
        customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    if (configuredEntitlementActive) return true;

    if (customerInfo.entitlements.active.isNotEmpty) {
      return true;
    }

    return customerInfo.activeSubscriptions.any(_isProProductId);
  }

  bool _isProProductId(String productId) {
    final baseProductId = productId.split(":").first;
    return _proProductIds.contains(productId) ||
        _proProductIds.contains(baseProductId) ||
        baseProductId.startsWith("snapcal_pro_");
  }

  Future<SubscriptionResult> purchasePackageDetailed(Package package) async {
    if (!_configured) {
      return const SubscriptionResult.storeUnavailable(
        message: 'Store is still initializing.',
      );
    }
    if (_purchaseInFlight) {
      return const SubscriptionResult.pending(
        message: 'A purchase is already in progress.',
      );
    }

    _purchaseInFlight = true;
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      ).timeout(TimeoutPolicy.revenueCat);

      await _processCustomerInfo(purchaseResult.customerInfo);
      invalidatePremiumCache();
      if (await refreshBackendPremiumStatus(force: true)) {
        return const SubscriptionResult.active();
      }

      final verified = await verifyCurrentEntitlement();
      if (verified) return const SubscriptionResult.active();
      _scheduleDelayedEntitlementVerification();
      return const SubscriptionResult.pending();
    } on PlatformException catch (e) {
      return _handlePurchasePlatformException(e);
    } on TimeoutException {
      _scheduleDelayedEntitlementVerification();
      return const SubscriptionResult.pending(
        message: 'Purchase is taking longer than expected.',
      );
    } catch (e) {
      debugPrint("Failed to purchase: $e");
      _scheduleDelayedEntitlementVerification();
      return SubscriptionResult.failed(message: e.toString());
    } finally {
      _purchaseInFlight = false;
    }
  }

  Future<SubscriptionResult> restorePurchasesDetailed() async {
    if (!_configured) {
      return const SubscriptionResult.storeUnavailable(
        message: 'Store is still initializing.',
      );
    }
    if (_restoreInFlight) {
      return const SubscriptionResult.pending(
        message: 'Restore is already in progress.',
      );
    }

    _restoreInFlight = true;
    try {
      final customerInfo = await Purchases.restorePurchases().timeout(
        TimeoutPolicy.revenueCat,
      );
      await _processCustomerInfo(customerInfo);
      invalidatePremiumCache();
      if (await refreshBackendPremiumStatus(force: true)) {
        return const SubscriptionResult.active();
      }

      final verified = await verifyCurrentEntitlement();
      if (verified) return const SubscriptionResult.active();
      return const SubscriptionResult.noPurchase();
    } on TimeoutException {
      _scheduleDelayedEntitlementVerification();
      return const SubscriptionResult.pending(
        message: 'Restore is taking longer than expected.',
      );
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return const SubscriptionResult.cancelled();
      }
      if (errorCode == PurchasesErrorCode.networkError) {
        return const SubscriptionResult.offline();
      }
      debugPrint("Failed to restore: $e");
      return SubscriptionResult.failed(message: e.message ?? e.code);
    } catch (e) {
      debugPrint("Failed to restore: $e");
      return SubscriptionResult.failed(message: e.toString());
    } finally {
      _restoreInFlight = false;
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) {
      debugPrint("RevenueCat offerings unavailable before configuration");
      return null;
    }

    try {
      final offerings = await Purchases.getOfferings().timeout(
        const Duration(seconds: 8),
      );
      // `_currentOffering` was declared and read but never assigned, so
      // hasValidCurrentOffering() answered false for every user and the
      // promotional paywall could never fire.
      _currentOffering = offerings.current ?? _currentOffering;
      return offerings;
    } catch (e) {
      debugPrint("Failed to get offerings: $e");
      return null;
    }
  }

  /// The discount currently configured on the RevenueCat offering, if any.
  ///
  /// Campaigns are driven from the dashboard: the app reads
  /// `discount_percent` and an optional `ends_at` off the offering's metadata,
  /// so starting or ending one needs no release.
  Future<PromoOffer?> fetchPromoOffer() async {
    // Home builds before RevenueCat finishes configuring, and getOfferings()
    // answers null until it has. Without this wait the first (and, for a
    // cached provider, only) read always missed.
    if (!_configured) {
      // Home builds well before RevenueCat finishes configuring — on a cold
      // start it is queued behind Firebase, FCM and the ads SDK — and
      // getOfferings() answers null until it has. A short wait lost the race
      // every time; this one is generous because it costs nothing but a
      // pending future on a background path.
      await _initFuture;
      const step = Duration(seconds: 1);
      for (var waited = 0; waited < 15 && !_configured; waited++) {
        await Future<void>.delayed(step);
      }
      if (!_configured) {
        debugPrint('🏷️ Promo: RevenueCat did not configure within 15s — '
            'skipping (check the API key and network)');
        return null;
      }
      debugPrint('🏷️ Promo: RevenueCat ready, reading offerings');
    }

    final offerings = await getOfferings();
    final offering = offerings?.current ?? _currentOffering;
    if (offering == null) {
      debugPrint('🏷️ Promo: no current offering — check RevenueCat is '
          'configured and an offering is marked current');
      return null;
    }

    // A dashboard campaign wins, because it can carry a deadline. Otherwise
    // fall back to the Play Console offer on the plan itself, derived from the
    // prices rather than typed anywhere.
    var offer = PromoOffer.fromMetadata(
      offering.identifier,
      offering.metadata,
    );

    if (offer == null) {
      // Resolve by package TYPE, not by the offering's `annual`/`monthly`
      // getters: those only match the standard $rc_annual / $rc_monthly
      // identifiers, and this project names its packages differently — so the
      // getters were null, the annual-vs-monthly comparison never ran, and the
      // header fell back to a different (also true) number than the paywall.
      Package? byType(PackageType type) {
        for (final package in offering.availablePackages) {
          if (package.packageType == type) return package;
        }
        return null;
      }

      offer = PromoOffer.fromPackages(
        offeringId: offering.identifier,
        annual: byType(PackageType.annual) ?? offering.annual,
        monthly: byType(PackageType.monthly) ?? offering.monthly,
      );
      if (offer != null) {
        debugPrint('🏷️ Promo: derived ${offer.percentOff}% from live prices '
            '(annual=${byType(PackageType.annual)?.storeProduct.identifier}, '
            'monthly=${byType(PackageType.monthly)?.storeProduct.identifier})');
      }
    }

    if (offer == null) {
      // Says which offering was read and what it carried, so a campaign put on
      // the wrong offering is one log line away instead of a guess.
      debugPrint('🏷️ Promo: offering "${offering.identifier}" carries no '
          'discount — no metadata (got: ${offering.metadata}) and no '
          'discounted pricing phase on its packages');
      return null;
    }

    if (!offer.isLiveAt(DateTime.now())) {
      debugPrint('🏷️ Promo: offer expired — ends_at was ${offer.endsAt}');
      return null;
    }

    debugPrint('🏷️ Promo LIVE: $offer');
    return offer;
  }

  Future<bool> purchasePackage(Package package) async {
    final result = await purchasePackageDetailed(package);
    return result.isActive;
  }

  Future<bool> restorePurchases() async {
    final result = await restorePurchasesDetailed();
    return result.isActive;
  }

  Future<bool> verifyCurrentEntitlement() async {
    if (!_configured) {
      debugPrint("RevenueCat entitlement verification skipped before config");
      return false;
    }

    final result = await SafeAsync.run<CustomerInfo>(
      label: 'RevenueCat entitlement verification',
      operation: Purchases.getCustomerInfo,
      timeout: TimeoutPolicy.revenueCat,
      retryPolicy: const RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 5),
      ),
    );
    if (result.isFailure) {
      debugPrint("RevenueCat verification pending: ${result.failure}");
      return false;
    }
    await _processCustomerInfo(result.requireData);
    return refreshBackendPremiumStatus();
  }

  /// Reconciles Pro status against the backend, without ever letting a
  /// negative or failed answer override a live store entitlement.
  ///
  /// `subscription/current` is written by the RevenueCat webhook, so a late,
  /// retried or misconfigured webhook makes the backend say `isActive: false`
  /// for someone who has genuinely paid. The store is the payment authority;
  /// the backend is its mirror. Only the store itself may take Pro away.
  /// Cached answer and its age.
  ///
  /// This call fired 8-12 times on a single app launch: RevenueCat listeners,
  /// the auth notifier and the entitlement verifier all reach for it
  /// independently. At 250k daily users that is ten million requests a day for
  /// a value that changes when someone subscribes — about once per user, ever.
  static bool? _cachedServerActive;
  static DateTime? _cachedAt;
  static Future<bool>? _inFlight;
  static const _cacheTtl = Duration(minutes: 5);

  /// Drops the cache so the next read hits the backend. Called after a
  /// purchase or restore, where the answer has genuinely just changed.
  static void invalidatePremiumCache() {
    _cachedServerActive = null;
    _cachedAt = null;
  }

  Future<bool> refreshBackendPremiumStatus({bool force = false}) async {
    final storeSaysActive = hasLocalEntitlement;

    if (!force) {
      final cachedAt = _cachedAt;
      final cached = _cachedServerActive;
      if (cached != null &&
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < _cacheTtl) {
        return cached || storeSaysActive;
      }
      // Collapse the burst: concurrent callers await one request instead of
      // issuing one each.
      final pending = _inFlight;
      if (pending != null) return pending;
    }

    final request = _fetchBackendPremiumStatus(storeSaysActive);
    _inFlight = request;
    try {
      return await request;
    } finally {
      _inFlight = null;
    }
  }

  Future<bool> _fetchBackendPremiumStatus(bool storeSaysActive) async {
    try {
      final response = await ApiClient.dio
          .get('${ConfigService().backendProxyUrl}/api/premium-status')
          .timeout(TimeoutPolicy.revenueCat);
      final serverSaysActive =
          response.data is Map && response.data['isActive'] == true;

      // The server owns the bonus-scan count. Take its number whenever it
      // answers, so a device that granted itself bonuses under an older build
      // -- or lost the response to one -- converges on what will actually be
      // honoured instead of showing a scan it cannot spend.
      if (response.data is Map) {
        final bonus = (response.data['bonusScans'] as num?)?.toInt();
        if (bonus != null) {
          await ScanGateService().syncBonusScansFromServer(bonus);
        }
      }

      _cachedServerActive = serverSaysActive;
      _cachedAt = DateTime.now();

      final effective = serverSaysActive || storeSaysActive;
      if (!serverSaysActive && storeSaysActive) {
        debugPrint(
          "⚠️ Backend reports inactive while the store entitlement is live — "
          "keeping Pro. Check the RevenueCat webhook.",
        );
      }
      await _settingsRepository?.updateProStatus(effective);
      return effective;
    } catch (e) {
      debugPrint("Backend premium status refresh failed: $e");
      if (storeSaysActive) {
        await _settingsRepository?.updateProStatus(true);
        return true;
      }
      // Unreachable backend is not evidence of anything. Leave the stored
      // value alone rather than guessing.
      return _settingsRepository?.isPro() ?? false;
    }
  }

  /// Whether the device is holding an active entitlement, according to the
  /// store SDK itself. This is the check `_hasProAccess` was written for and
  /// then never wired up.
  bool get hasLocalEntitlement => _hasProAccess();

  void _scheduleDelayedEntitlementVerification() {
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 8),
      ).then((_) => verifyCurrentEntitlement()),
    );
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 30),
      ).then((_) => verifyCurrentEntitlement()),
    );
  }

  Future<SubscriptionResult> _handlePurchasePlatformException(
    PlatformException e,
  ) async {
    final errorCode = PurchasesErrorHelper.getErrorCode(e);
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        return const SubscriptionResult.cancelled();
      case PurchasesErrorCode.productAlreadyPurchasedError:
        debugPrint("Product already purchased, attempting to restore...");
        return restorePurchasesDetailed();
      case PurchasesErrorCode.paymentPendingError:
        _scheduleDelayedEntitlementVerification();
        return const SubscriptionResult.pending();
      case PurchasesErrorCode.networkError:
        _scheduleDelayedEntitlementVerification();
        return const SubscriptionResult.offline();
      case PurchasesErrorCode.operationAlreadyInProgressError:
        return const SubscriptionResult.pending(
          message: 'A purchase is already in progress.',
        );
      case PurchasesErrorCode.storeProblemError:
      case PurchasesErrorCode.unknownBackendError:
      case PurchasesErrorCode.unexpectedBackendResponseError:
        _scheduleDelayedEntitlementVerification();
        return SubscriptionResult.storeUnavailable(
          message: e.message ?? e.code,
        );
      case PurchasesErrorCode.purchaseNotAllowedError:
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
      case PurchasesErrorCode.purchaseInvalidError:
      case PurchasesErrorCode.configurationError:
      case PurchasesErrorCode.invalidCredentialsError:
      case PurchasesErrorCode.insufficientPermissionsError:
        return SubscriptionResult.failed(message: e.message ?? e.code);
      default:
        debugPrint("Failed to purchase: $e");
        _scheduleDelayedEntitlementVerification();
        return SubscriptionResult.failed(message: e.message ?? e.code);
    }
  }

  Future<void> debugReset() async {
    await _settingsRepository?.updateProStatus(false);
  }
}

enum SubscriptionStatus {
  active,
  pending,
  cancelled,
  noPurchase,
  offline,
  storeUnavailable,
  failed,
}

class SubscriptionResult {
  final SubscriptionStatus status;
  final String? message;

  const SubscriptionResult._(this.status, {this.message});
  const SubscriptionResult.active() : this._(SubscriptionStatus.active);
  const SubscriptionResult.pending({String? message})
    : this._(SubscriptionStatus.pending, message: message);
  const SubscriptionResult.cancelled() : this._(SubscriptionStatus.cancelled);
  const SubscriptionResult.noPurchase() : this._(SubscriptionStatus.noPurchase);
  const SubscriptionResult.offline() : this._(SubscriptionStatus.offline);
  const SubscriptionResult.storeUnavailable({String? message})
    : this._(SubscriptionStatus.storeUnavailable, message: message);
  const SubscriptionResult.failed({String? message})
    : this._(SubscriptionStatus.failed, message: message);

  bool get isActive => status == SubscriptionStatus.active;
  bool get isPending => status == SubscriptionStatus.pending;
}
