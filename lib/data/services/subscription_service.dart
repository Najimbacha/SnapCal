import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../repositories/settings_repository.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  SettingsRepository? _settingsRepository;

  // Real keys should be stored in AppConstants or Remote Config. 
  // For now, we use these as default.
  static const String _appleApiKey = "appl_placeholder_for_ios_setup";
  static const String _googleApiKey = "goog_fgVDYvjpkxPzXqwYLndFXKGNEUr";
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
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      }
      
      if (configuration != null) {
        await Purchases.configure(configuration);
        
        // Initial identity sync
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await Purchases.logIn(currentUser.uid);
        }

        // Listen for identity changes
        FirebaseAuth.instance.authStateChanges().listen((user) async {
          if (user != null) {
            await Purchases.logIn(user.uid);
          } else {
            await Purchases.logOut();
          }
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

  void _processCustomerInfo(CustomerInfo customerInfo) {
    bool isActive = customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    
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
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final isActive = purchaseResult.customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
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
      final isActive = customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
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
