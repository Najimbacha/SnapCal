import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// ============================================================================
/// SNAPCAL AUTHENTICATION SCREEN
/// ============================================================================
/// A clean, premium, responsive authentication screen supporting:
/// - Light & Dark mode (same UI style, adapted colors)
/// - Google, Facebook, Email, and Anonymous Firebase sign-in
/// - Material 3 design principles
/// - Micro-interactions for enhanced UX
/// ============================================================================

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine if we're in dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define theme-aware colors - SAME STYLE, different palette
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor = AppColors.primary; // Unified emerald accent
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ========== APP LOGO ==========
                    _AppLogo(
                      isDark: isDark,
                      cardColor: cardColor,
                      accentColor: accentColor,
                    ),

                    const SizedBox(height: 40),

                    // ========== HEADLINE ==========
                    Text(
                      'Welcome to Snapcal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // ========== SUBTITLE ==========
                    Text(
                      'Sign in to track your calories and nutrition easily.',
                      style: TextStyle(
                        fontSize: 15,
                        color: textSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // ========== SIGN-IN BUTTONS ==========
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        final isLoading = auth.status == AuthStatus.loading;

                        return Column(
                          children: [
                            // Google Sign-In
                            _AuthButton(
                              label: 'Continue with Google',
                              icon: FontAwesomeIcons.google,
                              backgroundColor: cardColor,
                              foregroundColor: textPrimary,
                              iconColor: const Color(0xFFEA4335),
                              borderColor: borderColor,
                              isLoading: isLoading,
                              onPressed:
                                  () => _handleSignIn(
                                    context,
                                    () => auth.signInWithGoogle(),
                                  ),
                            ),

                            const SizedBox(height: 16),

                            // Facebook Sign-In
                            _AuthButton(
                              label: 'Continue with Facebook',
                              icon: FontAwesomeIcons.facebookF,
                              backgroundColor: const Color(0xFF1877F2),
                              foregroundColor: Colors.white,
                              iconColor: Colors.white,
                              isLoading: isLoading,
                              onPressed:
                                  () => _handleSignIn(
                                    context,
                                    () => auth.signInWithFacebook(),
                                  ),
                            ),

                            const SizedBox(height: 16),

                            // Email Sign-In
                            _AuthButton(
                              label: 'Continue with Email',
                              icon: Icons.email_outlined,
                              backgroundColor: cardColor,
                              foregroundColor: textPrimary,
                              iconColor: accentColor,
                              borderColor: borderColor,
                              isLoading: isLoading,
                              onPressed: () => _navigateToEmailAuth(context),
                              isIconData: true,
                            ),

                            const SizedBox(height: 16),

                            // Anonymous/Guest Sign-In
                            _AuthButton(
                              label: 'Continue as Guest',
                              icon: Icons.person_outline_rounded,
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF1E293B).withOpacity(0.5)
                                      : const Color(0xFFF1F5F9),
                              foregroundColor: textSecondary,
                              iconColor: textSecondary,
                              borderColor: borderColor,
                              isLoading: isLoading,
                              onPressed:
                                  () => _handleSignIn(
                                    context,
                                    () => auth.signInAnonymously(),
                                  ),
                              isIconData: true,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // ========== FOOTER TEXT ==========
                    Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary.withOpacity(0.7),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the sign-in process with loading state
  Future<void> _handleSignIn(
    BuildContext context,
    Future<void> Function() signInMethod,
  ) async {
    HapticFeedback.lightImpact();
    try {
      await signInMethod();
      if (context.mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.isAuthenticated) {
          context.go('/');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  /// Navigates to email authentication screen
  void _navigateToEmailAuth(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _EmailAuthSheet(),
    );
  }

  /// Displays an error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// =============================================================================
// APP LOGO WIDGET
// =============================================================================
class _AppLogo extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color accentColor;

  const _AppLogo({
    required this.isDark,
    required this.cardColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? accentColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon/icon.png',
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// =============================================================================
// AUTH BUTTON WIDGET
// =============================================================================
class _AuthButton extends StatefulWidget {
  final String label;
  final dynamic icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isIconData;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    this.borderColor,
    required this.isLoading,
    required this.onPressed,
    this.isIconData = false,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : _onTapDown,
      onTapUp: widget.isLoading ? null : _onTapUp,
      onTapCancel: widget.isLoading ? null : _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border:
                    widget.borderColor != null
                        ? Border.all(color: widget.borderColor!, width: 1)
                        : null,
                boxShadow: [
                  BoxShadow(
                    color:
                        widget.backgroundColor == const Color(0xFF1877F2)
                            ? const Color(0xFF1877F2).withOpacity(0.3)
                            : Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.isIconData
                      ? Icon(
                        widget.icon as IconData,
                        size: 20,
                        color: widget.iconColor,
                      )
                      : FaIcon(
                        widget.icon as IconData,
                        size: 18,
                        color: widget.iconColor,
                      ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.foregroundColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// EMAIL AUTH BOTTOM SHEET
// =============================================================================
class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet();

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    try {
      if (_isLogin) {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await auth.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (mounted && auth.isAuthenticated) {
        Navigator.pop(context);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Same style, adapted colors
    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor = const Color(0xFF3B82F6);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pull Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              _isLogin ? 'Sign In' : 'Create Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Email address',
                hintStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Email is required';
                if (!val.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: textSecondary,
                    size: 20,
                  ),
                  onPressed:
                      () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Password is required';
                if (val.length < 6)
                  return 'Password must be at least 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Submit Button
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final isLoading = auth.status == AuthStatus.loading;
                return GestureDetector(
                  onTap: isLoading ? null : _handleSubmit,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Toggle Sign In / Sign Up
            GestureDetector(
              onTap: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? "Don't have an account? Sign Up"
                    : "Already have an account? Sign In",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
