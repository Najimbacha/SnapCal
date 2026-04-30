import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AuthModal — now simply navigates to the full-screen auth screen.
/// Keeps the same public API so all existing callsites (e.g. home_screen)
/// continue to work without any changes.
class AuthModal extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthModal({
    super.key,
    this.title = 'Welcome to SnapCal',
    this.subtitle =
        'The next generation of AI calorie tracking. Precise, private, and premium.',
  });

  /// Show auth — navigates to the full-screen /auth route.
  static void show(BuildContext context, {String? title, String? subtitle}) {
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    // This widget body is no longer used directly, but kept for safety
    // in case someone instantiates it as a widget instead of calling show().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.push('/auth');
    });
    return const SizedBox.shrink();
  }
}
