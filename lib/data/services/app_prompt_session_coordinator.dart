class AppPromptSessionCoordinator {
  static final AppPromptSessionCoordinator _instance =
      AppPromptSessionCoordinator._internal();

  factory AppPromptSessionCoordinator() => _instance;
  AppPromptSessionCoordinator._internal();

  bool _promotionalPaywallShown = false;
  bool _reviewPromptAttempted = false;
  bool _subscriptionPurchased = false;
  bool _paywallOpened = false;
  bool _promotionReserved = false;

  bool get promotionalPaywallShown => _promotionalPaywallShown;
  bool get reviewPromptAttempted => _reviewPromptAttempted;
  bool get subscriptionPurchased => _subscriptionPurchased;

  bool get canShowPromotionalPaywall =>
      !_reviewPromptAttempted &&
      !_subscriptionPurchased &&
      !_paywallOpened &&
      !_promotionReserved &&
      !_promotionalPaywallShown;

  bool reservePromotion() {
    if (!canShowPromotionalPaywall) return false;
    _promotionReserved = true;
    return true;
  }

  void releasePromotion() => _promotionReserved = false;
  void markPaywallOpened() => _paywallOpened = true;
  void suppressAutomaticOffers() => _paywallOpened = true;

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
    _paywallOpened = false;
    _promotionReserved = false;
  }
}
