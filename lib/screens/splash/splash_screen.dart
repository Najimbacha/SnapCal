import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// ============================================================================
/// PREMIUM SNAPCAL SPLASH SCREEN - LIGHT/DARK MODE SUPPORT
/// ============================================================================
/// A visually stunning animated splash screen featuring:
/// - Auto light/dark mode based on system theme
/// - Animated gradient background with subtle movement
/// - Floating particles effect
/// - Logo reveal with scale, glow, and pulse animations
/// - Staggered text animations
/// - Smooth loading indicator
/// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main animation controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _loaderOpacity;
  late Animation<double> _pulseAnimation;

  // Particles for floating effect
  final List<_Particle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Generate floating particles
    for (int i = 0; i < 20; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 4 + 2,
          speed: _random.nextDouble() * 0.5 + 0.2,
          opacity: _random.nextDouble() * 0.3 + 0.1,
        ),
      );
    }

    // Main animation controller (2.5 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Pulse animation for glow effect (continuous)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Particle movement controller (continuous)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Logo scale: starts small, bounces to normal size
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5)),
    );

    // Logo opacity: fade in quickly
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Glow opacity: fade in after logo appears
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text opacity and slide: staggered after logo
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline opacity: appears after title
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    // Loader opacity: appears last
    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Pulse animation for breathing glow
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _mainController.forward();

    // Haptic feedback on splash
    HapticFeedback.lightImpact();

    // 1. Pre-cache app logo early for smooth dashboard entrance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/icon/icon.png'), context);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme detection
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final backgroundColor1 =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final backgroundColor2 =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B);
    final accentColor = AppColors.primary;
    final borderColor =
        isDark
            ? AppColors.primary.withOpacity(0.3)
            : AppColors.primary.withOpacity(0.2);
    final particleColor = AppColors.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor1,
                      Color.lerp(
                        backgroundColor2,
                        backgroundColor1,
                        (math.sin(_particleController.value * math.pi * 2) +
                                1) /
                            2,
                      )!,
                      backgroundColor1,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Floating Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                  particleColor: particleColor,
                ),
              );
            },
          ),

          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Glow Effect
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _mainController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(
                                      (isDark ? 0.4 : 0.3) *
                                          _glowOpacity.value *
                                          _pulseAnimation.value *
                                          0.6,
                                    ),
                                    blurRadius: 60 * _pulseAnimation.value,
                                    spreadRadius: 20 * _pulseAnimation.value,
                                  ),
                                ],
                              ),
                            ),
                            // Inner glow
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(
                                      (isDark ? 0.3 : 0.2) *
                                          _glowOpacity.value *
                                          0.8,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            // Logo Container
                            Container(
                              width: 130,
                              height: 130,
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
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/icon/icon.png',
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // App Title
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _textSlide,
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          'Snapcal',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Tagline
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacity.value,
                      child: Text(
                        'Snap. Track. Thrive.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Loading Indicator
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loaderOpacity.value,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Particle data class
class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

/// Custom painter for floating particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Color particleColor;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Calculate animated position
      final y = (particle.y + animationValue * particle.speed) % 1.0;
      final x =
          particle.x +
          math.sin(animationValue * math.pi * 2 + particle.y * 10) * 0.02;

      paint.color = particleColor.withOpacity(particle.opacity);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
