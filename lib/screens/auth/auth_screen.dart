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
      _staggeredAnims = List.generate(
        count,
        (index) => CurvedAnimation(
          parent: _animController,
          curve: Interval(
            index * 0.08,
            (index * 0.08 + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
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
          style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
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
    HapticFeedback.mediumImpact();
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.signInWithGoogle();
      if (auth.isAuthenticated) _onAuthSuccess();
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
        await auth.registerWithEmail(_emailController.text.trim(), _passwordController.text);
      } else {
        await auth.signInWithEmail(_emailController.text.trim(), _passwordController.text);
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
    if (auth.isAuthenticated && !auth.isAnonymous && !_googleLoading && !_facebookLoading && !_emailLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/settings');
      });
    }

    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFCFCF9),
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
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.leaf, color: AppColors.primary, size: 32),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Title ──
                  _StaggeredFade(
                    animation: _staggeredAnims![1],
                    child: Text(
                      _isSignUp ? "Create your account" : "Welcome back",
                      style: AppTypography.displaySmall.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Social Buttons Stack ──
                  _StaggeredFade(
                    animation: _staggeredAnims![2],
                    child: _AuthSocialButton(
                      label: "Continue with Google",
                      icon: FontAwesomeIcons.google,
                      isLoading: _googleLoading,
                      onTap: _handleGoogle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StaggeredFade(
                    animation: _staggeredAnims![3],
                    child: _AuthSocialButton(
                      label: "Continue with Facebook",
                      icon: FontAwesomeIcons.facebook,
                      isLoading: _facebookLoading,
                      onTap: _handleFacebook,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Divider ──
                  _StaggeredFade(
                    animation: _staggeredAnims![4],
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: context.dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR",
                            style: AppTypography.labelSmall.copyWith(color: context.textMutedColor),
                          ),
                        ),
                        Expanded(child: Divider(color: context.dividerColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Email Form ──
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _StaggeredFade(
                          animation: _staggeredAnims![5],
                          child: _AuthTextField(
                            controller: _emailController,
                            hint: "Email address",
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StaggeredFade(
                          animation: _staggeredAnims![6],
                          child: _AuthTextField(
                            controller: _passwordController,
                            hint: "Password",
                            isPassword: true,
                            showPassword: _showPassword,
                            onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _StaggeredFade(
                          animation: _staggeredAnims![7],
                          child: AppScaleTap(
                            onTap: _emailLoading ? () {} : _handleEmailSubmit,
                            child: Container(
                              height: 54,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _emailLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: isDark ? Colors.black : Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Continue",
                                        style: AppTypography.titleMedium.copyWith(
                                          color: isDark ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Footer ──
                  _StaggeredFade(
                    animation: _staggeredAnims![8],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? "Already have an account? " : "Don't have an account? ",
                          style: AppTypography.bodyMedium.copyWith(color: context.textSecondaryColor),
                        ),
                        AppScaleTap(
                          onTap: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? "Log in" : "Sign up",
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
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
  final dynamic icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _AuthSocialButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return AppScaleTap(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!,
          ),
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
              FaIcon(icon as FaIconData?, size: 18, color: isDark ? Colors.white : Colors.black),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !(showPassword ?? false),
        keyboardType: keyboardType,
        style: AppTypography.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyLarge.copyWith(color: context.textMutedColor),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    (showPassword ?? false) ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                    color: context.textMutedColor,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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


