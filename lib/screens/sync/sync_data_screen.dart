import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_blocks.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 48),

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
                                      color: colorScheme.primary.withValues(alpha: 0.3),
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
                                color: context.cardColor,
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
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
                                    color: colorScheme.onSurface,
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
                                          color: colorScheme.primary,
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withValues(alpha: 0.4),
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
                          'Cloud Sync',
                          style: AppTypography.headlineLarge.copyWith(
                            color: context.textPrimaryColor,
                            letterSpacing: -1.0,
                            fontWeight: FontWeight.w900,
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
                        'Keep your health data safe across all your devices with an account.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.textSecondaryColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Benefits List (compact)
                AppSectionCard(
                  glass: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: List.generate(_benefits.length, (index) {
                      return AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _benefitSlides[index],
                            child: Opacity(
                              opacity: _benefitAnimations[index].value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _benefits[index].icon,
                                        color: colorScheme.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        _benefits[index].text,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: context.textPrimaryColor,
                                          fontWeight: FontWeight.w600,
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
                  ),
                ),

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
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            isLoading: _isLoading,
                            isFaIcon: true,
                          ),
                          const SizedBox(height: 12),

                          // Secondary Buttons (Email/Facebook)
                          AppSectionCard(
                            glass: true,
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              children: [
                                _AuthButton(
                                  label: 'Continue with Facebook',
                                  icon: FontAwesomeIcons.facebook,
                                  onPressed: _handleFacebookSignIn,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: context.textPrimaryColor,
                                  isFaIcon: true,
                                ),
                                Divider(height: 1, color: context.dividerColor.withValues(alpha: 0.5)),
                                _AuthButton(
                                  label: 'Sign in with Email',
                                  icon: LucideIcons.mail,
                                  onPressed: _handleEmailSignIn,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: context.textPrimaryColor,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Skip Button
                          if (widget.onSkip != null)
                            _ScaleTap(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onSkip?.call();
                              },
                              child: Text(
                                'Skip for now',
                                style: AppTypography.titleSmall.copyWith(
                                  color: context.textMutedColor,
                                  fontWeight: FontWeight.w700,
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
  final dynamic icon;
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
    final isAccent = backgroundColor == Theme.of(context).colorScheme.primary;

    return _ScaleTap(
      onTap: isLoading ? () {} : onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
          border:
              borderColor != null
                  ? Border.all(color: borderColor!, width: 1)
                  : null,
          boxShadow:
              isAccent
                  ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
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
                  ? FaIcon(icon as FaIconData, size: 16, color: foregroundColor)
                  : Icon(icon as IconData, size: 18, color: foregroundColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String text;
  _Benefit({required this.icon, required this.text});
}
