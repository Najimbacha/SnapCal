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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxHeight < 760;
          final tight = viewport.maxHeight < 700;
          final heroHeight = (viewport.maxWidth + 22).clamp(240.0, 420.0);
          final hPad = compact ? 20.0 : 24.0;

          return Stack(
            children: [
              // ─── AMBIENT COLOR BLOBS (Premium mesh gradient effect) ───
              Positioned(
                top: heroHeight - 50,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.12),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(end: 1.3, duration: 4.seconds, curve: Curves.easeInOutSine),
              ),
              Positioned(
                bottom: -80,
                right: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.violet.withValues(alpha: isDark ? 0.45 : 0.12),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(end: 1.4, duration: 5.seconds, curve: Curves.easeInOutSine),
              ),
              Positioned(
                bottom: 200,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sky.withValues(alpha: isDark ? 0.40 : 0.08),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(end: 1.2, duration: 3.5.seconds, curve: Curves.easeInOutSine),
              ),
              // Blur layer for glassmorphism
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // ─── MAIN CONTENT ───
              Column(
                children: [
                  // ─── HERO: Full-width food scanning carousel ───
                  SizedBox(
                    height: heroHeight,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: _FoodScanShowcase(),
                        ),
                        // Close button (top-left, over image)
                        Positioned(
                          top: topPadding + 4, left: 8,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.32),
                            ),
                            icon: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                          ),
                        ),
                        // Restore button (top-right, over image)
                        Positioned(
                          top: topPadding + 10, right: 12,
                          child: GestureDetector(
                            onTap: _handleRestore,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.paywall_restore,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: tight ? 10 : 16),
                          _buildContextualTitle(context, compact),
                          SizedBox(height: tight ? 14 : 20),
                          _buildCheckmarkBenefits(context, compact),
                          SizedBox(height: tight ? 16 : 22),
                          _buildPricingRow(compact),
                          SizedBox(height: tight ? 16 : 22),
                          _LuxeButton(
                            text: _selectedPackage?.packageType == PackageType.annual
                                ? AppLocalizations.of(context)!.premium_start_trial
                                : "Unlock SnapCal Pro",
                            isLoading: _isLoading,
                            height: tight ? 52 : 58,
                            onTap: _handlePurchase,
                          ).animate().fadeIn(delay: 260.ms, duration: 300.ms),
                          SizedBox(height: tight ? 10 : 14),
                          // Cancel anytime
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.shieldCheck, size: 13, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                AppLocalizations.of(context)!.paywall_cancel_anytime,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: tight ? 8 : 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FooterLink(label: "Privacy Policy", onTap: () {}),
                              Text("  ·  ", style: TextStyle(color: colorScheme.outlineVariant, fontSize: 11)),
                              _FooterLink(label: AppLocalizations.of(context)!.paywall_terms_conditions, onTap: () {}),
                            ],
                          ),
                          SizedBox(height: math.max(tight ? 8.0 : 12.0, bottomPadding)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContextualTitle(BuildContext context, bool compact) {
    final colorScheme = Theme.of(context).colorScheme;
    String title;
    String subtitle;

    if (widget.limitReached || widget.entryPoint == PaywallEntryPoint.scanLimit) {
      title = "You used 3/3 free scans today";
      subtitle = "Upgrade to unlock unlimited scanning";
    } else if (widget.entryPoint == PaywallEntryPoint.aiCoachLimit) {
      title = "Unlock unlimited AI coaching";
      subtitle = "Get 24/7 personal nutrition guidance";
    } else if (widget.entryPoint == PaywallEntryPoint.plannerLockedDay ||
        widget.entryPoint == PaywallEntryPoint.plannerPreferences) {
      title = "Unlock smart meal planning";
      subtitle = "Customized daily plans for your goals";
    } else if (widget.entryPoint == PaywallEntryPoint.groceryList) {
      title = "Auto-generated shopping lists";
      subtitle = "Save time with smart grocery aggregation";
    } else if (widget.entryPoint == PaywallEntryPoint.progressPhotoLimit) {
      title = "Visual progress journey";
      subtitle = "Track your body transformation photos";
    } else if (widget.entryPoint == PaywallEntryPoint.reportInsight ||
        widget.entryPoint == PaywallEntryPoint.mealInsight) {
      title = "Deep metabolic analytics";
      subtitle = "Unlock personalized nutrition trends";
    } else if (widget.entryPoint == PaywallEntryPoint.adRemoval) {
      title = "100% focused experience";
      subtitle = "Remove all ads and interruptions";
    } else {
      title = "Upgrade your experience";
      subtitle = "Unlock all premium features today";
    }

    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.premiumGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          blendMode: BlendMode.srcIn,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white, // Color is replaced by the shader
              fontSize: compact ? 22 : 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),
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
    final benefits = [
      "Unlimited scans",
      "AI guidance",
      "Full history",
      "Weekly reports",
      "Ad-free",
      "Smart planner",
    ];

    return Wrap(
      spacing: 0,
      runSpacing: compact ? 10 : 14,
      children: benefits.map((b) => SizedBox(
        width: (MediaQuery.of(context).size.width - (compact ? 40 : 48)) / 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(LucideIcons.check, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(b, style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      )).toList(),
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
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: compact ? 108 : 124,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ]
                          : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white)
                                  : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.75)),
                        ),
                      ),
                      if (isSelected) ...[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, AppColors.sky],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF191A1C)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ] else ...[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.15) : context.cardBorderColor,
                                width: 1,
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
                                          ? AppColors.primary
                                          : context.textSecondaryColor,
                                  fontSize: compact ? 10 : 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
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
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 2 : 4),
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
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
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
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.015, 1.015),
          duration: 180.ms,
          curve: Curves.easeOutCubic,
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
          gradient: AppColors.premiumGradient,
          borderRadius: BorderRadius.circular(18),
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
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .boxShadow(
         begin: BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
         end: BoxShadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 32, offset: const Offset(0, 12)),
         duration: 2.seconds,
         curve: Curves.easeInOutSine,
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

    // Auto-advance slides every 5.5 seconds
    Future.delayed(const Duration(milliseconds: 5500), _autoPlayNextPage);
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
              const Duration(milliseconds: 5500),
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
            bottom: 22,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.85, 1.0], // Fade out smoothly at the bottom 15%
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
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
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: label.isLeftSide ? 8.0 : null,
                                            right: !label.isLeftSide ? 8.0 : null,
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
                            color: const Color(
                              0xFF2EE59D,
                            ).withValues(alpha: 0.75),
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
      final haloPaint =
          Paint()
            ..color = const Color(
              0xFF2EE59D,
            ).withValues(alpha: 0.22 * dotOpacity)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 11.0, haloPaint);

      // B. Fine outer scanning ring (radius 6.5)
      final outerRingPaint =
          Paint()
            ..color = const Color(
              0xFF2EE59D,
            ).withValues(alpha: 0.90 * dotOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
      canvas.drawCircle(end, 6.5, outerRingPaint);

      // C. Solid mint green core (radius 3.2)
      final corePaint =
          Paint()
            ..color = const Color(
              0xFF2EE59D,
            ).withValues(alpha: 1.00 * dotOpacity)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 3.2, corePaint);

      // D. Brilliant white focal center dot (radius 1.2)
      final centerPaint =
          Paint()
            ..color = Colors.white.withValues(alpha: 1.00 * dotOpacity)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 1.2, centerPaint);
    }

    // 2. Draw connector line if reveal progress has started
    if (progress <= 0.0) return;

    final start = Offset(startX, labelY);

    final glowPaint =
        Paint()
          ..color = const Color(0xFF2EE59D).withValues(alpha: 0.35 * progress)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Crisp neon green foreground line
    final linePaint =
        Paint()
          ..color = const Color(0xFF2EE59D).withValues(alpha: 1.00 * progress)
          ..strokeWidth = 1.8
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
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isScanning
                      ? const Color(0xFF2EE59D).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.40),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isScanning
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
                    fontSize: 10.0,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.flame, size: 9, color: Color(0xFFFF9F0A)),
                    const SizedBox(width: 2.5),
                    Text(
                      calories,
                      style: const TextStyle(
                        color: Color(0xFF1C1C1E),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      "($portion)",
                      style: TextStyle(
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
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
