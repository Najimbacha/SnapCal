import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/activity_service.dart';
import '../../../providers/activity_provider.dart';
import '../../../widgets/app_icon.dart';

void showActivityHealthConnectSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (_) => const _SheetScaffold(),
  );
}

/// Root scaffold that provides the sheet structure with drag handle.
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold();

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final isConnected = activity.trackingStatus == ActivityTrackingStatus.connected;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          if (isConnected) const _ConnectedState() else const _DisconnectedState(),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: context.textMutedColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ── Disconnected State ───────────────────────────────────────

class _DisconnectedState extends StatelessWidget {
  const _DisconnectedState();

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 72, height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(AppSymbols.heartPulse, size: 34, color: AppColors.green),
          ),
          const SizedBox(height: 24),
          Text(
            'Health Connect',
            style: AppTypography.titleLarge.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatically sync your steps,\nworkouts, and calories.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          _StatusBadge(activity: activity),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => activity.connect(),
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      'Connect',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ActivityProvider activity;
  const _StatusBadge({required this.activity});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (activity.trackingStatus) {
      case ActivityTrackingStatus.connected:
      case ActivityTrackingStatus.emptyData:
        label = 'Connected';
        color = AppColors.green;
      case ActivityTrackingStatus.permissionDenied:
        label = 'Permission denied';
        color = AppColors.error;
      case ActivityTrackingStatus.healthConnectUnavailable:
        label = 'Not available';
        color = context.textMutedColor;
      case ActivityTrackingStatus.loading:
        label = 'Checking...';
        color = context.textMutedColor;
      case ActivityTrackingStatus.notConnected:
        label = 'Not Connected';
        color = context.textMutedColor;
      case ActivityTrackingStatus.error:
        label = 'Error';
        color = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Connected State ──────────────────────────────────────────

class _ConnectedState extends StatelessWidget {
  const _ConnectedState();

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final steps = activity.steps;
    final calories = activity.burnedCalories;
    final stepProgress = steps / math.max(activity.stepGoal, 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Activity',
            style: AppTypography.titleLarge.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 28),
          RepaintBoundary(
            child: _ActivityRing(progress: stepProgress, steps: steps),
          ),
          const SizedBox(height: 6),
          Text(
            'Steps Today',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$calories kcal burned',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          if (steps >= 200) ...[
            const SizedBox(height: 6),
            Text(
              '${(steps / 100).round()} min walk',
              style: AppTypography.bodySmall.copyWith(
                color: context.textMutedColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _LastSyncBadge(lastSyncedAt: activity.lastSyncedAt),
        ],
      ),
    );
  }
}

class _ActivityRing extends StatelessWidget {
  final double progress;
  final int steps;
  const _ActivityRing({required this.progress, required this.steps});

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: 180, height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(width: 160, height: 160,
            child: CircularProgressIndicator(
              value: 1, strokeWidth: 8, strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.textMutedColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          SizedBox(width: 160, height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value, strokeWidth: 8, strokeCap: StrokeCap.round,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatNumber(steps),
                style: AppTypography.displaySmall.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 38,
                  letterSpacing: -1.2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'steps',
                style: AppTypography.bodySmall.copyWith(
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _LastSyncBadge extends StatelessWidget {
  final DateTime? lastSyncedAt;
  const _LastSyncBadge({required this.lastSyncedAt});

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final ago = activity.isSyncing ? 'Syncing...' : _ago(lastSyncedAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.textMutedColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Last synced $ago',
        style: TextStyle(
          color: context.textMutedColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _ago(DateTime? dt) {
    if (dt == null) return 'never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours}h ago';
  }
}
