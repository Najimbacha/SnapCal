import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        final googleApiKey = ConfigService().revenueCatGoogleApiKey;
        if (googleApiKey.isNotEmpty) {
          configuration = PurchasesConfiguration(googleApiKey);
        }
      } else if (Platform.isIOS) {
        final appleApiKey = ConfigService().revenueCatAppleApiKey;
        if (appleApiKey.isNotEmpty) {
          configuration = PurchasesConfiguration(appleApiKey);
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
        _instance._processCustomerInfo(customerInfo);

        // Listen for customer info changes (renewals, expirations, etc.)
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          _instance._processCustomerInfo(customerInfo);
        });
      }
    } catch (e) {
      debugPrint("RevenueCat Init Error: $e");
    }
  }

  Future<void> _syncRevenueCatIdentity(User? user) async {
    try {
      if (user != null && !user.isAnonymous) {
        final result = await Purchases.logIn(user.uid);
        _processCustomerInfo(result.customerInfo);
        return;
      }

      final isRevenueCatAnonymous = await Purchases.isAnonymous;
      if (isRevenueCatAnonymous) {
        return;
      }

      final customerInfo = await Purchases.logOut();
      _processCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint("RevenueCat identity sync warning: $e");
    }
  }

  void _processCustomerInfo(CustomerInfo customerInfo) {
    bool isActive =
        customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;

    // Pro status is derived solely from RevenueCat entitlements

    debugPrint("🏆 Pro Entitlement Active: $isActive");
    _settingsRepository?.updateProStatus(isActive);
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
      final isActive =
          purchaseResult
              .customerInfo
              .entitlements
              .all[_entitlementId]
              ?.isActive ??
          false;
      await _settingsRepository?.updateProStatus(isActive);
      return isActive;
    } catch (e) {
      debugPrint("Failed to purchase: $e");
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isActive =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
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
