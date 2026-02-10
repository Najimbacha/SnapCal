import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// ============================================================================
/// SYNC DATA SCREEN - WITH DIRECT AUTH OPTIONS
/// ============================================================================
/// A premium animated screen that encourages users to sign in for cloud sync.
/// Features direct Google, Facebook, and Email auth buttons.
/// ============================================================================

class SyncDataScreen extends StatefulWidget {
  final VoidCallback? onSkip;
  final VoidCallback? onAuthSuccess;

  const SyncDataScreen({super.key, this.onSkip, this.onAuthSuccess});

  @override
  State<SyncDataScreen> createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends State<SyncDataScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _syncController;

  // Animations
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late List<Animation<double>> _benefitAnimations;
  late List<Animation<Offset>> _benefitSlides;
  late Animation<double> _buttonsOpacity;
  late Animation<double> _syncRotation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;

  final List<_Benefit> _benefits = [
    _Benefit(
      icon: LucideIcons.smartphone,
      text: 'Sync across all your devices',
    ),
    _Benefit(icon: LucideIcons.shield, text: 'Never lose your progress'),
    _Benefit(
      icon: LucideIcons.cloudOff,
      text: 'Works offline, syncs when online',
    ),
    _Benefit(icon: LucideIcons.lock, text: 'Your data is encrypted & secure'),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _mainController.forward();
    HapticFeedback.lightImpact();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _syncController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4)),
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
      ),
    );

    _benefitAnimations = [];
    _benefitSlides = [];
    for (int i = 0; i < _benefits.length; i++) {
      final start = 0.35 + (i * 0.08);
      final end = start + 0.15;
      _benefitAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _benefitSlides.add(
        Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _syncRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_syncController);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _syncController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        widget.onAuthSuccess?.call();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await context.read<AuthProvider>().signInWithFacebook();
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        widget.onAuthSuccess?.call();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleEmailSignIn() {
    HapticFeedback.mediumImpact();
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme colors
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B);
    final accentColor = AppColors.primary;
    final borderColor =
        isDark
            ? AppColors.primary.withOpacity(0.3)
            : AppColors.primary.withOpacity(0.2);
    final iconBg =
        isDark
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.primary.withOpacity(0.1);
    final buttonSecondaryBg =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);
    final buttonSecondaryText =
        isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B);
    final buttonSecondaryBorder =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final skipTextColor =
        isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Animated Cloud Icon with Sync
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _mainController,
                    _pulseController,
                    _syncController,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _iconScale.value,
                      child: Opacity(
                        opacity: _iconOpacity.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow
                            Opacity(
                              opacity: _pulseAnimation.value * 0.5,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(
                                        isDark ? 0.3 : 0.2,
                                      ),
                                      blurRadius: 50 * _pulseAnimation.value,
                                      spreadRadius: 15 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Icon container
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardColor,
                                border: Border.all(
                                  color: borderColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.3 : 0.1,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.cloud,
                                    size: 40,
                                    color: textPrimary,
                                  ),
                                  Positioned(
                                    bottom: 18,
                                    right: 18,
                                    child: Transform.rotate(
                                      angle: _syncRotation.value,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accentColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentColor.withOpacity(
                                                0.4,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          LucideIcons.refreshCw,
                                          size: 14,
                                          color: Colors.white,
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
                  },
                ),

                const SizedBox(height: 32),

                // Title
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _titleSlide,
                      child: Opacity(
                        opacity: _titleOpacity.value,
                        child: Text(
                          'Save Your Progress',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Subtitle
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _subtitleOpacity.value,
                      child: Text(
                        'Sign in to keep your data safe and synced.',
                        style: TextStyle(
                          fontSize: 15,
                          color: textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Benefits List (compact)
                ...List.generate(_benefits.length, (index) {
                  return AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _benefitSlides[index],
                        child: Opacity(
                          opacity: _benefitAnimations[index].value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _benefits[index].icon,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _benefits[index].text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 32),

                // Auth Buttons
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _buttonsOpacity.value,
                      child: Column(
                        children: [
                          // Google Sign In
                          _AuthButton(
                            label: 'Continue with Google',
                            icon: FontAwesomeIcons.google,
                            onPressed: _handleGoogleSignIn,
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            isLoading: _isLoading,
                            isFaIcon: true,
                          ),
                          const SizedBox(height: 12),

                          // Facebook Sign In
                          _AuthButton(
                            label: 'Continue with Facebook',
                            icon: FontAwesomeIcons.facebook,
                            onPressed: _handleFacebookSignIn,
                            backgroundColor: buttonSecondaryBg,
                            foregroundColor: buttonSecondaryText,
                            borderColor: buttonSecondaryBorder,
                            isFaIcon: true,
                          ),
                          const SizedBox(height: 12),

                          // Email Sign In
                          _AuthButton(
                            label: 'Sign in with Email',
                            icon: LucideIcons.mail,
                            onPressed: _handleEmailSignIn,
                            backgroundColor: buttonSecondaryBg,
                            foregroundColor: buttonSecondaryText,
                            borderColor: buttonSecondaryBorder,
                          ),

                          const SizedBox(height: 24),

                          // Skip Button
                          if (widget.onSkip != null)
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                widget.onSkip?.call();
                              },
                              child: Text(
                                'Maybe Later',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: skipTextColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isFaIcon;
  final bool isLoading;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.isFaIcon = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAccent = backgroundColor == AppColors.primary;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: backgroundColor,
          border:
              borderColor != null
                  ? Border.all(color: borderColor!, width: 1)
                  : null,
          boxShadow:
              isAccent
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            else ...[
              isFaIcon
                  ? FaIcon(icon, size: 16, color: foregroundColor)
                  : Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String text;
  _Benefit({required this.icon, required this.text});
}
