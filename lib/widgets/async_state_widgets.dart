import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/state/async_ui_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/theme_colors.dart';
import 'ui_blocks.dart';

class AppSkeletonBlock extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadiusGeometry borderRadius;

  const AppSkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.75),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              borderRadius: borderRadius,
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }
}

class AppSectionSkeleton extends StatelessWidget {
  final int rows;

  const AppSectionSkeleton({super.key, this.rows = 3});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBlock(height: 18, width: 140),
          const SizedBox(height: 16),
          for (int i = 0; i < rows; i++) ...[
            AppSkeletonBlock(height: i == 0 ? 80 : 52),
            if (i < rows - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class AppInlineFallback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppInlineFallback({
    super.key,
    this.icon = LucideIcons.alertCircle,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      glass: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class AppAsyncOverlay extends StatelessWidget {
  final AsyncUiState state;
  final Widget child;

  const AppAsyncOverlay({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (state.isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}

class RetryButton extends StatefulWidget {
  final Future<void> Function() onRetry;
  final String label;

  const RetryButton({super.key, required this.onRetry, required this.label});

  @override
  State<RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<RetryButton> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isRetrying ? null : _handleRetry,
      icon:
          _isRetrying
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(LucideIcons.refreshCw, size: 16),
      label: Text(widget.label),
    );
  }
}

class OfflineActionBanner extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const OfflineActionBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppInlineFallback(
      icon: LucideIcons.wifiOff,
      title: 'Offline',
      message: message,
      actionLabel: onRetry == null ? null : 'Retry',
      onAction: onRetry == null ? null : () => onRetry!(),
    );
  }
}

class AppStateView extends StatelessWidget {
  final AsyncUiState state;
  final WidgetBuilder successBuilder;
  final Widget? loading;
  final Widget? empty;
  final Widget? offline;
  final Widget? error;
  final Future<void> Function()? onRetry;

  const AppStateView({
    super.key,
    required this.state,
    required this.successBuilder,
    this.loading,
    this.empty,
    this.offline,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case AsyncUiPhase.loading:
        return loading ?? const AppSectionSkeleton();
      case AsyncUiPhase.empty:
        return empty ??
            AppInlineFallback(
              icon: LucideIcons.inbox,
              title: 'Nothing here yet',
              message: state.message ?? 'There is no data to show.',
            );
      case AsyncUiPhase.offline:
        return offline ??
            OfflineActionBanner(
              message:
                  state.message ??
                  'You are offline. Cached data is still available.',
              onRetry: onRetry,
            );
      case AsyncUiPhase.error:
        return error ??
            AppInlineFallback(
              title: 'Something went wrong',
              message: state.message ?? 'Please try again.',
              actionLabel: onRetry == null ? null : 'Retry',
              onAction: onRetry == null ? null : () => onRetry!(),
            );
      case AsyncUiPhase.retrying:
      case AsyncUiPhase.refreshing:
      case AsyncUiPhase.partial:
      case AsyncUiPhase.success:
      case AsyncUiPhase.idle:
        return AppAsyncOverlay(state: state, child: successBuilder(context));
    }
  }
}

void showFriendlyFallbackSnack(
  BuildContext context,
  String message, {
  IconData icon = LucideIcons.info,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

