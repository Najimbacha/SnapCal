import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import 'package:snapcal/core/services/config_service.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/data/services/pro_feature_service.dart';
import 'package:snapcal/data/services/app_prompt_session_coordinator.dart';
import 'package:snapcal/data/services/promotional_paywall_service.dart';
import 'package:snapcal/data/services/scan_gate_service.dart';
import 'package:snapcal/data/services/subscription_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/metrics_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import '../../widgets/wazn_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/wazn_mark.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE
//
// The purchase screen is dark in both themes: the launch screen's ground,
// with the app icon's green spent only on what matters -- the Pro values, the
// chosen plan and the button. One green, one row style, no glows.
// ─────────────────────────────────────────────────────────────────────────────

const _bg = Color(0xFF0B110E);
const _card = Color(0xFF111915);
const _line = Color(0xFF22302A);
const _ink = Color(0xFFEEF3EF);
const _muted = Color(0xFF93A198);
const _faint = Color(0xFF5E6B63);
const _em = Color(0xFF34D399);
const _onEm = Color(0xFF04150D);
const _amber = Color(0xFFF5A524);

/// The few colours the notice and footer read, on the one dark ground.
class _Palette {
  const _Palette();

  bool get isDark => true;
  Color get ink => _ink;
  Color get muted => _muted;
  Color get accentInk => _em;
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
    super.dispose();
  }

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
          return l10n.paywall_disclosure_trial_until_year(
            _trialEnds(trial, l10n),
            priceString,
          );
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
          return l10n.paywall_disclosure_trial_until_month(
            _trialEnds(trial, l10n),
            priceString,
          );
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

  /// The day the free trial ends, so the line under the button can say
  /// exactly when the first payment happens.
  String _trialEnds(_TrialInfo trial, AppLocalizations l10n) => DateFormat.MMMd(
    l10n.localeName,
  ).format(DateTime.now().add(Duration(days: trial.days)));

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
    final l10n = AppLocalizations.of(context)!;

    // Close the screen if Pro arrives late.
    //
    // A purchase the store accepted but the server had not confirmed yet
    // comes back as `pending`: the user has been charged, and the paywall
    // stays up with an amber "processing" notice. SubscriptionService retries
    // the verification at 8s and 30s, so the entitlement usually does land --
    // and this is what notices it, rather than leaving the buy button live
    // for someone who has already paid.
    //
    // Guarded by _closed so this and the success path cannot both navigate.
    ref.listen<bool>(effectiveIsProProvider, (previous, isPro) {
      if (!isPro || _closed || !mounted) return;
      _closed = true;
      context.go('/pro-welcome', extra: {'restore': !_purchaseStarted});
    });

    final package = _selectedPackage;
    final trial = _trialFor(package);
    final disclosure = _disclosureFor(package, l10n);

    // Hold the screen while a purchase is in flight: leaving during the store
    // sheet threw the result away, success included.
    return PopScope(
      canPop: !_isLoading && !_restoring,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: _bg,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              // A soft light behind the name, and nothing else glowing.
              const Positioned(
                top: -170,
                left: -60,
                right: -60,
                height: 380,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0x1F34D399), Color(0x0034D399)],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                // One screen on most phones: the column fills the height, and
                // only a short phone or large text makes it scroll.
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTop(context),
                            const SizedBox(height: 10),
                            _buildHeader(context, l10n),
                            const SizedBox(height: 18),
                            Reveal(
                              delay: const Duration(milliseconds: 520),
                              offset: const Offset(0, 24),
                              duration: const Duration(milliseconds: 640),
                              child: _CompareCard(rows: _compareRows(l10n)),
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Reveal(
                                delay: const Duration(milliseconds: 800),
                                offset: const Offset(0, 8),
                                child: _EverythingLink(
                                  label: l10n.paywall_see_everything,
                                  onTap: () => _showEverything(context),
                                ),
                              ),
                            ),
                            const Spacer(),
                            ..._buildNotices(),
                            const SizedBox(height: 10),
                            _buildPlans(l10n),
                            const SizedBox(height: 12),
                            Reveal(
                              delay: const Duration(milliseconds: 1050),
                              offset: const Offset(0, 24),
                              duration: const Duration(milliseconds: 620),
                              child: _PrimaryCta(
                                key: const ValueKey('paywall-cta'),
                                label: _ctaLabel(l10n, package, trial),
                                busy: _isLoading,
                                done: _purchaseDone,
                                enabled:
                                    !_purchaseDone &&
                                    !_isLoading &&
                                    !_restoring &&
                                    !_loadingOfferings &&
                                    package != null,
                                onTap: _handlePurchase,
                              ),
                            ),
                            const SizedBox(height: 9),
                            // Store rules want the trial, the price after it
                            // and the billing period right beside the button.
                            AnimatedSwitcher(
                              duration: AppMotion.maybeZero(
                                context,
                                AppMotion.expansion,
                              ),
                              layoutBuilder:
                                  (current, previous) => Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      ...previous,
                                      if (current != null) current,
                                    ],
                                  ),
                              child: Text(
                                disclosure ?? l10n.paywall_cancel_anytime,
                                key: ValueKey(disclosure),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _LegalFooter(
                              palette: const _Palette(),
                              onTerms: () => _openUrl(_termsUrl),
                              onPrivacy: () => _openUrl(_privacyPolicyUrl),
                              onRestore:
                                  (_isLoading || _restoring)
                                      ? null
                                      : _handleRestore,
                              restoring: _restoring,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTop(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Reveal(
        offset: const Offset(0, -8),
        duration: const Duration(milliseconds: 400),
        child: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).closeButtonTooltip,
          child: GestureDetector(
            key: const ValueKey('paywall-close'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_isLoading || _restoring) return;
              if (context.canPop()) context.pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(WaznIcons.close, size: 17, color: _muted),
            ),
          ),
        ),
      ),
    );
  }

  /// The icon beside the name, and one line chosen by where the user came
  /// from, so the promise matches the door they walked through.
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final headline = _headline(l10n);
    final general = headline == l10n.purchase_headline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Reveal(
              delay: Duration(milliseconds: 80),
              offset: Offset.zero,
              scale: .4,
              curve: AppMotion.springCurve,
              duration: Duration(milliseconds: 760),
              child: WaznMark(size: 46),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Reveal(
                delay: const Duration(milliseconds: 220),
                offset: const Offset(0, 14),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l10n.appTitle} '),
                      const TextSpan(text: 'Pro', style: TextStyle(color: _em)),
                    ],
                  ),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Reveal(
          delay: const Duration(milliseconds: 400),
          offset: const Offset(0, 10),
          child: Text(
            headline,
            style: TextStyle(
              color: general ? _muted : _ink,
              fontSize: 15.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Same mapping as before: each door into the screen has its own line.
  String _headline(AppLocalizations l10n) {
    if (widget.featureName == 'barcode') return l10n.paywall_barcode_title;
    if (widget.limitReached) {
      // Real numbers from the gate that blocked the scan, never a figure
      // hardcoded here.
      final gate = ScanGateService();
      return l10n.paywall_free_scans_used_title(
        gate.getPeriodScanCount(),
        gate.getMonthlyLimit(),
      );
    }
    switch (widget.entryPoint) {
      case PaywallEntryPoint.scanLimit:
        return l10n.paywall_unlimited_scanning_title;
      case PaywallEntryPoint.aiCoachLimit:
        return l10n.paywall_ai_coaching_title;
      case PaywallEntryPoint.plannerLockedDay:
      case PaywallEntryPoint.plannerPreferences:
        return l10n.paywall_smart_planning_title;
      case PaywallEntryPoint.groceryList:
        return l10n.paywall_shopping_lists_title;
      case PaywallEntryPoint.progressPhotoLimit:
        return l10n.paywall_progress_journey_title;
      case PaywallEntryPoint.reportInsight:
      case PaywallEntryPoint.macroDetails:
      case PaywallEntryPoint.mealInsight:
        return l10n.paywall_analytics_title;
      default:
        return l10n.purchase_headline;
    }
  }

  /// What Free allows and what Pro gives, with Free's real limits.
  List<_CompareRowData> _compareRows(AppLocalizations l10n) {
    final gate = ScanGateService();
    final limit = gate.getMonthlyLimit();
    final used = gate.getPeriodScanCount();
    final out = widget.limitReached || used >= limit;
    return [
      _CompareRowData(
        icon: WaznIcons.scan,
        label: l10n.paywall_row_scans,
        free:
            out
                ? l10n.paywall_free_scans_left('0', '$limit')
                : l10n.paywall_free_scans_month('$limit'),
        pro: l10n.paywall_feature_unlimited,
        warning: out,
      ),
      _CompareRowData(
        icon: WaznIcons.calendar,
        label: l10n.paywall_row_meal_plans,
        free: l10n.paywall_free_meal_plan,
        pro: l10n.paywall_pro_meal_plan,
      ),
      _CompareRowData(
        icon: WaznIcons.coach,
        label: l10n.paywall_row_coach,
        free: l10n.paywall_free_coach,
        pro: l10n.paywall_pro_coach,
      ),
      _CompareRowData(
        icon: WaznIcons.image,
        label: l10n.paywall_row_photos,
        free: l10n.paywall_free_photos('${BodyMetrics.freePhotoCheckIns}'),
        pro: l10n.paywall_feature_unlimited,
      ),
      _CompareRowData(
        icon: WaznIcons.history,
        label: l10n.paywall_row_history,
        free: l10n.paywall_free_history('${ProFeatureService.freeHistoryDays}'),
        pro: l10n.paywall_pro_history,
      ),
    ];
  }

  void _showEverything(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final limit = ScanGateService().getMonthlyLimit();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF131C17),
      showDragHandle: true,
      builder:
          (_) => _EverythingSheet(
            title: l10n.paywall_everything_title,
            items: [
              (
                l10n.paywall_all_scans_title,
                l10n.paywall_all_scans_detail('$limit'),
              ),
              (l10n.paywall_all_coach_title, l10n.paywall_all_coach_detail),
              (l10n.paywall_all_plans_title, l10n.paywall_all_plans_detail),
              (
                l10n.paywall_all_history_title,
                l10n.paywall_all_history_detail(
                  '${ProFeatureService.freeHistoryDays}',
                ),
              ),
              (
                l10n.paywall_all_photos_title,
                l10n.paywall_all_photos_detail(
                  '${BodyMetrics.freePhotoCheckIns}',
                ),
              ),
            ],
          ),
    );
  }

  List<Widget> _buildNotices() {
    return [
      if (_purchaseNotice != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _NoticeBanner(
            message: _purchaseNotice!,
            palette: const _Palette(),
            // Every purchase notice is a state the user can try again from.
            onRetry: _isLoading ? null : _handlePurchase,
          ),
        ),
      if (_offeringsNotice != null && !_loadingOfferings)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _NoticeBanner(
            message: _offeringsNotice!,
            palette: const _Palette(),
            onRetry: _loadOfferings,
          ),
        ),
    ];
  }

  /// "Start 7-day free trial" when the store has a free trial for this plan;
  /// otherwise the plan and what is charged first.
  String _ctaLabel(AppLocalizations l10n, Package? package, _TrialInfo? trial) {
    if (_loadingOfferings) return l10n.premium_loading;
    if (package == null) return l10n.paywall_unlock_snapcal_pro;
    if (trial != null) return l10n.paywall_start_trial_days('${trial.days}');
    try {
      return l10n.premium_start_plan(
        _planLabel(package, l10n),
        _introFor(package)?.priceString ?? package.storeProduct.priceString,
      );
    } catch (_) {
      return l10n.paywall_unlock_snapcal_pro;
    }
  }

  Widget _buildPlans(AppLocalizations l10n) {
    if (_loadingOfferings) return const _PlanSkeleton();
    if (_packages.isEmpty) return const SizedBox.shrink();

    final savings = _savingsPercent(_monthlyPackage, _annualPackage);
    final annual = _annualPackage;
    return _PlanTiles(
      selectedIndex: _packages.indexWhere(
        (p) => identical(p, _selectedPackage),
      ),
      onSelect: (i) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPackage = _packages[i];
          _purchaseNotice = null;
        });
      },
      plans: [
        for (final p in _packages)
          _PlanData(
            label: _planLabel(p, l10n),
            // What is actually charged first is the biggest number: the store
            // rules ask for exactly this.
            price: _introFor(p)?.priceString ?? _safePriceString(p),
            note: _planNote(p, l10n),
            noteIsOffer: _trialFor(p) != null,
            badge:
                annual != null && identical(p, annual) && savings != null
                    ? l10n.paywall_save_percent(savings)
                    : null,
          ),
      ],
    );
  }

  /// The line under a plan's price: the free days, the price after a
  /// first-period discount, or simply the period.
  String _planNote(Package package, AppLocalizations l10n) {
    final trial = _trialFor(package);
    if (trial != null) return l10n.paywall_plan_days_free('${trial.days}');
    if (_introFor(package) != null) {
      return l10n.paywall_plan_then(_safePriceString(package));
    }
    return switch (package.packageType) {
      PackageType.annual => l10n.paywall_plan_per_year,
      PackageType.monthly => l10n.paywall_plan_per_month,
      _ => '',
    };
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
// FREE / PRO
//
// One card, one row style. The switch moves to Pro once by itself, so the
// difference is the first thing seen, then it is the reader's to flip.
// ─────────────────────────────────────────────────────────────────────────────

class _CompareRowData {
  const _CompareRowData({
    required this.icon,
    required this.label,
    required this.free,
    required this.pro,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final String free;
  final String pro;

  /// The Free value is a limit already reached: shown in amber.
  final bool warning;
}

class _CompareCard extends StatefulWidget {
  const _CompareCard({required this.rows});

  final List<_CompareRowData> rows;

  @override
  State<_CompareCard> createState() => _CompareCardState();
}

class _CompareCardState extends State<_CompareCard>
    with SingleTickerProviderStateMixin {
  bool _pro = false;
  bool _touched = false;

  /// Waits for the card to arrive before the first flip.
  late final AnimationController _wait = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void initState() {
    super.initState();
    _wait.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_touched && mounted) {
        setState(() => _pro = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wait.isAnimating || _wait.isCompleted || _touched) return;
    if (AppMotion.reduceMotion(context)) {
      _pro = true;
      _wait.value = 1;
    } else {
      _wait.forward();
    }
  }

  @override
  void dispose() {
    _wait.dispose();
    super.dispose();
  }

  void _set(bool pro) {
    _touched = true;
    if (pro == _pro) return;
    HapticFeedback.selectionClick();
    setState(() => _pro = pro);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      key: const ValueKey('paywall-compare'),
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 450)),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pro ? _em.withValues(alpha: 0.4) : _line),
      ),
      child: Column(
        children: [
          _Switch(
            pro: _pro,
            onChanged: _set,
            free: l10n.paywall_compare_free,
            proLabel: l10n.paywall_compare_pro,
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < widget.rows.length; i++)
            _CompareRow(
              data: widget.rows[i],
              pro: _pro,
              order: i,
              first: i == 0,
            ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.pro,
    required this.onChanged,
    required this.free,
    required this.proLabel,
  });

  final bool pro;
  final ValueChanged<bool> onChanged;
  final String free;
  final String proLabel;

  @override
  Widget build(BuildContext context) {
    Widget option(String text, bool value) => Expanded(
      child: Semantics(
        button: true,
        selected: pro == value,
        child: GestureDetector(
          key: ValueKey('paywall-switch-${value ? 'pro' : 'free'}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.standard,
              // Merged, not replaced: a bare style here dropped the font.
              style: DefaultTextStyle.of(context).style.copyWith(
                color: pro == value ? (value ? _onEm : _ink) : _muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              child: Text(text),
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment:
                pro
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
            duration: AppMotion.maybeZero(
              context,
              const Duration(milliseconds: 450),
            ),
            curve: AppMotion.springCurve,
            child: FractionallySizedBox(
              widthFactor: .5,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: AppMotion.standard,
                decoration: BoxDecoration(
                  color: pro ? _em : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          Row(children: [option(free, false), option(proLabel, true)]),
        ],
      ),
    );
  }
}

/// One line of the comparison. Its value turns over, top to bottom a
/// moment after the one above, when the switch moves.
class _CompareRow extends StatefulWidget {
  const _CompareRow({
    required this.data,
    required this.pro,
    required this.order,
    required this.first,
  });

  final _CompareRowData data;
  final bool pro;
  final int order;
  final bool first;

  @override
  State<_CompareRow> createState() => _CompareRowState();
}

class _CompareRowState extends State<_CompareRow>
    with SingleTickerProviderStateMixin {
  static const _turn = Duration(milliseconds: 520);
  static const _step = Duration(milliseconds: 70);

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: _turn + _step * widget.order,
    value: widget.pro ? 1 : 0,
  );

  @override
  void didUpdateWidget(_CompareRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pro == oldWidget.pro) return;
    if (AppMotion.reduceMotion(context)) {
      _flip.value = widget.pro ? 1 : 0;
    } else if (widget.pro) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final total = _turn + _step * widget.order;
    final wait = (_step * widget.order).inMicroseconds / total.inMicroseconds;
    return Container(
      constraints: const BoxConstraints(minHeight: 43),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border:
            widget.first ? null : const Border(top: BorderSide(color: _line)),
      ),
      // Name on the start edge, value on the end edge; each takes the room
      // it needs, and both wrap rather than overflow on a narrow phone.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: widget.pro ? _em : _faint),
                  duration: AppMotion.maybeZero(context, AppMotion.expansion),
                  builder:
                      (context, color, _) =>
                          Icon(data.icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    data.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(
                  ((_flip.value - wait) / (1 - wait)).clamp(0.0, 1.0),
                );
                final showPro = t >= .5;
                // Turns away on one side and comes round on the other.
                final angle =
                    showPro
                        ? -(1 - t) / .5 * math.pi / 2
                        : t / .5 * math.pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform:
                      Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(angle),
                  child: Text(
                    showPro ? data.pro : data.free,
                    key: ValueKey('paywall-row-${widget.order}'),
                    maxLines: 2,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: showPro ? _em : (data.warning ? _amber : _muted),
                      fontSize: 14,
                      fontWeight:
                          showPro || data.warning
                              ? FontWeight.w700
                              : FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EverythingLink extends StatelessWidget {
  const _EverythingLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('paywall-see-everything'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            color: _muted,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: _muted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// The full list of what Pro includes, for anyone who wants it, without it
/// taking space on the screen.
class _EverythingSheet extends StatelessWidget {
  const _EverythingSheet({required this.title, required this.items});

  final String title;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < items.length; i++)
              Reveal(
                delay: Duration(milliseconds: 120 + 60 * i),
                offset: const Offset(0, 12),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(WaznIcons.success, size: 20, color: _em),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].$1,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].$2,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLANS
//
// Side by side above the button, so the price is always in view. One outline
// glides to the chosen plan.
// ─────────────────────────────────────────────────────────────────────────────

class _PlanData {
  const _PlanData({
    required this.label,
    required this.price,
    required this.note,
    this.noteIsOffer = false,
    this.badge,
  });

  final String label;
  final String price;
  final String note;

  /// The note names a free trial: shown in green.
  final bool noteIsOffer;
  final String? badge;
}

class _PlanTiles extends StatelessWidget {
  const _PlanTiles({
    required this.plans,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_PlanData> plans;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final count = plans.length;
    final i = selectedIndex;
    final slide = AppMotion.maybeZero(
      context,
      const Duration(milliseconds: 450),
    );
    return IntrinsicHeight(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var k = 0; k < count; k++) ...[
                if (k > 0) const SizedBox(width: _gap),
                Expanded(
                  child: Reveal(
                    delay: Duration(milliseconds: 850 + 80 * k),
                    offset: const Offset(0, 20),
                    child: _PlanTile(
                      data: plans[k],
                      selected: k == i,
                      onTap: () => onSelect(k),
                    ),
                  ),
                ),
              ],
            ],
          ),
          // The outline takes one equal slot of the row and trims the gaps
          // off its sides, so it sits exactly on the chosen tile.
          if (i >= 0 && count > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedAlign(
                  alignment: AlignmentDirectional(
                    count == 1 ? 0 : -1 + 2 * i / (count - 1),
                    0,
                  ),
                  duration: slide,
                  curve: AppMotion.springCurve,
                  child: FractionallySizedBox(
                    widthFactor: 1 / count,
                    heightFactor: 1,
                    child: AnimatedPadding(
                      duration: slide,
                      curve: AppMotion.springCurve,
                      padding: EdgeInsetsDirectional.only(
                        start: _gap * i / count,
                        end: _gap * (count - 1 - i) / count,
                      ),
                      child: DecoratedBox(
                        key: const ValueKey('paywall-plan-ring'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _em, width: 2),
                        ),
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

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _PlanData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The name, with the saving beside it rather than on the
                  // edge, where the chosen outline would run through it.
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        data.label,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (data.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _em,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            data.badge!,
                            style: const TextStyle(
                              color: _onEm,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      data.price,
                      maxLines: 1,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (data.note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      data.note,
                      maxLines: 2,
                      style: TextStyle(
                        color: data.noteIsOffer ? _em : _faint,
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight:
                            data.noteIsOffer
                                ? FontWeight.w700
                                : FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
            ),
          ),
        ],
      ],
    );
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

/// The one filled object on the screen.
class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({
    super.key,
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
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _em,
                borderRadius: BorderRadius.circular(16),
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
                            valueColor: AlwaysStoppedAnimation(_onEm),
                          ),
                        )
                        : Text(
                          widget.label,
                          key: ValueKey(widget.label),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _onEm,
                            fontSize: 16,
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

/// A check that draws itself from left to right.
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
        ..color = _onEm
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
          label: l10n.paywall_restore,
          onTap: onRestore,
          palette: palette,
          busy: restoring,
        ),
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
