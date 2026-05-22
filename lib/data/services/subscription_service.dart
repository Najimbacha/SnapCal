import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../repositories/settings_repository.dart';
import '../../core/services/config_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  SettingsRepository? _settingsRepository;
  StreamSubscription<User?>? _authSubscription;

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
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          unawaited(_instance._processCustomerInfo(customerInfo));
        });
      }
    } catch (e) {
      debugPrint("RevenueCat Init Error: $e");
    }
  }

  Future<void> _syncRevenueCatIdentity(User? user) async {
    try {
      if (user != null) {
        final result = await Purchases.logIn(user.uid);
        debugPrint("RevenueCat App User ID: ${user.uid}");
        await _processCustomerInfo(result.customerInfo);
        return;
      }

      await _settingsRepository?.updateProStatus(false);
      final customerInfo = await Purchases.logOut();
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
          .timeout(const Duration(seconds: 10));
      return credential.user?.uid;
    } catch (e) {
      debugPrint("Firebase anonymous sign-in for RevenueCat failed: $e");
      return null;
    }
  }

  Future<void> _processCustomerInfo(CustomerInfo customerInfo) async {
    final isActive = _hasProAccess(customerInfo);

    debugPrint("RevenueCat Customer ID: ${customerInfo.originalAppUserId}");
    debugPrint(
      "RevenueCat Active Entitlements: "
      "${customerInfo.entitlements.active.keys.join(", ")}",
    );
    debugPrint(
      "RevenueCat Active Subscriptions: "
      "${customerInfo.activeSubscriptions.join(", ")}",
    );
    debugPrint("🏆 Pro Active: $isActive");
    await _settingsRepository?.updateProStatus(isActive);
  }

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

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint("Failed to get offerings: $e");
      return null;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final isActive = _hasProAccess(purchaseResult.customerInfo);
      await _settingsRepository?.updateProStatus(isActive);
      return isActive;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        debugPrint("Product already purchased, attempting to restore...");
        return await restorePurchases();
      }
      debugPrint("Failed to purchase: $e");
      return false;
    } catch (e) {
      debugPrint("Failed to purchase: $e");
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isActive = _hasProAccess(customerInfo);
      await _settingsRepository?.updateProStatus(isActive);
      return isActive;
    } catch (e) {
      debugPrint("Failed to restore: $e");
      return false;
    }
  }

  Future<void> debugReset() async {
    await _settingsRepository?.updateProStatus(false);
  }
}
