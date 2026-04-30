import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/settings_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  final bool limitReached;
  
  const PaywallScreen({
    super.key,
    this.limitReached = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Package? _selectedPackage;
  List<Package> _packages = [];

  // ─── Entrance Animations ───
  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final List<Animation<double>> _featureAnims;
  late final Animation<double> _ctaAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // Create staggered animations for 5 items (4 features + 1 package selector)
    _featureAnims = List.generate(5, (index) {
      final start = 0.3 + (index * 0.1);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, start + 0.3, curve: Curves.easeOut),
      );
    });

    _ctaAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await SubscriptionService().getOfferings();
      if (mounted && offerings?.current != null && offerings!.current!.availablePackages.isNotEmpty) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          // Try to select annual by default if available
          try {
            _selectedPackage = _packages.firstWhere((p) => p.packageType == PackageType.annual);
          } catch (_) {
            _selectedPackage = _packages.first;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading offerings: $e");
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(BuildContext context) async {
    if (_selectedPackage == null) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final subService = SubscriptionService();
    
    try {
      final success = await subService.purchasePackage(_selectedPackage!);
      if (!mounted) return;
      
      if (success) {
        settingsProvider.refresh();
        router.pop();
        _showSuccessSnackBar(messenger);
      }
    } catch (e) {
      _showErrorSnackBar(messenger, "Purchase failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final subService = SubscriptionService();
    
    try {
      final success = await subService.restorePurchases();
      if (!mounted) return;
      
      if (success) {
        settingsProvider.refresh();
        router.pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Purchases Restored! 🎉'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        _showErrorSnackBar(messenger, "No previous purchases found.");
      }
    } catch (e) {
      _showErrorSnackBar(messenger, "Failed to restore purchases.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Welcome to SnapCal Pro! 🎉'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(ScaffoldMessengerState messenger, String error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _staggeredSlide(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ─── Helpers for package display ───
  String _packageLabel(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.annual:
        return 'Yearly';
      case PackageType.sixMonth:
        return '6 Months';
      case PackageType.threeMonth:
        return '3 Months';
      case PackageType.twoMonth:
        return '2 Months';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.lifetime:
        return 'Lifetime';
      default:
        return pkg.storeProduct.title;
    }
  }

  String _perMonthPrice(Package pkg) {
    final price = pkg.storeProduct.price;
    final priceString = pkg.storeProduct.priceString;
    double monthly;
    switch (pkg.packageType) {
      case PackageType.annual:
        monthly = price / 12;
        break;
      case PackageType.sixMonth:
        monthly = price / 6;
        break;
      case PackageType.threeMonth:
        monthly = price / 3;
        break;
      case PackageType.twoMonth:
        monthly = price / 2;
        break;
      default:
        monthly = price;
    }

    // Extract currency symbol from the localized priceString
    // e.g. "$59.99" → "$", "€9.99" → "€", "59.99 zł" → " zł"
    final formattedMonthly = monthly.toStringAsFixed(2);

    // Check if symbol is a prefix (e.g. $, €, £)
    final priceIndex = priceString.indexOf(RegExp(r'[0-9]'));
    if (priceIndex > 0) {
      final prefix = priceString.substring(0, priceIndex);
      return '$prefix$formattedMonthly/mo';
    }

    // Check if symbol is a suffix (e.g. "zł", "kr", "IQD")
    final lastDigit = priceString.lastIndexOf(RegExp(r'[0-9]'));
    if (lastDigit >= 0 && lastDigit < priceString.length - 1) {
      final suffix = priceString.substring(lastDigit + 1);
      return '$formattedMonthly$suffix/mo';
    }

    // Fallback: use currency code
    return '$formattedMonthly ${pkg.storeProduct.currencyCode}/mo';
  }

  bool _isRecommended(Package pkg) {
    return pkg.packageType == PackageType.annual;
  }

  String? _trialText(Package pkg) {
    final intro = pkg.storeProduct.introductoryPrice;
    if (intro == null) return null;
    final periods = intro.cycles;
    final unit = intro.periodUnit.name.toLowerCase();
    if (intro.price == 0) {
      // Free trial
      final label = periods == 1 ? '1 $unit' : '$periods ${unit}s';
      return '$label free trial';
    }
    return null;
  }

  String _ctaLabel() {
    if (_selectedPackage == null) return 'Loading...';
    final pkg = _selectedPackage!;
    final label = _packageLabel(pkg);
    final trial = _trialText(pkg);
    if (trial != null) {
      return 'Start Free Trial';
    }
    return 'Start $label — ${pkg.storeProduct.priceString}';
  }

  int _discountPercent(Package pkg, double? monthlyPrice) {
    if (monthlyPrice == null || monthlyPrice <= 0) return 0;
    final months = switch (pkg.packageType) {
      PackageType.annual => 12,
      PackageType.sixMonth => 6,
      PackageType.threeMonth => 3,
      PackageType.twoMonth => 2,
      _ => 1,
    };
    if (months <= 1) return 0;
    final fullPrice = monthlyPrice * months;
    if (fullPrice <= pkg.storeProduct.price) return 0;
    return ((1 - (pkg.storeProduct.price / fullPrice)) * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double? monthlyPrice;
    try {
      monthlyPrice = _packages.firstWhere((p) => p.packageType == PackageType.monthly).storeProduct.price;
    } catch (_) {}

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // ── Premium Glassmorphism Background ──
          Positioned(
            top: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF10B981), // Emerald
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF0EA5E9), // Light Blue
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: context.backgroundColor.withValues(alpha: 0.6),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // Spacer
                      Text(
                        'PRO PLAN',
                        style: AppTypography.labelSmall.copyWith(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w900,
                          color: context.textMutedColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.x),
                        color: context.textSecondaryColor,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 0),
                        
                        // ── COMPACT HERO & TITLE ──
                        _staggeredSlide(
                          _heroAnim,
                          Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  widget.limitReached ? 'Unlock Unlimited' : 'SnapCal Pro',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.headlineLarge.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Experience the full power of AI nutrition coaching.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── 2x2 FEATURE GRID (Replaces long list) ──
                        _staggeredSlide(
                          _featureAnims[0],
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: const [
                              _FeatureCard(
                                icon: LucideIcons.scanLine,
                                title: 'Unlimited',
                                subtitle: 'Daily Scans',
                                color: Color(0xFF10B981),
                              ),
                              _FeatureCard(
                                icon: LucideIcons.chefHat,
                                title: 'Smart',
                                subtitle: 'Meal Plans',
                                color: Colors.orange,
                              ),
                              _FeatureCard(
                                icon: LucideIcons.users,
                                title: 'AI Coach',
                                subtitle: 'Proactive Advice',
                                color: Colors.blue,
                              ),
                              _FeatureCard(
                                icon: LucideIcons.shieldCheck,
                                title: 'Ad-Free',
                                subtitle: 'Zero Interrupts',
                                color: Colors.purple,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Package Selection ──
                        if (_packages.isNotEmpty)
                          _staggeredSlide(
                            _featureAnims[4],
                            Column(
                              children: _packages.map((pkg) {
                                final isSelected = _selectedPackage == pkg;
                                final recommended = _isRecommended(pkg);
                                final discount = _discountPercent(pkg, monthlyPrice);
                                final trial = _trialText(pkg);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PackageCard(
                                    label: _packageLabel(pkg),
                                    priceString: pkg.storeProduct.priceString,
                                    perMonth: _perMonthPrice(pkg),
                                    isSelected: isSelected,
                                    isRecommended: recommended,
                                    discountPercent: discount,
                                    trialText: trial,
                                    isDark: isDark,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedPackage = pkg);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // ── Referral Section (Secondary) ──
                        _staggeredSlide(
                          _ctaAnim,
                          _ReferralMiniCard(),
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed Bottom CTA ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.backgroundColor.withValues(alpha: 0.0),
                    context.backgroundColor,
                    context.backgroundColor,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _staggeredSlide(
                    _ctaAnim,
                    _ScaleTapButton(
                      onTap: _isLoading ? null : () => _handlePurchase(context),
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _ctaLabel(),
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _staggeredSlide(
                    _ctaAnim,
                    TextButton(
                      onPressed: _isLoading ? null : () => _handleRestore(context),
                      child: Text(
                        'Restore Purchases',
                        style: AppTypography.labelMedium.copyWith(
                          color: context.textSecondaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ── Package Card Widget ──
// ══════════════════════════════════════════════════════

class _PackageCard extends StatelessWidget {
  final String label;
  final String priceString;
  final String perMonth;
  final bool isSelected;
  final bool isRecommended;
  final int discountPercent;
  final bool isDark;
  final VoidCallback onTap;

  final String? trialText;

  const _PackageCard({
    required this.label,
    required this.priceString,
    required this.perMonth,
    required this.isSelected,
    required this.isRecommended,
    required this.discountPercent,
    required this.isDark,
    required this.onTap,
    this.trialText,
  });

  @override
  Widget build(BuildContext context) {
    // Premium styling
    final selectedBorder = const Color(0xFF10B981); // Emerald
    final unselectedBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    
    final selectedBg = isDark
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : const Color(0xFF10B981).withValues(alpha: 0.08);
        
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.02);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              // ── Premium Trial Banner ──
              if (trialText != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        trialText!.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
              Padding(
                padding: EdgeInsets.fromLTRB(20, trialText != null ? 16 : 20, 20, 20),
                child: Row(
                  children: [
                    // ── Glowing Radio Indicator ──
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : context.textMutedColor.withValues(alpha: 0.3),
                          width: isSelected ? 0 : 2,
                        ),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // ── Plan info ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                label,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isSelected ? context.textPrimaryColor : context.textSecondaryColor,
                                ),
                              ),
                              if (isRecommended) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'BEST VALUE',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            perMonth,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected ? context.textPrimaryColor : context.textMutedColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (trialText != null) ...[
                             const SizedBox(height: 2),
                             Text(
                               'Then $priceString',
                               style: AppTypography.labelSmall.copyWith(
                                 color: context.textSecondaryColor,
                                 fontWeight: FontWeight.w500,
                                 fontSize: 11,
                               ),
                             ),
                          ]
                        ],
                      ),
                    ),

                    // ── Price + discount ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (trialText == null)
                          Text(
                            priceString,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: isSelected ? context.textPrimaryColor : context.textSecondaryColor,
                            ),
                          ),
                        if (discountPercent > 0) ...[
                          if (trialText == null) const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : context.textMutedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SAVE $discountPercent%',
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected ? const Color(0xFF10B981) : context.textSecondaryColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
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
}

// ══════════════════════════════════════════════════════
// ── Feature Tile ──
// ══════════════════════════════════════════════════════

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? tintColor;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = tintColor ?? AppColors.primary;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

// ══════════════════════════════════════════════════════
// ── Scale Tap Button ──
// ══════════════════════════════════════════════════════

class _ScaleTapButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _ScaleTapButton({required this.onTap, required this.child});

  @override
  State<_ScaleTapButton> createState() => _ScaleTapButtonState();
}

class _ScaleTapButtonState extends State<_ScaleTapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _controller.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel:
          widget.onTap != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ── Blinkist Trial Timeline ──
// ══════════════════════════════════════════════════════

class _BlinkistTimeline extends StatelessWidget {
  final String trialText;

  const _BlinkistTimeline({required this.trialText});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int trialDays = trialText.contains('7') ? 7 : (trialText.contains('14') ? 14 : 7);
    final int reminderDay = trialDays > 2 ? trialDays - 2 : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How your trial works',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          _TimelineItem(
            icon: LucideIcons.unlock,
            iconColor: AppColors.primary,
            title: 'Today',
            subtitle: 'You get full access to all Pro features.',
            isLast: false,
          ),
          _TimelineItem(
            icon: LucideIcons.bellRing,
            iconColor: Colors.orange,
            title: 'Day $reminderDay',
            subtitle: 'We send you a reminder that your trial is ending.',
            isLast: false,
          ),
          _TimelineItem(
            icon: LucideIcons.star,
            iconColor: Colors.purple,
            title: 'Day $trialDays',
            subtitle: 'You are charged. Cancel anytime before this to avoid charges.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralMiniCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.users, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want it for free?',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Invite friends to get bonus scans.',
                  style: AppTypography.labelSmall.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: context.textMutedColor),
        ],
      ),
    );
  }
}
