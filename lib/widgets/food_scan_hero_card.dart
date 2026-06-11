import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_colors.dart';

/// Public reusable food scan hero card.
/// Shows a food image, plays a single scan beam animation,
/// then reveals the detected meal result (title, calories, macros).
///
/// Does NOT auto-advance, loop, or show multiple slides.
/// Configure per-screen via constructor parameters.
class FoodScanHeroCard extends StatefulWidget {
  final String imagePath;
  final String mealTitle;
  final int calories;
  final int proteinGrams;
  final int carbGrams;
  final int fatGrams;
  final VoidCallback? onScanComplete;
  final bool reducedMotion;
  final double imageHeight;

  const FoodScanHeroCard({
    super.key,
    required this.imagePath,
    required this.mealTitle,
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    this.onScanComplete,
    this.reducedMotion = false,
    this.imageHeight = 220,
  });

  @override
  State<FoodScanHeroCard> createState() => _FoodScanHeroCardState();
}

class _FoodScanHeroCardState extends State<FoodScanHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _scanProgress;
  late Animation<double> _focusA;
  late Animation<double> _focusB;
  late Animation<double> _focusC;
  late Animation<double> _calorieCount;
  late Animation<double> _calorieScale;
  late Animation<double> _resultFade;
  late Animation<double> _macro1Fade;
  late Animation<double> _macro2Fade;
  late Animation<double> _macro3Fade;
  Animation<double> _glowPulse = const AlwaysStoppedAnimation<double>(1.0);

  bool _scanning = true;
  bool _reduced = false;

  static const _totalMs = 1800;

  @override
  void initState() {
    super.initState();
    _reduced =
        widget.reducedMotion ||
        (WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .reduceMotion);

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _reduced ? 200 : _totalMs),
    );

    final t = _reduced ? 0.0 : 1.0;

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0, _reduced ? 0.5 : 0.17, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0, _reduced ? 0.5 : 0.17, curve: Curves.easeOut),
      ),
    );

    _scanProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _reduced ? 0 : 0.14,
          _reduced ? 0.5 : 0.53,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _focusA = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.14 * t, 0.30 * t, curve: Curves.easeOut),
      ),
    );
    _focusB = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.20 * t, 0.36 * t, curve: Curves.easeOut),
      ),
    );
    _focusC = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.25 * t, 0.41 * t, curve: Curves.easeOut),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );

    _resultFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _reduced ? 0.3 : 0.53,
          _reduced ? 0.6 : 0.64,
          curve: Curves.easeIn,
        ),
      ),
    );

    _calorieCount = Tween<double>(
      begin: 0,
      end: widget.calories.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _reduced ? 0.4 : 0.61,
          _reduced ? 0.7 : 0.83,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _calorieScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _reduced ? 0.6 : 0.80,
          _reduced ? 0.7 : 0.88,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _macro1Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _reduced ? 0.5 : 0.83,
          _reduced ? 0.7 : 0.89,
          curve: Curves.easeOut,
        ),
      ),
    );
    _macro2Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _reduced ? 0.55 : 0.87,
          _reduced ? 0.75 : 0.93,
          curve: Curves.easeOut,
        ),
      ),
    );
    _macro3Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _reduced ? 0.6 : 0.91,
          _reduced ? 0.8 : 0.97,
          curve: Curves.easeOut,
        ),
      ),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _scanning = false);
        widget.onScanComplete?.call();
      }
    });

    _ctrl.addListener(() {
      if (_scanProgress.value >= 0.85 && _scanning && mounted) {
        setState(() => _scanning = false);
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = context.primaryColor;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowPulse,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: -52,
                left: -20,
                right: -20,
                height: 170,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(
                          alpha:
                              isDark
                                  ? 0.22 * _glowPulse.value
                                  : 0.10 * _glowPulse.value,
                        ),
                        AppColors.tertiarySeed.withValues(
                          alpha:
                              isDark
                                  ? 0.10 * _glowPulse.value
                                  : 0.05 * _glowPulse.value,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.42, 1],
                      radius: 0.82,
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _cardFade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDark
                                ? const [AppColors.neutralDarkDeep, AppColors.neutralDarkDeepAlt]
                                : const [AppColors.white, AppColors.neutralCoolSurface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.white.withValues(alpha: 0.85),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: isDark ? 0.22 : 0.10),
                          blurRadius: 50,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.36 : 0.08,
                          ),
                          blurRadius: 34,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Image area
                        SizedBox(
                          height: widget.imageHeight,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  widget.imagePath,
                                  fit: BoxFit.cover,
                                  cacheWidth: 750,
                                  errorBuilder:
                                      (c, e, s) => Container(
                                        color:
                                            isDark
                                                ? AppColors.emeraldDark
                                                : AppColors.primaryContainer,
                                      ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.08),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.10),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: isDark ? 0.07 : 0.35,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                // Scan beam with glow
                                if (_scanning)
                                  AnimatedBuilder(
                                    animation: _scanProgress,
                                    builder: (context, _) {
                                      final p = _scanProgress.value;
                                      if (p <= 0 || p >= 1) {
                                        return const SizedBox.shrink();
                                      }
                                      return Positioned(
                                        top: p * widget.imageHeight - 3,
                                        left: 0,
                                        right: 0,
                                        height: 6,
                                        child: BackdropFilter(
                                          filter: ui.ImageFilter.blur(
                                            sigmaX: 2,
                                            sigmaY: 2,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  accent.withValues(alpha: 0),
                                                  accent.withValues(
                                                    alpha: 0.55,
                                                  ),
                                                  accent.withValues(alpha: 0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                // Focus markers during scan
                                if (_scanning)
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: [
                                          _focusMarker(
                                            _focusA,
                                            constraints,
                                            0.22,
                                            0.28,
                                            accent,
                                          ),
                                          _focusMarker(
                                            _focusB,
                                            constraints,
                                            0.68,
                                            0.48,
                                            accent,
                                          ),
                                          _focusMarker(
                                            _focusC,
                                            constraints,
                                            0.38,
                                            0.72,
                                            accent,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                // Scan corners
                                ..._corners(accent),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Result area
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child:
                              _scanning
                                  ? _scanningState(context)
                                  : FadeTransition(
                                    opacity: _resultFade,
                                    child: _resultContent(context),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scanningState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      key: const ValueKey('scanning'),
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          l10n.onboarding_scan_scanning,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _resultContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = context.primaryColor;
    final tc = context.textPrimaryColor;
    final mc = context.textMutedColor;

    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.mealTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tc,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.onboarding_scan_ai_label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _calorieCount,
          builder: (context, _) {
            return AnimatedBuilder(
              animation: _calorieScale,
              builder: (context, _) {
                return Transform.scale(
                  scale: _calorieScale.value,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _calorieCount.value.round().toString(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 0.96,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          l10n.onboarding_scan_kcal,
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.82),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _macroChip(
                label: l10n.onboarding_plan_protein,
                value: l10n.onboarding_plan_grams(widget.proteinGrams),
                fade: _macro1Fade,
                accent: AppColors.oliveAccent,
                tc: tc,
                mc: mc,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _macroChip(
                label: l10n.onboarding_plan_carbs,
                value: l10n.onboarding_plan_grams(widget.carbGrams),
                fade: _macro2Fade,
                accent: AppColors.blueAccent,
                tc: tc,
                mc: mc,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _macroChip(
                label: l10n.onboarding_plan_fat,
                value: l10n.onboarding_plan_grams(widget.fatGrams),
                fade: _macro3Fade,
                accent: AppColors.warmOrange,
                tc: tc,
                mc: mc,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _macroChip({
    required String label,
    required String value,
    required Animation<double> fade,
    required Color accent,
    required Color tc,
    required Color mc,
  }) {
    return FadeTransition(
      opacity: fade,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: tc.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tc.withValues(alpha: 0.035)),
        ),
        child: Column(
          children: [
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: tc,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: mc.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _focusMarker(
    Animation<double> anim,
    BoxConstraints constraints,
    double fracX,
    double fracY,
    Color accent,
  ) {
    return Positioned(
      left: constraints.maxWidth * fracX - 12,
      top: constraints.maxHeight * fracY - 12,
      child: FadeTransition(
        opacity: anim,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
          ),
        ),
      ),
    );
  }

  List<Widget> _corners(Color accent) {
    final c = accent.withValues(alpha: 0.35);
    return [
      Positioned(top: 0, left: 0, child: _CornerLine(color: c)),
      Positioned(
        top: 0,
        right: 0,
        child: Transform.flip(flipX: true, child: _CornerLine(color: c)),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Transform.flip(flipY: true, child: _CornerLine(color: c)),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Transform(
          transform: Matrix4.identity()..rotateZ(3.14159),
          child: _CornerLine(color: c),
        ),
      ),
    ];
  }
}

class _CornerLine extends StatelessWidget {
  final Color color;
  const _CornerLine({required this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22,
    height: 22,
    child: CustomPaint(painter: _CornerPainter(color: color)),
  );
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - 16, 0), p);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - 16), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter d) => false;
}
