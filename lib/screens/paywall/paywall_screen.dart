import 'dart:math' as math;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: tight ? 2 : 6),
                            _ProHero(
                              compact: compact,
                              limitReached: widget.limitReached,
                            ).animate().fadeIn().scale(
                              delay: 120.ms,
                              curve: Curves.easeOutBack,
                            ),
                            SizedBox(height: compact ? 10 : 14),
                            _BenefitGrid(compact: compact),
                            SizedBox(height: compact ? 8 : 12),
                            const _BenefitChipRow(),
                            const Spacer(),
                            _buildPricingRow(compact),
                          ],
                        ),
                      ),
                      SizedBox(height: tight ? 10 : 14),
                      _LuxeButton(
                        text: "Subscribe",
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

    return Row(
      children: [
        Expanded(
          child: _PricingOption(
            package: _packages.firstWhere(
              (p) => p.packageType == PackageType.monthly,
              orElse: () => _packages.first,
            ),
            isSelected: _selectedPackage?.packageType == PackageType.monthly,
            onTap:
                () => setState(
                  () =>
                      _selectedPackage = _packages.firstWhere(
                        (p) => p.packageType == PackageType.monthly,
                      ),
                ),
            label: "Monthly",
            subLabel: "Flexible plan",
            compact: compact,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _PricingOption(
            package: _packages.firstWhere(
              (p) => p.packageType == PackageType.annual,
              orElse: () => _packages.last,
            ),
            isSelected: _selectedPackage?.packageType == PackageType.annual,
            onTap:
                () => setState(
                  () =>
                      _selectedPackage = _packages.firstWhere(
                        (p) => p.packageType == PackageType.annual,
                      ),
                ),
            label: "Yearly",
            subLabel: "Best value",
            showBadge: true,
            compact: compact,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.08, end: 0);
  }
}

class _ProHero extends StatelessWidget {
  final bool compact;
  final bool limitReached;

  const _ProHero({required this.compact, required this.limitReached});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: context.cardColor,
        border: Border.all(color: context.cardBorderColor),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 10,
                  vertical: compact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "SnapCal Pro",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (limitReached) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You used today's free scans.",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            "Eat smarter every day.",
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: compact ? 23 : 27,
              fontWeight: FontWeight.w900,
              height: 1.04,
            ),
          ),
          SizedBox(height: compact ? 5 : 6),
          Text(
            "Unlimited scans, AI coaching, smart planning, and no ads.",
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
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
                title: "AI Coach",
                body: "Food advice",
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
                title: "Smart planner",
                body: "Week + grocery",
                compact: compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BenefitCard(
                icon: LucideIcons.badgeX,
                title: "No ads",
                body: "Zero interrupts",
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

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 16),
          ),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
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
        _BenefitPill(label: "Progress photos"),
        _BenefitPill(label: "Meal routines"),
        _BenefitPill(label: "Grocery list"),
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: compact ? 108 : 124,
            padding: EdgeInsets.symmetric(
              vertical: compact ? 10 : 14,
              horizontal: compact ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? colorScheme.primary : context.cardBorderColor,
                width: 2,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? colorScheme.onPrimaryContainer
                            : context.textSecondaryColor,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 4 : 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    package.storeProduct.priceString,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: compact ? 22 : 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  subLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0D9BD8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Save 80%",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
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
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF0D9BD8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
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
