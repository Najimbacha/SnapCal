import 'package:purchases_flutter/purchases_flutter.dart';

/// A live discount.
///
/// Two sources, in priority order:
///
/// 1. **The Play Console offer** on the subscription's base plan. RevenueCat
///    surfaces it as pricing phases, so the percentage is derived from the
///    prices you actually charge and can never drift from them. These carry no
///    per-user deadline, so they show no countdown — correct, since an
///    invented timer is a dark pattern.
/// 2. **Offering metadata** in the RevenueCat dashboard, for a time-boxed
///    campaign whose deadline is not visible in the prices themselves.
///
/// Metadata keys, for source 2 — set on the offering in the RevenueCat
/// dashboard, so a campaign starts and ends without shipping an update:
///
/// ```json
/// { "discount_percent": 40, "ends_at": "2026-09-08T21:00:00Z" }
/// ```
class PromoOffer {
  final String offeringId;
  final int percentOff;
  final DateTime? endsAt;

  /// Optional override for the pill's text, e.g. "Launch week".
  final String? label;

  const PromoOffer({
    required this.offeringId,
    required this.percentOff,
    this.endsAt,
    this.label,
  });

  static PromoOffer? fromMetadata(
    String offeringId,
    Map<String, dynamic> metadata,
  ) {
    final percent = _asInt(metadata['discount_percent']);
    if (percent == null || percent <= 0 || percent >= 100) return null;

    final rawEnd = metadata['ends_at'];
    final endsAt = rawEnd is String ? DateTime.tryParse(rawEnd) : null;

    final rawLabel = metadata['discount_label'];
    return PromoOffer(
      offeringId: offeringId,
      percentOff: percent,
      endsAt: endsAt?.toLocal(),
      label: rawLabel is String && rawLabel.trim().isNotEmpty ? rawLabel : null,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// An offer with a past deadline is not an offer.
  bool isLiveAt(DateTime now) => endsAt == null || endsAt!.isAfter(now);

  Duration? remainingAt(DateTime now) {
    final end = endsAt;
    if (end == null) return null;
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Derives the discount from the offering's real prices.
  ///
  /// Uses the same comparison the paywall headlines — the annual plan against
  /// twelve monthly payments, priced at what the user actually pays this year
  /// (the Play Console intro offer when there is one). Two different true
  /// numbers in one app is worse than either: the header promised 43% off the
  /// annual list price while the paywall promised 76% against monthly, and a
  /// user who taps the first expects to find it.
  ///
  /// Falls back to the intro-versus-full-price gap when there is no monthly
  /// plan to compare against.
  ///
  /// A free trial returns null on purpose: "0% off" is nonsense, and a trial
  /// belongs on the paywall where it can be explained, not in a badge.
  static PromoOffer? fromPackages({
    required String offeringId,
    Package? annual,
    Package? monthly,
  }) {
    final vsMonthly = _savingsAgainstMonthly(annual, monthly);
    if (vsMonthly != null) {
      return PromoOffer(offeringId: offeringId, percentOff: vsMonthly);
    }
    for (final package in [annual, monthly]) {
      if (package == null) continue;
      final intro = _introDiscount(package);
      if (intro != null) {
        return PromoOffer(offeringId: offeringId, percentOff: intro);
      }
    }
    return null;
  }

  /// What the annual plan saves against paying monthly for a year.
  static int? _savingsAgainstMonthly(Package? annual, Package? monthly) {
    if (annual == null || monthly == null || identical(annual, monthly)) {
      return null;
    }
    final monthlyPrice = monthly.storeProduct.price;
    // What is actually charged this year, intro offer included.
    final annualPrice = _effectivePrice(annual);
    if (monthlyPrice <= 0 || annualPrice <= 0) return null;
    final twelveMonths = monthlyPrice * 12;
    if (annualPrice >= twelveMonths) return null;
    final pct = ((twelveMonths - annualPrice) / twelveMonths * 100).round();
    return pct >= 5 ? pct : null;
  }

  /// The gap between a Play Console intro offer and the price it reverts to.
  ///
  /// Android exposes the base plan's phases; the percentage is only computed
  /// when both bill for the same period, because a one-month intro on an
  /// annual plan is a different shape of deal and dividing one by the other
  /// would invent a number.
  static int? _introDiscount(Package package) {
    final product = package.storeProduct;
    final option = product.defaultOption;
    final full = option?.fullPricePhase;
    final intro = option?.introPhase;
    if (full != null && intro != null) {
      final samePeriod =
          full.billingPeriod?.unit == intro.billingPeriod?.unit &&
          full.billingPeriod?.value == intro.billingPeriod?.value;
      final fullMicros = full.price.amountMicros;
      final introMicros = intro.price.amountMicros;
      if (samePeriod && fullMicros > 0 && introMicros < fullMicros) {
        return (100 * (1 - introMicros / fullMicros)).round();
      }
    }

    final introPrice = product.introductoryPrice;
    if (introPrice != null && introPrice.price > 0 && product.price > 0) {
      final off = (100 * (1 - introPrice.price / product.price)).round();
      if (off > 0 && off < 100) return off;
    }
    return null;
  }

  /// The price charged for the first period: the paid intro offer if there is
  /// one, otherwise the list price. A free trial is not a price.
  static double _effectivePrice(Package package) {
    final intro = package.storeProduct.introductoryPrice;
    if (intro != null && intro.price > 0) return intro.price;
    return package.storeProduct.price;
  }

  @override
  String toString() =>
      'PromoOffer($offeringId, $percentOff%, ends $endsAt)';
}
