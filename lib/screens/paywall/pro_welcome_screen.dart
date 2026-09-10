import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_motion.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

/// The gold of the home screen's PRO badge, so the two read as one thing.
const _proGold = Color(0xFFE29200);
const _paywallSage = Color(0xFF92AF83);

/// Shown once, right after a purchase or restore makes the user Pro.
///
/// This replaces a green toast that appeared while the paywall stayed on
/// screen, which left someone who had just paid unsure whether anything had
/// changed. Continuing, or pressing back, leads into the app -- never back to
/// the paywall they paid through.
class ProWelcomeScreen extends StatefulWidget {
  const ProWelcomeScreen({
    super.key,
    this.isRestore = false,
    required this.onContinue,
  });

  final bool isRestore;
  final VoidCallback onContinue;

  @override
  State<ProWelcomeScreen> createState() => _ProWelcomeScreenState();
}

class _ProWelcomeScreenState extends State<ProWelcomeScreen> {
  static const _ringStart = Duration(milliseconds: 150);
  static const _ringDuration = Duration(milliseconds: 850);
  static const _ringCloses = Duration(milliseconds: 1000);
  static const _firstBenefitMs = 1500;
  static const _benefitCount = 4;

  // One short burst, never looped: the Pro badge was deliberately made to stop
  // animating for the whole session, and this should not bring that back.
  final _confetti = ConfettiController(
    duration: const Duration(milliseconds: 350),
  );
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = AppMotion.reduceMotion(context);
    if (_reduceMotion) return;

    Future.delayed(_ringCloses, () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _confetti.play();
    });
    for (var i = 0; i < _benefitCount; i++) {
      Future.delayed(Duration(milliseconds: _firstBenefitMs + i * 100), () {
        if (mounted) HapticFeedback.selectionClick();
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Widget _enter(Widget child, int delayMs) {
    if (_reduceMotion) return child;
    return child
        .animate(delay: delayMs.ms)
        .fadeIn(duration: AppMotion.reveal, curve: AppMotion.entranceCurve)
        .slideY(
          begin: 0.35,
          end: 0,
          duration: AppMotion.reveal,
          curve: AppMotion.entranceCurve,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? AppColors.darkBackground : AppColors.background;
    final ink = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final benefits = [
      l10n.paywall_benefit_unlimited_scans,
      l10n.paywall_benefit_ai_guidance,
      l10n.paywall_benefit_smart_planner,
      l10n.paywall_benefit_weekly_reports,
    ];
    assert(benefits.length == _benefitCount);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onContinue();
      },
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          // Scrolls only when it has to. On a small phone, with large text, or
          // with the longer French and Arabic copy, the fixed column overflowed
          // and pushed "Start exploring" off the bottom of the screen.
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          _Emblem(
                            dark: dark,
                            background: background,
                            reduceMotion: _reduceMotion,
                            confetti: _confetti,
                            ringStart: _ringStart,
                            ringDuration: _ringDuration,
                          ),
                          const SizedBox(height: 28),
                          _enter(
                            Text(
                              widget.isRestore
                                  ? l10n.pro_restored_eyebrow
                                  : l10n.pro_welcome_eyebrow,
                              style: AppTypography.labelLarge.copyWith(
                                color:
                                    dark
                                        ? AppColors.emeraldLight
                                        : AppColors.primaryDark,
                                letterSpacing: 0.4,
                              ),
                            ),
                            1150,
                          ),
                          const SizedBox(height: 6),
                          _enter(
                            Text(
                              widget.isRestore
                                  ? l10n.pro_restored_title
                                  : l10n.pro_welcome_title,
                              textAlign: TextAlign.center,
                              style: AppTypography.headlineMedium.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            1250,
                          ),
                          const SizedBox(height: 8),
                          _enter(
                            Text(
                              l10n.pro_welcome_subtitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: muted,
                              ),
                            ),
                            1350,
                          ),
                          const SizedBox(height: 32),
                          for (var i = 0; i < benefits.length; i++)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                              child: _enter(
                                _BenefitRow(label: benefits[i], color: ink),
                                _firstBenefitMs + i * 100,
                              ),
                            ),
                          const Spacer(flex: 3),
                          _enter(
                            // A minimum, not a fixed height: with large text or the
                            // longer French label the button grows instead of
                            // clipping its label.
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: double.infinity,
                                minHeight: 54,
                              ),
                              child: FilledButton(
                                onPressed: widget.onContinue,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.emeraldDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        l10n.pro_welcome_cta,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              color: AppColors.emeraldDark,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Directionality.of(context) ==
                                              TextDirection.rtl
                                          ? LucideIcons.arrowLeft
                                          : LucideIcons.arrowRight,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            2100,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({
    required this.dark,
    required this.background,
    required this.reduceMotion,
    required this.confetti,
    required this.ringStart,
    required this.ringDuration,
  });

  final bool dark;
  final Color background;
  final bool reduceMotion;
  final ConfettiController confetti;
  final Duration ringStart;
  final Duration ringDuration;

  @override
  Widget build(BuildContext context) {
    final track = dark ? const Color(0xFF12211B) : AppColors.primaryContainer;
    const size = Size.square(136);

    final Widget ring =
        reduceMotion
            ? CustomPaint(size: size, painter: _RingPainter(1, track))
            : Animate(delay: ringStart).custom(
              duration: ringDuration,
              curve: AppMotion.entranceCurve,
              builder:
                  (context, value, _) => CustomPaint(
                    size: size,
                    painter: _RingPainter(value, track),
                  ),
            );

    final Widget badge = Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Opaque: a translucent tint let the confetti behind it show through
        // the diamond at the moment of the burst.
        color: Color.alphaBlend(
          AppColors.primary.withValues(alpha: dark ? 0.16 : 0.12),
          background,
        ),
      ),
      child: const Icon(LucideIcons.gem, size: 44, color: _proGold),
    );

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ring,
          // Behind the emblem, so the burst frames it instead of covering it.
          ConfettiWidget(
            confettiController: confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 26,
            emissionFrequency: 0.45,
            minBlastForce: 12,
            maxBlastForce: 32,
            gravity: 0.22,
            minimumSize: const Size(8, 5),
            maximumSize: const Size(14, 8),
            colors: [
              AppColors.primary,
              AppColors.emeraldLight,
              _proGold,
              AppColors.premiumGold,
              _paywallSage,
              if (dark) Colors.white,
            ],
          ),
          reduceMotion
              ? badge
              : badge
                  .animate(delay: 850.ms)
                  .fadeIn(duration: 200.ms)
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.checkCircle, size: 22, color: AppColors.primary),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.track);

  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);
    canvas.drawCircle(
      rect.center,
      circle.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      circle,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track;
}
