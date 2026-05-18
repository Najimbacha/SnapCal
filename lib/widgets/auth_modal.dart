import 'package:flutter/material.dart';

import '../screens/auth/auth_bottom_sheet.dart';

/// AuthModal — now simply opens the modern half-screen AuthBottomSheet modal.
/// Keeps the same public API so all existing callsites continue to work.
class AuthModal extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthModal({
    super.key,
    this.title = 'Welcome to SnapCal',
    this.subtitle =
        'The next generation of AI calorie tracking. Precise, private, and premium.',
  });

  /// Show auth — displays the modern, premium half-screen AuthBottomSheet modal.
  static void show(BuildContext context, {String? title, String? subtitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget body is no longer used directly, but kept for safety
    // in case someone instantiates it as a widget instead of calling show().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) show(context);
    });
    return const SizedBox.shrink();
  }
}
