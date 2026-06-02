import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_blocks.dart';
import '../../l10n/generated/app_localizations.dart';

const _minimalBg = Color(0xFFF9F8F5);
const _minimalDarkBg = Color(0xFF14130F);
const _minimalInk = Color(0xFF1C1917);
const _minimalLine = Color(0xFFE8E4DC);
const _minimalGreen = Color(0xFF1A3D2B);
const _minimalGreenText = Color(0xFF16733A);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _showPassword = false;
  bool _googleLoading = false;
  bool _facebookLoading = false;
  bool _emailLoading = false;
  bool _showEmailForm = false;

  late final AnimationController _animController;
  List<Animation<double>>? _staggeredAnims;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController.forward();
  }

  void _ensureAnims(int count) {
    if (_staggeredAnims == null || _staggeredAnims!.length < count) {
      _staggeredAnims = List.generate(count, (index) {
        final start = (index * 0.08).clamp(0.0, 1.0);
        final end = (start + 0.4).clamp(0.0, 1.0);
        return CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showStyledSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  void _onAuthSuccess() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    context.go('/settings');
  }

  Future<void> _handleGoogle() async {
    if (_googleLoading) return;
    debugPrint('🔑 AuthScreen: Google button tapped');
    HapticFeedback.mediumImpact();
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.signInWithGoogle();
      if (auth.isAuthenticated && !auth.isAnonymous) {
        _onAuthSuccess();
      } else if (auth.errorMessage != null && auth.errorMessage!.isNotEmpty) {
        _showStyledSnackBar(auth.errorMessage!);
      }
    } catch (e) {
      _showStyledSnackBar('$e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleFacebook() async {
    HapticFeedback.mediumImpact();
    setState(() => _facebookLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.signInWithFacebook();
      if (auth.isAuthenticated) _onAuthSuccess();
    } catch (e) {
      _showStyledSnackBar('$e');
    } finally {
      if (mounted) setState(() => _facebookLoading = false);
    }
  }

  Future<void> _handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _emailLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      if (_isSignUp) {
        await auth.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (auth.isAuthenticated) _onAuthSuccess();
    } catch (e) {
      _showStyledSnackBar('$e');
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureAnims(10);

    // Failsafe Redirection for logged-in users
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated &&
        !auth.isAnonymous &&
        !_googleLoading &&
        !_facebookLoading &&
        !_emailLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/settings');
      });
    }

    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? _minimalDarkBg : _minimalBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  _StaggeredFade(
                    animation: _staggeredAnims![0],
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _minimalGreen.withValues(
                          alpha: isDark ? 0.18 : 0.08,
                        ),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : _minimalLine,
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/icon.png',
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Title ──
                  _StaggeredFade(
                    animation: _staggeredAnims![1],
                    child: Text(
                      _showEmailForm
                          ? (_isSignUp
                              ? l10n.auth_create_account
                              : l10n.auth_welcome_back_title)
                          : l10n.auth_lets_dive,
                      style: AppTypography.displayMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StaggeredFade(
                    animation: _staggeredAnims![1],
                    child: Text(
                      l10n.auth_intro_body,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Auth Options ──
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                    child:
                        _showEmailForm
                            ? Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _StaggeredFade(
                                    animation: _staggeredAnims![5],
                                    child: _AuthTextField(
                                      controller: _emailController,
                                      hint: l10n.auth_hint_email,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _StaggeredFade(
                                    animation: _staggeredAnims![6],
                                    child: _AuthTextField(
                                      controller: _passwordController,
                                      hint: l10n.auth_hint_password,
                                      isPassword: true,
                                      showPassword: _showPassword,
                                      onTogglePassword:
                                          () => setState(
                                            () =>
                                                _showPassword = !_showPassword,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _StaggeredFade(
                                    animation: _staggeredAnims![7],
                                    child: AppScaleTap(
                                      onTap:
                                          _emailLoading
                                              ? () {}
                                              : _handleEmailSubmit,
                                      child: Container(
                                        height: 54,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? Colors.white.withValues(
                                                    alpha: 0.10,
                                                  )
                                                  : _minimalGreen,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Center(
                                          child:
                                              _emailLoading
                                                  ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color:
                                                              isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : Text(
                                                    _isSignUp
                                                        ? l10n
                                                            .auth_sign_up_short
                                                        : l10n.auth_log_in,
                                                    style: AppTypography
                                                        .titleMedium
                                                        .copyWith(
                                                          color:
                                                              isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // ── Footer ──
                                  _StaggeredFade(
                                    animation: _staggeredAnims![8],
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isSignUp
                                              ? l10n.auth_have_account
                                              : l10n.auth_no_account,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color:
                                                    context.textSecondaryColor,
                                              ),
                                        ),
                                        AppScaleTap(
                                          onTap:
                                              () => setState(
                                                () => _isSignUp = !_isSignUp,
                                              ),
                                          child: Text(
                                            _isSignUp
                                                ? l10n.auth_log_in
                                                : l10n.auth_sign_up_short,
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                                  color: _minimalGreenText,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextButton(
                                    onPressed:
                                        () => setState(
                                          () => _showEmailForm = false,
                                        ),
                                    child: Text(
                                      l10n.auth_back_to_social,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: context.textMutedColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Column(
                              children: [
                                // ── Google (Primary) ──
                                _StaggeredFade(
                                  animation: _staggeredAnims![2],
                                  child: _AuthSocialButton(
                                    label: l10n.sync_google,
                                    backgroundColor:
                                        isDark ? Colors.white : Colors.white,
                                    textColor: Colors.black,
                                    borderColor: Colors.transparent,
                                    iconWidget: Image.asset(
                                      'assets/images/google_logo.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    isLoading: _googleLoading,
                                    onTap: _handleGoogle,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Divider ──
                                _StaggeredFade(
                                  animation: _staggeredAnims![3],
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: context.dividerColor
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          l10n.common_or,
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: context.textMutedColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: context.dividerColor
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Secondary Actions (Facebook & Email) ──
                                _StaggeredFade(
                                  animation: _staggeredAnims![4],
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _AuthSocialButton(
                                          label: l10n.sync_facebook,
                                          backgroundColor: const Color(
                                            0x00FFFFFF,
                                          ),
                                          textColor:
                                              isDark
                                                  ? Colors.white
                                                  : _minimalInk,
                                          borderColor:
                                              isDark
                                                  ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                  : _minimalLine,
                                          iconWidget: const FaIcon(
                                            FontAwesomeIcons.facebookF,
                                            size: 16,
                                            color: _minimalGreenText,
                                          ),
                                          isLoading: _facebookLoading,
                                          onTap: _handleFacebook,
                                          small: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AuthSocialButton(
                                          label: l10n.sync_email,
                                          backgroundColor:
                                              isDark
                                                  ? Colors.white.withValues(
                                                    alpha: 0.05,
                                                  )
                                                  : const Color(0x00FFFFFF),
                                          textColor:
                                              isDark
                                                  ? Colors.white
                                                  : _minimalInk,
                                          borderColor:
                                              isDark
                                                  ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                  : _minimalLine,
                                          iconWidget: Icon(
                                            LucideIcons.mail,
                                            size: 16,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : _minimalGreenText,
                                          ),
                                          isLoading: false,
                                          onTap:
                                              () => setState(() {
                                                _showEmailForm = true;
                                                _isSignUp = false;
                                              }),
                                          small: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthSocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final bool isLoading;
  final VoidCallback onTap;
  final bool small;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const _AuthSocialButton({
    required this.label,
    required this.iconWidget,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.isLoading = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final radius = BorderRadius.circular(100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: radius,
        child: Ink(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: small ? 8 : 16),
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0x00FFFFFF)),
            borderRadius: radius,
            border: Border.all(
              color:
                  borderColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : _minimalLine),
            ),
            boxShadow: null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                iconWidget,
                if (!small) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: AppTypography.titleSmall.copyWith(
                          color:
                              textColor ??
                              (isDark ? Colors.white : _minimalInk),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: AppTypography.labelLarge.copyWith(
                          color:
                              textColor ??
                              (isDark ? Colors.white : _minimalInk),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isPassword;
  final bool? showPassword;
  final VoidCallback? onTogglePassword;
  final TextInputType? keyboardType;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.showPassword,
    this.onTogglePassword,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0x00FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : _minimalLine,
        ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !(showPassword ?? false),
        keyboardType: keyboardType,
        style: AppTypography.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: context.textMutedColor,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      (showPassword ?? false)
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye,
                      size: 18,
                      color: context.textMutedColor,
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _StaggeredFade extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _StaggeredFade({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
