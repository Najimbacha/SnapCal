import 'dart:math' as math;
import 'dart:io';
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
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/widgets/ui_blocks.dart';

class PaywallScreen extends StatefulWidget {
  final bool limitReached;

  const PaywallScreen({super.key, this.limitReached = false});

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
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.10),
                    colorScheme.surface,
                    colorScheme.surface,
                  ],
                  stops: const [0, 0.28, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final compact = viewport.maxHeight < 760;
                final tight = viewport.maxHeight < 700;
                final horizontalPadding = compact ? 20.0 : 24.0;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 2 : 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: Icon(
                                LucideIcons.x,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _handleRestore,
                              child: Text(
                                "Restore Purchase",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
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
                              const _FoodScanShowcase().animate().fadeIn().scale(
                                delay: 100.ms,
                                curve: Curves.easeOutBack,
                              ),
                              SizedBox(height: tight ? 8 : 12),
                              _BenefitGrid(compact: compact),
                              SizedBox(height: compact ? 8 : 10),
                              const _BenefitChipRow(),
                              SizedBox(height: compact ? 14 : 18),
                              _buildPricingRow(compact),
                              SizedBox(height: compact ? 8 : 12),
                            ],
                          ),
                        ),
                      ),
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
                );
              },
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
    final colorScheme = Theme.of(context).colorScheme;
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
    final colorScheme = Theme.of(context).colorScheme;
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

class _FoodScanShowcase extends StatefulWidget {
  const _FoodScanShowcase();

  @override
  State<_FoodScanShowcase> createState() => _FoodScanShowcaseState();
}

class _FoodScanShowcaseState extends State<_FoodScanShowcase> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // The Healthy Plate Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/paywall/showcase_plate.png',
                fit: BoxFit.cover,
              ),
            ),

            // Neural Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),

            // 1. Scanner Line
            const _ScannerLine(),

            // 2. Popping Calorie Labels (Timed to Scanner Position)
            const _CalorieBubble(
              top: 35,
              left: 100,
              label: "Avocado",
              calories: "140 kcal",
              delay: 400, // Top section
            ),
            const _CalorieBubble(
              top: 100,
              right: 40,
              label: "Quinoa",
              calories: "180 kcal",
              delay: 1400, // Middle section
            ),
            const _CalorieBubble(
              bottom: 45,
              left: 80,
              label: "Salmon",
              calories: "320 kcal",
              delay: 2400, // Bottom section
            ),
            
            // AI Vision Badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.scan, color: Colors.white, size: 12),
                    const SizedBox(width: 5),
                    const Text(
                      "AI VISION LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
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

class _ScannerLine extends StatelessWidget {
  const _ScannerLine();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      )
          .animate(onPlay: (controller) => controller.repeat())
          .moveY(
            begin: -200,
            end: 0,
            duration: 3.5.seconds,
            curve: Curves.easeInOut,
          ),
    );
  }
}

class _CalorieBubble extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final String label;
  final String calories;
  final int delay;

  const _CalorieBubble({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.label,
    required this.calories,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              calories,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 600.ms,
            delay: delay.ms,
            curve: Curves.easeOutBack,
          )
          .fadeOut(delay: (delay + 3000).ms, duration: 400.ms),
    );
  }
}
