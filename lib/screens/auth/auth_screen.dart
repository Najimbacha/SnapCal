import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLogin = true;
  bool _usePhone = false;
  String? _verificationId;
  bool _otpSent = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final controller = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.glassBorderColor),
            ),
            title: Text(
              'Reset Password',
              style: TextStyle(color: context.textPrimaryColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your email address and we will send you a reset link.',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                _buildMinimalTextField(
                  controller: controller,
                  hint: 'Email Address',
                  icon: LucideIcons.mail,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = controller.text.trim();
                  if (email.isEmpty) return;
                  try {
                    await context.read<AuthProvider>().sendPasswordResetEmail(
                      email,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset email sent!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Send Reset Link'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    if (_isLogin) {
      await authProvider.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      await authProvider.registerWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    }
    if (mounted && authProvider.isAuthenticated) {
      context.go('/');
    }
  }

  Future<void> _handlePhoneVerify() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });
      },
      onVerificationFailed: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  Future<void> _handleOTPVerify() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationId == null) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithOTP(
      _verificationId!,
      _otpController.text.trim(),
    );
    if (mounted && authProvider.isAuthenticated) {
      context.go('/');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle();
    if (mounted && authProvider.isAuthenticated) {
      context.go('/');
    }
  }

  Future<void> _handleFacebookSignIn() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithFacebook();
    if (mounted && authProvider.isAuthenticated) {
      context.go('/');
    }
  }

  Future<void> _handleGuestSignIn() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInAnonymously();
    if (mounted && authProvider.isAuthenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.surfaceLightColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.glassBorderColor,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.flame,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _isLogin ? 'Welcome Back' : 'Join SnapCal',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isLogin
                                    ? 'Login to continue your fitness journey'
                                    : 'Start tracking your nutrition today',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Social Sign In
                        if (!_usePhone) ...[
                          _buildSocialButton(
                            label: 'Google',
                            icon: FontAwesomeIcons.google,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            borderColor: Colors.white.withOpacity(0.1),
                            textColor: Colors.white,
                            onTap: _handleGoogleSignIn,
                            isLoading:
                                auth.status == AuthStatus.loading &&
                                !_usePhone &&
                                _emailController.text.isEmpty,
                          ),
                          const SizedBox(height: 12),
                          _buildSocialButton(
                            label: 'Facebook',
                            icon: FontAwesomeIcons.facebook,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            borderColor: Colors.white.withOpacity(0.1),
                            textColor: Colors.white,
                            onTap: _handleFacebookSignIn,
                            isLoading: false, // For simplicity
                          ),
                          const SizedBox(height: 32),
                          _buildDivider(),
                          const SizedBox(height: 32),
                        ],

                        // Input Fields
                        if (!_usePhone) ...[
                          _buildMinimalTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: LucideIcons.mail,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMinimalTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: LucideIcons.lock,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: 20,
                                color: Colors.white.withOpacity(0.4),
                              ),
                              onPressed:
                                  () => setState(
                                    () =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible,
                                  ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ] else ...[
                          _buildMinimalTextField(
                            controller: _phoneController,
                            hint: 'Phone Number (e.g. +1234567890)',
                            icon: LucideIcons.phone,
                            enabled: !_otpSent,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          if (_otpSent) ...[
                            const SizedBox(height: 16),
                            _buildMinimalTextField(
                              controller: _otpController,
                              hint: 'Verification Code',
                              icon: LucideIcons.shieldCheck,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the code';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],

                        const SizedBox(height: 32),

                        // Primary Action Button
                        ElevatedButton(
                          onPressed:
                              auth.status == AuthStatus.loading
                                  ? null
                                  : (_usePhone
                                      ? (_otpSent
                                          ? _handleOTPVerify
                                          : _handlePhoneVerify)
                                      : _handleEmailAuth),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.textPrimaryColor,
                            foregroundColor: context.backgroundColor,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child:
                              auth.status == AuthStatus.loading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _usePhone
                                        ? (_otpSent
                                            ? 'Verify & Continue'
                                            : 'Send Code')
                                        : (_isLogin ? 'Sign In' : 'Sign Up'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account?"
                                  : "Already have an account?",
                              style: TextStyle(color: context.textMutedColor),
                            ),
                            TextButton(
                              onPressed:
                                  () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Sign In',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Auth Mode Toggle
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _usePhone = !_usePhone;
                                _otpSent = false;
                              });
                            },
                            child: Text(
                              _usePhone
                                  ? 'Use Email instead'
                                  : 'Use Phone instead',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        // Guest Mode (Optional)
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _handleGuestSignIn,
                            child: Text(
                              'Continue as Guest',
                              style: TextStyle(
                                color: AppColors.primary.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        if (auth.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    Color? borderColor,
    required Color textColor,
    Color? iconColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: context.textPrimaryColor,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor ?? textColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        validator: validator,
        style: TextStyle(color: context.textPrimaryColor),
        decoration: InputDecoration(
          filled: false,
          hintText: hint,
          hintStyle: TextStyle(color: context.textMutedColor),
          prefixIcon: Icon(icon, size: 20, color: context.textSecondaryColor),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
