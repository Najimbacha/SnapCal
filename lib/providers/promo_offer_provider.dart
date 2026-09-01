import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/promo_offer.dart';
import '../data/services/subscription_service.dart';

/// The live discount, if the RevenueCat offering carries one.
///
/// Written by hand rather than generated: it is a single read with no state to
/// keep, and adding it to the codegen set would mean regenerating for one
/// provider. `null` covers every quiet case — no campaign, no network, or
/// RevenueCat not configured yet — so callers only ever ask "is there an
/// offer".
final promoOfferProvider = FutureProvider<PromoOffer?>((ref) async {
  final offer = await SubscriptionService().fetchPromoOffer();

  // A null here is usually "not ready yet" rather than "no campaign": the
  // first read can land before RevenueCat is configured or while the device is
  // offline. Without this the miss would be cached for the whole session and
  // the pill could never appear until the next cold start.
  if (offer == null) {
    final retry = Timer(const Duration(seconds: 20), () {
      ref.invalidateSelf();
    });
    ref.onDispose(retry.cancel);
  }
  return offer;
});
