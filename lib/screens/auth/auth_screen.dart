import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/app_page_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _showPassword = false;
  bool _googleLoading = false;
  bool _facebookLoading = false;
  bool _emailLoading = false;

  AnimationController? _animController;
  List<Animation<double>>? _staggeredAnims;

  void _ensureAnims() {
    if (_animController == null) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _animController!.forward();
    }
    if (_staggeredAnims == null) {
      _staggeredAnims = List.generate(
        6,
        (index) => CurvedAnimation(
          parent: _animController!,
          curve: Interval(index * 0.1, (index * 0.1 + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutQuart),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureAnims();
    
    // Failsafe: Listen for auth changes and exit if authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && !auth.isAnonymous) {
        context.go('/settings');
      }
    });
  }

  @override
  void dispose() {
    _animController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showStyledSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _onAuthSuccess() {
    if (!mounted) return;
    
    HapticFeedback.heavyImpact();
    
    final name = context.read<AuthProvider>().user?.displayName;
    _showStyledSnackBar(
      name != null ? 'Welcome back, $name!' : 'Login successful!',
      isError: false,
    );

    context.go('/settings');
  }

  Future<void> _handleGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();
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
    auth.clearError();
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
    auth.clearError();
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

  Future<void> _handleGuest() async {
    HapticFeedback.mediumImpact();
    setState(() => _emailLoading = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();
    try {
      await auth.signInAnonymously();
      if (auth.isAuthenticated) _onAuthSuccess();
    } catch (e) {
      _showStyledSnackBar('$e');
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureAnims();
    
    // Hard-Redirection Failsafe: If we are here but already logged in, GET OUT.
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated && !auth.isAnonymous && !_googleLoading && !_facebookLoading && !_emailLoading) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) context.go('/settings');
       });
    }

    final isDark = context.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // ── Background Glows (Subtle) ──
          Positioned(
            top: -100,
            left: -50,
            child: _AmbientCircle(color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08), size: 400),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _AmbientCircle(color: AppColors.secondarySeed.withValues(alpha: isDark ? 0.08 : 0.04), size: 350),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: false,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Center(
                      child: IconButton(
                        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                        icon: const Icon(Icons.close_rounded, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _handleGuest,
                      child: Text('Skip', style: AppTypography.titleSmall.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        // ── Header ──
                        _StaggeredFade(
                          animation: _staggeredAnims![0],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Journey\nStarts Here',
                                style: AppTypography.heading2.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -1.0,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Scan, Track, and Master your nutrition in seconds.',
                                style: AppTypography.bodyLarge.copyWith(color: context.textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Social Buttons Section ──
                        _StaggeredFade(
                          animation: _staggeredAnims![1],
                          child: AppSectionCard(
                            glass: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _MainSocialButton(
                                  iconWidget: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437), size: 18),
                                  label: 'Continue with Google',
                                  color: Colors.white,
                                  textColor: Colors.black,
                                  isLoading: _googleLoading,
                                  onTap: _handleGoogle,
                                ),
                                const SizedBox(height: 12),
                                _MainSocialButton(
                                  iconWidget: const FaIcon(FontAwesomeIcons.facebook, color: Colors.white, size: 18),
                                  label: 'Continue with Facebook',
                                  color: const Color(0xFF1877F2),
                                  textColor: Colors.white,
                                  isLoading: _facebookLoading,
                                  onTap: _handleFacebook,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Divider ──
                        _StaggeredFade(
                          animation: _staggeredAnims![3],
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: SectionLabel(title: 'Or use email'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Email Form Section ──
                        _StaggeredFade(
                          animation: _staggeredAnims![4],
                          child: AppSectionCard(
                            glass: true,
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _AuthTextField(
                                    controller: _emailController,
                                    hint: 'Email Address',
                                    icon: LucideIcons.mail,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  _AuthTextField(
                                    controller: _passwordController,
                                    hint: 'Password',
                                    icon: LucideIcons.lock,
                                    isPassword: true,
                                    showPassword: _showPassword,
                                    onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                                  ),
                                  const SizedBox(height: 20),
                                  AppScaleTap(
                                    onTap: _emailLoading ? () {} : _handleEmailSubmit,
                                    child: Container(
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.25),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _emailLoading
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : Text(
                                                _isSignUp ? 'Create My Account' : 'Sign In with Email',
                                                style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),

                        // ── Footer ──
                        _StaggeredFade(
                          animation: _staggeredAnims![5],
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24, top: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isSignUp ? 'Already a member? ' : 'New to SnapCal? ', style: AppTypography.bodyMedium.copyWith(color: context.textSecondaryColor)),
                                GestureDetector(
                                  onTap: () => setState(() => _isSignUp = !_isSignUp),
                                  child: Text(_isSignUp ? 'Sign In' : 'Join Now', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainSocialButton extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _MainSocialButton({
    required this.iconWidget,
    required this.label,
    required this.color,
    required this.textColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: color == Colors.white ? Border.all(color: Colors.black.withValues(alpha: 0.1)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: textColor, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Text(label, style: AppTypography.titleSmall.copyWith(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
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
  final IconData icon;
  final bool isPassword;
  final bool? showPassword;
  final VoidCallback? onTogglePassword;
  final TextInputType? keyboardType;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.showPassword,
    this.onTogglePassword,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !(showPassword ?? false),
        keyboardType: keyboardType,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(color: context.textMutedColor),
          prefixIcon: Icon(icon, size: 18, color: context.textSecondaryColor),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon((showPassword ?? false) ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: context.textMutedColor),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
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
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}
