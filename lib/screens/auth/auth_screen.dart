import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLogin = true;
  bool _usePhone = false;
  String? _verificationId;
  bool _otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
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
    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
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
    if (_verificationId == null) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithOTP(_verificationId!, _otpController.text);
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Glow (Aurora) - Kept from previous step
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
                    AppColors.primary.withOpacity(0.2),
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
                  if (auth.status == AuthStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.flame,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _isLogin ? 'Welcome back' : 'Create account',
                              style: const TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. Social Buttons (Dark Glass + Brand Icons)
                      _buildSocialButton(
                        label: 'Continue with Google',
                        icon: FontAwesomeIcons.google, // The "G"
                        backgroundColor: Colors.white.withOpacity(0.08),
                        borderColor: Colors.white.withOpacity(0.1),
                        textColor: Colors.white,
                        iconColor: const Color(0xFFDB4437), // Google Red
                        onTap: _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 16),
                      _buildSocialButton(
                        label: 'Continue with Facebook',
                        icon: FontAwesomeIcons.facebookF, // The "f"
                        backgroundColor: Colors.white.withOpacity(0.08),
                        borderColor: Colors.white.withOpacity(0.1),
                        textColor: Colors.white,
                        iconColor: const Color(0xFF1877F2), // FB Blue
                        onTap: _handleFacebookSignIn,
                      ),

                      const SizedBox(height: 32),

                      // 3. Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 4. Input Fields (Darker #1A1A1A, Radius 12)
                      if (!_usePhone) ...[
                        _buildMinimalTextField(
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: LucideIcons.mail,
                        ),
                        const SizedBox(height: 16),
                        _buildMinimalTextField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: LucideIcons.lock,
                          obscureText: true,
                        ),
                      ] else ...[
                        _buildMinimalTextField(
                          controller: _phoneController,
                          hint: 'Phone Number',
                          icon: LucideIcons.phone,
                          enabled: !_otpSent,
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 16),
                          _buildMinimalTextField(
                            controller: _otpController,
                            hint: 'Verification Code',
                            icon: LucideIcons.shieldCheck,
                          ),
                        ],
                      ],

                      // 5. Actions
                      const SizedBox(height: 24),
                      if (_isLogin && !_usePhone)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Forgot password
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // 6. Primary Action Button (White, Radius 12)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _usePhone
                                  ? (_otpSent
                                      ? _handleOTPVerify
                                      : _handlePhoneVerify)
                                  : _handleEmailAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _usePhone
                                ? (_otpSent ? 'Verify & Login' : 'Send Code')
                                : (_isLogin ? 'Sign in' : 'Create Account'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 7. Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? 'Sign up' : 'Sign in',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // Guest Option (Low priority)
                      Center(
                        child: TextButton(
                          onPressed: _handleGuestSignIn,
                          child: Text(
                            'Continue as Guest',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap:
                              () => setState(() {
                                _usePhone = !_usePhone;
                                _otpSent = false;
                              }),
                          child: Text(
                            _usePhone
                                ? 'Continue with Email'
                                : 'Continue with Phone',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                              color: Color(0xFFFF453A),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? textColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500, // Lighter weight for premium feel
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Requested Dark Background
        borderRadius: BorderRadius.circular(12), // Requested Radius
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: false, // Prevent global theme fill from showing
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: Colors.white.withOpacity(0.5),
          ),
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
