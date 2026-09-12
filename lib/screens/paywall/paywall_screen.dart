import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/data/services/app_prompt_session_coordinator.dart';
import 'package:snapcal/data/services/promotional_paywall_service.dart';
import 'package:snapcal/data/services/scan_gate_service.dart';
import 'package:snapcal/data/services/subscription_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE
//
// The paywall photography is bright, top-down and shot on white marble, so the
// screen is built light-first: a warm paper ground that the plate can sit on
// without a seam, hairline rules instead of borders, and one accent — emerald,
// the app's own — spent only on the things you can act on. Dark mode keeps the
// same structure on a near-black ground biased green, so the marble reads as
// deliberate rather than blown out.
// ─────────────────────────────────────────────────────────────────────────────

const _paywallSage = Color(0xFF92AF83);
const _paperLight = Color(0xFFFFFFFF);
const _paperDark = Color(0xFF000000);
const _surfaceLight = Color(0xFFFFFFFF);
const _surfaceDark = Color(0xFF0D0F0E);
const _hairlineLight = Color(0xFFDDDFDD);
const _hairlineDark = Color(0xFF242C28);
const _inkLight = Color(0xFF16181D);
const _inkDark = Color(0xFFF1F4F2);
const _mutedLight = Color(0xFF76766E);
const _mutedDark = Color(0xFFA0A3A1);

/// Resolves the palette once per build instead of threading `isDark` through
/// every widget in the file.
class _Palette {
  const _Palette(this.isDark);

  final bool isDark;

  Color get paper => isDark ? _paperDark : _paperLight;
  Color get surface => isDark ? _surfaceDark : _surfaceLight;
  Color get hairline => isDark ? _hairlineDark : _hairlineLight;
  Color get ink => isDark ? _inkDark : _inkLight;
  Color get muted => isDark ? _mutedDark : _mutedLight;

  /// Emerald that stays legible as text on the current ground.
  Color get accentInk => isDark ? _paywallSage : const Color(0xFF47613E);

  Color get accentWash =>
      AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10);
}

// Same destinations the Settings > About screen links to. Store review requires
// these to be reachable from the purchase screen itself, not only from Settings.
const _privacyPolicyUrl =
    'https://gist.githubusercontent.com/Najimbacha/ab1c18844431efb2c5701e36f1ab0ff0/raw';
const _termsUrl = 'https://snapcal.app/terms';

/// A free introductory offer resolved from the store product, never assumed.
class _TrialInfo {
  final int days;
  const _TrialInfo(this.days);
}

/// A *discounted* (not free) introductory offer resolved from the store product.
///
/// Play returns these as a first pricing phase with a lower price and a finite
/// billingCycleCount — e.g. the annual plan's `intro-sale` offer at SAR 85.99
/// for year one, then SAR 149.99. [_TrialInfo] deliberately rejects a paid
/// intro so the CTA never promises a free trial, and until now nothing else
/// picked it up: the screen advertised the full price the user would not
/// actually be charged first, and the savings badge was computed against the
/// wrong number.
class _IntroInfo {
  /// The introductory price, formatted by the store (e.g. "SAR 85.99").
  final String priceString;

  /// The introductory price as a number, for savings maths.
  final double price;

  const _IntroInfo(this.priceString, this.price);
}

final paywallOfferingsLoaderProvider = Provider<Future<Offerings?> Function()>(
  (ref) => SubscriptionService().getOfferings,
);

class PaywallScreen extends ConsumerStatefulWidget {
  final bool limitReached;
  final PaywallEntryPoint entryPoint;
  final String? featureName;
  final bool automatic;

  const PaywallScreen({
    super.key,
    this.limitReached = false,
    this.entryPoint = PaywallEntryPoint.settings,
    this.featureName,
    this.automatic = false,
  });

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  bool _loadingOfferings = true;
  String? _offeringsNotice;
  Package? _selectedPackage;
  List<Package> _packages = [];
  String? _purchaseNotice;

  /// Set once the screen has finished its job, so the success path and the
  /// late-arriving entitlement below cannot both pop the route.
  bool _closed = false;

  // Whether this paywall started a purchase. Pro arriving without one is an
  // existing subscription being recognised late, so it is welcomed back
  // rather than congratulated on a purchase it did not just make.
  bool _purchaseStarted = false;

  /// Restore is in flight. Separate from [_isLoading] on purpose: sharing one
  /// flag put a spinner inside the *Subscribe* button while a restore ran, so
  /// tapping "Restore Purchases" looked like a payment being processed.
  bool _restoring = false;

  final GlobalKey _dockKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  /// Real rendered height of the CTA dock, measured after first paint.
  double? _dockHeight;

  /// 0 while the hero still covers the status bar, 1 once it has scrolled
  /// away. Drives the scrim that stops body text drawing through the clock.
  double _statusBarScrim = 0;
  bool _promotionPresented = false;

  @override
  void initState() {
    super.initState();
    AppPromptSessionCoordinator().markPaywallOpened();
    if (widget.automatic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _promotionPresented = true;
        unawaited(
          PromotionalPaywallService.instance().recordPromotionalPaywallShown(),
        );
      });
    }
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureDock());
    _loadOfferings();
  }

  @override
  void dispose() {
    if (_promotionPresented && !_closed) {
      unawaited(
        PromotionalPaywallService.instance()
            .recordPromotionalPaywallDismissed(),
      );
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _measureDock() {
    if (!mounted) return;
    final box = _dockKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final height = box.size.height;
    if (_dockHeight != null && (_dockHeight! - height).abs() < 0.5) return;
    setState(() => _dockHeight = height);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final topInset = MediaQuery.of(context).padding.top;
    // Fade the scrim in over the last stretch of the hero, so it is fully
    // opaque by the time the headline reaches the status bar.
    final travel = math.max(1.0, _heroExtent - topInset);
    final next = (_scrollController.offset / travel).clamp(0.0, 1.0);
    if ((next - _statusBarScrim).abs() < 0.01) return;
    setState(() => _statusBarScrim = next);
  }

  /// Height handed to the hero on the last build, so the scroll listener can
  /// work out when the hero has cleared the status bar.
  double _heroExtent = 240;

  Future<void> _loadOfferings() async {
    if (mounted) {
      setState(() {
        _loadingOfferings = true;
        _offeringsNotice = null;
      });
    }
    try {
      final offerings = await ref
          .read(paywallOfferingsLoaderProvider)()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        if (offerings?.current != null &&
            offerings!.current!.availablePackages.isNotEmpty) {
          _packages = offerings.current!.availablePackages;
          try {
            _selectedPackage = _packages.firstWhere(
              (p) => p.packageType == PackageType.annual,
            );
          } catch (_) {
            _selectedPackage = _packages.isNotEmpty ? _packages.first : null;
          }
          _offeringsNotice = null;
        } else {
          _packages = const [];
          _selectedPackage = null;
          _offeringsNotice = _purchaseCopy(
            context,
            _PurchaseCopyKey.plansUnavailable,
          );
        }
      });
    } catch (e) {
      debugPrint("Error loading offerings: $e");
      // Never leave the highest-value screen on an indefinite spinner: surface
      // a retry affordance when the store connection fails (§7).
      if (!mounted) return;
      setState(() {
        _packages = const [];
        _selectedPackage = null;
        _offeringsNotice = _purchaseCopy(
          context,
          _PurchaseCopyKey.plansUnavailable,
        );
      });
    } finally {
      if (mounted) setState(() => _loadingOfferings = false);
    }
  }

  /// Reads the real introductory offer off the store product.
  ///
  /// Returns null when there is no offer, or when the offer is a discounted
  /// (rather than free) intro price — in both cases the CTA must not promise a
  /// free trial. Never assume a trial exists because a package is annual.
  _TrialInfo? _trialFor(Package? package) {
    if (package == null) return null;
    try {
      final intro = package.storeProduct.introductoryPrice;
      if (intro == null) return null;
      if (intro.price > 0) return null;
      final units = intro.periodNumberOfUnits;
      if (units <= 0) return null;
      final unit = intro.periodUnit.name.toLowerCase();
      final days =
          unit.startsWith('day')
              ? units
              : unit.startsWith('week')
              ? units * 7
              : unit.startsWith('month')
              ? units * 30
              : unit.startsWith('year')
              ? units * 365
              : units;
      return _TrialInfo(days);
    } catch (_) {
      return null;
    }
  }

  /// Reads a discounted introductory offer off the store product.
  ///
  /// The mirror image of [_trialFor]: that one keeps only free intros, this one
  /// keeps only paid ones, so the two can never both describe the same offer.
  _IntroInfo? _introFor(Package? package) {
    if (package == null) return null;
    try {
      final intro = package.storeProduct.introductoryPrice;
      if (intro == null) return null;
      if (intro.price <= 0) return null; // free -> handled by _trialFor
      final full = package.storeProduct.price;
      if (full > 0 && intro.price >= full) return null; // not a discount
      final priceString = intro.priceString;
      if (priceString.isEmpty) return null;
      return _IntroInfo(priceString, intro.price);
    } catch (_) {
      return null;
    }
  }

  /// Percentage saved by the annual plan against twelve monthly payments.
  int? _savingsPercent(Package? monthly, Package? yearly) {
    if (monthly == null || yearly == null || identical(monthly, yearly)) {
      return null;
    }
    try {
      final m = monthly.storeProduct.price;
      // Compare against what the user actually pays first: with an
      // introductory offer the badge was understating the discount (58%
      // against the full SAR 149.99, when the first year really costs
      // SAR 85.99 and saves 76%).
      final y = _introFor(yearly)?.price ?? yearly.storeProduct.price;
      if (m <= 0 || y <= 0) return null;
      final fullPrice = m * 12;
      if (y >= fullPrice) return null;
      final pct = ((fullPrice - y) / fullPrice * 100).round();
      return pct >= 5 ? pct : null;
    } catch (_) {
      return null;
    }
  }

  /// "SAR 12.50/mo" — with the separator the store's own priceString uses.
  ///
  /// Derived from the introductory price when there is one, so every number on
  /// an annual card describes the same period: the year the user is buying.
  /// The renewal price is stated in full by the disclosure under the CTA.
  String? _monthlyEquivalent(Package package) {
    try {
      final price = _introFor(package)?.price ?? package.storeProduct.price;
      if (price <= 0) return null;
      final priceString = package.storeProduct.priceString;
      final symbol = priceString.replaceAll(RegExp(r'[0-9.,\s]+'), '').trim();
      if (symbol.isEmpty) return null;
      final formatted = (price / 12.0).toStringAsFixed(2);
      return priceString.trim().startsWith(symbol)
          ? '$symbol $formatted/mo'
          : '$formatted $symbol/mo';
    } catch (_) {
      return null;
    }
  }

  /// The billing disclosure shown directly beneath the CTA.
  ///
  /// Apple 3.1.2 and Google Play both require the trial length, the price
  /// charged afterwards, and the billing period to appear next to the purchase
  /// button before the user commits.
  String? _disclosureFor(Package? package, AppLocalizations l10n) {
    if (package == null) return null;
    final String priceString;
    try {
      priceString = package.storeProduct.priceString;
    } catch (_) {
      return null;
    }
    final trial = _trialFor(package);
    final intro = _introFor(package);
    switch (package.packageType) {
      case PackageType.annual:
        if (trial != null) {
          return l10n.paywall_disclosure_trial_year(trial.days, priceString);
        }
        // The introductory year has to be named before the user commits: the
        // disclosure previously quoted only the renewal price.
        return intro == null
            ? l10n.paywall_disclosure_year(priceString)
            : l10n.paywall_disclosure_intro_year(
              intro.priceString,
              priceString,
            );
      case PackageType.monthly:
        if (trial != null) {
          return l10n.paywall_disclosure_trial_month(trial.days, priceString);
        }
        return intro == null
            ? l10n.paywall_disclosure_month(priceString)
            : l10n.paywall_disclosure_intro_month(
              intro.priceString,
              priceString,
            );
      case PackageType.lifetime:
        return l10n.paywall_disclosure_lifetime(priceString);
      default:
        return trial == null
            ? null
            : l10n.paywall_disclosure_trial_month(trial.days, priceString);
    }
  }

  /// Deliberately switches on only the three package types the previous
  /// screen already used. Anything else falls through to the generic label
  /// rather than naming an enum value this codebase has never referenced.
  String _planLabel(Package package, AppLocalizations l10n) {
    switch (package.packageType) {
      case PackageType.annual:
        return l10n.premium_plan_yearly;
      case PackageType.monthly:
        return l10n.premium_plan_monthly;
      case PackageType.lifetime:
        return l10n.premium_plan_lifetime;
      default:
        return l10n.paywall_pro_plan;
    }
  }

  Package? get _monthlyPackage {
    for (final p in _packages) {
      if (p.packageType == PackageType.monthly) return p;
    }
    return null;
  }

  Package? get _annualPackage {
    for (final p in _packages) {
      if (p.packageType == PackageType.annual) return p;
    }
    return null;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Paywall: could not open $url: $e');
    }
  }

  Future<void> _handlePurchase() async {
    if (_isLoading) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      // Narrow, but real: just after returning from the background the button
      // is fully enabled and this returns before setting any state, so the tap
      // does nothing with no spinner and no message. Say why.
      _showPurchaseSnackBar(
        ScaffoldMessenger.of(context),
        _purchaseCopy(context, _PurchaseCopyKey.storeNotReady),
        backgroundColor: AppColors.warning,
        icon: LucideIcons.clock,
      );
      return;
    }
    if (_selectedPackage == null) {
      final message = _purchaseCopy(context, _PurchaseCopyKey.plansUnavailable);
      setState(() => _purchaseNotice = message);
      _showPurchaseSnackBar(
        ScaffoldMessenger.of(context),
        message,
        backgroundColor: AppColors.warning,
        icon: LucideIcons.refreshCw,
      );
      unawaited(_loadOfferings());
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
      _purchaseNotice = null;
      _purchaseStarted = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final subService = SubscriptionService();

    final result = await subService.purchasePackageDetailed(_selectedPackage!);
    if (!mounted) return;
    _handleSubscriptionResult(result, messenger: messenger, isRestore: false);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRestore() async {
    if (_isLoading || _restoring) return;
    HapticFeedback.mediumImpact();
    setState(() => _restoring = true);
    final messenger = ScaffoldMessenger.of(context);
    final subService = SubscriptionService();

    final result = await subService.restorePurchasesDetailed();
    if (!mounted) return;
    _handleSubscriptionResult(result, messenger: messenger, isRestore: true);
    if (mounted) setState(() => _restoring = false);
  }

  void _handleSubscriptionResult(
    SubscriptionResult result, {
    required ScaffoldMessengerState messenger,
    required bool isRestore,
  }) {
    switch (result.status) {
      case SubscriptionStatus.active:
        // Not `ref.invalidate` — that drops the provider back to `loading`,
        // and for that window every consumer sees Pro status as unknown,
        // immediately after the purchase succeeded. Refresh in place instead.
        unawaited(ref.read(settingsProvider.notifier).refreshProStatus());
        _closed = true;
        // `go`, not `pop`. A successful test purchase left the user on the
        // paywall with only a toast; replacing the whole stack means nothing
        // underneath can be left showing, however the paywall was opened.
        context.go('/pro-welcome', extra: {'restore': isRestore});
        return;
      case SubscriptionStatus.pending:
        final message = _purchaseCopy(
          context,
          isRestore
              ? _PurchaseCopyKey.restorePending
              : _PurchaseCopyKey.purchasePending,
        );
        setState(() => _purchaseNotice = message);
        _showPurchaseSnackBar(
          messenger,
          message,
          backgroundColor: AppColors.warning,
          icon: LucideIcons.clock,
        );
        return;
      case SubscriptionStatus.cancelled:
        // Neutral, not celebratory. This was the brand green with a tick --
        // the same colours as "Welcome to SnapCal Pro" two cases up, with
        // only the icon differing. Someone who cancels and glances at a green
        // check-marked toast can reasonably believe they just subscribed.
        _showPurchaseSnackBar(
          messenger,
          _purchaseCopy(context, _PurchaseCopyKey.purchaseCancelled),
          backgroundColor: const Color(0xFF3A3A3C),
          icon: LucideIcons.x,
        );
        return;
      case SubscriptionStatus.noPurchase:
        // Reachable from the buy path too: the store answers "you already own
        // this", the service quietly switches to a restore, and the restore
        // finds nothing. Answering "no active subscription was found" to
        // someone who just tapped Subscribe contradicts what they did, so on
        // that path say the truthful thing instead -- it did not complete.
        final message = _purchaseCopy(
          context,
          isRestore
              ? _PurchaseCopyKey.restoreNoPurchase
              : _PurchaseCopyKey.purchaseFailed,
        );
        if (!isRestore) setState(() => _purchaseNotice = message);
        _showPurchaseSnackBar(
          messenger,
          message,
          backgroundColor: AppColors.warning,
          icon: LucideIcons.refreshCw,
        );
        return;
      case SubscriptionStatus.offline:
        final message = _purchaseCopy(
          context,
          isRestore
              ? _PurchaseCopyKey.restoreOffline
              : _PurchaseCopyKey.purchaseOffline,
        );
        setState(() => _purchaseNotice = message);
        _showPurchaseSnackBar(
          messenger,
          message,
          backgroundColor: AppColors.warning,
          icon: LucideIcons.wifiOff,
        );
        return;
      case SubscriptionStatus.storeUnavailable:
        // Two very different situations arrive here. If the SDK never
        // configured, nothing was sent to Google and raising the idea of a
        // completed payment is both false and frightening.
        final message = _purchaseCopy(
          context,
          result.storeNeverConfigured
              ? _PurchaseCopyKey.storeNotReady
              : _PurchaseCopyKey.storeSlow,
        );
        setState(() => _purchaseNotice = message);
        _showPurchaseSnackBar(
          messenger,
          message,
          backgroundColor: AppColors.warning,
          icon: LucideIcons.clock,
        );
        return;
      case SubscriptionStatus.failed:
        // Also set the persistent notice. This is the state most likely to
        // leave someone wondering whether they were charged, and it was the
        // only one whose entire feedback was a toast that clears itself in
        // four seconds -- gone before a user who looked away could read it.
        final message = _purchaseCopy(
          context,
          isRestore
              ? _PurchaseCopyKey.restoreFailed
              : _PurchaseCopyKey.purchaseFailed,
        );
        setState(() => _purchaseNotice = message);
        _showPurchaseSnackBar(
          messenger,
          message,
          backgroundColor: AppColors.warning,
          icon: LucideIcons.refreshCw,
        );
        return;
    }
  }

  void _showPurchaseSnackBar(
    ScaffoldMessengerState messenger,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = _Palette(Theme.of(context).brightness == Brightness.dark);
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);

    // Close the screen if Pro arrives late.
    //
    // A purchase the store accepted but the server had not confirmed yet
    // comes back as `pending`: the user has been charged, and the paywall
    // stays up with an amber "processing" notice. SubscriptionService retries
    // the verification at 8s and 30s, so the entitlement usually does land --
    // but nothing on this screen was listening for it. The paywall sat there
    // with the notice still showing and the buy button live, which is how
    // someone who has already paid ends up buying twice, or writing in to say
    // nothing happened.
    //
    // Guarded by _closed so this and the success path cannot both navigate.
    ref.listen<bool>(effectiveIsProProvider, (previous, isPro) {
      if (!isPro || _closed || !mounted) return;
      _closed = true;
      context.go('/pro-welcome', extra: {'restore': !_purchaseStarted});
    });

    // Hold the screen while a purchase is in flight.
    //
    // Without this, the back gesture and the hero's close button stay live
    // during the store sheet. Leaving then hits `if (!mounted) return;` right
    // after the await, and the entire result is discarded -- success included.
    // The entitlement still lands, so nobody is charged for nothing, but they
    // are told nothing either, which is exactly the "did that go through?"
    // message you do not want to receive about a payment.
    return PopScope(
      canPop: !_isLoading && !_restoring,
      child: Scaffold(
        backgroundColor: palette.paper,
        body: LayoutBuilder(
          builder: (context, viewport) {
            _heroExtent = 240;
            final dense = viewport.maxHeight < 720;
            const hPad = 20.0;
            final inlineDock =
                viewport.maxHeight < 600 ||
                MediaQuery.textScalerOf(context).scale(14) > 19;
            final dock = _CtaDock(
              key: _dockKey,
              palette: palette,
              hPad: hPad,
              isLoading: _isLoading,
              package: _selectedPackage,
              loadingOfferings: _loadingOfferings,
              trialDays: _trialFor(_selectedPackage)?.days,
              introPriceString: _introFor(_selectedPackage)?.priceString,
              planLabel:
                  _selectedPackage == null
                      ? null
                      : _planLabel(_selectedPackage!, l10n),
              disclosure: _disclosureFor(_selectedPackage, l10n),
              onPurchase: _handlePurchase,
              restoring: _restoring,
              onRestore: (_isLoading || _restoring) ? null : _handleRestore,
              onTerms: () => _openUrl(_termsUrl),
              onPrivacy: () => _openUrl(_privacyPolicyUrl),
            );

            // The dock's height depends on the disclosure text, which changes
            // with the selected plan and the locale. Re-measure after each build.
            WidgetsBinding.instance.addPostFrameCallback((_) => _measureDock());

            return Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  // The dock is measured, not guessed. The old constant
                  // (236/252) under-shot its real height, so the last benefit
                  // row was sliced in half by the CTA and could never be
                  // scrolled clear of it -- which reads as a rendering bug
                  // rather than as "there is more below".
                  padding: EdgeInsets.only(
                    bottom:
                        inlineDock
                            ? 16
                            : (_dockHeight ?? (dense ? 236.0 : 252.0)) +
                                (_dockHeight == null
                                    ? media.padding.bottom
                                    : 0.0) +
                                16,
                  ),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  children: [
                    // The scan, full width and running under the status
                    // bar. This is the only proof on the screen that the
                    // product works, and it was rendered in `compact` mode at
                    // about a third of the width, boxed in beside a second
                    // set of macro bars that repeated it. The full-size hero
                    // already draws its own close button and its own fade
                    // into the page -- the machinery was here all along.
                    _ScanHero(
                      height: _heroExtent,
                      palette: palette,
                      topInset: media.padding.top,
                      onClose: () {
                        if (_isLoading || _restoring) return;
                        if (context.canPop()) context.pop();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildTitleBlock(context, palette),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: hPad),
                      child: _BenefitLedger(palette: palette),
                    ),
                    SizedBox(height: dense ? 20 : 26),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildPlans(context, palette, l10n),
                    ),
                    if (_purchaseNotice != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _NoticeBanner(
                          message: _purchaseNotice!,
                          palette: palette,
                          // A warning with nothing to do about it is a dead
                          // end. Every purchase notice is a state the user can
                          // reasonably try again from.
                          onRetry: _isLoading ? null : _handlePurchase,
                        ),
                      ),
                    ],
                    if (_offeringsNotice != null && !_loadingOfferings) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _NoticeBanner(
                          message: _offeringsNotice!,
                          palette: palette,
                          onRetry: _loadOfferings,
                        ),
                      ),
                    ],
                    if (inlineDock) dock,
                  ],
                ),
                if (!inlineDock)
                  Positioned(left: 0, right: 0, bottom: 0, child: dock),
                // Scrolled body text used to run straight through the status bar
                // clock and icons: the list starts at y=0 and nothing sat behind
                // the inset. This scrim fades in as the hero scrolls away.
                if (media.padding.top > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: _statusBarScrim,
                        child: Container(
                          height: media.padding.top,
                          decoration: BoxDecoration(
                            color: palette.paper,
                            border: Border(
                              bottom: BorderSide(
                                color: palette.hairline.withValues(
                                  alpha: _statusBarScrim,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The headline, chosen by where the user came from.
  ///
  /// Same mapping as before: the promise on the screen has to match the door
  /// they walked through, or the purchase feels like a bait and switch.
  Widget _buildTitleBlock(BuildContext context, _Palette palette) {
    final l10n = AppLocalizations.of(context)!;
    String title;

    if (widget.featureName == 'barcode') {
      title = l10n.paywall_barcode_title;
    } else if (widget.limitReached) {
      // Real numbers, not a hardcoded "3/3 today". The allowance is monthly and
      // the server owns it, so the copy asks the same gate that blocked the
      // scan rather than repeating a figure that has been wrong since the
      // limit moved off 3.
      final gate = ScanGateService();
      final limit = gate.getMonthlyLimit();
      title = l10n.paywall_free_scans_used_title(
        gate.getPeriodScanCount(),
        limit,
      );
    } else if (widget.entryPoint == PaywallEntryPoint.scanLimit) {
      title = l10n.paywall_unlimited_scanning_title;
    } else if (widget.entryPoint == PaywallEntryPoint.aiCoachLimit) {
      title = l10n.paywall_ai_coaching_title;
    } else if (widget.entryPoint == PaywallEntryPoint.plannerLockedDay ||
        widget.entryPoint == PaywallEntryPoint.plannerPreferences) {
      title = l10n.paywall_smart_planning_title;
    } else if (widget.entryPoint == PaywallEntryPoint.groceryList) {
      title = l10n.paywall_shopping_lists_title;
    } else if (widget.entryPoint == PaywallEntryPoint.progressPhotoLimit) {
      title = l10n.paywall_progress_journey_title;
    } else if (widget.entryPoint == PaywallEntryPoint.reportInsight ||
        widget.entryPoint == PaywallEntryPoint.macroDetails ||
        widget.entryPoint == PaywallEntryPoint.mealInsight) {
      title = l10n.paywall_analytics_title;
    } else {
      title = l10n.paywall_upgrade_experience_title;
    }

    final general = title == l10n.paywall_upgrade_experience_title;

    // One headline -- the product name -- and one line of context under it.
    //
    // The headline used to name the three things the benefit list names
    // directly below it, so the screen introduced itself twice. The entry
    // point's own message becomes the supporting line, and the second
    // subtitle goes: "Upgrade to unlock unlimited scanning" under "You used
    // 15/15 free scans this month" added nothing the reader did not have.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${l10n.appTitle} Pro',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.ink,
            fontSize: 25,
            height: 1.15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          general ? l10n.purchase_headline : title,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontSize: 12.5, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildPlans(
    BuildContext context,
    _Palette palette,
    AppLocalizations l10n,
  ) {
    if (_loadingOfferings) {
      return _PlanSkeleton(palette: palette);
    }
    if (_packages.isEmpty) {
      return const SizedBox.shrink();
    }

    final savings = _savingsPercent(_monthlyPackage, _annualPackage);
    final annual = _annualPackage;

    return Column(
      children: [
        for (var i = 0; i < _packages.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _PlanCard(
            palette: palette,
            label: _planLabel(_packages[i], l10n),
            price: _safePriceString(_packages[i]),
            introPrice: _introFor(_packages[i])?.priceString,
            perMonth:
                _packages[i].packageType == PackageType.annual
                    ? _monthlyEquivalent(_packages[i])
                    : null,
            badge:
                (annual != null &&
                        identical(_packages[i], annual) &&
                        savings != null)
                    ? l10n.paywall_save_percent(savings)
                    : (annual != null && identical(_packages[i], annual)
                        ? l10n.paywall_best_value
                        : null),
            selected: identical(_packages[i], _selectedPackage),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPackage = _packages[i];
                _purchaseNotice = null;
              });
            },
          ),
        ],
      ],
    );
  }

  String _safePriceString(Package package) {
    try {
      return package.storeProduct.priceString;
    } catch (_) {
      return '—';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO — the plate, scanned
//
// One photograph at a time, held long enough to be appetising, with the scan
// the product actually performs drawn over it: a sweep down the plate, then
// each food naming itself, then the total. It is the thirty-second demo, and
// it is the only place on the screen that moves.
// ─────────────────────────────────────────────────────────────────────────────

/// One food the scanner "finds", anchored to where it sits in the photograph.
///
/// [spot] is a resolution-independent [Alignment] on the image, and is
/// deliberately *not* direction-aware: the tomatoes are on the right of the
/// plate in Arabic too.
/// One named food on a hero plate.
///
/// Two coordinates, deliberately in two different spaces:
///
///  * [anchor] is where the food actually is, in the *photograph's* own square
///    coordinate space (-1..1 on each axis, measured off the 1024x1024 asset).
///    The hero crops that square to a landscape band, so this has to be
///    converted at paint time rather than baked in as a hero offset.
///  * [chip] is where the label card sits, in the *hero's* coordinate space,
///    chosen so the cards never cover the food, each other, the close button
///    or the calorie readout.
///
/// The leader line drawn between the two is what makes the label read as a
/// detection rather than as a sticker: the old chips sat loose over the plate,
/// overlapping one another, pointing at nothing.
class _Detection {
  const _Detection({
    required this.anchor,
    required this.slots,
    required this.label,
    required this.portion,
    required this.kcal,
  });

  /// The middle of the food, in the photograph's square space, measured off
  /// the 1024x1024 asset. The marker goes here and nowhere else: it is what
  /// tells the user *this* food is *these* calories.
  final Alignment anchor;

  /// Candidate slots, best first. The resolver takes the first one that
  /// covers no food marker, so the card yields to the plate rather than the
  /// marker being nudged off the middle of the food it names.
  final List<_ChipSlot> slots;

  final String Function(AppLocalizations) label;
  final String Function(AppLocalizations) portion;
  final int kcal;
}

/// Fixed so the leader geometry is exact: the painter needs the card's rect to
/// work out which edge the caret belongs on, and an intrinsically sized card
/// would only be measurable a frame late.
const double _chipHeight = 30; // one line now, not two

/// Card width, as a share of the hero.
///
/// Fixed-width cards ate 37% of a small phone's hero from each side, leaving no
/// middle corridor: a dot anchored to the left of a plate landed underneath the
/// very card naming it. Scaling with the hero keeps that corridor open, and
/// every [_Detection.anchor] is kept inside it (|x| <= 0.26).
/// Text style of a detection label, shared by the pill and the measurer so
/// they cannot disagree about how wide a name is.
const TextStyle _chipLabelStyle = TextStyle(
  color: Color(0xFF1C1917),
  fontSize: 11.5,
  height: 1.15,
  letterSpacing: -0.1,
  fontWeight: FontWeight.w600,
);
const TextStyle _chipKcalStyle = TextStyle(
  color: Color(0xFF047857),
  fontSize: 11.5,
  height: 1.15,
  letterSpacing: -0.1,
  fontWeight: FontWeight.w600,
);
const double _chipPadH = 11;
const double _chipGap = 7;

/// How wide this label needs to be, measured rather than assumed.
///
/// Every card used to be 32% of the hero whatever it said, so "Rice" got the
/// same slab as "Grilled Chicken" and sat half empty. The layout reserves
/// rectangles and the leader lines start from their edges, so the width has to
/// be known here, not improvised at paint time.
double _chipWidthForLabel(String label, String kcal, double heroWidth) {
  double measure(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  final content =
      measure(label, _chipLabelStyle) +
      _chipGap +
      measure(kcal, _chipKcalStyle);
  return (content + _chipPadH * 2).clamp(64.0, heroWidth * 0.56);
}

/// The Ken Burns range. Kept shallow: every extra percent of zoom pushes the
/// anchors off the food they point at.
const double _heroZoomFrom = 1.01;
const double _heroZoomTo = 1.04;

/// Which column and band a label card sits in.
///
/// Deliberately not an [Alignment]. Fixed alignments assumed a short status
/// bar: on a device with a tall inset the top band slid under the close button
/// and the calorie readout, both of which paint over the cards -- "Avocado
/// Toast" showed up as "oast". The bands are now derived from the actual inset
/// and the actual chrome heights, so the cards clear them on any device.
enum _ChipSide { left, right }

class _ChipSlot {
  const _ChipSlot(this.side, this.row);

  final _ChipSide side;

  /// 0 = upper band, 1 = lower band.
  final int row;

  @override
  bool operator ==(Object other) =>
      other is _ChipSlot && other.side == side && other.row == row;

  @override
  int get hashCode => Object.hash(side, row);
}

const _slotLeftTop = _ChipSlot(_ChipSide.left, 0);
const _slotLeftLow = _ChipSlot(_ChipSide.left, 1);
const _slotRightTop = _ChipSlot(_ChipSide.right, 0);
const _slotRightLow = _ChipSlot(_ChipSide.right, 1);

/// Hero chrome, for band maths. Must track the widgets themselves.
const double _heroChromeTop =
    8; // close button / readout offset below the inset
const double _closeButtonSize = 38;
const double _readoutHeight = 46;
const double _chromeGap = 10;

/// Radius of the marker ring dropped on the middle of each food.
const double _reticleRadius = 10.5;

/// Height of the hero's bottom dissolve. Shared so card placement and the
/// gradient cannot disagree about where the usable area ends.
double _heroFadeHeight(double heroHeight) => math.max(28, heroHeight * 0.12);

/// One plate, two foods, one to each side.
///
/// Two foods because three meant two of them shared a column, and a food
/// sitting in its own upper band pushes its label to the lower one -- so the
/// pair swapped and their leader lines crossed. One food per side cannot.
///
/// One plate because this paywall is reached by people already using the app,
/// who know what it looks like; a rotating gallery is an onboarding device.
/// The carousel also could not be steered -- the dots were decoration, with no
/// swipe and no tap -- so a photograph you wanted back was gone.
///
/// Totals are folded from whatever is listed here, so they follow.
final List<_HeroSlide> _heroSlides = [
  _HeroSlide(
    asset: 'assets/images/paywall/hero_slide_1.png',
    detections: [
      _Detection(
        anchor: const Alignment(-0.32, -0.32),
        slots: const [_slotLeftTop, _slotLeftLow],
        label: (l) => l.paywall_slide_grilled_chicken,
        portion: (l) => l.paywall_slide_chicken_portion,
        kcal: 248,
      ),
      _Detection(
        anchor: const Alignment(0.31, -0.24),
        slots: const [_slotRightTop, _slotRightLow],
        label: (l) => l.paywall_slide_rice,
        portion: (l) => l.paywall_slide_rice_portion,
        kcal: 169,
      ),
    ],
  ),
];

class _HeroSlide {
  const _HeroSlide({required this.asset, required this.detections});

  final String asset;
  final List<_Detection> detections;

  int get totalKcal => detections.fold(0, (sum, d) => sum + d.kcal);
}

/// Where a detection's card and its food land, in hero pixels.
class _DetectionGeometry {
  const _DetectionGeometry(this.card, this.food, {this.visible = true});

  final Rect card;
  final Offset food;

  /// False when the plate is too crowded on this screen to place the card
  /// without covering food. Showing two clean labels beats three tangled ones,
  /// and the readout still totals the whole plate either way.
  final bool visible;

  /// The point on the card's edge that faces the food, plus the direction to
  /// travel from there. Used for both the caret and the leader line.
  (Offset, Offset) get exit {
    final centre = card.center;
    final delta = food - centre;
    if (delta.distance < 0.001) return (centre, const Offset(0, -1));
    final dir = delta / delta.distance;

    // Scale the ray until it meets the card's boundary.
    final tx =
        dir.dx.abs() < 1e-6 ? double.infinity : (card.width / 2) / dir.dx.abs();
    final ty =
        dir.dy.abs() < 1e-6
            ? double.infinity
            : (card.height / 2) / dir.dy.abs();
    final t = math.min(tx, ty);
    return (centre + dir * t, dir);
  }
}

/// Places the cards and resolves the food anchors for one slide.
///
/// The photograph is square and drawn with [BoxFit.cover] into a landscape
/// hero, so it is the *width* that fills and the top and bottom that get
/// cropped. An anchor's x therefore maps against the drawn width and its y
/// against that same width -- not against the hero's height, which is what
/// made naive placement drift down the plate as the hero got shorter.
///
/// Cards are laid into two bands per column. The upper band starts below
/// whichever piece of chrome shares its column, the lower band ends above the
/// bottom fade, so nothing is ever painted over or washed out.
List<_DetectionGeometry> _resolveDetections(
  List<_Detection> detections,
  Size size,
  double zoom,
  double topInset,
  double fadeHeight,
  List<double> chipWidths,
) {
  final drawn = math.max(size.width, size.height) * zoom;
  final centre = Offset(size.width / 2, size.height / 2);
  const margin = 12.0;

  // Markers first, and they never move: each sits on the middle of its food.
  // The cards are what give way.
  final markers = [
    for (final d in detections)
      Offset(
        centre.dx + d.anchor.x * drawn / 2,
        centre.dy + d.anchor.y * drawn / 2,
      ),
  ];

  final closeRect = Rect.fromLTWH(
    margin,
    topInset + _heroChromeTop,
    _closeButtonSize,
    _closeButtonSize,
  );
  final readoutRect = Rect.fromLTWH(
    size.width - margin - 130,
    topInset + _heroChromeTop,
    130,
    _readoutHeight,
  );

  final leftTop = topInset + _heroChromeTop + _closeButtonSize + _chromeGap;
  final rightTop = topInset + _heroChromeTop + _readoutHeight + _chromeGap;
  final lowest = size.height - fadeHeight - _chipHeight - 6;
  final bandBottom = math.max(
    math.max(leftTop, rightTop) + _chipHeight + 8,
    lowest,
  );

  Rect rectFor(_ChipSlot slot, int index) => Rect.fromLTWH(
    slot.side == _ChipSide.left
        ? margin
        : math.max(margin, size.width - chipWidths[index] - margin),
    (slot.row == 0
            ? (slot.side == _ChipSide.left ? leftTop : rightTop)
            : bandBottom)
        .clamp(margin, math.max(margin, size.height - _chipHeight - margin)),
    chipWidths[index],
    _chipHeight,
  );

  /// A card must fully clear the marker it names -- covering that would hide
  /// the very thing it points at -- and must not sit on top of anybody else's.
  /// The second test is looser on purpose: demanding full reticle clearance
  /// from every marker leaves no legal placement on a busy plate.
  bool clearOfMarkers(Rect card, int self) {
    for (var i = 0; i < markers.length; i++) {
      final pad = i == self ? _reticleRadius + 4 : 2.0;
      if (card.inflate(pad).contains(markers[i])) return false;
    }
    return true;
  }

  bool clearOfChrome(Rect card) =>
      !card.overlaps(closeRect) && !card.overlaps(readoutRect);

  final placed = <Rect>[];
  bool clearOfCards(Rect card) =>
      !placed.any((other) => card.overlaps(other.inflate(4)));

  bool usable(Rect card, int self) =>
      clearOfMarkers(card, self) && clearOfChrome(card) && clearOfCards(card);

  /// Last resort before accepting a bad placement: slide the card along its
  /// column. Cheaper than reserving a whole extra band on a short hero, and it
  /// keeps the card near the food it belongs to.
  Rect? nudged(Rect card, int self) {
    for (var step = 6.0; step <= 54; step += 6) {
      for (final dy in [step, -step]) {
        final moved = card.translate(0, dy);
        if (moved.top < margin || moved.bottom > lowest + _chipHeight) continue;
        if (usable(moved, self)) return moved;
      }
    }
    return null;
  }

  final taken = <_ChipSlot>{};
  final chosen = <Rect?>[];

  for (var i = 0; i < detections.length; i++) {
    final d = detections[i];
    Rect? pick;

    for (final slot in d.slots) {
      if (taken.contains(slot)) continue;
      final rect = rectFor(slot, i);
      if (!usable(rect, i)) continue;
      taken.add(slot);
      pick = rect;
      break;
    }

    if (pick == null) {
      for (final slot in d.slots) {
        if (taken.contains(slot)) continue;
        final moved = nudged(rectFor(slot, i), i);
        if (moved == null) continue;
        taken.add(slot);
        pick = moved;
        break;
      }
    }

    if (pick != null) placed.add(pick);
    chosen.add(pick);
  }

  return [
    for (var i = 0; i < detections.length; i++)
      _DetectionGeometry(
        chosen[i] ?? Rect.zero,
        markers[i],
        visible: chosen[i] != null,
      ),
  ];
}

class _ScanHero extends StatefulWidget {
  const _ScanHero({
    required this.height,
    required this.palette,
    required this.topInset,
    required this.onClose,
  });

  final double height;
  final _Palette palette;
  final double topInset;
  final VoidCallback onClose;

  @override
  State<_ScanHero> createState() => _ScanHeroState();
}

class _ScanHeroState extends State<_ScanHero>
    with SingleTickerProviderStateMixin {
  static const Duration _cycle = Duration(milliseconds: 8200);

  /// Where the scan comes to rest.
  ///
  /// The reveal fades everything back out over the last 7% so the next
  /// photograph could take over. There is no next photograph now, so the
  /// animation stops just short of that and holds the finished scan: every
  /// label placed, the total counted. It plays once and then the screen is
  /// still, which is the point -- a decision screen that keeps moving is
  /// asking you to watch it instead of read it.
  static const double _restPoint = 0.92;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle)
      ..animateTo(_restPoint);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Eases a value into 0..1 across [start]..[end], flat outside.
  double _phase(double t, double start, double end) {
    if (end <= start) return t >= end ? 1 : 0;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final l10n = AppLocalizations.of(context)!;
    final slide = _heroSlides.first;

    return ClipRect(
      // Explicit. The zoomed photograph was painting a sliver of itself past
      // the hero's bottom edge, showing up as a ~10dp band of un-faded image
      // below the fade -- the "little space" between the hero and the page.
      child: SizedBox(
        key: const ValueKey('paywall-scan-hero'),
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder:
              (context, constraints) => AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  // Hold the plate still for a beat, sweep, name the food, then leave.
                  final entrance = _phase(t, 0.00, 0.07);
                  final exit = 1 - _phase(t, 0.93, 1.00);
                  final sweep = _phase(t, 0.12, 0.44);
                  final opacity = entrance * exit;

                  final zoom =
                      _heroZoomFrom + (t * (_heroZoomTo - _heroZoomFrom));
                  final chipWidths = [
                    for (final det in slide.detections)
                      _chipWidthForLabel(
                        det.label(l10n),
                        '${det.kcal} kcal',
                        constraints.maxWidth,
                      ),
                  ];
                  final geometry = _resolveDetections(
                    slide.detections,
                    Size(constraints.maxWidth, widget.height),
                    zoom,
                    widget.topInset,
                    _heroFadeHeight(widget.height),
                    chipWidths,
                  );
                  final reveal = [
                    for (var i = 0; i < slide.detections.length; i++)
                      _phase(t, 0.26 + (i * 0.075), 0.44 + (i * 0.075)) * exit,
                  ];

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── The photograph, breathing ──
                      Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: zoom,
                          child: Image.asset(
                            slide.asset,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            gaplessPlayback: true,
                            errorBuilder:
                                (context, error, stack) =>
                                    ColoredBox(color: palette.accentWash),
                          ),
                        ),
                      ),

                      // ── Dark mode needs the marble knocked back, or it glares ──
                      if (palette.isDark)
                        const Positioned.fill(
                          child: ColoredBox(color: Color(0x33000000)),
                        ),

                      // ── The scan sweep ──
                      if (sweep > 0 && sweep < 1)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _SweepPainter(
                                progress: sweep,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                      // ── Detections, landing in the sweep's wake ──
                      //
                      // Leaders underneath, cards on top, so each line vanishes under
                      // the card edge it grows from.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _DetectionLeaderPainter(
                              geometry: geometry,
                              progress: reveal,
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < slide.detections.length; i++)
                        if (geometry[i].visible)
                          Positioned(
                            left: geometry[i].card.left,
                            top: geometry[i].card.top,
                            child: _DetectionChip(
                              detection: slide.detections[i],
                              l10n: l10n,
                              progress: reveal[i],
                              width: geometry[i].card.width,
                            ),
                          ),

                      // ── Running total, in the empty marble at the top end ──
                      //
                      // It sat bottom-start until the third detection chip landed on
                      // top of it. The corner opposite the close button is clear in
                      // all three photographs and reads like a scanner's own readout.
                      PositionedDirectional(
                        end: 12,
                        top: widget.topInset + _heroChromeTop,
                        child: Opacity(
                          opacity: _phase(t, 0.34, 0.48) * exit,
                          child: _CalorieReadout(
                            kcal: slide.totalKcal,
                            progress: _phase(t, 0.34, 0.72),
                          ),
                        ),
                      ),

                      // The photograph ends where it ends.
                      //
                      // There was a gradient here washing the page colour up
                      // over the bottom of the plate -- 60px of it, then 28 --
                      // and at any height it read as a smudge rather than a
                      // transition, because the photo is still busy where the
                      // wash begins. A clean edge is what a full-bleed image
                      // does everywhere else. _heroFadeHeight stays as the
                      // reserve that keeps food labels off the bottom edge.

                      // ── Chrome ──
                      PositionedDirectional(
                        start: 12,
                        top: widget.topInset + _heroChromeTop,
                        child: _HeroIconButton(
                          icon: LucideIcons.x,
                          onTap: widget.onClose,
                          semanticLabel:
                              MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final bandHeight = size.height * 0.26;

    final band =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.30),
            ],
          ).createShader(
            Rect.fromLTWH(0, y - bandHeight, size.width, bandHeight),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, y - bandHeight, size.width, bandHeight),
      band,
    );

    final edge =
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..strokeWidth = 1.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), edge);
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.progress != progress;
}

/// Draws the anchor dot on the food and the leader that ties it to the card.
///
/// Painted beneath the cards, so the leader disappears cleanly under the card
/// edge and the caret reads as part of it.
class _DetectionLeaderPainter extends CustomPainter {
  _DetectionLeaderPainter({required this.geometry, required this.progress});

  final List<_DetectionGeometry> geometry;

  /// Per-detection reveal, 0..1, matching each card's own fade-in.
  final List<double> progress;

  static const double _caretHalfWidth = 5.5;
  static const double _caretLength = 6.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < geometry.length; i++) {
      final t = progress[i].clamp(0.0, 1.0);
      if (t <= 0) continue;

      final g = geometry[i];
      if (!g.visible) continue;
      final (edge, dir) = g.exit;
      final tip = edge + dir * _caretLength;
      final target = g.food - dir * (_reticleRadius + 3);

      // A shallow arc rather than a ruled line: it reads as drawn rather than
      // as a diagram, and it keeps the leader off whatever it passes over.
      final chord = target - tip;
      final normal = Offset(-chord.dy, chord.dx);
      final bow =
          chord.distance < 1
              ? Offset.zero
              : (normal / chord.distance) * (chord.distance * 0.13);
      final control = tip + chord / 2 + bow;

      // Grow the arc out from the card as the label lands.
      final grown = Curves.easeOutCubic.transform(t);
      final end = _quadratic(tip, control, target, grown);
      final path = Path()..moveTo(tip.dx, tip.dy);
      _appendQuadratic(path, tip, control, target, grown);

      // Caret, pointing along the arc's opening tangent.
      final tangent = control - tip;
      final td = tangent.distance < 0.001 ? dir : tangent / tangent.distance;
      final tn = Offset(-td.dy, td.dx);
      canvas.drawPath(
        Path()
          ..moveTo(
            edge.dx + td.dx * _caretLength,
            edge.dy + td.dy * _caretLength,
          )
          ..lineTo(
            edge.dx + tn.dx * _caretHalfWidth,
            edge.dy + tn.dy * _caretHalfWidth,
          )
          ..lineTo(
            edge.dx - tn.dx * _caretHalfWidth,
            edge.dy - tn.dy * _caretHalfWidth,
          )
          ..close(),
        Paint()..color = Colors.black.withValues(alpha: 0.48 * t),
      );

      // Dark pass first so the leader survives a pale plate, bright pass on top.
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.88 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );

      // A bead riding the head of the line while it travels.
      if (grown < 0.98) {
        canvas.drawCircle(
          end,
          2.2,
          Paint()..color = Colors.white.withValues(alpha: 0.9 * t),
        );
        continue;
      }

      _paintReticle(canvas, g.food, t);
    }
  }

  /// The marker itself: a ring that snaps in around a solid core, sitting on
  /// the middle of the food.
  void _paintReticle(Canvas canvas, Offset at, double t) {
    final land = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    if (land <= 0) return;
    final ease = Curves.easeOutBack.transform(land).clamp(0.0, 1.2);

    // Halo, so the marker reads on dark and light food alike.
    canvas.drawCircle(
      at,
      _reticleRadius * ease,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18 * land)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      at,
      _reticleRadius * ease,
      Paint()..color = AppColors.primary.withValues(alpha: 0.20 * land),
    );

    // Ring.
    canvas.drawCircle(
      at,
      _reticleRadius * ease,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * land)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // A single pulse outward as it lands, then gone.
    final pulse = ((land - 0.25) / 0.75).clamp(0.0, 1.0);
    if (pulse > 0 && pulse < 1) {
      canvas.drawCircle(
        at,
        _reticleRadius + (_reticleRadius * 1.5 * pulse),
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.45 * (1 - pulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Core.
    canvas.drawCircle(
      at,
      4.6 * ease,
      Paint()..color = Colors.white.withValues(alpha: 0.95 * land),
    );
    canvas.drawCircle(
      at,
      3.1 * ease,
      Paint()..color = AppColors.primary.withValues(alpha: land),
    );
  }

  static Offset _quadratic(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  /// Appends the first [t] of the curve a->c->b, subdivided by de Casteljau so
  /// the partial arc keeps the full curve's shape as it grows.
  static void _appendQuadratic(
    Path path,
    Offset a,
    Offset c,
    Offset b,
    double t,
  ) {
    if (t <= 0) return;
    final c1 = Offset.lerp(a, c, t)!;
    final end = _quadratic(a, c, b, t);
    path.quadraticBezierTo(c1.dx, c1.dy, end.dx, end.dy);
  }

  @override
  bool shouldRepaint(_DetectionLeaderPainter old) =>
      old.progress != progress || old.geometry != geometry;
}

/// The label card. Fixed size (see [_chipWidth]) so the leader geometry above
/// can be computed exactly rather than measured a frame late.
class _DetectionChip extends StatelessWidget {
  const _DetectionChip({
    required this.detection,
    required this.l10n,
    required this.progress,
    required this.width,
  });

  final _Detection detection;
  final AppLocalizations l10n;
  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();

    // A light pill, sized to its words.
    //
    // This was a dark slab: a black gradient, a white border, a coloured spine
    // and two lines, all laid over food photography at a fixed 32% of the hero
    // whatever it said. Dark chrome fights a bright photograph; light glass
    // with dark text stays readable on almost anything and lets the picture
    // through, which is how Lens and Visual Look Up label a photo. The gram
    // weight goes with the second line -- on a sales screen the calories are
    // the point and nobody is checking the portion.
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.94 + (0.06 * progress),
        child: Container(
          width: width,
          height: _chipHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: _chipPadH),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(_chipHeight / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: detection.label(l10n), style: _chipLabelStyle),
                const TextSpan(text: '  '),
                TextSpan(text: '${detection.kcal} kcal', style: _chipKcalStyle),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CalorieReadout extends StatelessWidget {
  const _CalorieReadout({required this.kcal, required this.progress});

  final int kcal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final shown = (kcal * Curves.easeOutCubic.transform(progress)).round();

    // Named, and a different colour from the food labels.
    //
    // This was an unlabelled number wearing the same dark glass pill as the
    // detections, in the same corner family, so it read as a fourth food
    // rather than as the sum of the other three. Two things fix that: the
    // word, and not looking like an ingredient. Emerald 700 rather than the
    // brighter brand green -- white on it measures 5.48:1, where the brand
    // green manages 2.54:1.
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 13, 9),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            AppLocalizations.of(context)!.result_total_calories,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 8.5,
              height: 1.2,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          // "453 kcal", not "kcal 453". The row mirrors with the layout in
          // Arabic, but a figure and its Latin unit are one left-to-right run
          // in any language.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$shown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1,
                    letterSpacing: -0.8,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.5),
                  child: Text(
                    'kcal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE FURNITURE
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitLedger extends StatelessWidget {
  const _BenefitLedger({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Titles only. Each row used to carry a second sentence underneath --
    // "Unlimited scans" followed by "Log meals without the daily limit",
    // which said the same thing again and said it wrongly, since the limit
    // is monthly. A tick and a phrase is the pattern people already read on
    // every other subscription screen.
    final items = <String>[
      l10n.paywall_benefit_unlimited_scans,
      l10n.purchase_planner_title,
      l10n.purchase_coach_title,
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration:
                i == items.length - 1
                    ? null
                    : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: palette.hairline),
                      ),
                    ),
            child: Row(
              children: [
                Icon(LucideIcons.check, size: 16, color: palette.accentInk),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.palette,
    required this.label,
    required this.price,
    required this.introPrice,
    required this.perMonth,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final _Palette palette;
  final String label;
  final String price;

  /// Set when the store returns a discounted first period. [price] then becomes
  /// the struck-through renewal price and this is what the user pays now.
  final String? introPrice;
  final String? perMonth;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(15) > 18;
    final title = Text(
      label,
      style: TextStyle(
        color: palette.ink,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    );
    final amount = Column(
      crossAxisAlignment:
          large ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (introPrice != null)
          Text(
            price,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          introPrice ?? price,
          style: TextStyle(
            color: palette.ink,
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (perMonth != null)
          Text(
            perMonth!,
            style: TextStyle(color: palette.muted, fontSize: 11, height: 1.3),
          ),
      ],
    );
    final card = Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? _paywallSage : palette.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Radio(selected: selected, palette: palette),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      large
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 8),
                              amount,
                            ],
                          )
                          : Row(
                            children: [
                              Expanded(child: title),
                              const SizedBox(width: 8),
                              Flexible(child: amount),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (badge == null) return card;

    // The badge straddles the top border rather than sitting inside next to
    // the plan name, so the discount and the price read as one object.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.only(top: 7), child: card),
        PositionedDirectional(
          end: 13,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: palette.accentInk,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: palette.paper,
                fontSize: 9,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.palette});

  final bool selected;
  final _Palette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: 21,
    height: 21,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? _paywallSage : palette.muted,
        width: 1.5,
      ),
    ),
    child:
        selected
            ? Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _paywallSage,
                ),
              ),
            )
            : null,
  );
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
      height: 66,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
      ),
    );

    return Column(children: [bar(), const SizedBox(height: 10), bar()])
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 700.ms, begin: 0.45);
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({
    required this.message,
    required this.palette,
    this.onRetry,
  });

  final String message;
  final _Palette palette;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(
          alpha: palette.isDark ? 0.14 : 0.09,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 17,
            color: AppColors.warning,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.ink,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              // The only way back into the purchase flow once the plans fail
              // to load, and it was a bare 17px glyph.
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.refreshCw,
                  size: 17,
                  color: palette.accentInk,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA DOCK
//
// Pinned, because the decision should never be more than a thumb away, and
// because the store requires the billing disclosure to sit beside the button
// rather than somewhere up the scroll.
// ─────────────────────────────────────────────────────────────────────────────

class _CtaDock extends StatelessWidget {
  const _CtaDock({
    super.key,
    required this.palette,
    required this.hPad,
    required this.isLoading,
    required this.restoring,
    required this.package,
    required this.loadingOfferings,
    required this.trialDays,
    required this.introPriceString,
    required this.planLabel,
    required this.disclosure,
    required this.onPurchase,
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
  });

  final _Palette palette;
  final double hPad;
  final bool isLoading;
  final bool restoring;
  final Package? package;
  final bool loadingOfferings;
  final int? trialDays;

  /// The discounted first-period price, when the store offers one. The button
  /// used to name the renewal price, which is not what the user is charged.
  final String? introPriceString;
  final String? planLabel;
  final String? disclosure;
  final VoidCallback onPurchase;
  final VoidCallback? onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  String _ctaLabel(AppLocalizations l10n) {
    if (loadingOfferings) return l10n.premium_loading;
    if (trialDays != null) return l10n.premium_start_trial;
    if (package != null && planLabel != null) {
      try {
        return l10n.premium_start_plan(
          planLabel!,
          introPriceString ?? package!.storeProduct.priceString,
        );
      } catch (_) {
        return l10n.paywall_unlock_snapcal_pro;
      }
    }
    return l10n.paywall_unlock_snapcal_pro;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          decoration: BoxDecoration(
            color: palette.paper,
            border: Border(top: BorderSide(color: palette.hairline)),
          ),
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, bottomInset + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PrimaryCta(
                label: _ctaLabel(l10n),
                busy: isLoading,
                enabled:
                    !isLoading &&
                    !restoring &&
                    !loadingOfferings &&
                    package != null,
                onTap: onPurchase,
              ),
              if (disclosure != null) ...[
                const SizedBox(height: 10),
                Text(
                  disclosure!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  l10n.paywall_cancel_anytime,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                // Spacing, not separators.
                //
                // The dots were siblings of the links in this Wrap, so a line
                // break could fall after one -- "Terms & Conditions · Privacy
                // policy ·" with nothing following it, and Restore on the line
                // below. Binding each dot to a neighbour only moves the
                // dangling mark to the start of the next line. Three labels
                // this long wrap on a 390pt screen in English and wrap harder
                // in French and Arabic, so the separator has to go rather than
                // be repositioned.
                spacing: 20,
                runSpacing: 6,
                children: [
                  _FooterLink(
                    label: l10n.paywall_terms_conditions,
                    onTap: onTerms,
                    palette: palette,
                  ),
                  _FooterLink(
                    label: l10n.settings_privacy,
                    onTap: onPrivacy,
                    palette: palette,
                  ),
                  _FooterLink(
                    label: l10n.paywall_restore,
                    onTap: onRestore,
                    palette: palette,
                    busy: restoring,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one filled object on the screen.
class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp:
            enabled
                ? (_) {
                  setState(() => _pressed = false);
                  widget.onTap();
                }
                : null,
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.55,
            duration: const Duration(milliseconds: 160),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _paywallSage,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  widget.busy
                      ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                      : Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF111810),
                          fontSize: 15,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.onTap,
    required this.palette,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final _Palette palette;

  /// Shows a spinner in place of the label. Restore had no busy state at all
  /// and rendered identically whether or not it was disabled, so during a
  /// purchase it looked tappable and silently did nothing.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // 11.5pt text with 4px of padding is a 22dp target, and three of
      // these sit shoulder to shoulder in a Wrap. One of them is Restore
      // Purchases -- the control a returning subscriber needs to get back
      // what they already paid for, and the one the stores require here.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child:
            busy
                ? SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.muted),
                  ),
                )
                : Text(
                  label,
                  style: TextStyle(
                    // Dimmed when there is nothing behind the tap, so a
                    // disabled link does not look like a live one.
                    color: palette.muted.withValues(
                      alpha: onTap == null ? 0.4 : 1,
                    ),
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}

// ─── PRESERVED: store-facing copy, verbatim from the previous screen ────────

enum _PurchaseCopyKey {
  plansUnavailable,
  purchasePending,
  restorePending,
  purchaseCancelled,
  purchaseOffline,
  restoreOffline,
  storeSlow,
  storeNotReady,
  restoreNoPurchase,
  purchaseFailed,
  restoreFailed,
}

String _purchaseCopy(BuildContext context, _PurchaseCopyKey key) {
  final locale = AppLocalizations.of(context)!.localeName.split('_').first;
  final copy = switch (locale) {
    'ar' => <_PurchaseCopyKey, String>{
      _PurchaseCopyKey.plansUnavailable:
          'خطط الاشتراك ما زالت قيد التحميل. تحقق من الاتصال وحاول مرة أخرى.',
      _PurchaseCopyKey.purchasePending:
          'عملية الشراء قيد المعالجة. سيتم تفعيل Pro تلقائيا بعد تأكيد المتجر.',
      _PurchaseCopyKey.restorePending:
          'الاستعادة قيد المعالجة. سيتم تفعيل Pro تلقائيا بعد تأكيد المتجر.',
      _PurchaseCopyKey.purchaseCancelled:
          'تم إلغاء الشراء. لم يتم خصم أي مبلغ.',
      _PurchaseCopyKey.purchaseOffline:
          'انقطع الاتصال أثناء التحقق. إذا اكتمل الدفع، سيتم تفعيل Pro تلقائيا عند عودة الاتصال.',
      _PurchaseCopyKey.restoreOffline:
          'لا يمكن التحقق الآن. حاول مرة أخرى عند عودة الاتصال.',
      _PurchaseCopyKey.storeSlow:
          'المتجر يستغرق وقتا أطول من المعتاد. إذا اكتمل الدفع، سيتم تفعيل Pro تلقائيا.',
      _PurchaseCopyKey.storeNotReady:
          'المتجر غير جاهز بعد. لم تتم أي عملية شراء ولم يتم خصم أي مبلغ. حاول بعد لحظات.',
      _PurchaseCopyKey.restoreNoPurchase:
          'لم نجد اشتراكا نشطا على حساب المتجر هذا.',
      _PurchaseCopyKey.purchaseFailed:
          'تعذر إكمال الشراء. لم يتم تفعيل Pro. حاول مرة أخرى.',
      _PurchaseCopyKey.restoreFailed:
          'تعذرت الاستعادة الآن. تحقق من الاتصال وحاول مرة أخرى.',
    },
    'es' => <_PurchaseCopyKey, String>{
      _PurchaseCopyKey.plansUnavailable:
          'Los planes todavía se están cargando. Revisa tu conexión e inténtalo de nuevo.',
      _PurchaseCopyKey.purchasePending:
          'La compra se está procesando. Pro se activará automáticamente cuando la tienda la confirme.',
      _PurchaseCopyKey.restorePending:
          'La restauración se está procesando. Pro se activará automáticamente cuando la tienda la confirme.',
      _PurchaseCopyKey.purchaseCancelled:
          'Compra cancelada. No se realizó ningún cargo.',
      _PurchaseCopyKey.purchaseOffline:
          'Se perdió la conexión durante la verificación. Si el pago se completó, Pro se activará automáticamente al volver la conexión.',
      _PurchaseCopyKey.restoreOffline:
          'No podemos verificarlo ahora. Inténtalo de nuevo cuando vuelva la conexión.',
      _PurchaseCopyKey.storeSlow:
          'La tienda está tardando más de lo normal. Si el pago se completó, Pro se activará automáticamente.',
      _PurchaseCopyKey.storeNotReady:
          'La tienda aún no está lista. No se inició ninguna compra y no se realizó ningún cargo. Inténtalo en un momento.',
      _PurchaseCopyKey.restoreNoPurchase:
          'No encontramos una suscripción activa en esta cuenta de la tienda.',
      _PurchaseCopyKey.purchaseFailed:
          'No pudimos completar la compra. Pro no se activó. Inténtalo de nuevo.',
      _PurchaseCopyKey.restoreFailed:
          'No pudimos restaurar ahora. Revisa tu conexión e inténtalo de nuevo.',
    },
    'fr' => <_PurchaseCopyKey, String>{
      _PurchaseCopyKey.plansUnavailable:
          'Les offres sont encore en chargement. Vérifiez votre connexion et réessayez.',
      _PurchaseCopyKey.purchasePending:
          'L’achat est en cours de traitement. Pro sera activé automatiquement après confirmation du store.',
      _PurchaseCopyKey.restorePending:
          'La restauration est en cours. Pro sera activé automatiquement après confirmation du store.',
      _PurchaseCopyKey.purchaseCancelled: 'Achat annulé. Aucun débit effectué.',
      _PurchaseCopyKey.purchaseOffline:
          'La connexion a été interrompue pendant la vérification. Si le paiement a abouti, Pro sera activé automatiquement au retour de la connexion.',
      _PurchaseCopyKey.restoreOffline:
          'Vérification impossible pour le moment. Réessayez lorsque la connexion revient.',
      _PurchaseCopyKey.storeSlow:
          'Le store prend plus de temps que prévu. Si le paiement a abouti, Pro sera activé automatiquement.',
      _PurchaseCopyKey.storeNotReady:
          "Le store n'est pas encore prêt. Aucun achat n'a été lancé et aucun débit n'a eu lieu. Réessayez dans un instant.",
      _PurchaseCopyKey.restoreNoPurchase:
          'Aucun abonnement actif trouvé sur ce compte du store.',
      _PurchaseCopyKey.purchaseFailed:
          'Impossible de finaliser l’achat. Pro n’a pas été activé. Réessayez.',
      _PurchaseCopyKey.restoreFailed:
          'Restauration impossible pour le moment. Vérifiez votre connexion et réessayez.',
    },
    _ => <_PurchaseCopyKey, String>{
      _PurchaseCopyKey.plansUnavailable:
          'Plans are still loading. Check your connection and try again.',
      _PurchaseCopyKey.purchasePending:
          'Your purchase is processing. Pro will unlock automatically when the store confirms it.',
      _PurchaseCopyKey.restorePending:
          'Restore is processing. Pro will unlock automatically when the store confirms it.',
      _PurchaseCopyKey.purchaseCancelled:
          'Purchase cancelled. No charge was made.',
      _PurchaseCopyKey.purchaseOffline:
          'Connection dropped during verification. If payment completed, Pro will unlock automatically when you are back online.',
      _PurchaseCopyKey.restoreOffline:
          'We cannot verify right now. Try again when your connection returns.',
      _PurchaseCopyKey.storeSlow:
          'The store is taking longer than usual. If payment completed, Pro will unlock automatically.',
      _PurchaseCopyKey.storeNotReady:
          'The store is not ready yet. No purchase was started and nothing was charged. Try again in a moment.',
      _PurchaseCopyKey.restoreNoPurchase:
          'No active subscription was found for this store account.',
      _PurchaseCopyKey.purchaseFailed:
          'We could not complete the purchase. Pro was not activated. Please try again.',
      _PurchaseCopyKey.restoreFailed:
          'We could not restore right now. Check your connection and try again.',
    },
  };
  return copy[key]!;
}
