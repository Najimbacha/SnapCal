import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Correct Internal Imports
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/core/theme/theme_colors.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/ui_blocks.dart';
import 'package:snapcal/data/services/subscription_service.dart';
import 'package:snapcal/providers/settings_provider.dart';

class PaywallScreen extends StatefulWidget {
  final bool limitReached;
  
  const PaywallScreen({
    super.key,
    this.limitReached = false,
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
      final offerings = await SubscriptionService().getOfferings();
      if (mounted && offerings?.current != null && offerings!.current!.availablePackages.isNotEmpty) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          try {
            _selectedPackage = _packages.firstWhere((p) => p.packageType == PackageType.annual);
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
    if (_selectedPackage == null) return;
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);
    
    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final subService = SubscriptionService();
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final success = await subService.purchasePackage(_selectedPackage!);
      if (!mounted) return;
      if (success) {
        settingsProvider.refresh();
        router.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premium_welcome),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final subService = SubscriptionService();
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final success = await subService.restorePurchases();
      if (!mounted) return;
      
      if (success) {
        settingsProvider.refresh();
        context.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.premium_restore_success),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/mesh_bg.png', // Fallback to a custom painter if missing
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.8, -0.6),
                      radius: 1.5,
                      colors: [Color(0xFF1A1F35), Color(0xFF07090E)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(LucideIcons.x, color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: _handleRestore,
                          child: const Text(
                            "Restore Purchase",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Hero Card (Dreamify Style)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Futuristic Character Image
                        Positioned(
                          right: -20, bottom: -10, top: -10,
                          child: Opacity(
                            opacity: 0.9,
                            child: Image.asset(
                              'assets/images/premium_hero.png', // User's premium hero image
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(LucideIcons.sparkles, size: 160, color: Color(0xFFE0E7FF)),
                            ),
                          ),
                        ),
                        // Branding Text
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFFF8C38), Color(0xFFB066FE)],
                                ).createShader(bounds),
                                child: const Text(
                                  "SnapCal",
                                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Upgrade to\nPremium",
                                style: TextStyle(color: Color(0xFF1A1F35), fontSize: 24, fontWeight: FontWeight.w800, height: 1.1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(delay: 200.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // Feature List (Ultra Minimalist)
                  const _FeatureItem(icon: LucideIcons.sparkles, label: "Unlimited AI Food Scans"),
                  const _FeatureItem(icon: LucideIcons.zap, label: "Faster Processing"),
                  const _FeatureItem(icon: LucideIcons.layout, label: "Smart Meal Planner"),
                  const _FeatureItem(icon: LucideIcons.shieldCheck, label: "No Ads"),
                  const _FeatureItem(icon: LucideIcons.userCheck, label: "Elite AI Coach Access"),

                  const Spacer(),

                  // Pricing Selection (Side-by-Side)
                  if (_packages.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: _PricingOption(
                            package: _packages.firstWhere((p) => p.packageType == PackageType.monthly, orElse: () => _packages.first),
                            isSelected: _selectedPackage?.packageType == PackageType.monthly,
                            onTap: () => setState(() => _selectedPackage = _packages.firstWhere((p) => p.packageType == PackageType.monthly)),
                            label: "Monthly",
                            subLabel: "Basic",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PricingOption(
                            package: _packages.firstWhere((p) => p.packageType == PackageType.annual, orElse: () => _packages.last),
                            isSelected: _selectedPackage?.packageType == PackageType.annual,
                            onTap: () => setState(() => _selectedPackage = _packages.firstWhere((p) => p.packageType == PackageType.annual)),
                            label: "Yearly",
                            subLabel: "Best Value",
                            showBadge: true,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0)
                  else
                    const Center(child: CircularProgressIndicator(color: Color(0xFFB066FE))),

                  const SizedBox(height: 24),

                  // Continue Button (Dreamify Gradient)
                  _LuxeButton(
                    text: "Continue",
                    isLoading: _isLoading,
                    onTap: _handlePurchase,
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 16),

                  // Compliance Footer
                  const Text(
                    "No Commitment. Cancel anytime",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FooterLink(label: "Privacy Policy", onTap: () {}),
                      const Text("  |  ", style: TextStyle(color: Colors.white12)),
                      _FooterLink(label: "Terms & Conditions", onTap: () {}),
                    ],
                  ),
                  SizedBox(height: math.max(12.0, bottomPadding)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, end: 0);
  }
}

class _PricingOption extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final String subLabel;
  final bool showBadge;

  const _PricingOption({
    required this.package,
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.subLabel,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1A1F35) : const Color(0xFF11141D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFFB066FE) : Colors.white.withValues(alpha: 0.05),
                width: 2,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: const Color(0xFFB066FE).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))
              ] : null,
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    package.storeProduct.priceString,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: -10,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF8C38), Color(0xFFB066FE)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Save 80%",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
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

  const _LuxeButton({required this.text, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8C38), Color(0xFFB066FE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB066FE).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
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
        style: const TextStyle(color: Colors.white24, fontSize: 11, decoration: TextDecoration.underline),
      ),
    );
  }
}



