import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:snapcal/core/theme/app_colors.dart';

import 'package:snapcal/core/theme/theme_colors.dart';
import 'package:snapcal/data/services/subscription_service.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/widgets/ui_blocks.dart';

const _minimalBg = Color(0xFFF9F8F5);
const _minimalDarkBg = Color(0xFF14130F);
const _minimalInk = Color(0xFF1C1917);
const _minimalLine = Color(0xFFE8E4DC);
const _minimalGreen = Color(0xFF1A3D2B);
const _minimalGreenText = Color(0xFF16733A);

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
  Package? _selectedPackage;
  List<Package> _packages = [];
  String? _purchaseNotice;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await SubscriptionService().getOfferings().timeout(
        const Duration(seconds: 8),
      );
      if (mounted &&
          offerings?.current != null &&
          offerings!.current!.availablePackages.isNotEmpty) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          try {
            _selectedPackage = _packages.firstWhere(
              (p) => p.packageType == PackageType.annual,
            );
          } catch (_) {
            _selectedPackage = _packages.isNotEmpty ? _packages.first : null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading offerings: $e");
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
      settings: ref.read(settingsProvider).valueOrNull ?? UserSettings.defaults(),
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
      settings: ref.read(settingsProvider).valueOrNull ?? UserSettings.defaults(),
      successMessage: l10n.premium_restore_success,
      isRestore: true,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleSubscriptionResult(
    SubscriptionResult result, {
    required ScaffoldMessengerState messenger,
    required UserSettings settings,
    required String successMessage,
    required bool isRestore,
  }) {
    switch (result.status) {
      case SubscriptionStatus.active:
        ref.invalidate(settingsProvider);
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bgColor = isDark ? _minimalDarkBg : _minimalBg;

    final ambientGradient =
        isDark
            ? const LinearGradient(
              colors: [Color(0xFF0B0E0C), Color(0xFF05120B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
            : const LinearGradient(
              colors: [Color(0xFFFFFDF9), Color(0xFFEAF5F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: ambientGradient),
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxHeight < 760;
            final tight = viewport.maxHeight < 700;
            final heroHeight = ((viewport.maxWidth + 22) * 0.90).clamp(
              216.0,
              379.0,
            );
            final hPad = compact ? 20.0 : 24.0;

            return Stack(
              children: [
                // ─── MAIN CONTENT ───
                Column(
                  children: [
                    // ─── HERO: Full-width food scanning carousel ───
                    SizedBox(
                      height: heroHeight,
                      child: Stack(
                        children: [
                          const Positioned.fill(child: _FoodScanShowcase()),
                          // Close button (top-left, over image)
                          Positioned(
                            top: topPadding + 8,
                            left: hPad,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.20,
                                        ),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.x,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Restore button (top-right, over image)
                          Positioned(
                            top: topPadding + 8,
                            right: hPad,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: GestureDetector(
                                  onTap: _handleRestore,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.20,
                                        ),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.paywall_restore,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── CONTENT below the hero ───
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: tight ? 4 : 8),
                                _buildContextualTitle(context, compact),
                                SizedBox(height: tight ? 6 : 10),
                                _buildCheckmarkBenefits(context, compact),
                                SizedBox(
                                  height: tight ? 12 : 16,
                                ), // Clears the plan badge
                                _buildPricingRow(context, compact),
                                const SizedBox(
                                  height: 4,
                                ), // Space before sticky footer
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ─── PINNED STICKY BOTTOM SECTION ───
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        6,
                        hPad,
                        math.max(6.0, bottomPadding),
                      ),
                      decoration: BoxDecoration(
                        color: bgColor.withValues(alpha: 0.96),
                        border: Border(
                          top: BorderSide(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : _minimalLine,
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LuxeButton(
                                  text:
                                      _selectedPackage?.packageType ==
                                              PackageType.annual
                                          ? AppLocalizations.of(
                                            context,
                                          )!.premium_start_trial
                                          : AppLocalizations.of(
                                            context,
                                          )!.paywall_unlock_snapcal_pro,
                                  isLoading: _isLoading,
                                  height: tight ? 48 : 52,
                                  onTap: _handlePurchase,
                                ).animate().fadeIn(
                                  delay: 100.ms,
                                  duration: 200.ms,
                                ),
                                if (_purchaseNotice != null) ...[
                                  const SizedBox(height: 8),
                                  _PurchaseNoticeBanner(
                                    message: _purchaseNotice!,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                // Cancel anytime
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.shieldCheck,
                                      size: 13,
                                      color: _minimalGreenText,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.paywall_cancel_anytime,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.72),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 2,
                                  children: [
                                    _FooterLink(
                                      label:
                                          AppLocalizations.of(
                                            context,
                                          )!.settings_privacy,
                                      onTap: () {},
                                    ),
                                    Text(
                                      "·",
                                      style: TextStyle(
                                        color: colorScheme.outlineVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    _FooterLink(
                                      label:
                                          AppLocalizations.of(
                                            context,
                                          )!.paywall_terms_conditions,
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContextualTitle(BuildContext context, bool compact) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : _minimalInk,
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckmarkBenefits(BuildContext context, bool compact) {
    final l10n = AppLocalizations.of(context)!;
    final benefits = [
      l10n.paywall_benefit_unlimited_scans,
      l10n.paywall_benefit_ai_guidance,
      l10n.paywall_benefit_full_history,
      l10n.paywall_benefit_weekly_reports,
      l10n.paywall_benefit_smart_planner,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: compact ? 10 : 14,
          children:
              benefits
                  .map(
                    (b) => SizedBox(
                      width: itemWidth,
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _minimalGreenText.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              LucideIcons.check,
                              size: 14,
                              color: _minimalGreenText,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: compact ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _buildPricingRow(BuildContext context, bool compact) {
    if (_packages.isEmpty) {
      return SizedBox(
        height: compact ? 108 : 122,
        child: const Center(
          child: CircularProgressIndicator(color: _minimalGreenText),
        ),
      );
    }

    Package packageFor(PackageType type, Package fallback) {
      return _packages.firstWhere(
        (p) => p.packageType == type,
        orElse: () => fallback,
      );
    }

    final monthly = packageFor(PackageType.monthly, _packages.first);
    final yearly = packageFor(PackageType.annual, _packages.last);
    Package? lifetime;
    for (final package in _packages) {
      if (package.packageType == PackageType.lifetime) {
        lifetime = package;
        break;
      }
    }

    String monthlyEquivalent(Package package) {
      try {
        final price = package.storeProduct.price;
        final priceString = package.storeProduct.priceString;
        final monthlyPrice = price / 12.0;

        final regExp = RegExp(r'[0-9.,\s]+');
        final symbol = priceString.replaceAll(regExp, '').trim();

        final formattedPrice = monthlyPrice.toStringAsFixed(2);
        if (priceString.trim().startsWith(symbol)) {
          return '$symbol$formattedPrice/mo';
        } else {
          return '$formattedPrice $symbol/mo';
        }
      } catch (e) {
        return '\$3.33/mo';
      }
    }

    final l10n = AppLocalizations.of(context)!;
    final options = <Widget>[
      Expanded(
        child: _PricingOption(
          package: monthly,
          isSelected: _selectedPackage == monthly,
          onTap: () => setState(() => _selectedPackage = monthly),
          label: l10n.premium_plan_monthly,
          subLabel: l10n.paywall_billing_monthly,
          compact: compact,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _PricingOption(
          package: yearly,
          isSelected: _selectedPackage == yearly,
          onTap: () => setState(() => _selectedPackage = yearly),
          label: l10n.premium_plan_yearly,
          subLabel: monthlyEquivalent(yearly),
          showBadge: true,
          compact: compact,
        ),
      ),
      if (lifetime != null) ...[
        const SizedBox(width: 10),
        Expanded(
          child: _PricingOption(
            package: lifetime,
            isSelected: _selectedPackage == lifetime,
            onTap: () => setState(() => _selectedPackage = lifetime),
            label: l10n.premium_plan_lifetime,
            subLabel: l10n.paywall_billing_lifetime,
            compact: compact,
          ),
        ),
      ],
    ];

    return Row(
      children: options,
    ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.08, end: 0);
  }
}

class _PricingOption extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final String subLabel;
  final bool showBadge;
  final bool compact;

  const _PricingOption({
    required this.package,
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.subLabel,
    required this.compact,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: compact ? 96 : 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: const Color(
                                0xFF2EE59D,
                              ).withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                          : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      if (isSelected) ...[
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1A3D2B), Color(0xFF2EE59D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark ? _minimalDarkBg : _minimalBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ] else ...[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.black.withValues(alpha: 0.01),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],

                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                label.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? _minimalGreenText
                                          : context.textSecondaryColor,
                                  fontSize: compact ? 10 : 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              SizedBox(height: compact ? 4 : 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  package.storeProduct.priceString,
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: compact ? 22 : 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 1 : 2),
                              Text(
                                subLabel,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? context.textSecondaryColor
                                          : context.textMutedColor,
                                  fontSize: compact ? 10 : 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showBadge)
              Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF165C38), Color(0xFF26B06E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF165C38,
                          ).withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.paywall_best_value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.015, 1.015),
          duration: 180.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

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

class _PurchaseNoticeBanner extends StatelessWidget {
  final String message;

  const _PurchaseNoticeBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.36 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxeButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onTap;
  final double height;

  const _LuxeButton({
    required this.text,
    required this.isLoading,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: isLoading ? () {} : onTap,
      child: Container(
            height: height,
            decoration: BoxDecoration(
              color: _minimalGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child:
                  isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .boxShadow(
            begin: const BoxShadow(
              color: Color(0x2A1A3D2B),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
            end: const BoxShadow(
              color: Color(0x661A3D2B),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
            duration: 1200.ms,
            curve: Curves.easeInOutSine,
          )
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.025, 1.025),
            duration: 1200.ms,
            curve: Curves.easeInOutSine,
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            delay: 2.seconds,
            duration: 1500.ms,
            color: Colors.white.withValues(alpha: 0.35),
          ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: context.textMutedColor,
          fontSize: 11,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _FoodDetectionLabel {
  final String name;
  final String portion;
  final String calories;
  final double foodX;
  final double foodY;
  final bool isLeftSide;
  final double labelY;

  const _FoodDetectionLabel({
    required this.name,
    required this.portion,
    required this.calories,
    required this.foodX,
    required this.foodY,
    required this.isLeftSide,
    required this.labelY,
  });
}

class _ScanSlideData {
  final String imagePath;
  final List<_FoodDetectionLabel> labels;

  const _ScanSlideData({required this.imagePath, required this.labels});
}

class _FoodScanShowcase extends StatefulWidget {
  const _FoodScanShowcase();

  @override
  State<_FoodScanShowcase> createState() => _FoodScanShowcaseState();
}

class _FoodScanShowcaseState extends State<_FoodScanShowcase>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _scanController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Vertical scanning sweep animation (2.8 seconds single sweep)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Show the clean image briefly before starting the scan overlay.
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _scanController.forward(from: 0.0);
      }
    });

    // Keep resolved scan labels readable before advancing.
    Future.delayed(const Duration(milliseconds: 7500), _autoPlayNextPage);
  }

  void _autoPlayNextPage() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % 3;
    _pageController
        .animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          if (mounted) {
            Future.delayed(
              const Duration(milliseconds: 7500),
              _autoPlayNextPage,
            );
          }
        });
  }

  List<_ScanSlideData> _getSlides(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _ScanSlideData(
        imagePath: 'assets/images/paywall/hero_slide_1.png',
        labels: [
          _FoodDetectionLabel(
            name: l10n.paywall_slide_grilled_chicken,
            portion: l10n.paywall_slide_chicken_portion,
            calories: "220 kcal",
            foodX: 0.35, // Exact middle of grilled chicken
            foodY: 0.35,
            isLeftSide: true,
            labelY: 0.28,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_rice,
            portion: l10n.paywall_slide_rice_portion,
            calories: "180 kcal",
            foodX: 0.65, // Exact middle of rice pile
            foodY: 0.35,
            isLeftSide: false,
            labelY: 0.28,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_avocado,
            portion: l10n.paywall_slide_avocado_portion,
            calories: "160 kcal",
            foodX: 0.35, // Exact middle of avocado
            foodY: 0.65,
            isLeftSide: true,
            labelY: 0.80,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_cherry_tomatoes,
            portion: l10n.paywall_slide_tomatoes_portion,
            calories: "30 kcal",
            foodX: 0.65, // Exact middle of cherry tomatoes
            foodY: 0.65,
            isLeftSide: false,
            labelY: 0.80,
          ),
        ],
      ),
      _ScanSlideData(
        imagePath: 'assets/images/paywall/hero_slide_2.png',
        labels: [
          _FoodDetectionLabel(
            name: l10n.paywall_slide_salmon,
            portion: l10n.paywall_slide_salmon_portion,
            calories: "320 kcal",
            foodX: 0.35, // Exact middle of salmon fillet
            foodY: 0.50,
            isLeftSide: true,
            labelY: 0.40,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_sweet_potato,
            portion: l10n.paywall_slide_sweet_potato_portion,
            calories: "153 kcal",
            foodX: 0.65, // Exact middle of sweet potatoes pile
            foodY: 0.35,
            isLeftSide: false,
            labelY: 0.28,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_broccoli,
            portion: l10n.paywall_slide_broccoli_portion,
            calories: "40 kcal",
            foodX: 0.65, // Exact middle of broccoli bouquet
            foodY: 0.65,
            isLeftSide: false,
            labelY: 0.80,
          ),
        ],
      ),
      _ScanSlideData(
        imagePath: 'assets/images/paywall/hero_slide_3.png',
        labels: [
          _FoodDetectionLabel(
            name: l10n.paywall_slide_toast,
            portion: l10n.paywall_slide_toast_portion,
            calories: "150 kcal",
            foodX: 0.35, // Exact middle of toast
            foodY: 0.50,
            isLeftSide: true,
            labelY: 0.45,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_boiled_eggs,
            portion: l10n.paywall_slide_eggs_portion,
            calories: "140 kcal",
            foodX: 0.65, // Exact middle of boiled eggs
            foodY: 0.50,
            isLeftSide: false,
            labelY: 0.45,
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);

    return ClipRect(
      child: Stack(
        children: [
          // PageView sliding carousel wrapped in ShaderMask, leaving 22px gap at the bottom
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 14,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _scanController.reset();

                setState(() {
                  _currentPage = index;
                });
                // Delay scanner sweep for a full 1.0 second to show the clean image first
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (mounted && _currentPage == index) {
                    _scanController.forward(from: 0.0);
                  }
                });
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        slide.imagePath,
                        fit: BoxFit.cover,
                        cacheWidth: 750,
                        alignment: const Alignment(0, -0.35),
                      ),
                    ),

                    _ScannerLine(controller: _scanController),

                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              for (final label in slide.labels)
                                AnimatedBuilder(
                                  animation: _scanController,
                                  builder: (context, child) {
                                    final val = _scanController.value;

                                    // 1. Calculate active laser sweep Y position (occurs during first 60% of duration)
                                    final laserYFraction = (val / 0.60).clamp(
                                      0.0,
                                      1.0,
                                    );

                                    // 2. Target dot is detected as soon as the sweeping laser crosses its coordinate
                                    final isDetected =
                                        laserYFraction >= label.foodY;
                                    final dotOpacity = isDetected ? 1.0 : 0.0;

                                    // 3. Connector lines & card reveals start ONLY after the sweep completes (val >= 0.60)
                                    double progress = 0.0;
                                    bool isScanning = true;

                                    if (val >= 0.60) {
                                      // Curve grows from 0.60 to 0.78 progress (about 500ms)
                                      progress = ((val - 0.60) / 0.18).clamp(
                                        0.0,
                                        1.0,
                                      );

                                      // Resolves from SCANNING to final stats once progress reaches 0.82 (another 110ms)
                                      if (val >= 0.82) {
                                        isScanning = false;
                                      }
                                    }

                                    return Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _ConnectorPainter(
                                              end: Offset(
                                                label.foodX *
                                                    constraints.maxWidth,
                                                label.foodY *
                                                    constraints.maxHeight,
                                              ),
                                              progress: progress,
                                              isLeftSide: label.isLeftSide,
                                              labelY:
                                                  label.labelY *
                                                  constraints.maxHeight,
                                              startX:
                                                  label.isLeftSide
                                                      ? 94.0
                                                      : constraints.maxWidth -
                                                          94.0,
                                              dotOpacity: dotOpacity,
                                              scanValue: val,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: label.isLeftSide ? 16.0 : null,
                                          right:
                                              !label.isLeftSide ? 16.0 : null,
                                          top:
                                              label.labelY *
                                                  constraints.maxHeight -
                                              20.0,
                                          child: Opacity(
                                            opacity: progress,
                                            child: _GlassCalorieLabel(
                                              name: label.name,
                                              portion: label.portion,
                                              calories: label.calories,
                                              isScanning: isScanning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Dots (rendered outside ShaderMask to prevent fading, placed at bottom: 2)
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentPage == index
                            ? const Color(0xFF2EE59D)
                            : Colors.white.withValues(alpha: 0.35),
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

class _ScannerLine extends StatelessWidget {
  final Animation<double> controller;

  const _ScannerLine({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final val = controller.value;
        final progress = Curves.easeInOutCubic.transform(
          (val / 0.68).clamp(0.0, 1.0),
        );

        double opacity = 0.0;
        if (val > 0.02 && val < 0.68) {
          opacity = 0.92;
        } else if (val >= 0.68 && val <= 0.78) {
          opacity = ((0.78 - val) / 0.10).clamp(0.0, 1.0) * 0.92;
        }

        return Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: _AIFocusScanPainter(progress: progress, phase: val),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _AIFocusScanPainter extends CustomPainter {
  final double progress;
  final double phase;

  const _AIFocusScanPainter({required this.progress, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.52),
      width: size.width * 0.76,
      height: size.height * 0.62,
    );
    final radius = Radius.circular(math.min(34, rect.width * 0.12));
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final pulse = 0.72 + math.sin(phase * math.pi * 2.0).abs() * 0.18;

    canvas.save();
    canvas.clipRRect(rrect);

    final scanY = rect.top + rect.height * progress;
    final bandRect = Rect.fromLTRB(
      rect.left,
      scanY - 28,
      rect.right,
      scanY + 28,
    );
    final bandPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.08),
              AppColors.sky.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.30, 0.50, 0.70, 1.0],
          ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);

    final linePaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.68),
              AppColors.sky.withValues(alpha: 0.56),
              Colors.white.withValues(alpha: 0.68),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTRB(rect.left, scanY, rect.right, scanY + 1))
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.left + 18, scanY),
      Offset(rect.right - 18, scanY),
      linePaint,
    );

    canvas.restore();

    final fillPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.12 * pulse);
    canvas.drawRRect(rrect, fillPaint);

    final shadowPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    _drawCorners(canvas, rect, radius.x, shadowPaint);

    final cornerPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.76 * pulse);
    _drawCorners(canvas, rect, radius.x, cornerPaint);

    final accentPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.sky.withValues(alpha: 0.34 * pulse);
    _drawCorners(canvas, rect.deflate(3), radius.x - 3, accentPaint);
  }

  void _drawCorners(Canvas canvas, Rect rect, double radius, Paint paint) {
    final length = math.min(34.0, rect.shortestSide * 0.18);
    final inset = radius * 0.45;

    canvas.drawLine(
      Offset(rect.left + inset, rect.top),
      Offset(rect.left + inset + length, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + inset),
      Offset(rect.left, rect.top + inset + length),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - inset, rect.top),
      Offset(rect.right - inset - length, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + inset),
      Offset(rect.right, rect.top + inset + length),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + inset, rect.bottom),
      Offset(rect.left + inset + length, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - inset),
      Offset(rect.left, rect.bottom - inset - length),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - inset, rect.bottom),
      Offset(rect.right - inset - length, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - inset),
      Offset(rect.right, rect.bottom - inset - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AIFocusScanPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}

class _ConnectorPainter extends CustomPainter {
  final Offset end;
  final double progress;
  final bool isLeftSide;
  final double labelY;
  final double startX;
  final double dotOpacity;
  final double scanValue;

  _ConnectorPainter({
    required this.end,
    required this.progress,
    required this.isLeftSide,
    required this.labelY,
    required this.startX,
    required this.dotOpacity,
    required this.scanValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pulse animation factor based on the current scanning time (5 cycles)
    final pulseFactor = math.sin(scanValue * math.pi * 5.0).abs();

    // 1. Draw circular scan marker at food point if detected
    if (dotOpacity > 0.0) {
      final pulseRadius = 7.0 + (pulseFactor * 4.5);
      final pulseOpacity = (0.2 + (1.0 - pulseFactor) * 0.45) * dotOpacity;

      // A. Outer soft sky blue halo/glow (grows with pulse)
      final haloPaint =
          Paint()
            ..color = AppColors.sky.withValues(alpha: 0.25 * pulseOpacity)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(end, pulseRadius + 6.0, haloPaint);

      // B. Fine outer pulsing ring (expands and fades)
      final outerRingPaint =
          Paint()
            ..color = AppColors.sky.withValues(alpha: 0.95 * pulseOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
      canvas.drawCircle(end, pulseRadius, outerRingPaint);

      // C. Solid sky blue core
      final corePaint =
          Paint()
            ..color = AppColors.sky.withValues(alpha: 1.0 * dotOpacity)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 3.5, corePaint);

      // D. Inner center dot (Brilliant White)
      final centerPaint =
          Paint()
            ..color = Colors.white.withValues(alpha: 1.0 * dotOpacity)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 1.5, centerPaint);
    }

    // 2. Draw connector line if reveal progress has started
    if (progress <= 0.0) return;

    final start = Offset(startX, labelY);

    // Soft dark drop shadow to ensure visibility on bright white/marble backgrounds
    final shadowPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25 * progress)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Clean, elegant white foreground line
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * progress)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(
      end.dx,
      end.dy,
    ); // Start exactly from the middle of the food (end point)

    // Clean, crisp straight line from the food dot to the label
    path.lineTo(start.dx, start.dy);

    // Animate both paths growing outward
    for (final metric in path.computeMetrics()) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, shadowPaint);
      canvas.drawPath(extractPath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.end != end ||
        oldDelegate.labelY != labelY ||
        oldDelegate.startX != startX ||
        oldDelegate.dotOpacity != dotOpacity ||
        oldDelegate.scanValue != scanValue;
  }
}

class _GlassCalorieLabel extends StatelessWidget {
  final String name;
  final String portion;
  final String calories;
  final bool isScanning;

  const _GlassCalorieLabel({
    required this.name,
    required this.portion,
    required this.calories,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      constraints: const BoxConstraints(minWidth: 124, maxWidth: 156),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isScanning
                  ? AppColors.sky.withValues(alpha: 0.62)
                  : AppColors.sky.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 11.0,
              vertical: 8.5,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _buildLoadedState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState() {
    return TweenAnimationBuilder<double>(
      key: ValueKey("loaded-$name-$calories"),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final calorieReveal = ((value - 0.35) / 0.65).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: math.max(0.04, value),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: calorieReveal,
              child: Transform.translate(
                offset: Offset(0, 4 * (1 - calorieReveal)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFF9F0A).withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.flame,
                        size: 11,
                        color: Color(0xFFFF8A00),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        calories,
                        style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          portion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(
                              0xFF1C1C1E,
                            ).withValues(alpha: 0.62),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

