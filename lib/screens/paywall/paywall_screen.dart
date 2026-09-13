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

const _paywallSage = AppColors.primary;
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
            _heroExtent = viewport.maxHeight < 680 ? 210 : 228;
            final dense = viewport.maxHeight < 720;
            const hPad = 20.0;
            final inlineDock =
                viewport.maxHeight < 700 ||
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
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildTitleBlock(context, palette),
                    ),
                    const SizedBox(height: 18),
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
            fontSize: 31,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          general ? l10n.purchase_headline : title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.muted,
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
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
// HERO
//
// A purchase screen needs a calm first impression. The image proves the food
// scanning context, while the offer details sit below where they can be read.
// ─────────────────────────────────────────────────────────────────────────────

const double _heroChromeTop = 8;

final List<_HeroSlide> _heroSlides = [
  const _HeroSlide(asset: 'assets/images/paywall/hero_slide_1.png'),
];

class _HeroSlide {
  const _HeroSlide({required this.asset});

  final String asset;
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

class _ScanHeroState extends State<_ScanHero> {
  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final slide = _heroSlides.first;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        key: const ValueKey('paywall-scan-hero'),
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              slide.asset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
              errorBuilder:
                  (context, error, stack) =>
                      ColoredBox(color: palette.accentWash),
            ),
            if (palette.isDark)
              const Positioned.fill(
                child: ColoredBox(color: Color(0x44000000)),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.transparent,
                      palette.paper.withValues(
                        alpha: palette.isDark ? 0.32 : 0.18,
                      ),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: _HeroFocusMarks()),
            ),
            PositionedDirectional(
              start: 12,
              top: widget.topInset + _heroChromeTop,
              child: _HeroIconButton(
                icon: LucideIcons.x,
                onTap: widget.onClose,
                semanticLabel:
                    MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFocusMarks extends StatelessWidget {
  const _HeroFocusMarks();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HeroFocusPainter());
  }
}

class _HeroFocusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.33, size.height * 0.38),
      Offset(size.width * 0.66, size.height * 0.36),
    ];
    for (final point in points) {
      canvas.drawCircle(
        point,
        12,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        point,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.86),
      );
      canvas.drawCircle(
        point,
        4.2,
        Paint()..color = AppColors.primary.withValues(alpha: 0.95),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroFocusPainter oldDelegate) => false;
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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : 10,
                bottom: i == items.length - 1 ? 0 : 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: palette.isDark ? 0.22 : 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 14,
                      color: palette.accentInk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 15.5,
                        height: 1.25,
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
    final large =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(15) > 18;
    final title = Text(
      label,
      style: TextStyle(
        color: palette.ink,
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w800,
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
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              decorationColor: palette.muted,
            ),
          ),
        Text(
          introPrice ?? price,
          style: TextStyle(
            color: palette.ink,
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        if (perMonth != null)
          Text(
            perMonth!,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
    final card = Semantics(
      button: true,
      selected: selected,
      child: Material(
        color:
            selected
                ? AppColors.primary.withValues(
                  alpha: palette.isDark ? 0.13 : 0.07,
                )
                : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color:
                selected
                    ? AppColors.primary.withValues(alpha: 0.62)
                    : palette.hairline,
            width: selected ? 1.8 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 17, 16, 17),
            child: Row(
              children: [
                _Radio(selected: selected, palette: palette),
                const SizedBox(width: 14),
                Expanded(
                  child:
                      large
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 10),
                              amount,
                            ],
                          )
                          : Row(
                            children: [
                              Expanded(child: title),
                              const SizedBox(width: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w800,
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
        color:
            selected
                ? AppColors.primary
                : palette.muted.withValues(alpha: 0.72),
        width: selected ? 2 : 1.5,
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
                  color: AppColors.primary,
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
            color: palette.paper.withValues(alpha: 0.97),
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.26),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                          color: Colors.white,
                          fontSize: 15,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w800,
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
