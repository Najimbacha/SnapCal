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
  Offering? _currentOffering;

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
    return _currentEntitlement?.isActive == true;
  }

  Future<bool> hasValidCurrentOffering() async {
    return _currentOffering != null;
  }

  Future<void> _syncRevenueCatIdentity(User? user) async {
    if (!_configured) return;

    try {
      if (user != null) {
        final result = await Purchases.logIn(
          user.uid,
        ).timeout(TimeoutPolicy.revenueCat);
        debugPrint("RevenueCat App User ID: ${user.uid}");
        await _processCustomerInfo(result.customerInfo);
        return;
      }

      await _settingsRepository?.updateProStatus(false);
      final customerInfo = await Purchases.logOut().timeout(
        TimeoutPolicy.revenueCat,
      );
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
    _currentEntitlement =
        customerInfo.entitlements.all[_entitlementId];
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

  // ignore: unused_element
  bool _hasProAccess(CustomerInfo customerInfo) {
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

  Future<bool> refreshBackendPremiumStatus() async {
    try {
      final response = await ApiClient.dio
          .get('${ConfigService().backendProxyUrl}/api/premium-status')
          .timeout(TimeoutPolicy.revenueCat);
      final isActive =
          response.data is Map && response.data['isActive'] == true;
      await _settingsRepository?.updateProStatus(isActive);
      return isActive;
    } catch (e) {
      debugPrint("Backend premium status refresh failed: $e");
      return _settingsRepository?.isPro() ?? false;
    }
  }

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
