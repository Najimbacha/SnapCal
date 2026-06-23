import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_provider.g.dart';

@Riverpod(keepAlive: true)
Future<CustomerInfo> subscriptionInfo(SubscriptionInfoRef ref) =>
    Purchases.getCustomerInfo();

@Riverpod(keepAlive: true)
bool isPremium(IsPremiumRef ref) {
  return ref.watch(subscriptionInfoProvider).maybeWhen(
    data: (info) => info.entitlements.active.containsKey('premium'),
    orElse: () => false,
  );
}
