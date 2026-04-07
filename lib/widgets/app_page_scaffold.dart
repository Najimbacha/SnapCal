import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';

class AppPageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final Widget? bottomBar;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.bottomBar,
    this.scrollable = false,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 32),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final content =
        scrollable
            ? SingleChildScrollView(
              padding: padding,
              physics: const BouncingScrollPhysics(),
              child: child,
            )
            : Padding(padding: padding, child: child);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.headlineLarge.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
            Expanded(child: content),
            if (bottomBar != null) bottomBar!,
          ],
        ),
      ),
    );
  }
}
