import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../core/theme/app_typography.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import 'ui_blocks.dart';

class AppPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final Widget? bottomBar;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final Widget? leading;
  final Widget? floatingActionButton;
  final bool? forceShowBackButton; // New: To override auto-detection

  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
    this.leading,
    this.bottomBar,
    this.floatingActionButton,
    this.scrollable = false,
    this.padding,
    this.forceShowBackButton,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hPadding = Responsive.hPadding(context);
    final maxWidth = Responsive.maxWidth(context);
    final canPop = context.canPop();
    final shouldShowBack = forceShowBackButton ?? canPop;

    final resolvedPadding = padding ?? EdgeInsets.fromLTRB(hPadding, 0, hPadding, 24);
    
    final content = scrollable
        ? SingleChildScrollView(
            padding: resolvedPadding,
            physics: const BouncingScrollPhysics(),
            child: child,
          )
        : Padding(padding: resolvedPadding, child: child);

    Widget header = Container(
      height: 64, // Compact height
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Centered Title ──
          if (title.isNotEmpty)
            Center(
              child: Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // ── Leading ──
          Positioned(
            left: 0,
            child: leading ?? (shouldShowBack ? AppScaleTap(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded, 
                  size: 16, 
                  color: colorScheme.onSurface,
                ),
              ),
            ) : const SizedBox.shrink()),
          ),
          
          // ── Trailing ──
          if (trailing != null)
            Positioned(
              right: 0,
              child: trailing!,
            ),
        ],
      ),
    );

    Widget body = Column(
      children: [
        header,
        Expanded(child: content),
        if (bottomBar != null) bottomBar!,
      ],
    );

    // Apply tablet max-width and centering
    if (maxWidth != null) {
      body = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
