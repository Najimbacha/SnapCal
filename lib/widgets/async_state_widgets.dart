import 'package:flutter/material.dart';
import '../core/state/async_ui_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/theme_colors.dart';
import '../l10n/generated/app_localizations.dart';
import 'ui_blocks.dart';
import 'wazn_icons.dart';
import 'app_toast.dart';

/// A soft placeholder in the shape of what is loading, with a band of light
/// gliding across it so the wait reads as progress. Still with reduced
/// motion.
class AppSkeletonBlock extends StatefulWidget {
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
  State<AppSkeletonBlock> createState() => _AppSkeletonBlockState();
}

class _AppSkeletonBlockState extends State<AppSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final base =
        dark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFF16181D).withValues(alpha: 0.06);
    final light = Colors.white.withValues(alpha: dark ? 0.07 : 0.55);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            AnimatedBuilder(
              animation: _sweep,
              builder:
                  (context, child) =>
                      _sweep.isAnimating
                          ? FractionalTranslation(
                            translation: Offset(
                              -1 + 2 * Curves.easeInOut.transform(_sweep.value),
                              0,
                            ),
                            child: child,
                          )
                          : const SizedBox.shrink(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      light.withValues(alpha: 0),
                      light,
                      light.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

/// The outline of a stats page while it loads: three figures, a week of
/// bars and a line of text, in the places the real ones will take.
class AppStatsSkeleton extends StatelessWidget {
  const AppStatsSkeleton({super.key});

  static const _bars = [.55, .75, .45, .85, .65, .7, .5];

  @override
  Widget build(BuildContext context) {
    Widget tile() => Expanded(
      child: AppSectionCard(
        glass: true,
        padding: const EdgeInsets.all(12),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeletonBlock(height: 10, width: 54),
            SizedBox(height: 8),
            AppSkeletonBlock(height: 20, width: 70),
          ],
        ),
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            tile(),
            const SizedBox(width: 10),
            tile(),
            const SizedBox(width: 10),
            tile(),
          ],
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          glass: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSkeletonBlock(height: 14, width: 150),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, h) in _bars.indexed) ...[
                      if (i > 0) const SizedBox(width: 9),
                      Expanded(
                        child: AppSkeletonBlock(
                          height: 120 * h,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                            bottom: Radius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const AppSectionSkeleton(rows: 2),
      ],
    );
  }
}

/// The outline of a list of cards, such as a day of planned meals.
class AppListSkeleton extends StatelessWidget {
  final int rows;

  const AppListSkeleton({super.key, this.rows = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++) ...[
          AppSectionCard(
            glass: true,
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                AppSkeletonBlock(
                  height: 52,
                  width: 52,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonBlock(height: 14, width: 160),
                      SizedBox(height: 8),
                      AppSkeletonBlock(height: 11, width: 100),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                AppSkeletonBlock(height: 18, width: 44),
              ],
            ),
          ),
          if (i < rows - 1) const SizedBox(height: 12),
        ],
      ],
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
    this.icon = WaznIcons.error,
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
              : Icon(WaznIcons.refresh, size: 16),
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
    final l10n = AppLocalizations.of(context)!;
    return AppInlineFallback(
      icon: WaznIcons.offline,
      title: l10n.state_offline,
      message: message,
      actionLabel: onRetry == null ? null : l10n.state_retry,
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
    final l10n = AppLocalizations.of(context)!;
    switch (state.phase) {
      case AsyncUiPhase.loading:
        return loading ?? const AppSectionSkeleton();
      case AsyncUiPhase.empty:
        return empty ??
            AppInlineFallback(
              icon: WaznIcons.inbox,
              title: l10n.state_empty_title,
              message: state.message ?? l10n.state_empty_message,
            );
      case AsyncUiPhase.offline:
        return offline ??
            OfflineActionBanner(
              message: state.message ?? l10n.state_offline_message,
              onRetry: onRetry,
            );
      case AsyncUiPhase.error:
        return error ??
            AppInlineFallback(
              title: l10n.state_error_title,
              message: state.message ?? l10n.state_error_message,
              actionLabel: onRetry == null ? null : l10n.state_retry,
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
  IconData icon = WaznIcons.info,
}) {
  showAppToastOf(context, kind: ToastKind.info, icon: icon, title: message);
}
