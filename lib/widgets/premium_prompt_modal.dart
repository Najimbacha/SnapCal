import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/promo_offer.dart';
import '../data/services/premium_conversion_service.dart';
import '../data/services/scan_gate_service.dart';
import '../data/services/subscription_service.dart';
import '../providers/settings_provider.dart';
import 'pro_offer_sheet.dart';

class PremiumPromptModal {
  /// How long to wait for the store's prices before showing the sheet
  /// without them. The prompt fires a moment after a screen opens; holding it
  /// longer would land it on whatever the user has moved on to.
  static const Duration _offerWait = Duration(seconds: 4);

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    PaywallEntryPoint entryPoint = PaywallEntryPoint.homeAha,
    String? featureName,
    bool hasCompletedValueAction = true,
  }) async {
    // Never sell Pro to a user whose Pro status we do not know yet.
    //
    // This used to read `settings?.isPro ?? false`, which answers "free" while
    // the settings provider is still loading — and the callers fire on a
    // 1.5s/2s timer from initState, and again right after the paywall
    // refreshes the provider. That is how paying users were shown "Unlock
    // SnapCal Pro".
    //
    // Waiting is better than guessing: settle the status first, then decide.
    // A free user still gets the prompt, a moment later than before.
    var access = ref.read(proAccessProvider);
    if (access.isUnknown) {
      try {
        await ref.read(settingsProvider.future).timeout(
          const Duration(seconds: 6),
        );
      } catch (_) {
        return; // Still unknown, and unknown never sells.
      }
      if (!context.mounted) return;
      access = ref.read(proAccessProvider);
    }
    if (!access.isFree) return;

    // Read the offer before deciding, so the sheet opens with its prices
    // rather than filling them in after it appears.
    final offer = await _loadOffer();
    if (!context.mounted) return;

    final conversion = PremiumConversionService();
    final canShow = await conversion.maybeShowAhaPrompt(
      context,
      entryPoint: entryPoint,
      isPro: access.isPro,
      hasCompletedValueAction: hasCompletedValueAction,
      featureName: featureName,
    );

    if (!canShow || !context.mounted) return;

    final scans = ScanGateService();
    final used = scans.getPeriodScanCount();

    await ProOfferSheet.show(
      context,
      offer: offer,
      // "You've used 0 of 15" sells nothing: the meter appears once some of
      // the month's free scans have actually gone.
      scansUsed: used > 0 ? used : null,
      scanLimit: scans.getMonthlyLimit(),
      onUpgrade: () {
        if (!context.mounted) return;
        conversion.openPaywall(context, entryPoint, featureName: featureName);
      },
      onDismiss:
          () => conversion.recordPromptDismissed(
            entryPoint,
            featureName: featureName,
          ),
    );
  }

  /// The offering the paywall sells from (`offerings.current`), so the sheet
  /// and the paywall always quote the same prices.
  static Future<ProOfferSummary?> _loadOffer() async {
    try {
      final offerings = await SubscriptionService().getOfferings().timeout(
        _offerWait,
      );
      final offering = offerings?.current;
      if (offering == null) return null;

      // A dashboard campaign, if one is running and not yet over.
      var campaign = PromoOffer.fromMetadata(
        offering.identifier,
        offering.metadata,
      );
      if (campaign != null && !campaign.isLiveAt(DateTime.now())) {
        campaign = null;
      }
      return ProOfferSummary.fromOffering(offering, promo: campaign);
    } catch (_) {
      return null;
    }
  }
}
