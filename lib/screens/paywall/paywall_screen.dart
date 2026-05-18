import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/theme_colors.dart';
import 'package:snapcal/data/services/subscription_service.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/widgets/ui_blocks.dart';

class PaywallScreen extends StatefulWidget {
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
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  Package? _selectedPackage;
  List<Package> _packages = [];

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
    if (_isLoading || _selectedPackage == null) return;
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final subService = SubscriptionService();
    final l10n = AppLocalizations.of(context)!;

    try {
      final success = await subService
          .purchasePackage(_selectedPackage!)
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      if (success) {
        settingsProvider.refresh();
        router.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premium_welcome),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(messenger, l10n.paywall_purchase_failed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final subService = SubscriptionService();
    final l10n = AppLocalizations.of(context)!;

    try {
      final success = await subService.restorePurchases().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;

      if (success) {
        settingsProvider.refresh();
        context.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premium_restore_success),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      } else {
        _showErrorSnackBar(messenger, l10n.premium_restore_empty);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(messenger, l10n.premium_restore_fail);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(ScaffoldMessengerState messenger, String error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxHeight < 760;
            final tight = viewport.maxHeight < 700;
            final horizontalPadding = compact ? 20.0 : 24.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 0, left: horizontalPadding - 8, right: horizontalPadding - 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        icon: Icon(
                          LucideIcons.x,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      TextButton(
                        onPressed: _handleRestore,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Restore Purchase",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: tight ? 4 : 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: _buildContextualBanner(context, compact),
                            ).animate().fadeIn(delay: 50.ms),
                            
                            // Clean edge-to-edge full-width scanning showcase!
                            const _FoodScanShowcase().animate().fadeIn(delay: 100.ms),
                            
                            SizedBox(height: tight ? 8 : 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _BenefitGrid(compact: compact),
                                  SizedBox(height: compact ? 8 : 10),
                                  const _BenefitChipRow(),
                                  SizedBox(height: compact ? 14 : 18),
                                  _buildPricingRow(compact),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 8 : 12),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: tight ? 10 : 14),
                          _LuxeButton(
                            text:
                                _selectedPackage?.packageType == PackageType.annual
                                    ? "Start 7-day free trial"
                                    : "Unlock Pro",
                            isLoading: _isLoading,
                            height: tight ? 52 : 58,
                            onTap: _handlePurchase,
                          ).animate().fadeIn(delay: 360.ms),
                          SizedBox(height: tight ? 8 : 10),
                          Text(
                            "Cancel anytime.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: tight ? 5 : 7),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FooterLink(label: "Privacy Policy", onTap: () {}),
                              Text(
                                "  |  ",
                                style: TextStyle(color: colorScheme.outlineVariant),
                              ),
                              _FooterLink(
                                label: "Terms & Conditions",
                                onTap: () {},
                              ),
                            ],
                          ),
                          SizedBox(
                            height: math.max(tight ? 6.0 : 10.0, bottomPadding),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }

  Widget _buildContextualBanner(BuildContext context, bool compact) {
    final colorScheme = Theme.of(context).colorScheme;
    String? badgeText;
    String? titleText;
    String? descText;
    IconData? icon;

    if (widget.limitReached || widget.entryPoint == PaywallEntryPoint.scanLimit) {
      badgeText = "LIMIT REACHED";
      titleText = "You used 3/3 free scans today";
      descText = "Upgrade to Pro for unlimited food scans and premium insights.";
      icon = LucideIcons.scan;
    } else if (widget.entryPoint == PaywallEntryPoint.aiCoachLimit) {
      badgeText = "AI COACH";
      titleText = "Unlock unlimited coaching";
      descText = "Get 24/7 personal nutrition guidance, meal reviews, and expert advice.";
      icon = LucideIcons.sparkles;
    } else if (widget.entryPoint == PaywallEntryPoint.plannerLockedDay || widget.entryPoint == PaywallEntryPoint.plannerPreferences) {
      badgeText = "PLANNER PRO";
      titleText = "Unlock smart meal planning";
      descText = "Get customized daily meal plans tailored to your macro goals.";
      icon = LucideIcons.calendarRange;
    } else if (widget.entryPoint == PaywallEntryPoint.groceryList) {
      badgeText = "GROCERY LIST";
      titleText = "Auto-generated shopping lists";
      descText = "Save time with automatic consolidated grocery shopping list aggregation.";
      icon = LucideIcons.shoppingBag;
    } else if (widget.entryPoint == PaywallEntryPoint.progressPhotoLimit) {
      badgeText = "PROGRESS TRACKER";
      titleText = "Visual progress journey";
      descText = "Track side-by-side visual body transformation photo logs.";
      icon = LucideIcons.camera;
    } else if (widget.entryPoint == PaywallEntryPoint.reportInsight || widget.entryPoint == PaywallEntryPoint.mealInsight) {
      badgeText = "ELITE INSIGHTS";
      titleText = "Deep metabolic analytics";
      descText = "Unlock personalized biological trends, macronutrient ratios, and logs.";
      icon = LucideIcons.trendingUp;
    } else if (widget.entryPoint == PaywallEntryPoint.adRemoval) {
      badgeText = "AD FREE";
      titleText = "100% focused experience";
      descText = "Remove all interruptions and track meals in a pure fluid environment.";
      icon = LucideIcons.shieldCheck;
    }

    if (badgeText == null || titleText == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2EE59D).withValues(alpha: 0.08),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF2EE59D).withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2EE59D).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF2EE59D), size: compact ? 18 : 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EE59D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titleText,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  descText ?? "",
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(bool compact) {
    if (_packages.isEmpty) {
      return SizedBox(
        height: compact ? 108 : 122,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
    final options = <Widget>[
      Expanded(
        child: _PricingOption(
          package: monthly,
          isSelected: _selectedPackage == monthly,
          onTap: () => setState(() => _selectedPackage = monthly),
          label: "Monthly",
          subLabel: "\$9.99 target",
          compact: compact,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _PricingOption(
          package: yearly,
          isSelected: _selectedPackage == yearly,
          onTap: () => setState(() => _selectedPackage = yearly),
          label: "Yearly",
          subLabel: "7-day trial",
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
            label: "Lifetime",
            subLabel: "\$149.99 target",
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

class _BenefitGrid extends StatelessWidget {
  final bool compact;

  const _BenefitGrid({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BenefitCard(
                icon: LucideIcons.scanLine,
                title: "Unlimited scans",
                body: "No 3/day limit",
                compact: compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BenefitCard(
                icon: LucideIcons.sparkles,
                title: "AI guidance",
                body: "Next best meal",
                compact: compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BenefitCard(
                icon: LucideIcons.calendarDays,
                title: "Full history",
                body: "Beyond 14 days",
                compact: compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BenefitCard(
                icon: LucideIcons.fileText,
                title: "Reports",
                body: "Weekly + export",
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool compact;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: compact ? 12 : 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  body,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w500,
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

class _BenefitChipRow extends StatelessWidget {
  const _BenefitChipRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BenefitPill(label: "Smart reminders"),
        _BenefitPill(label: "Recipe analysis"),
        _BenefitPill(label: "Saved meals"),
      ],
    );
  }
}

class _BenefitPill extends StatelessWidget {
  final String label;
  const _BenefitPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.textSecondaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: compact ? 116 : 132,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Base Background
                  Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isDark ? const Color(0xFF252525) : Colors.white)
                          : context.cardColor,
                    ),
                  ),
                  
                  // Selected State: Gradient Border + Shimmer
                  if (isSelected) ...[
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent, width: 2),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              const Color(0xFF8B5CF6),
                            ],
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    // Content "Shield" to create the border effect
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252525) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Normal State Border
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: context.cardBorderColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Text Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.textSecondaryColor,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              package.storeProduct.priceString,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: compact ? 22 : 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 4),
                          Text(
                            subLabel,
                            style: TextStyle(
                              color: isSelected 
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
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "BEST VALUE",
                  style: TextStyle(
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
        .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 200.ms);
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
          gradient: AppColors.premiumGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      delay: 2.seconds,
                      duration: 1500.ms,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
              ),
            Center(
              child: isLoading
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
          ],
        ),
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

  const _ScanSlideData({
    required this.imagePath,
    required this.labels,
  });
}

class _FoodScanShowcase extends StatefulWidget {
  const _FoodScanShowcase();

  @override
  State<_FoodScanShowcase> createState() => _FoodScanShowcaseState();
}

class _FoodScanShowcaseState extends State<_FoodScanShowcase> with TickerProviderStateMixin {
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

    // Initial sweep run with a gorgeous 1.0 second delay to show the clean slide first
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _scanController.forward(from: 0.0);
      }
    });

    // Auto-advance slides every 5.5 seconds
    Future.delayed(const Duration(milliseconds: 5500), _autoPlayNextPage);
  }

  void _autoPlayNextPage() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % 3;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 5500), _autoPlayNextPage);
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
            foodX: 0.36, // Exact middle of grilled chicken
            foodY: 0.38,
            isLeftSide: true,
            labelY: 0.18,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_rice,
            portion: l10n.paywall_slide_rice_portion,
            calories: "180 kcal",
            foodX: 0.63, // Slightly more right and higher up inside rice pile
            foodY: 0.30,
            isLeftSide: false,
            labelY: 0.20,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_avocado,
            portion: l10n.paywall_slide_avocado_portion,
            calories: "160 kcal",
            foodX: 0.36, // Exact middle of avocado
            foodY: 0.70,
            isLeftSide: true,
            labelY: 0.80,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_cherry_tomatoes,
            portion: l10n.paywall_slide_tomatoes_portion,
            calories: "30 kcal",
            foodX: 0.64, // Exact middle of cherry tomatoes
            foodY: 0.68,
            isLeftSide: false,
            labelY: 0.82,
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
            foodX: 0.36, // Exact middle of salmon fillet
            foodY: 0.50,
            isLeftSide: true,
            labelY: 0.35,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_sweet_potato,
            portion: l10n.paywall_slide_sweet_potato_portion,
            calories: "153 kcal",
            foodX: 0.46, // Exact middle of sweet potatoes pile
            foodY: 0.36,
            isLeftSide: false,
            labelY: 0.16,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_broccoli,
            portion: l10n.paywall_slide_broccoli_portion,
            calories: "40 kcal",
            foodX: 0.66, // Exact middle of broccoli bouquet
            foodY: 0.44,
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
            foodX: 0.36, // Exact middle of toast
            foodY: 0.50,
            isLeftSide: true,
            labelY: 0.45,
          ),
          _FoodDetectionLabel(
            name: l10n.paywall_slide_boiled_eggs,
            portion: l10n.paywall_slide_eggs_portion,
            calories: "140 kcal",
            foodX: 0.64, // Exact middle of boiled eggs
            foodY: 0.50,
            isLeftSide: false,
            labelY: 0.48,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slides = _getSlides(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Stack(
          children: [
            // PageView sliding carousel
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Immediately reset the scanner animation controller so all labels, 
                // dots, and laser lines are completely hidden during the clean-image phase!
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
                    // A. Plate image
                    Positioned.fill(
                      child: Image.asset(
                        slide.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // B. Dark gradient overlay for modern depth
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // C. Scanning sweep line
                    _ScannerLine(controller: _scanController),

                    // D. Symmetrically-positioned glass chips and orthogonal curves
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
                                    final laserYFraction = (val / 0.60).clamp(0.0, 1.0);
                                    
                                    // 2. Target dot is detected as soon as the sweeping laser crosses its coordinate
                                    final isDetected = laserYFraction >= label.foodY;
                                    final dotOpacity = isDetected ? 1.0 : 0.0;
                                    
                                    // 3. Connector lines & card reveals start ONLY after the sweep completes (val >= 0.60)
                                    double progress = 0.0;
                                    bool isScanning = true;
                                    
                                    if (val >= 0.60) {
                                      // Curve grows from 0.60 to 0.78 progress (about 500ms)
                                      progress = ((val - 0.60) / 0.18).clamp(0.0, 1.0);
                                      
                                      // Resolves from SCANNING to final stats once progress reaches 0.82 (another 110ms)
                                      if (val >= 0.82) {
                                        isScanning = false;
                                      }
                                    }

                                    return Stack(
                                      children: [
                                        // 1. Beautiful Bezier curve spline connector
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _ConnectorPainter(
                                              end: Offset(label.foodX * constraints.maxWidth, label.foodY * constraints.maxHeight),
                                              progress: progress,
                                              isLeftSide: label.isLeftSide,
                                              labelY: label.labelY * constraints.maxHeight,
                                              startX: label.isLeftSide ? 94.0 : constraints.maxWidth - 94.0,
                                              dotOpacity: dotOpacity,
                                            ),
                                          ),
                                        ),
                                        // 2. Beautiful white glass chip
                                        Positioned(
                                          left: label.isLeftSide ? 8.0 : null,
                                          right: !label.isLeftSide ? 8.0 : null,
                                          top: label.labelY * constraints.maxHeight - 20.0,
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



            // Pagination dots indicator
            Positioned(
              bottom: 12,
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
                      color: _currentPage == index
                          ? const Color(0xFF2EE59D)
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        // The laser sweep takes the first 60% of the animation duration
        final laserYFraction = (val / 0.60).clamp(0.0, 1.0);
        
        // Smoothly fade out laser once sweep is finished (between 0.60 and 0.68)
        double opacity = 0.0;
        if (val > 0.01 && val < 0.60) {
          opacity = 1.0;
        } else if (val >= 0.60 && val <= 0.68) {
          opacity = ((0.68 - val) / 0.08).clamp(0.0, 1.0);
        }

        return Opacity(
          opacity: opacity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final yPos = laserYFraction * constraints.maxHeight;
              return Stack(
                children: [
                  // Laser green sweep glow trail
                  Positioned(
                    top: yPos - 60.0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF2EE59D).withValues(alpha: 0.28),
                            const Color(0xFF2EE59D).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Laser sweep horizontal bar line
                  Positioned(
                    top: yPos,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EE59D),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2EE59D).withValues(alpha: 0.75),
                            blurRadius: 10,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Offset end;
  final double progress;
  final bool isLeftSide;
  final double labelY;
  final double startX;
  final double dotOpacity;

  _ConnectorPainter({
    required this.end,
    required this.progress,
    required this.isLeftSide,
    required this.labelY,
    required this.startX,
    required this.dotOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw circular scan marker at food point if detected
    if (dotOpacity > 0.0) {
      // A. Outer soft neon halo/glow (radius 11.0)
      final haloPaint = Paint()
        ..color = const Color(0xFF2EE59D).withValues(alpha: 0.22 * dotOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 11.0, haloPaint);

      // B. Fine outer scanning ring (radius 6.5)
      final outerRingPaint = Paint()
        ..color = const Color(0xFF2EE59D).withValues(alpha: 0.90 * dotOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(end, 6.5, outerRingPaint);

      // C. Solid mint green core (radius 3.2)
      final corePaint = Paint()
        ..color = const Color(0xFF2EE59D).withValues(alpha: 1.00 * dotOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 3.2, corePaint);

      // D. Brilliant white focal center dot (radius 1.2)
      final centerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 1.00 * dotOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 1.2, centerPaint);
    }

    // 2. Draw connector line if reveal progress has started
    if (progress <= 0.0) return;

    final start = Offset(startX, labelY);

    // Neon green glowing background trail for ultra-visibility on dark backgrounds
    final glowPaint = Paint()
      ..color = const Color(0xFF2EE59D).withValues(alpha: 0.35 * progress)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Crisp neon green foreground line
    final linePaint = Paint()
      ..color = const Color(0xFF2EE59D).withValues(alpha: 1.00 * progress)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(end.dx, end.dy); // Start exactly from the middle of the food (end point)

    // Smooth Bezier spline path that curves gracefully from the center food dot (end) to the label (start)
    final controlX = end.dx + (start.dx - end.dx) * 0.45;
    final controlY = end.dy + (start.dy - end.dy) * 0.90;

    path.quadraticBezierTo(controlX, controlY, start.dx, start.dy);

    // Animate both paths growing outward
    for (final metric in path.computeMetrics()) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.end != end ||
        oldDelegate.labelY != labelY ||
        oldDelegate.startX != startX ||
        oldDelegate.dotOpacity != dotOpacity;
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 86,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isScanning
                  ? const Color(0xFF2EE59D).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.40),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: isScanning
                    ? const Color(0xFF2EE59D).withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isScanning) ...[
                Row(
                  children: [
                    const Text(
                      "SCANNING",
                      style: TextStyle(
                        color: Color(0xFF2EE59D),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 6,
                      height: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 0.8,
                        color: const Color(0xFF2EE59D),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF2EE59D).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  "··· · ··· kcal",
                  style: TextStyle(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.3),
                    fontSize: 7.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1.5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      portion,
                      style: TextStyle(
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.50),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    const Text(
                      "·",
                      style: TextStyle(
                        color: Color(0xFF34C759),
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      calories,
                      style: const TextStyle(
                        color: Color(0xFF34C759),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
