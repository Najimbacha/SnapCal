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

const _paperLight = Color(0xFFFBFAF7);
const _paperDark = Color(0xFF0A0D0C);
const _surfaceLight = Color(0xFFFFFFFF);
const _surfaceDark = Color(0xFF141917);
const _hairlineLight = Color(0xFFEAE6DE);
const _hairlineDark = Color(0xFF242C28);
const _inkLight = Color(0xFF16181D);
const _inkDark = Color(0xFFF1F4F2);
const _mutedLight = Color(0xFF76766E);
const _mutedDark = Color(0xFF8B9A94);

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
  Color get accentInk => isDark ? AppColors.emeraldLight : AppColors.primaryDark;

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

class PaywallScreen extends ConsumerStatefulWidget {
  final bool limitReached;
  final PaywallEntryPoint entryPoint;
  final String? featureName;

  const PaywallScreen({
    super.key,
    this.limitReached = false,
    this.entryPoint = PaywallEntryPoint.settings,
    this.featureName,
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

  final GlobalKey _dockKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  /// Real rendered height of the CTA dock, measured after first paint.
  double? _dockHeight;

  /// 0 while the hero still covers the status bar, 1 once it has scrolled
  /// away. Drives the scrim that stops body text drawing through the clock.
  double _statusBarScrim = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureDock());
    _loadOfferings();
  }

  @override
  void dispose() {
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
      final offerings = await SubscriptionService().getOfferings().timeout(
        const Duration(seconds: 8),
      );
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
            : l10n.paywall_disclosure_intro_year(intro.priceString, priceString);
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

  String? _billingCadence(Package package, AppLocalizations l10n) {
    switch (package.packageType) {
      case PackageType.monthly:
        return l10n.paywall_billing_monthly;
      case PackageType.lifetime:
        return l10n.paywall_billing_lifetime;
      default:
        return null;
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
    });

    final messenger = ScaffoldMessenger.of(context);
    final subService = SubscriptionService();
    final l10n = AppLocalizations.of(context)!;

    final result = await subService.purchasePackageDetailed(_selectedPackage!);
    if (!mounted) return;
    _handleSubscriptionResult(
      result,
      messenger: messenger,
      successMessage: l10n.premium_welcome,
      isRestore: false,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRestore() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final subService = SubscriptionService();
    final l10n = AppLocalizations.of(context)!;

    final result = await subService.restorePurchasesDetailed();
    if (!mounted) return;
    _handleSubscriptionResult(
      result,
      messenger: messenger,
      successMessage: l10n.premium_restore_success,
      isRestore: true,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleSubscriptionResult(
    SubscriptionResult result, {
    required ScaffoldMessengerState messenger,
    required String successMessage,
    required bool isRestore,
  }) {
    switch (result.status) {
      case SubscriptionStatus.active:
        // Not `ref.invalidate` — that drops the provider back to `loading`,
        // and for that window every consumer sees Pro status as unknown,
        // immediately after the purchase succeeded. Refresh in place instead.
        unawaited(ref.read(settingsProvider.notifier).refreshProStatus());
        if (mounted && context.canPop()) {
          context.pop();
        }
        _showPurchaseSnackBar(
          messenger,
          successMessage,
          backgroundColor: AppColors.primary,
          icon: LucideIcons.sparkles,
        );
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
        _showPurchaseSnackBar(
          messenger,
          _purchaseCopy(context, _PurchaseCopyKey.purchaseCancelled),
          backgroundColor: AppColors.primary,
          icon: LucideIcons.checkCircle2,
        );
        return;
      case SubscriptionStatus.noPurchase:
        _showPurchaseSnackBar(
          messenger,
          _purchaseCopy(context, _PurchaseCopyKey.restoreNoPurchase),
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
        final message = _purchaseCopy(context, _PurchaseCopyKey.storeSlow);
        setState(() => _purchaseNotice = message);
        _showPurchaseSnackBar(
          messenger,
          message,
          backgroundColor: AppColors.warning,
          icon: LucideIcons.clock,
        );
        return;
      case SubscriptionStatus.failed:
        _showPurchaseSnackBar(
          messenger,
          _purchaseCopy(
            context,
            isRestore
                ? _PurchaseCopyKey.restoreFailed
                : _PurchaseCopyKey.purchaseFailed,
          ),
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

    return Scaffold(
      backgroundColor: palette.paper,
      body: LayoutBuilder(
        builder: (context, viewport) {
          // The photography is square, so the hero is sized against the
          // narrower of the two axes and never allowed to eat the fold.
          //
          // Was 0.44 of the viewport (and up to 420pt), which on a normal phone
          // resolved to ~390pt: the hero owned nearly half the screen and
          // pushed the headline, the benefits and the plan selector below the
          // fold. The image sells the product, but it is not the product.
          //
          // There is also a floor: the hero has to fit the status-bar inset,
          // the chrome under it, two bands of label cards and the bottom fade.
          // Below that the cards get pushed into the fade or on top of the
          // food. Solving it for a 24% fade gives (inset + 172) / 0.76.
          final heroFloor = (media.padding.top + 172) / 0.76;
          final heroHeight = math
              .max(
                math.min(
                  viewport.maxHeight * 0.32,
                  viewport.maxWidth * 0.70,
                ),
                heroFloor,
              )
              .clamp(190.0, math.min(340.0, viewport.maxHeight * 0.46))
              .toDouble();
          _heroExtent = heroHeight;
          final dense = viewport.maxHeight < 720;
          final hPad = viewport.maxWidth < 360 ? 18.0 : 22.0;

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
                      (_dockHeight ?? (dense ? 236.0 : 252.0)) +
                      (_dockHeight == null ? media.padding.bottom : 0.0) +
                      16,
                ),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  _ScanHero(
                    height: heroHeight,
                    palette: palette,
                    topInset: media.padding.top,
                    onClose: () {
                      if (context.canPop()) context.pop();
                    },
                  ),
                  SizedBox(height: dense ? 18 : 26),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildTitleBlock(context, palette),
                  ),
                  SizedBox(height: dense ? 20 : 26),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _BenefitLedger(palette: palette),
                  ),
                  ..._buildTrialSection(context, palette, hPad, dense),
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
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CtaDock(
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
                  onRestore: _isLoading ? null : _handleRestore,
                  onTerms: () => _openUrl(_termsUrl),
                  onPrivacy: () => _openUrl(_privacyPolicyUrl),
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
    );
  }

  /// The headline, chosen by where the user came from.
  ///
  /// Same mapping as before: the promise on the screen has to match the door
  /// they walked through, or the purchase feels like a bait and switch.
  Widget _buildTitleBlock(BuildContext context, _Palette palette) {
    final l10n = AppLocalizations.of(context)!;
    String title;
    String subtitle;

    if (widget.featureName == 'barcode') {
      title = l10n.paywall_barcode_title;
      subtitle = l10n.paywall_barcode_subtitle;
    } else if (widget.limitReached) {
      title = l10n.paywall_free_scans_used_title;
      subtitle = l10n.paywall_unlimited_scanning_subtitle;
    } else if (widget.entryPoint == PaywallEntryPoint.scanLimit) {
      title = l10n.paywall_unlimited_scanning_title;
      subtitle = l10n.paywall_scan_track_subtitle;
    } else if (widget.entryPoint == PaywallEntryPoint.aiCoachLimit) {
      title = l10n.paywall_ai_coaching_title;
      subtitle = l10n.paywall_ai_coaching_subtitle;
    } else if (widget.entryPoint == PaywallEntryPoint.plannerLockedDay ||
        widget.entryPoint == PaywallEntryPoint.plannerPreferences) {
      title = l10n.paywall_smart_planning_title;
      subtitle = l10n.paywall_smart_planning_subtitle;
    } else if (widget.entryPoint == PaywallEntryPoint.groceryList) {
      title = l10n.paywall_shopping_lists_title;
      subtitle = l10n.paywall_shopping_lists_subtitle;
    } else if (widget.entryPoint == PaywallEntryPoint.progressPhotoLimit) {
      title = l10n.paywall_progress_journey_title;
      subtitle = l10n.paywall_progress_journey_subtitle;
    } else if (widget.entryPoint == PaywallEntryPoint.reportInsight ||
        widget.entryPoint == PaywallEntryPoint.macroDetails ||
        widget.entryPoint == PaywallEntryPoint.mealInsight) {
      title = l10n.paywall_analytics_title;
      subtitle = l10n.paywall_analytics_subtitle;
    } else if (widget.entryPoint == PaywallEntryPoint.adRemoval) {
      title = l10n.paywall_focused_title;
      subtitle = l10n.paywall_ad_removal_subtitle;
    } else {
      title = l10n.paywall_upgrade_experience_title;
      subtitle = l10n.paywall_upgrade_experience_subtitle;
    }

    return Column(
      children: [
        _Eyebrow(text: l10n.paywall_pro_plan, palette: palette),
        const SizedBox(height: 14),
        Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.ink,
                fontSize: 29,
                height: 1.12,
                letterSpacing: -0.7,
                fontWeight: FontWeight.w700,
              ),
            )
            .animate()
            .fadeIn(duration: 420.ms, delay: 60.ms)
            .slideY(begin: 0.18, end: 0, duration: 460.ms, curve: Curves.easeOut),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.muted,
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(duration: 420.ms, delay: 160.ms),
      ],
    );
  }

  /// The trial explainer, rendered only when the store actually offers one.
  List<Widget> _buildTrialSection(
    BuildContext context,
    _Palette palette,
    double hPad,
    bool dense,
  ) {
    final trial = _trialFor(_selectedPackage);
    if (trial == null) return const [];
    return [
      SizedBox(height: dense ? 20 : 26),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: _TrialSpine(days: trial.days, palette: palette),
      ),
    ];
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
            cadence: _billingCadence(_packages[i], l10n),
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
const double _chipHeight = 40;

/// Card width, as a share of the hero.
///
/// Fixed-width cards ate 37% of a small phone's hero from each side, leaving no
/// middle corridor: a dot anchored to the left of a plate landed underneath the
/// very card naming it. Scaling with the hero keeps that corridor open, and
/// every [_Detection.anchor] is kept inside it (|x| <= 0.26).
double _chipWidthFor(double heroWidth) =>
    (heroWidth * 0.32).clamp(108.0, 134.0);

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
const double _heroChromeTop = 8; // close button / readout offset below the inset
const double _closeButtonSize = 38;
const double _readoutHeight = 46;
const double _chromeGap = 10;

/// Radius of the marker ring dropped on the middle of each food.
const double _reticleRadius = 10.5;

/// Height of the hero's bottom dissolve. Shared so card placement and the
/// gradient cannot disagree about where the usable area ends.
double _heroFadeHeight(double heroHeight) => math.max(60, heroHeight * 0.24);

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
      _Detection(
        anchor: const Alignment(-0.22, 0.25),
        slots: const [_slotLeftLow, _slotLeftTop, _slotRightLow],
        label: (l) => l.paywall_slide_avocado,
        portion: (l) => l.paywall_slide_avocado_portion,
        kcal: 160,
      ),
    ],
  ),
  _HeroSlide(
    asset: 'assets/images/paywall/hero_slide_2.png',
    detections: [
      _Detection(
        anchor: const Alignment(0.21, -0.375),
        slots: const [_slotRightTop, _slotRightLow],
        label: (l) => l.paywall_slide_sweet_potato,
        portion: (l) => l.paywall_slide_sweet_potato_portion,
        kcal: 118,
      ),
      _Detection(
        anchor: const Alignment(-0.30, 0.09),
        slots: const [_slotLeftTop, _slotLeftLow],
        label: (l) => l.paywall_slide_salmon,
        portion: (l) => l.paywall_slide_salmon_portion,
        kcal: 312,
      ),
      _Detection(
        anchor: const Alignment(0.35, 0.23),
        slots: const [_slotRightLow, _slotLeftLow, _slotRightTop],
        label: (l) => l.paywall_slide_broccoli,
        portion: (l) => l.paywall_slide_broccoli_portion,
        kcal: 35,
      ),
    ],
  ),
  _HeroSlide(
    asset: 'assets/images/paywall/hero_slide_3.png',
    detections: [
      _Detection(
        anchor: const Alignment(-0.16, 0.00),
        slots: const [_slotLeftTop, _slotLeftLow],
        label: (l) => l.paywall_slide_toast,
        portion: (l) => l.paywall_slide_toast_portion,
        kcal: 290,
      ),
      _Detection(
        // The pair's centroid falls in the gap between the two eggs, which
        // points at the plate. Aim at the near egg's yolk instead.
        anchor: const Alignment(0.29, 0.21),
        slots: const [_slotRightTop, _slotRightLow],
        label: (l) => l.paywall_slide_boiled_eggs,
        portion: (l) => l.paywall_slide_eggs_portion,
        kcal: 155,
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
    final tx = dir.dx.abs() < 1e-6 ? double.infinity : (card.width / 2) / dir.dx.abs();
    final ty = dir.dy.abs() < 1e-6 ? double.infinity : (card.height / 2) / dir.dy.abs();
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
) {
  final drawn = math.max(size.width, size.height) * zoom;
  final centre = Offset(size.width / 2, size.height / 2);
  const margin = 12.0;
  final chipWidth = _chipWidthFor(size.width);

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
  final bandBottom = math.max(math.max(leftTop, rightTop) + _chipHeight + 8, lowest);

  Rect rectFor(_ChipSlot slot) => Rect.fromLTWH(
    slot.side == _ChipSide.left
        ? margin
        : math.max(margin, size.width - chipWidth - margin),
    (slot.row == 0
            ? (slot.side == _ChipSide.left ? leftTop : rightTop)
            : bandBottom)
        .clamp(margin, math.max(margin, size.height - _chipHeight - margin)),
    chipWidth,
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
      final rect = rectFor(slot);
      if (!usable(rect, i)) continue;
      taken.add(slot);
      pick = rect;
      break;
    }

    if (pick == null) {
      for (final slot in d.slots) {
        if (taken.contains(slot)) continue;
        final moved = nudged(rectFor(slot), i);
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

  late final AnimationController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted) return;
        setState(() => _index = (_index + 1) % _heroSlides.length);
        _controller.forward(from: 0);
      })
      ..forward();
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
    final slide = _heroSlides[_index];

    return ClipRect(
      // Explicit. The zoomed photograph was painting a sliver of itself past
      // the hero's bottom edge, showing up as a ~10dp band of un-faded image
      // below the fade -- the "little space" between the hero and the page.
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Hold the plate still for a beat, sweep, name the food, then leave.
          final entrance = _phase(t, 0.00, 0.07);
          final exit = 1 - _phase(t, 0.93, 1.00);
          final sweep = _phase(t, 0.12, 0.44);
          final opacity = entrance * exit;

          final zoom = _heroZoomFrom + (t * (_heroZoomTo - _heroZoomFrom));
          final geometry = _resolveDetections(
            slide.detections,
            Size(constraints.maxWidth, widget.height),
            zoom,
            widget.topInset,
            _heroFadeHeight(widget.height),
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

              // ── Dissolve into the page rather than cutting ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _heroFadeHeight(widget.height),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.paper.withValues(alpha: 0),
                          palette.paper.withValues(alpha: 0.72),
                          palette.paper,
                          palette.paper,
                        ],
                        // Solid well before the edge: the last stretch is
                        // flat paper, so the hero meets the page with nothing
                        // half-visible in between.
                        stops: const [0, 0.55, 0.88, 1],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Chrome ──
              PositionedDirectional(
                start: 12,
                top: widget.topInset + _heroChromeTop,
                child: _HeroIconButton(
                  icon: LucideIcons.x,
                  onTap: widget.onClose,
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonTooltip,
                ),
              ),
              // ── Which plate we are on ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _heroSlides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 16 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color:
                                i == _index
                                    ? AppColors.primary
                                    : palette.muted.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
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

/// A soft emerald band travelling down the plate, with a bright leading edge.
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
      final td =
          tangent.distance < 0.001
              ? dir
              : tangent / tangent.distance;
      final tn = Offset(-td.dy, td.dx);
      canvas.drawPath(
        Path()
          ..moveTo(edge.dx + td.dx * _caretLength, edge.dy + td.dy * _caretLength)
          ..lineTo(edge.dx + tn.dx * _caretHalfWidth, edge.dy + tn.dy * _caretHalfWidth)
          ..lineTo(edge.dx - tn.dx * _caretHalfWidth, edge.dy - tn.dy * _caretHalfWidth)
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

    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.92 + (0.08 * progress),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: width,
              height: _chipHeight,
              padding: const EdgeInsets.fromLTRB(9, 0, 10, 0),
              decoration: BoxDecoration(
                // A touch of vertical gradient so the card has a top edge
                // rather than reading as a flat grey rectangle.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.42),
                    Colors.black.withValues(alpha: 0.56),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accent rule rather than a dot: it gives the two lines a
                  // spine and ties the card to the marker's colour.
                  Container(
                    width: 3,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detection.label(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            height: 1.15,
                            letterSpacing: -0.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // The calories are the point of the label, so they are
                        // the only coloured thing on it.
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${detection.portion(l10n)}  ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.66),
                                  fontSize: 9.5,
                                  height: 1.1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: '${detection.kcal}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              TextSpan(
                                text: ' kcal',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.66),
                                  fontSize: 9,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }
}

/// The total, counting up as the plate is read.
class _CalorieReadout extends StatelessWidget {
  const _CalorieReadout({required this.kcal, required this.progress});

  final int kcal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final shown = (kcal * Curves.easeOutCubic.transform(progress)).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 15, 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
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
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, required this.palette});

  final String text;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: palette.accentWash,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: palette.accentInk,
          fontSize: 10.5,
          height: 1,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// What you get, as a ledger rather than a sales list: hairline rules, one
/// line each, the emerald tick doing all the affirming.
class _BenefitLedger extends StatelessWidget {
  const _BenefitLedger({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <String>[
      l10n.paywall_benefit_unlimited_scans,
      l10n.paywall_benefit_ai_guidance,
      l10n.paywall_benefit_smart_planner,
      l10n.paywall_benefit_weekly_reports,
      l10n.paywall_benefit_full_history,
      l10n.paywall_benefit_ad_free,
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Container(
              decoration: BoxDecoration(
                border:
                    i == items.length - 1
                        ? null
                        : Border(
                          bottom: BorderSide(
                            color: palette.hairline.withValues(alpha: 0.7),
                          ),
                        ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: palette.accentWash,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 13,
                      color: palette.accentInk,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              duration: 340.ms,
              delay: Duration(milliseconds: 220 + (i * 55)),
            ),
        ],
      ),
    );
  }
}

/// The three dates that matter, on one rail. Shown only when a real free
/// trial exists on the selected product.
class _TrialSpine extends StatelessWidget {
  const _TrialSpine({required this.days, required this.palette});

  final int days;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reminderDay = math.max(1, days - 2);

    final steps = <List<String>>[
      [l10n.paywall_trial_today, l10n.paywall_trial_today_desc],
      [
        l10n.paywall_trial_reminder(reminderDay),
        l10n.paywall_trial_reminder_desc,
      ],
      [l10n.paywall_trial_end(days), l10n.paywall_trial_end_desc],
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paywall_trial_title,
            style: TextStyle(
              color: palette.ink,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The rail: solid emerald while the trial is free, fading to
                  // a hairline at the point money changes hands.
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color:
                                i == steps.length - 1
                                    ? palette.surface
                                    : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  i == steps.length - 1
                                      ? palette.muted.withValues(alpha: 0.5)
                                      : AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        if (i != steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary,
                                    i == steps.length - 2
                                        ? palette.muted.withValues(alpha: 0.4)
                                        : AppColors.primary,
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i == steps.length - 1 ? 14 : 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i][0],
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 13.5,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            steps[i][1],
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.palette,
    required this.label,
    required this.price,
    required this.introPrice,
    required this.cadence,
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
  final String? cadence;
  final String? perMonth;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? palette.accentWash : palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : palette.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          padding: EdgeInsets.fromLTRB(15, 15, 15, selected ? 14 : 15),
          child: Row(
            children: [
              _Radio(selected: selected, palette: palette),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 15.5,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                height: 1,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (cadence != null || perMonth != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        perMonth ?? cadence!,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (introPrice != null)
                    Text(
                      price,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.2,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: palette.muted,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  Text(
                    introPrice ?? price,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 16,
                      height: 1.2,
                      letterSpacing: -0.3,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.palette});

  final bool selected;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : palette.muted.withValues(alpha: 0.5),
          width: 1.8,
        ),
      ),
      child:
          selected
              ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
              : null,
    );
  }
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

    return Column(
      children: [
        bar(),
        const SizedBox(height: 10),
        bar(),
      ],
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
      duration: 700.ms,
      begin: 0.45,
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
        color: AppColors.warning.withValues(alpha: palette.isDark ? 0.14 : 0.09),
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
              child: Icon(
                LucideIcons.refreshCw,
                size: 17,
                color: palette.accentInk,
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
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: palette.paper.withValues(alpha: 0.90),
            border: Border(top: BorderSide(color: palette.hairline)),
          ),
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, bottomInset + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PrimaryCta(
                label: _ctaLabel(l10n),
                busy: isLoading,
                enabled: !isLoading && !loadingOfferings,
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
                spacing: 9,
                runSpacing: 2,
                children: [
                  _FooterLink(
                    label: l10n.paywall_terms_conditions,
                    onTap: onTerms,
                    palette: palette,
                  ),
                  _FooterDot(palette: palette),
                  _FooterLink(
                    label: l10n.settings_privacy,
                    onTap: onPrivacy,
                    palette: palette,
                  ),
                  _FooterDot(palette: palette),
                  _FooterLink(
                    label: l10n.paywall_restore,
                    onTap: onRestore,
                    palette: palette,
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
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.32),
                    blurRadius: 22,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: -0.1,
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
  });

  final String label;
  final VoidCallback? onTap;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: palette.muted,
            fontSize: 11.5,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.5,
      height: 2.5,
      decoration: BoxDecoration(
        color: palette.muted.withValues(alpha: 0.5),
        shape: BoxShape.circle,
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
