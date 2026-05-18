import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

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
  late AnimationController _scanController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _loaderOpacity;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;
  late Animation<double> _progressAnimation;

  final List<_StarParticle> _stars = [];
  final _random = math.Random();
  String _statusText = 'Initializing Calorie Intelligence Engine...';

  @override
  void initState() {
    super.initState();

    // Generate slow micro-stars
    for (int i = 0; i < 15; i++) {
      _stars.add(
        _StarParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1,
          speed: _random.nextDouble() * 0.3 + 0.1,
          opacity: _random.nextDouble() * 0.4 + 0.1,
        ),
      );
    }

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

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

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // Progressive status indicators
    _progressController.addListener(() {
      final val = _progressAnimation.value;
      String nextStatusText = _statusText;
      if (val < 0.2) {
        nextStatusText = 'Initializing Calorie Intelligence Engine...';
      } else if (val < 0.45) {
        nextStatusText = 'Opening encrypted database...';
      } else if (val < 0.65) {
        nextStatusText = 'Configuring AI Coach & Gemini gateways...';
      } else if (val < 0.85) {
        nextStatusText = 'Calibrating wellness dashboard...';
      } else {
        nextStatusText = 'Syncing cloud profile...';
      }
      if (nextStatusText != _statusText) {
        setState(() => _statusText = nextStatusText);
      }
    });

    _mainController.forward();
    _progressController.forward();
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
    _scanController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final accentColor = colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Organic breathing Mesh Ambient Glow
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _AmbientMeshPainter(
                  animationValue: _particleController.value,
                  isDark: isDark,
                ),
              );
            },
          ),

          // 2. Slow micro stars overlay
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _StarPainter(
                  stars: _stars,
                  animationValue: _particleController.value,
                  isDark: isDark,
                  starColor: colorScheme.primaryContainer,
                ),
              );
            },
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3. Central Glassmorphic App Logo with weightless Parallax floating offset
                AnimatedBuilder(
                  animation: Listenable.merge([_mainController, _pulseController, _particleController]),
                  builder: (context, child) {
                    final floatOffsetY = 7.0 * math.sin(_particleController.value * 2 * math.pi);
                    return Transform.translate(
                      offset: Offset(0, floatOffsetY),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft ambient backing shadow glow
                              Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(
                                        alpha: (isDark ? 0.35 : 0.18) * _glowOpacity.value * _pulseAnimation.value,
                                      ),
                                      blurRadius: 80 * _pulseAnimation.value,
                                      spreadRadius: 24 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                              ),
                              // Rotating Camera HUD Rings framing the logo
                              SizedBox(
                                width: 220,
                                height: 220,
                                child: CustomPaint(
                                  painter: _CameraHudPainter(
                                    rotation: _particleController.value * 2 * math.pi,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              // Floating glass plate with rounded outer glow
                              Container(
                                width: 154,
                                height: 154,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.black.withValues(alpha: 0.02),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.45 : 0.06,
                                      ),
                                      blurRadius: 32,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Dynamic futuristic SnapCal Camera Calorie Lens illustration inside the glass
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _particleController,
                                            builder: (context, _) {
                                              return CustomPaint(
                                                painter: _SnapCalScannerLensPainter(
                                                  animationValue: _particleController.value,
                                                  primaryColor: accentColor,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Vertical holographic Laser scan loop overlay
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _scanAnimation,
                                            builder: (context, _) {
                                              return CustomPaint(
                                                painter: _LaserScanPainter(
                                                  progress: _scanAnimation.value,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 54),

                // 4. App Title Text
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _textSlide,
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          l10n?.appTitle ?? 'SnapCal',
                          style: AppTypography.displayMedium.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.2,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // 5. App Tagline
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacity.value,
                      child: Text(
                        l10n?.splash_tagline ?? 'Snap. Track. Thrive.',
                        style: AppTypography.labelLarge.copyWith(
                          color: textSecondary,
                          letterSpacing: 4.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 64),

                // 6. Horizontal Pill Progress Indicator
                AnimatedBuilder(
                  animation: Listenable.merge([_mainController, _progressAnimation]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loaderOpacity.value,
                      child: Container(
                        width: 200,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFF0D9BD8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 7. Micro-Feedback Status Indicators
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loaderOpacity.value,
                      child: Text(
                        _statusText,
                        style: AppTypography.bodySmall.copyWith(
                          color: textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.3,
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

class _StarParticle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _AmbientMeshPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _AmbientMeshPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF09090B) : const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!isDark) return;

    final angle = animationValue * 2 * math.pi;
    final paint = Paint()..style = PaintingStyle.fill;

    // Bubble 1: Emerald Green (Slow floating left)
    final bubble1Center = Offset(
      size.width * (0.2 + 0.1 * math.sin(angle)),
      size.height * (0.35 + 0.1 * math.cos(angle)),
    );
    final bubble1Radius = size.width * 0.7;
    paint.shader = RadialGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.14),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: bubble1Center, radius: bubble1Radius));
    canvas.drawCircle(bubble1Center, bubble1Radius, paint);

    // Bubble 2: Premium Violet (Slow floating right)
    final bubble2Center = Offset(
      size.width * (0.8 - 0.12 * math.cos(angle)),
      size.height * (0.65 + 0.08 * math.sin(angle)),
    );
    final bubble2Radius = size.width * 0.8;
    paint.shader = RadialGradient(
      colors: [
        AppColors.violet.withValues(alpha: 0.12),
        AppColors.violet.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: bubble2Center, radius: bubble2Radius));
    canvas.drawCircle(bubble2Center, bubble2Radius, paint);

    // Bubble 3: Sky Blue (Slow floating center-top)
    final bubble3Center = Offset(
      size.width * (0.5 + 0.14 * math.cos(angle)),
      size.height * (0.48 - 0.1 * math.sin(angle)),
    );
    final bubble3Radius = size.width * 0.6;
    paint.shader = RadialGradient(
      colors: [
        AppColors.sky.withValues(alpha: 0.09),
        AppColors.sky.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: bubble3Center, radius: bubble3Radius));
    canvas.drawCircle(bubble3Center, bubble3Radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientMeshPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue || isDark != oldDelegate.isDark;
  }
}

class _StarPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double animationValue;
  final bool isDark;
  final Color starColor;

  _StarPainter({
    required this.stars,
    required this.animationValue,
    required this.isDark,
    required this.starColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDark) return;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final y = (star.y - animationValue * star.speed) % 1.0;
      final x = star.x + math.sin(animationValue * math.pi * 1.5 + star.y * 8) * 0.015;

      paint.color = starColor.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue || isDark != oldDelegate.isDark;
  }
}

class _CameraHudPainter extends CustomPainter {
  final double rotation;
  final Color color;

  _CameraHudPainter({required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Sleek rotating corner brackets (shutter framing)
    final bracketPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final bracketLength = math.pi / 6; // 30 degrees
    for (int i = 0; i < 4; i++) {
      final startAngle = rotation + (i * math.pi / 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        startAngle,
        bracketLength,
        false,
        bracketPaint,
      );
    }

    // 2. Continuous rotating tick dials
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final numTicks = 20;
    for (int i = 0; i < numTicks; i++) {
      final angle = -rotation * 0.8 + (i * 2 * math.pi / numTicks);
      final tickStart = radius - 26;
      final tickEnd = radius - 20;

      final startOffset = Offset(
        center.dx + tickStart * math.cos(angle),
        center.dy + tickStart * math.sin(angle),
      );
      final endOffset = Offset(
        center.dx + tickEnd * math.cos(angle),
        center.dy + tickEnd * math.sin(angle),
      );
      canvas.drawLine(startOffset, endOffset, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CameraHudPainter oldDelegate) {
    return rotation != oldDelegate.rotation || color != oldDelegate.color;
  }
}

class _LaserScanPainter extends CustomPainter {
  final double progress;

  _LaserScanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;

    // Glowing scan trail upward
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.primary.withValues(alpha: 0.45),
        ],
      ).createShader(Rect.fromLTRB(0, y - 28, size.width, y));
    canvas.drawRect(Rect.fromLTRB(0, y - 28, size.width, y), trailPaint);

    // Glowing neon green laser blur
    final laserBlurPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), laserBlurPaint);

    // Ultra-bright solid white core
    final laserCorePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), laserCorePaint);
  }

  @override
  bool shouldRepaint(covariant _LaserScanPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _SnapCalScannerLensPainter extends CustomPainter {
  final double animationValue; // continuous 0.0 to 1.0
  final Color primaryColor;

  _SnapCalScannerLensPainter({
    required this.animationValue,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    // 1. Draw Outer Camera Lens Ring (Metallic Dark Carbon Slate)
    final outerRingPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius - 4, outerRingPaint);

    final outerRingBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx, cy), radius - 4, outerRingBorder);

    // 2. Draw Calorie HUD Circular Speedometer Gauge (Emerald to Sky)
    final gaugePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor,
          const Color(0xFF0D9BD8),
          primaryColor.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.75, 1.0],
        transform: GradientRotation(animationValue * 2 * math.pi * 0.2), // slow spin
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius - 14));

    final gaugeStroke = Paint()
      ..shader = gaugePaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw an open progress arc representing the calorie limit gauge
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius - 14),
      -math.pi * 0.8,
      math.pi * 1.6 * 0.85, // 85% filled
      false,
      gaugeStroke,
    );

    // Minor tick marks inside the gauge
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const numTicks = 36;
    for (int i = 0; i < numTicks; i++) {
      final tickAngle = (i * 2 * math.pi / numTicks);
      final startR = radius - 22;
      final endR = radius - 18;
      canvas.drawLine(
        Offset(cx + startR * math.cos(tickAngle), cy + startR * math.sin(tickAngle)),
        Offset(cx + endR * math.cos(tickAngle), cy + endR * math.sin(tickAngle)),
        tickPaint,
      );
    }

    // 3. Draw Camera Aperture Shutter Core (Glossy Emerald Glass)
    final coreRadius = radius - 30;
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.4),
          const Color(0xFF065F46).withValues(alpha: 0.85),
          const Color(0xFF022C22),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: coreRadius));
    canvas.drawCircle(Offset(cx, cy), coreRadius, corePaint);

    final coreBorder = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), coreRadius, coreBorder);

    // 4. Shutter Blades converging toward the center
    final bladePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const numBlades = 6;
    final bladeOffsetAngle = animationValue * 0.15; // subtle breathing opening of blades
    for (int i = 0; i < numBlades; i++) {
      final startAngle = bladeOffsetAngle + (i * 2 * math.pi / numBlades);
      final p1 = Offset(
        cx + coreRadius * math.cos(startAngle),
        cy + coreRadius * math.sin(startAngle),
      );
      final p2 = Offset(
        cx + (coreRadius * 0.3) * math.cos(startAngle + math.pi / 3),
        cy + (coreRadius * 0.3) * math.sin(startAngle + math.pi / 3),
      );
      canvas.drawLine(p1, p2, bladePaint);
    }

    // 5. Central Glowing Camera Focus Target Crosshair [ + ]
    final targetOpacity = 0.4 + (0.5 * math.sin(animationValue * 4 * math.pi).abs()); // flashing
    final focusPaint = Paint()
      ..color = primaryColor.withValues(alpha: targetOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw central plus sign
    canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), focusPaint);
    canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), focusPaint);
    // Draw target brackets surrounding plus
    const bracketRadius = 14.0;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: bracketRadius), -math.pi * 0.15, math.pi * 0.3, false, focusPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: bracketRadius), math.pi * 0.85, math.pi * 0.3, false, focusPaint);

    // 6. Curved Physical Reflection Glass Highlights (3D Gloss)
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    // Gloss highlight oval in the top left quadrant
    final glossPath = Path()
      ..addOval(Rect.fromLTWH(cx - radius * 0.6, cy - radius * 0.6, radius * 0.8, radius * 0.4));

    canvas.save();
    canvas.rotate(-math.pi / 6); // tilt gloss
    canvas.drawPath(glossPath, glossPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SnapCalScannerLensPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        primaryColor != oldDelegate.primaryColor;
  }
}
