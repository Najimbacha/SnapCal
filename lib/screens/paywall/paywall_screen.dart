import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show BoxParentData;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:snapcal/core/services/config_service.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/data/services/app_prompt_session_coordinator.dart';
import 'package:snapcal/data/services/promotional_paywall_service.dart';
import 'package:snapcal/data/services/scan_gate_service.dart';
import 'package:snapcal/data/services/subscription_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import '../../widgets/wazn_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/motion/shine_sweep.dart';

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

// The legal pages are hosted by the backend (see `backend/legal/`), and the
// app links to the same `/terms` and `/privacy` routes there. Store review
// requires them reachable from the purchase screen itself, not only Settings.
String get _termsUrl => '${ConfigService().backendProxyUrl}/terms';
String get _privacyPolicyUrl => '${ConfigService().backendProxyUrl}/privacy';

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

  /// "SAR 12.50/month", in the user's language, with the separator the
  /// store's own priceString uses.
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
      final monthly =
          priceString.trim().startsWith(symbol)
              ? '$symbol $formatted'
              : '$formatted $symbol';
      return AppLocalizations.of(context)!.pro_offer_per_month(monthly);
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

  /// Set once a purchase has gone through, for the button's tick.
  bool _purchaseDone = false;

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
        icon: WaznIcons.clock,
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
        icon: WaznIcons.refresh,
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
        if (isRestore || AppMotion.reduceMotion(context)) {
          context.go('/pro-welcome', extra: {'restore': isRestore});
          return;
        }
        // A bought plan first turns the button into a tick, so the moment
        // of paying lands before the screen moves on.
        HapticFeedback.heavyImpact();
        setState(() => _purchaseDone = true);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) context.go('/pro-welcome', extra: {'restore': false});
        });
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
          icon: WaznIcons.clock,
        );
        return;
      case SubscriptionStatus.cancelled:
        // Neutral, not celebratory. This was the brand green with a tick --
        // the same colours as "Welcome to Wazn Pro" two cases up, with
        // only the icon differing. Someone who cancels and glances at a green
        // check-marked toast can reasonably believe they just subscribed.
        _showPurchaseSnackBar(
          messenger,
          _purchaseCopy(context, _PurchaseCopyKey.purchaseCancelled),
          backgroundColor: const Color(0xFF3A3A3C),
          icon: WaznIcons.close,
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
          icon: WaznIcons.refresh,
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
          icon: WaznIcons.offline,
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
          icon: WaznIcons.clock,
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
          icon: WaznIcons.refresh,
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
              done: _purchaseDone,
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
                    // Store review wants Terms and Privacy reachable from the
                    // purchase screen, but they are not part of the buy action.
                    // They sit at the tail of the scroll as fine print so the
                    // sticky CTA stays one clean object.
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        dense ? 24 : 30,
                        hPad,
                        8,
                      ),
                      child: _LegalFooter(
                        palette: palette,
                        onTerms: () => _openUrl(_termsUrl),
                        onPrivacy: () => _openUrl(_privacyPolicyUrl),
                        onRestore:
                            (_isLoading || _restoring) ? null : _handleRestore,
                        restoring: _restoring,
                      ),
                    ),
                  ],
                ),
                if (!inlineDock)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Reveal(
                      delay: const Duration(milliseconds: 1500),
                      offset: const Offset(0, 30),
                      duration: const Duration(milliseconds: 600),
                      child: dock,
                    ),
                  ),
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
        // Below the scan, the page assembles in order: name, promise,
        // benefits, plans, button.
        Reveal(
          delay: const Duration(milliseconds: 450),
          offset: const Offset(0, 14),
          child: Text(
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
        ),
        const SizedBox(height: 9),
        Reveal(
          delay: const Duration(milliseconds: 600),
          offset: const Offset(0, 10),
          child: Text(
            general ? l10n.purchase_headline : title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
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

    return _PlanChooser(
      selectedIndex: _packages.indexWhere(
        (p) => identical(p, _selectedPackage),
      ),
      badged: [
        for (final p in _packages) annual != null && identical(p, annual),
      ],
      cards: [
        for (var i = 0; i < _packages.length; i++)
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
// A purchase screen needs a first impression that proves the product. The plate
// photo is the proof; a single scan sweep and labelled callouts turn it into
// "this app reads your food and counts the calories". The sequence plays once,
// settles on the caught plate, then breathes very slowly so the screen still
// feels alive without ever pulling attention away from the offer below.
// ─────────────────────────────────────────────────────────────────────────────

const double _heroChromeTop = 8;
const String _heroAsset = 'assets/images/paywall/hero_slide_1.png';
const double _heroImageExtent = 1024;
const int _heroCalories = 590;

/// One item detected on the plate. [anchor] is a fraction of the square source
/// image, mapped onto the cover-cropped box when the hero is laid out.
class _HeroIngredient {
  const _HeroIngredient({
    required this.anchor,
    required this.label,
    required this.portion,
  });

  final Offset anchor;
  final String label;
  final String portion;
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

class _ScanHeroState extends State<_ScanHero> with TickerProviderStateMixin {
  static const Duration _revealDuration = Duration(milliseconds: 2400);
  static const Duration _ambientDuration = Duration(milliseconds: 2600);

  late final AnimationController _reveal;
  late final AnimationController _ambient;
  late final Animation<double> _scan;
  late final Animation<double> _pillFade;
  late final Animation<double> _badgeFade;
  late final Animation<double> _count;
  late final Animation<double> _badgeScale;
  late final List<Animation<double>> _ringFade;
  late final List<Animation<double>> _chipFade;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _reduced =
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .reduceMotion;

    _reveal = AnimationController(
      vsync: this,
      duration: _reduced ? const Duration(milliseconds: 200) : _revealDuration,
    );
    _ambient = AnimationController(vsync: this, duration: _ambientDuration);

    _scan = _segment(0.10, 0.45, Curves.easeInOut);
    _pillFade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(_segment(0.38, 0.52, Curves.easeIn));
    _badgeFade = _segment(0.52, 0.64, Curves.easeOut);
    _count = Tween<double>(
      begin: 0,
      end: _heroCalories.toDouble(),
    ).animate(_segment(0.55, 0.90, Curves.easeOutCubic));
    _badgeScale = Tween<double>(
      begin: 0.86,
      end: 1,
    ).animate(_segment(0.72, 0.88, Curves.easeOutBack));
    _ringFade = [
      for (final start in const [0.14, 0.19, 0.24, 0.29])
        _segment(start, start + 0.16, Curves.easeOut),
    ];
    _chipFade = [
      for (final start in const [0.50, 0.57, 0.64, 0.71])
        _segment(start, start + 0.12, Curves.easeOut),
    ];

    if (_reduced) {
      _reveal.value = 1;
    } else {
      _reveal.forward().whenComplete(() {
        if (mounted) _ambient.repeat(reverse: true);
      });
    }
  }

  Animation<double> _segment(double begin, double end, Curve curve) {
    return CurvedAnimation(
      parent: _reveal,
      curve: Interval(begin, end, curve: curve),
    );
  }

  @override
  void dispose() {
    _reveal.dispose();
    _ambient.dispose();
    super.dispose();
  }

  List<_HeroIngredient> _ingredients(AppLocalizations l10n) {
    return [
      _HeroIngredient(
        anchor: const Offset(0.33, 0.34),
        label: l10n.paywall_slide_grilled_chicken,
        portion: l10n.paywall_slide_chicken_portion,
      ),
      _HeroIngredient(
        anchor: const Offset(0.65, 0.36),
        label: l10n.paywall_slide_rice,
        portion: l10n.paywall_slide_rice_portion,
      ),
      _HeroIngredient(
        anchor: const Offset(0.31, 0.68),
        label: l10n.paywall_slide_avocado,
        portion: l10n.paywall_slide_avocado_portion,
      ),
      _HeroIngredient(
        anchor: const Offset(0.68, 0.70),
        label: l10n.paywall_slide_cherry_tomatoes,
        portion: l10n.paywall_slide_tomatoes_portion,
      ),
    ];
  }

  /// Maps a fraction of the square source image onto the cover-cropped box so
  /// callouts stay glued to the food whatever the viewport aspect is.
  Offset _coverPoint(Size box, Offset fraction) {
    final scale = math.max(
      box.width / _heroImageExtent,
      box.height / _heroImageExtent,
    );
    final rendered = _heroImageExtent * scale;
    return Offset(
      fraction.dx * rendered + (box.width - rendered) / 2,
      fraction.dy * rendered + (box.height - rendered) / 2,
    );
  }

  double _textWidth(
    String text,
    TextStyle base,
    double fontSize,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: base.merge(TextStyle(fontSize: fontSize, fontWeight: weight)),
      ),
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  /// Each chip hugs its own text so a short name like "Rice" reads as one tidy
  /// pill rather than a wide box with dead space. Chips are pinned to the near
  /// edge, which keeps two foods on the same row from ever colliding.
  List<Rect> _chipRects(
    Size box,
    List<Offset> dots,
    List<_HeroIngredient> ingredients,
    TextStyle base, {
    required bool rtl,
  }) {
    const chipHeight = 36.0;
    // The close button sits at the top of the leading edge -- the left in
    // English, the right in Arabic -- so the top chip on that side keeps
    // clear of it.
    const closeClearance = 56.0;
    const edge = 12.0;
    const dotSize = 6.0;
    const dotGap = 8.0;
    const hPad = 9.0;
    final maxWidth = math.max(48.0, (box.width - 86) / 2);
    final rects = <Rect>[];
    for (var i = 0; i < dots.length; i++) {
      final dot = dots[i];
      final item = ingredients[i];
      final isTop = item.anchor.dy < 0.5;
      final isLeft = item.anchor.dx < 0.5;
      final content = math.max(
        _textWidth(item.label, base, 10, FontWeight.w700),
        _textWidth(item.portion, base, 8.5, FontWeight.w600),
      );
      // A couple of pixels of slack: sizing to the exact glyph width makes the
      // text ellipsize over sub-pixel rounding, which drops a whole word.
      final width = math.min(
        maxWidth,
        content + dotSize + dotGap + hPad * 2 + 4,
      );
      final besideClose = isTop && (isLeft != rtl);
      final inset = besideClose ? closeClearance : edge;
      final left = isLeft ? inset : box.width - inset - width;
      final rawTop = isTop ? dot.dy + 12 : dot.dy - chipHeight - 12;
      final top =
          rawTop
              .clamp(edge, math.max(edge, box.height - chipHeight - edge))
              .toDouble();
      rects.add(Rect.fromLTWH(left, top, width, chipHeight));
    }
    return rects;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final l10n = AppLocalizations.of(context)!;
    final ingredients = _ingredients(l10n);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        key: const ValueKey('paywall-scan-hero'),
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final dots = [
              for (final item in ingredients) _coverPoint(size, item.anchor),
            ];
            final rects = _chipRects(
              size,
              dots,
              ingredients,
              DefaultTextStyle.of(context).style,
              rtl: Directionality.of(context) == TextDirection.rtl,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _heroAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  cacheWidth: 900,
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
                // The beam only needs the one-shot reveal, so it is kept out of
                // the ambient rebuild below.
                AnimatedBuilder(
                  animation: _scan,
                  builder: (context, _) => _scanBeam(),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_reveal, _ambient]),
                        builder:
                            (context, _) =>
                                _overlay(l10n, dots, rects, ingredients),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 12,
                  top: widget.topInset + _heroChromeTop,
                  child: _HeroIconButton(
                    icon: WaznIcons.close,
                    onTap: widget.onClose,
                    semanticLabel:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scanBeam() {
    final progress = _scan.value;
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final opacity =
        progress < 0.15
            ? progress / 0.15
            : (progress > 0.85 ? (1 - progress) / 0.15 : 1.0);
    return Positioned(
      top: progress * widget.height - 3,
      left: 0,
      right: 0,
      height: 6,
      child: Opacity(
        opacity: opacity,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0),
                  AppColors.primary.withValues(alpha: 0.55),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlay(
    AppLocalizations l10n,
    List<Offset> dots,
    List<Rect> rects,
    List<_HeroIngredient> ingredients,
  ) {
    final pulse = _reduced ? 1.0 : 0.72 + 0.28 * _ambient.value;
    final palette = widget.palette;
    // On the bright marble a white hairline disappears; a soft dark line reads
    // as a leader without competing with the food.
    final lineColor =
        palette.isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.24);

    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: _CalloutConnectorPainter(
            dots: dots,
            rects: rects,
            opacities: [for (final fade in _chipFade) fade.value],
            color: lineColor,
          ),
        ),
      ),
    ];

    for (var i = 0; i < dots.length; i++) {
      final dot = dots[i];
      final ring = _ringFade[i].value;
      final diameter = 18 + 10 * ring;
      children.add(
        Positioned(
          left: dot.dx - diameter / 2,
          top: dot.dy - diameter / 2,
          child: Opacity(
            opacity: (ring * (0.35 + 0.65 * pulse)).clamp(0, 1),
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      palette.isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.black.withValues(alpha: 0.32),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      );
      children.add(
        Positioned(
          left: dot.dx - 5,
          top: dot.dy - 5,
          child: Opacity(
            opacity: (_chipFade[i].value * pulse).clamp(0, 1),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5 * pulse),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < ingredients.length; i++) {
      final fade = _chipFade[i].value;
      final rect = rects[i];
      children.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: Opacity(
            opacity: fade.clamp(0, 1),
            child: Transform.scale(
              scale: 0.94 + 0.06 * fade,
              child: _IngredientChip(item: ingredients[i], palette: palette),
            ),
          ),
        ),
      );
    }

    // The spinner drives its own ticker, so it must leave the tree once the
    // scan is done rather than merely fade out.
    if (_pillFade.value > 0.01) {
      children.add(
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: _pillFade.value.clamp(0, 1),
              child: _AnalyzingPill(label: l10n.onboarding_scan_scanning),
            ),
          ),
        ),
      );
    }

    children.add(
      Positioned(
        left: 0,
        right: 0,
        bottom: 10,
        child: Center(
          child: Opacity(
            opacity: _badgeFade.value.clamp(0, 1),
            child: Transform.scale(
              scale: _badgeScale.value,
              child: _CalorieBadge(
                calories: _count.value.round(),
                kcalLabel: l10n.onboarding_scan_kcal,
                aiLabel: l10n.onboarding_scan_ai_label,
                pulse: pulse,
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(fit: StackFit.expand, children: children);
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.item, required this.palette});

  final _HeroIngredient item;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final isDark = palette.isDark;
    final labelColor = isDark ? Colors.white : palette.ink;
    final portionColor =
        isDark ? Colors.white.withValues(alpha: 0.7) : palette.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        // Frosted paper in light mode so the pill sits on the marble instead of
        // punching a black hole in it; the HUD-dark pill only in dark mode.
        color:
            isDark
                ? Colors.black.withValues(alpha: 0.58)
                : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.18) : palette.hairline,
        ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  strutStyle: const StrutStyle(
                    fontSize: 10,
                    height: 1.15,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.portion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  strutStyle: const StrutStyle(
                    fontSize: 8.5,
                    height: 1.1,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    color: portionColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
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

class _CalorieBadge extends StatelessWidget {
  const _CalorieBadge({
    required this.calories,
    required this.kcalLabel,
    required this.aiLabel,
    required this.pulse,
  });

  final int calories;
  final String kcalLabel;
  final String aiLabel;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.34 * pulse),
            blurRadius: 24 * pulse,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              aiLabel,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.96),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '$calories',
            textScaler: TextScaler.noScaling,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            kcalLabel,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzingPill extends StatelessWidget {
  const _AnalyzingPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutConnectorPainter extends CustomPainter {
  _CalloutConnectorPainter({
    required this.dots,
    required this.rects,
    required this.opacities,
    required this.color,
  });

  final List<Offset> dots;
  final List<Rect> rects;
  final List<double> opacities;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < dots.length; i++) {
      final opacity = opacities[i].clamp(0.0, 1.0);
      if (opacity <= 0.01) continue;
      final dot = dots[i];
      final rect = rects[i];
      final target = Offset(
        dot.dx.clamp(rect.left + 12, rect.right - 12).toDouble(),
        dot.dy < rect.top
            ? rect.top
            : (dot.dy > rect.bottom ? rect.bottom : rect.center.dy),
      );
      final paint =
          Paint()
            ..color = color.withValues(alpha: color.a * opacity)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round;
      canvas.drawLine(target, dot, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalloutConnectorPainter oldDelegate) => true;
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

    return Reveal(
      delay: const Duration(milliseconds: 800),
      offset: const Offset(0, 16),
      child: Container(
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
                    // Each tick pops in turn as its line fades up.
                    Reveal(
                      delay: Duration(milliseconds: 1000 + 170 * i),
                      offset: Offset.zero,
                      scale: .3,
                      duration: const Duration(milliseconds: 480),
                      curve: AppMotion.springCurve,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: palette.isDark ? 0.22 : 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          WaznIcons.check,
                          size: 14,
                          color: palette.accentInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Reveal(
                        delay: Duration(milliseconds: 1000 + 170 * i),
                        offset: const Offset(0, 6),
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
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The plans, with one outline that glides to whichever is chosen rather
/// than each card lighting up on its own. The cards rise in one by one.
class _PlanChooser extends StatefulWidget {
  const _PlanChooser({
    required this.cards,
    required this.selectedIndex,
    required this.badged,
  });

  final List<Widget> cards;
  final int selectedIndex;

  /// Which cards carry a badge above them, which sits in a strip on top.
  final List<bool> badged;

  @override
  State<_PlanChooser> createState() => _PlanChooserState();
}

class _PlanChooserState extends State<_PlanChooser> {
  static const _badgeStrip = 7.0;

  final List<GlobalKey> _keys = [];
  Rect? _ring;

  Duration _delay(int i) => Duration(milliseconds: 1300 + 120 * i);

  void _measure() {
    if (!mounted) return;
    final i = widget.selectedIndex;
    Rect? next;
    if (i >= 0 && i < _keys.length) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize && box.parentData is BoxParentData) {
        final offset = (box.parentData! as BoxParentData).offset;
        final top = widget.badged[i] ? _badgeStrip : 0.0;
        next = Rect.fromLTWH(
          offset.dx,
          offset.dy + top,
          box.size.width,
          box.size.height - top,
        );
      }
    }
    if (next != _ring) setState(() => _ring = next);
  }

  @override
  Widget build(BuildContext context) {
    while (_keys.length < widget.cards.length) {
      _keys.add(GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final ring = _ring;
    return _RingScope(
      active: ring != null,
      child: Stack(
        children: [
          Column(
            children: [
              for (var i = 0; i < widget.cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                KeyedSubtree(
                  key: _keys[i],
                  child: Reveal(
                    delay: _delay(i),
                    offset: const Offset(0, 22),
                    child: widget.cards[i],
                  ),
                ),
              ],
            ],
          ),
          if (ring != null)
            AnimatedPositioned.fromRect(
              rect: ring,
              duration: AppMotion.maybeZero(
                context,
                const Duration(milliseconds: 500),
              ),
              curve: const Cubic(0.34, 1.3, 0.55, 1),
              child: IgnorePointer(
                child: Reveal(
                  delay: _delay(widget.selectedIndex.clamp(0, 9)),
                  offset: const Offset(0, 22),
                  child: DecoratedBox(
                    key: const ValueKey('paywall-plan-ring'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.62),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tells the plan cards the gliding outline is drawing the selection, so
/// they don't draw their own as well.
class _RingScope extends InheritedWidget {
  const _RingScope({required this.active, required super.child});

  final bool active;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RingScope>()?.active ?? false;

  @override
  bool updateShouldNotify(_RingScope old) => old.active != active;
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
    final outlined = selected && !_RingScope.of(context);
    final card = Semantics(
      button: true,
      selected: selected,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          end:
              selected
                  ? Color.alphaBlend(
                    AppColors.primary.withValues(
                      alpha: palette.isDark ? 0.13 : 0.07,
                    ),
                    palette.surface,
                  )
                  : palette.surface,
        ),
        duration: AppMotion.maybeZero(context, AppMotion.expansion),
        builder:
            (context, fill, child) => Material(
              color: fill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color:
                      outlined
                          ? AppColors.primary.withValues(alpha: 0.62)
                          : palette.hairline,
                  width: outlined ? 1.8 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  // The struck renewal price is the first line of the right column;
                  // when the discount badge straddles the top border it needs enough
                  // clearance not to sit on top of it.
                  padding: EdgeInsets.fromLTRB(
                    16,
                    introPrice != null ? 24 : 17,
                    16,
                    17,
                  ),
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
          child: _Wiggle(
            active: selected,
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
        ),
      ],
    );
  }
}

/// Gives its child a quick shake when [active] turns on: the savings badge
/// nodding as its plan is picked.
class _Wiggle extends StatelessWidget {
  const _Wiggle({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(active),
      tween: Tween(begin: active ? 0 : 1, end: 1),
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 560)),
      builder:
          (context, t, child) => Transform.rotate(
            angle: math.sin(t * math.pi * 3) * (1 - t) * 0.12,
            child: Transform.scale(
              scale: 1 + math.sin(t * math.pi) * 0.08,
              child: child,
            ),
          ),
      child: child,
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.palette});

  final bool selected;
  final _Palette palette;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.maybeZero(context, AppMotion.standard),
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
    // The dot springs in, a touch past full size.
    child: Center(
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 420),
        ),
        curve: selected ? AppMotion.springCurve : Curves.easeIn,
        child: Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
      ),
    ),
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
          const Icon(WaznIcons.error, size: 17, color: AppColors.warning),
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
                  WaznIcons.refresh,
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
    required this.done,
    required this.isLoading,
    required this.restoring,
    required this.package,
    required this.loadingOfferings,
    required this.trialDays,
    required this.introPriceString,
    required this.planLabel,
    required this.disclosure,
    required this.onPurchase,
  });

  final _Palette palette;
  final double hPad;
  final bool done;
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
              // A light crosses the button once the page has settled.
              ShineSweep(
                borderRadius: BorderRadius.circular(16),
                delay: const Duration(milliseconds: 2600),
                sweep: const Duration(milliseconds: 950),
                child: _PrimaryCta(
                  label: _ctaLabel(l10n),
                  busy: isLoading,
                  done: done,
                  enabled:
                      !done &&
                      !isLoading &&
                      !restoring &&
                      !loadingOfferings &&
                      package != null,
                  onTap: onPurchase,
                ),
              ),
              if (disclosure != null) ...[
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: AppMotion.maybeZero(context, AppMotion.expansion),
                  layoutBuilder:
                      (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, if (current != null) current],
                      ),
                  child: Text(
                    disclosure!,
                    key: ValueKey(disclosure),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
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
    this.done = false,
  });

  final String label;
  final bool busy;

  /// The purchase went through: the button shows a tick.
  final bool done;
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
              // A new plan's words rise into the button; paying turns them
              // into a spinner and then a tick.
              child: AnimatedSwitcher(
                duration: AppMotion.maybeZero(
                  context,
                  const Duration(milliseconds: 320),
                ),
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, .6),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: AppMotion.springCurve,
                            reverseCurve: Curves.easeIn,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                child:
                    widget.done
                        ? const _DrawnTick(key: ValueKey('done'))
                        : widget.busy
                        ? const SizedBox(
                          key: ValueKey('busy'),
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : Text(
                          widget.label,
                          key: ValueKey(widget.label),
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
      ),
    );
  }
}

/// A white check that draws itself from left to right.
class _DrawnTick extends StatelessWidget {
  const _DrawnTick({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 420)),
      curve: Curves.easeOutCubic,
      builder:
          (context, t, _) => CustomPaint(
            size: const Size.square(24),
            painter: _TickPainter(t),
          ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path =
        Path()
          ..moveTo(size.width * .2, size.height * .52)
          ..lineTo(size.width * .41, size.height * .72)
          ..lineTo(size.width * .8, size.height * .3);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.palette,
    required this.onTerms,
    required this.onPrivacy,
    required this.onRestore,
    required this.restoring,
  });

  final _Palette palette;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final VoidCallback? onRestore;
  final bool restoring;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      // Spacing, not separators: a wrapped separator would leave a dangling
      // dot at the end of the first line in the longer locales.
      spacing: 16,
      runSpacing: 2,
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
