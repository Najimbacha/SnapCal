import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../repositories/settings_repository.dart';
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
      if (await refreshBackendPremiumStatus()) {
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
      if (await refreshBackendPremiumStatus()) {
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
      return await Purchases.getOfferings().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint("Failed to get offerings: $e");
      return null;
    }
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
  Future<bool> refreshBackendPremiumStatus() async {
    final storeSaysActive = hasLocalEntitlement;

    try {
      final response = await ApiClient.dio
          .get('${ConfigService().backendProxyUrl}/api/premium-status')
          .timeout(TimeoutPolicy.revenueCat);
      final serverSaysActive =
          response.data is Map && response.data['isActive'] == true;

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
