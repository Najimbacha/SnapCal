import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../data/services/connectivity_service.dart';
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
  final bool isPremium;
  final bool? forceShowBackButton; // New: To override auto-detection
  final Decoration? headerDecoration;
  final Widget? background;
  final Color? backgroundColor;
  final bool showHeader;
  final bool extendBehindStatusBar;
  final double headerHeight;

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
    this.isPremium = false,
    this.forceShowBackButton,
    this.headerDecoration,
    this.background,
    this.backgroundColor,
    this.showHeader = true,
    this.extendBehindStatusBar = false,
    this.headerHeight = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hPadding = Responsive.hPadding(context);
    final maxWidth = Responsive.maxWidth(context);
    final canPop = context.canPop();
    final shouldShowBack = forceShowBackButton ?? canPop;

    final resolvedPadding =
        padding ?? EdgeInsets.fromLTRB(hPadding, 0, hPadding, 24);

    final content =
        scrollable
            ? SingleChildScrollView(
              padding: resolvedPadding,
              physics: const BouncingScrollPhysics(),
              child: child,
            )
            : Padding(padding: resolvedPadding, child: child);

    final isOnline = context.select<ConnectivityService, bool>(
      (s) => s.isOnline,
    );

    final statusBarTopInset =
        extendBehindStatusBar ? MediaQuery.of(context).padding.top : 0.0;

    final header = Container(
      height: headerHeight + statusBarTopInset,
      padding: EdgeInsets.fromLTRB(hPadding, statusBarTopInset, hPadding, 0),
      decoration: headerDecoration,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Centered Title ──
          if (title.isNotEmpty)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                      child: Text(
                        title,
                        key: ValueKey(title),
                        style: AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (isPremium) ...[
                    const SizedBox(width: 6),
                    Icon(LucideIcons.gem, color: AppColors.primary, size: 14),
                  ],
                ],
              ),
            ),

          // ── Leading ──
          Positioned(
            left: 0,
            child:
                leading ??
                (shouldShowBack
                    ? AppScaleTap(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      child: _HeaderIconButton(
                        icon: LucideIcons.arrowLeft,
                        colorScheme: colorScheme,
                      ),
                    )
                    : const SizedBox.shrink()),
          ),

          // ── Trailing ──
          if (trailing != null) Positioned(right: 0, child: trailing!),
        ],
      ),
    );

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.10),
            colorScheme.surface,
            colorScheme.surface,
          ],
          stops: const [0, 0.28, 1],
        ),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: isOnline ? const SizedBox.shrink() : _OfflineBanner(),
          ),
          if (showHeader)
            header.animate().fadeIn(duration: 220.ms).slideY(begin: -0.08),
          Expanded(
            child: content
                .animate()
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.03),
          ),
          if (bottomBar != null) bottomBar!,
        ],
      ),
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

    final overlayStyle =
        Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: colorScheme.surface,
            )
            : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: colorScheme.surface,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        extendBodyBehindAppBar: extendBehindStatusBar,
        backgroundColor: backgroundColor ?? colorScheme.surface,
        body: background != null
            ? Stack(
                children: [
                  Positioned.fill(child: background!),
                  SafeArea(top: !extendBehindStatusBar, bottom: true, child: body),
                ],
              )
            : SafeArea(top: !extendBehindStatusBar, bottom: true, child: body),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final ColorScheme colorScheme;

  const _HeaderIconButton({required this.icon, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Icon(icon, size: 20, color: colorScheme.onSurface),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.wifiOff,
            size: 12,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)?.common_offline_mode ?? "Offline Mode",
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
