class AppPromptSessionCoordinator {
  static final AppPromptSessionCoordinator _instance =
      AppPromptSessionCoordinator._internal();

  factory AppPromptSessionCoordinator() => _instance;
  AppPromptSessionCoordinator._internal();

  bool _promotionalPaywallShown = false;
  bool _reviewPromptAttempted = false;
  bool _subscriptionPurchased = false;

  bool get promotionalPaywallShown => _promotionalPaywallShown;
  bool get reviewPromptAttempted => _reviewPromptAttempted;
  bool get subscriptionPurchased => _subscriptionPurchased;

  bool get canShowPromotionalPaywall => !_reviewPromptAttempted;

  bool get canAttemptReviewPrompt =>
      !_promotionalPaywallShown && !_subscriptionPurchased;

  void markPromotionalPaywallShown() {
    _promotionalPaywallShown = true;
  }

  void markReviewPromptAttempted() {
    _reviewPromptAttempted = true;
  }

  void markSubscriptionPurchased() {
    _subscriptionPurchased = true;
  }

  void resetForTesting() {
    _promotionalPaywallShown = false;
    _reviewPromptAttempted = false;
    _subscriptionPurchased = false;
  }
}
