import '../repositories/settings_repository.dart';

/// Mock Service to simulate IAP functionality
class SubscriptionService {
  final SettingsRepository _settingsRepository;

  SubscriptionService(this._settingsRepository);

  /// Simulate a purchase flow
  Future<bool> purchasePro() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success
    await _settingsRepository.updateProStatus(true);
    return true;
  }

  /// Simulate restoring purchases
  Future<bool> restorePurchases() async {
    await Future.delayed(const Duration(seconds: 2));
    await _settingsRepository.updateProStatus(true);
    return true;
  }

  /// Debug only: Reset to free tier
  Future<void> debugReset() async {
    await _settingsRepository.updateProStatus(false);
  }
}
