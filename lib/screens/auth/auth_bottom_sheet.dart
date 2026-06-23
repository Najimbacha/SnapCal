import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_notifier_provider.dart';
import '../../widgets/ui_blocks.dart';
import '../../l10n/generated/app_localizations.dart';

const _minimalBg = Color(0xFFF9F8F5);
const _minimalDarkBg = Color(0xFF14130F);
const _minimalInk = Color(0xFF1C1917);
const _minimalLine = Color(0xFFE8E4DC);
const _minimalGreen = Color(0xFF1A3D2B);
const _minimalGreenText = Color(0xFF16733A);

class AuthBottomSheet extends ConsumerStatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  ConsumerState<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends ConsumerState<AuthBottomSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _showPassword = false;
  bool _googleLoading = false;
  bool _facebookLoading = false;
  bool _emailLoading = false;
  bool _showEmailForm = false;
  bool _isPopped = false;

  late final AnimationController _animController;
  List<Animation<double>>? _staggeredAnims;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('timeout') || msg.contains('SocketException')) {
      return 'Connection error. Please check your internet and try again.';
    }
    if (msg.contains('wrong-password') || msg.contains('invalid-email') || msg.contains('user-not-found') || msg.contains('invalid-credential')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('too-many-requests') || msg.contains('rate-limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('weak-password')) {
      return 'Password is too weak. Use at least 8 characters with a mix of letters and numbers.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _onAuthSuccess() {
    if (!mounted || _isPopped) return;
    _isPopped = true;
    HapticFeedback.heavyImpact();
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Dismiss the half-screen bottom sheet
    }
  }

  Future<void> _handleGoogle() async {
    if (_googleLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _googleLoading = true);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    try {
      await authNotifier.signInWithGoogle();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        _onAuthSuccess();
      } else if (ref.read(authNotifierProvider).hasError) {
        _showStyledSnackBar('Sign in failed. Please try again.');
      }
    } catch (e) {
      _showStyledSnackBar(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleFacebook() async {
    HapticFeedback.mediumImpact();
    setState(() => _facebookLoading = true);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    try {
      await authNotifier.signInWithFacebook();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) _onAuthSuccess();
    } catch (e) {
      _showStyledSnackBar(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _facebookLoading = false);
    }
  }

  Future<void> _handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _emailLoading = true);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    try {
      if (_isSignUp) {
        await authNotifier.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authNotifier.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) _onAuthSuccess();
    } catch (e) {
      _showStyledSnackBar(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureAnims(10);
    final isDark = context.isDarkMode;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final l10n = AppLocalizations.of(context)!;

    // Authentication is handled via direct listeners and action buttons.

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _minimalDarkBg : _minimalBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : _minimalLine,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 14,
                bottom: 24 + viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag indicator
                  Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header icon
                  _StaggeredFade(
                    animation: _staggeredAnims![0],
                    child: Container(
                      width: 60,
                      height: 60,
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
                          width: 1.2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/icon.png',
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          cacheWidth: 80,
                          cacheHeight: 80,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title and Subtitle
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
                        letterSpacing: -1.0,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 28),

                  // Form & Social flow
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
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
                                  const SizedBox(height: 12),
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
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (value.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _StaggeredFade(
                                    animation: _staggeredAnims![7],
                                    child: AppScaleTap(
                                      onTap:
                                          _emailLoading
                                              ? () {}
                                              : _handleEmailSubmit,
                                      child: Container(
                                        height: 52,
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
                                                    width: 18,
                                                    height: 18,
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
                                  const SizedBox(height: 20),
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
                                  const SizedBox(height: 16),
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
                                _StaggeredFade(
                                  animation: _staggeredAnims![2],
                                  child: _AuthSocialButton(
                                    label: l10n.sync_google,
                                    backgroundColor: Colors.white,
                                    textColor: Colors.black,
                                    borderColor: Colors.transparent,
                                    iconWidget: Image.asset(
                                      'assets/images/google_logo.png',
                                      width: 18,
                                      height: 18,
                                      cacheWidth: 120,
                                      cacheHeight: 40,
                                    ),
                                    isLoading: _googleLoading,
                                    onTap: _handleGoogle,
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                          horizontal: 14,
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
                                const SizedBox(height: 12),
                                _StaggeredFade(
                                  animation: _staggeredAnims![3],
                                  child: _AuthSocialButton(
                                    label: l10n.sync_facebook,
                                    backgroundColor: const Color(0x00FFFFFF),
                                    textColor:
                                        isDark ? Colors.white : _minimalInk,
                                    borderColor:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.08,
                                            )
                                            : _minimalLine,
                                    iconWidget: const FaIcon(
                                      FontAwesomeIcons.facebookF,
                                      size: 14,
                                      color: _minimalGreenText,
                                    ),
                                    isLoading: _facebookLoading,
                                    onTap: _handleFacebook,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _StaggeredFade(
                                  animation: _staggeredAnims![4],
                                  child: _AuthSocialButton(
                                    label: l10n.sync_email,
                                    backgroundColor:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.05,
                                            )
                                            : const Color(0x00FFFFFF),
                                    textColor:
                                        isDark ? Colors.white : _minimalInk,
                                    borderColor:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.08,
                                            )
                                            : _minimalLine,
                                    iconWidget: Icon(
                                      LucideIcons.mail,
                                      size: 14,
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
                                  ),
                                ),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final bool isLoading;
  final VoidCallback onTap;
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
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                iconWidget,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.titleSmall.copyWith(
                      color: textColor ?? (isDark ? Colors.white : _minimalInk),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
  final String? Function(String?)? validator;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.showPassword,
    this.onTogglePassword,
    this.keyboardType,
    this.validator,
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
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !(showPassword ?? false),
        keyboardType: keyboardType,
        validator: validator,
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
            vertical: 14,
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
