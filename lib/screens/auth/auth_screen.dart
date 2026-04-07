import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_blocks.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: context.primaryGradient),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.overlayColor),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      AppSectionCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset('assets/icon/icon.png'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome to SnapCal',
                              style: AppTypography.heading1.copyWith(
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Save your meals, sync your progress, and keep the experience simple across devices.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                final isLoading =
                                    auth.status == AuthStatus.loading;
                                return Column(
                                  children: [
                                    _AuthButton(
                                      label: 'Continue with Google',
                                      icon: FontAwesomeIcons.google,
                                      onPressed:
                                          () => _handleSignIn(
                                            context,
                                            () => auth.signInWithGoogle(),
                                          ),
                                      loading: isLoading,
                                    ),
                                    const SizedBox(height: 12),
                                    _AuthButton(
                                      label: 'Continue with Facebook',
                                      icon: FontAwesomeIcons.facebookF,
                                      onPressed:
                                          () => _handleSignIn(
                                            context,
                                            () => auth.signInWithFacebook(),
                                          ),
                                      loading: isLoading,
                                    ),
                                    const SizedBox(height: 12),
                                    _AuthButton(
                                      label: 'Continue with Email',
                                      icon: Icons.email_outlined,
                                      onPressed: () => _openEmailSheet(context),
                                      loading: isLoading,
                                      iconIsMaterial: true,
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed:
                                          () => _handleSignIn(
                                            context,
                                            () => auth.signInAnonymously(),
                                          ),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(54),
                                      ),
                                      child: const Text('Continue as Guest'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'By continuing, you agree to the Terms of Service and Privacy Policy.',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn(
    BuildContext context,
    Future<void> Function() signInMethod,
  ) async {
    HapticFeedback.lightImpact();
    try {
      await signInMethod();
      if (context.mounted && context.read<AuthProvider>().isAuthenticated) {
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _openEmailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EmailAuthSheet(),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final dynamic icon;
  final VoidCallback onPressed;
  final bool loading;
  final bool iconIsMaterial;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.loading,
    this.iconIsMaterial = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: context.cardSoftColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (iconIsMaterial)
            Icon(icon as IconData, size: 18)
          else
            FaIcon(icon as IconData, size: 16),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

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
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      if (!mounted) return;
      Navigator.pop(context);
      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isLogin ? 'Sign in with email' : 'Create an account',
              style: AppTypography.heading3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                hintText: 'Password',
                suffixIcon: IconButton(
                  onPressed:
                      () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: Text(_isLogin ? 'Sign In' : 'Create Account'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? "Don't have an account? Sign up"
                    : 'Already have an account? Sign in',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
