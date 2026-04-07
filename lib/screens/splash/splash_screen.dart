import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _loaderOpacity;
  late Animation<double> _pulseAnimation;

  final List<_Particle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

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

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );

    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.5, curve: Curves.easeOut)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic)),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.55, 0.8, curve: Curves.easeOut)),
    );

    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    HapticFeedback.lightImpact();

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor1 = colorScheme.surface;
    final backgroundColor2 = colorScheme.surfaceContainer;
    final cardColor = colorScheme.surfaceContainerLow;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final accentColor = colorScheme.primary;
    final particleColor = colorScheme.primaryContainer;

    return Scaffold(
      body: Stack(
        children: [
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
                        (math.sin(_particleController.value * math.pi * 2) + 1) / 2,
                      )!,
                      backgroundColor1,
                    ],
                  ),
                ),
              );
            },
          ),

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

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_mainController, _pulseController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(
                                      alpha: (isDark ? 0.3 : 0.2) * _glowOpacity.value * _pulseAnimation.value,
                                    ),
                                    blurRadius: 70 * _pulseAnimation.value,
                                    spreadRadius: 20 * _pulseAnimation.value,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardColor,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
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

                const SizedBox(height: 60),

                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _textSlide,
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          'SnapCal',
                          style: AppTypography.displayMedium.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacity.value,
                      child: Text(
                        'Snap. Track. Thrive.',
                        style: AppTypography.labelLarge.copyWith(
                          color: textSecondary,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 80),

                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loaderOpacity.value,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor.withValues(alpha: 0.6),
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
      final y = (particle.y + animationValue * particle.speed) % 1.0;
      final x = particle.x + math.sin(animationValue * math.pi * 2 + particle.y * 10) * 0.02;

      paint.color = particleColor.withValues(alpha: particle.opacity);

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
