import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_errors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_notifier_provider.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/ui_blocks.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../widgets/wazn_icons.dart';
import '../../widgets/app_toast.dart';

/// ============================================================================
/// SYNC DATA SCREEN - WITH DIRECT AUTH OPTIONS
/// ============================================================================
/// A premium animated screen that encourages users to sign in for cloud sync.
/// Features direct Google, Facebook, and Email auth buttons.
/// ============================================================================

class SyncDataScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSkip;
  final VoidCallback? onAuthSuccess;

  const SyncDataScreen({super.key, this.onSkip, this.onAuthSuccess});

  @override
  ConsumerState<SyncDataScreen> createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends ConsumerState<SyncDataScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;

  // Animations
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late List<Animation<double>> _benefitAnimations;
  late List<Animation<Offset>> _benefitSlides;
  late List<Animation<double>> _benefitTicks;
  late Animation<double> _buttonsOpacity;

  bool _isLoading = false;

  List<_Benefit> _buildBenefits(BuildContext context) => [
    _Benefit(
      icon: WaznIcons.smartphone,
      text: AppLocalizations.of(context)!.sync_benefit_devices,
    ),
    _Benefit(
      icon: WaznIcons.shield,
      text: AppLocalizations.of(context)!.sync_benefit_progress,
    ),
    _Benefit(
      icon: WaznIcons.cloudOff,
      text: AppLocalizations.of(context)!.sync_benefit_offline,
    ),
    _Benefit(
      icon: WaznIcons.lock,
      text: AppLocalizations.of(context)!.sync_benefit_secure,
    ),
  ];

  static const _benefitCount = 4;

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
    _benefitTicks = [];
    final benefitCount = _benefitCount;
    for (int i = 0; i < benefitCount; i++) {
      final start = (0.35 + (i * 0.08)).clamp(0.0, 1.0);
      final end = (start + 0.15).clamp(0.0, 1.0);
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
      _benefitTicks.add(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(
            end,
            (end + 0.12).clamp(0.0, 1.0),
            curve: AppMotion.springCurve,
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Arrive already in place for someone who has asked for less motion.
    if (AppMotion.reduceMotion(context) && !_mainController.isCompleted) {
      _mainController.value = 1;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (mounted && _isSignedIn(FirebaseAuth.instance.currentUser)) {
        widget.onAuthSuccess?.call();
      }
    } catch (e) {
      _showAuthError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authNotifierProvider.notifier).signInWithFacebook();
      if (mounted && _isSignedIn(FirebaseAuth.instance.currentUser)) {
        widget.onAuthSuccess?.call();
      }
    } catch (e) {
      _showAuthError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailSignIn() async {
    HapticFeedback.mediumImpact();
    // The email sheet closes itself after signing in. Nothing told this screen,
    // so someone who had just signed in was left looking at its sign-in
    // buttons, and tapping sync again brought them straight back here.
    await AuthModal.show(context);
    if (!mounted) return;
    if (_isSignedIn(FirebaseAuth.instance.currentUser)) {
      widget.onAuthSuccess?.call();
    }
  }

  /// What went wrong, in the user's language; nothing for a cancel, which
  /// was reported as a failure.
  void _showAuthError(Object e) {
    if (!mounted) return;
    final message = authErrorMessage(AppLocalizations.of(context)!, e);
    if (message == null) return;
    showAppToastOf(context, kind: ToastKind.error, title: message);
  }

  /// A guest session is a signed-in Firebase user too; only a real account
  /// counts. Checking for any user closed this screen as though sign-in had
  /// worked when Google or Facebook sign-in was cancelled.
  bool _isSignedIn(User? user) => user != null && !user.isAnonymous;

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
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),

                // A cloud that draws itself, with a meal, a weigh-in and a
                // photo drifting up into it.
                const _BackupCloudArt(),

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
                          AppLocalizations.of(context)!.sync_title,
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
                        AppLocalizations.of(context)!.sync_subtitle,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_buildBenefits(context).length, (
                      index,
                    ) {
                      return AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _benefitSlides[index],
                            child: Opacity(
                              opacity: _benefitAnimations[index].value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _buildBenefits(context)[index].icon,
                                        color: colorScheme.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        _buildBenefits(context)[index].text,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: context.textPrimaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // A tick lands once the row is in.
                                    _BenefitTick(
                                      t: _benefitTicks[index].value,
                                      color: colorScheme.primary,
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
                    // The buttons rise into place as they appear.
                    return Transform.translate(
                      offset: Offset(0, 24 * (1 - _buttonsOpacity.value)),
                      child: Opacity(
                        opacity: _buttonsOpacity.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Google Sign In
                            _AuthButton(
                              label: AppLocalizations.of(context)!.sync_google,
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _AuthButton(
                                    label:
                                        AppLocalizations.of(
                                          context,
                                        )!.sync_facebook,
                                    icon: FontAwesomeIcons.facebook,
                                    onPressed: _handleFacebookSignIn,
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: context.textPrimaryColor,
                                    isFaIcon: true,
                                  ),
                                  Divider(
                                    height: 1,
                                    color: context.dividerColor.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  _AuthButton(
                                    label:
                                        AppLocalizations.of(
                                          context,
                                        )!.sync_email,
                                    icon: WaznIcons.mail,
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
                                  AppLocalizations.of(context)!.sync_skip,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: context.textMutedColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
  final bool isFaIcon;
  final bool isLoading;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
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
          boxShadow:
              isAccent
                  ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.35),
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
              // Shrinks rather than running off a narrow button.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.titleSmall.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
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

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
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
      // Without opaque, the hit area is whatever the child paints -- for the
      // Skip control that is a single line of text, about 20dp tall.
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String text;
  _Benefit({required this.icon, required this.text});
}

/// A benefit's tick, popping in and drawing itself as [t] runs 0 to 1.
class _BenefitTick extends StatelessWidget {
  const _BenefitTick({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: t.clamp(0.0, 1.2),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: CustomPaint(
          painter: _TickPainter(
            progress: ((t - .3) / .7).clamp(0.0, 1.0),
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path =
        Path()
          ..moveTo(size.width * .28, size.height * .52)
          ..lineTo(size.width * .44, size.height * .67)
          ..lineTo(size.width * .73, size.height * .36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.progress != progress || old.color != color;
}

/// The cloud at the top: its outline draws itself, it fills, an upload
/// arrow springs up inside, and a meal, a weigh-in and a photo drift up into
/// it one after another. Then it floats gently.
class _BackupCloudArt extends StatefulWidget {
  const _BackupCloudArt();

  @override
  State<_BackupCloudArt> createState() => _BackupCloudArtState();
}

class _BackupCloudArtState extends State<_BackupCloudArt>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _enter.value = 1;
      return;
    }
    _enter.forward().whenComplete(() {
      if (mounted) _float.repeat();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const items = [WaznIcons.lunch, WaznIcons.weight, WaznIcons.camera];
    return SizedBox(
      width: 180,
      height: 140,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _float]),
        builder: (context, _) {
          final t = _enter.value;
          double part(double a, double b, [Curve c = Curves.linear]) =>
              c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
          final bob = math.sin(_float.value * math.pi * 2) * 3;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, bob - 8),
                child: CustomPaint(
                  size: const Size(150, 110),
                  painter: _CloudPainter(
                    outline: part(0, .4, Curves.easeInOut),
                    fill: part(.25, .5),
                    arrow: part(.35, .55, AppMotion.springCurve),
                    color: primary,
                  ),
                ),
              ),
              // Three things drifting up into the cloud.
              for (var i = 0; i < items.length; i++)
                Builder(
                  builder: (context) {
                    final p = part(.35 + i * .12, .75 + i * .08);
                    if (p <= 0 || p >= 1) return const SizedBox.shrink();
                    final x = (i - 1) * 56.0 * (1 - p);
                    final y = 62 - 70 * Curves.easeInOut.transform(p);
                    final opacity =
                        p < .2 ? p / .2 : (p > .75 ? (1 - p) / .25 : 1.0);
                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 1 - .45 * p,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(items[i], size: 17, color: primary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter({
    required this.outline,
    required this.fill,
    required this.arrow,
    required this.color,
  });

  final double outline;
  final double fill;
  final double arrow;
  final Color color;

  Path _cloud(Size s) {
    final w = s.width / 150, h = s.height / 110;
    return Path()
      ..moveTo(40 * w, 92 * h)
      ..arcToPoint(
        Offset(37 * w, 40.2 * h),
        radius: Radius.elliptical(26 * w, 26 * h),
      )
      ..arcToPoint(
        Offset(102 * w, 30 * h),
        radius: Radius.elliptical(34 * w, 34 * h),
      )
      ..arcToPoint(
        Offset(114 * w, 92 * h),
        radius: Radius.elliptical(24 * w, 24 * h),
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = _cloud(size);
    if (fill > 0) {
      canvas.drawPath(
        cloud,
        Paint()..color = color.withValues(alpha: 0.14 * fill),
      );
    }
    final stroke =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    if (outline > 0) {
      for (final metric in cloud.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * outline), stroke);
      }
    }
    if (arrow > 0) {
      final cx = size.width / 2, base = size.height * .7;
      final top = base - 26 * arrow;
      canvas.drawLine(Offset(cx, base), Offset(cx, top), stroke);
      canvas.drawLine(Offset(cx - 11, top + 11), Offset(cx, top), stroke);
      canvas.drawLine(Offset(cx + 11, top + 11), Offset(cx, top), stroke);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) =>
      old.outline != outline ||
      old.fill != fill ||
      old.arrow != arrow ||
      old.color != color;
}
