import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_state_provider.dart';
import 'welcome_scan_demo.dart';

class WelcomeStep extends ConsumerStatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomeStep({super.key, required this.onGetStarted});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep>
    with SingleTickerProviderStateMixin {
  bool _scanComplete = false;
  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  Animation<Offset>? _textSlide;

  @override
  void initState() {
    super.initState();
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _onScanComplete() {
    if (mounted) {
      setState(() => _scanComplete = true);
      _textCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 4),
        WelcomeScanDemo(onScanComplete: _onScanComplete),
        const SizedBox(height: 22),
        // Title and CTA — fade in only after scan completes
        SlideTransition(
          position: _textSlide ?? const AlwaysStoppedAnimation(Offset.zero),
          child: FadeTransition(
            opacity: _textFade,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors:
                            context.isDarkMode
                                ? [
                                  Colors.white,
                                  context.primaryColor.withValues(alpha: 0.7),
                                ]
                                : [
                                  context.textPrimaryColor,
                                  context.primaryColor.withValues(alpha: 0.6),
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                  child: Text(
                    l10n.onboarding_welcome_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l10n.onboarding_welcome_body,
                    style: TextStyle(
                      color: context.textSecondaryColor.withValues(alpha: 0.92),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.42,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: _ScanButton(
                    enabled: _scanComplete,
                    text: l10n.onboarding_get_started,
                    onTap: widget.onGetStarted,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    if (!ref.watch(isAnonymousProvider)) return const SizedBox.shrink();
                    return _AuthLinkButton(
                      text: l10n.onboarding_already_account,
                      onTap: () => context.push('/auth'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _AuthLinkButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.055)
                  : Colors.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.95),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppSymbols.userCircle2,
              size: 16,
              color: context.primaryColor.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: context.textPrimaryColor.withValues(alpha: 0.82),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              AppSymbols.chevronRight,
              size: 15,
              color: context.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatefulWidget {
  final bool enabled;
  final String text;
  final VoidCallback onTap;

  const _ScanButton({
    required this.enabled,
    required this.text,
    required this.onTap,
  });

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.985,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enabled) _scaleCtrl.reverse();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.enabled) {
      _scaleCtrl.forward();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) _scaleCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                widget.enabled
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
            gradient: widget.enabled ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  widget.enabled
                      ? Colors.white.withValues(alpha: isDark ? 0.16 : 0.22)
                      : Colors.transparent,
            ),
            boxShadow:
                widget.enabled
                    ? [
                      BoxShadow(
                        color: context.primaryColor.withValues(
                          alpha: isDark ? 0.34 : 0.24,
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppColors.tertiarySeed.withValues(
                          alpha: isDark ? 0.20 : 0.14,
                        ),
                        blurRadius: 32,
                        offset: const Offset(10, 14),
                      ),
                    ]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                if (widget.enabled)
                  Positioned(
                    top: 0,
                    left: 18,
                    right: 18,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.text,
                        style: TextStyle(
                          color:
                              widget.enabled
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.2)),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(
                        AppSymbols.arrowRight,
                        color:
                            widget.enabled
                                ? Colors.white
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.2)),
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
