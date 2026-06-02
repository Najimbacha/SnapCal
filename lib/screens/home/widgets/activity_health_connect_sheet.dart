import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/activity_summary.dart';
import '../../../data/services/activity_service.dart';
import '../../../providers/activity_provider.dart';

void showActivityHealthConnectSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const ActivityHealthConnectSheet(),
  );
}

class ActivityHealthConnectSheet extends StatelessWidget {
  const ActivityHealthConnectSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final progress = (activity.steps / math.max(activity.stepGoal, 1)).clamp(
      0.0,
      1.0,
    );
    final workout =
        activity.today.workouts.isEmpty ? null : activity.today.workouts.first;
    final showConnectGuidance =
        activity.trackingStatus != ActivityTrackingStatus.connected;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.heartPulse,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Connect',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        activity.statusLabel(),
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showConnectGuidance) ...[
              const SizedBox(height: 12),
              Text(
                'SnapCal reads your step and activity data from Health Connect only after you allow permission.',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _StatusMessage(activity: activity),
              const SizedBox(height: 14),
            ] else
              const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    label: 'Today steps',
                    value: '${activity.steps}',
                    icon: LucideIcons.footprints,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricBlock(
                    label: 'Target steps',
                    value: '${activity.stepGoal}',
                    icon: LucideIcons.target,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).round()}% of step target',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _MetricBlock(
              label: activity.caloriesLabel,
              value: '${activity.burnedCalories} kcal',
              icon: LucideIcons.flame,
            ),
            const SizedBox(height: 8),
            _WorkoutBlock(workout: workout),
            const SizedBox(height: 8),
            _LastSyncedBlock(lastSyncedAt: activity.lastSyncedAt),
            if (!activity.isConnected) ...[
              const SizedBox(height: 14),
              _ActionButtons(activity: activity),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final ActivityProvider activity;

  const _StatusMessage({required this.activity});

  @override
  Widget build(BuildContext context) {
    final message = switch (activity.trackingStatus) {
      ActivityTrackingStatus.loading => 'Checking Health Connect...',
      ActivityTrackingStatus.connected =>
        'Connected. Refresh to read the latest Health Connect data.',
      ActivityTrackingStatus.emptyData =>
        'Connected, but Health Connect has no step or activity data for today.',
      ActivityTrackingStatus.notConnected =>
        'Connect Health Connect to show steps, activity, and calories burned.',
      ActivityTrackingStatus.permissionDenied =>
        'Permission was denied. You can retry or manage permissions in Health Connect.',
      ActivityTrackingStatus.healthConnectUnavailable =>
        'Health Connect is not available or needs to be installed or updated.',
      ActivityTrackingStatus.error =>
        activity.errorMessage ?? 'Health Connect data could not be loaded.',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutBlock extends StatelessWidget {
  final WorkoutEntry? workout;

  const _WorkoutBlock({required this.workout});

  @override
  Widget build(BuildContext context) {
    final currentWorkout = workout;
    final text =
        currentWorkout == null
            ? 'No workout data today'
            : '${currentWorkout.type} • ${currentWorkout.duration.inMinutes} min • ${currentWorkout.calories} kcal';
    return _MetricBlock(
      label: 'Workout summary',
      value: text,
      icon: LucideIcons.dumbbell,
    );
  }
}

class _LastSyncedBlock extends StatelessWidget {
  final DateTime? lastSyncedAt;

  const _LastSyncedBlock({required this.lastSyncedAt});

  @override
  Widget build(BuildContext context) {
    final value =
        lastSyncedAt == null
            ? 'Not synced yet'
            : TimeOfDay.fromDateTime(lastSyncedAt!).format(context);
    return _MetricBlock(
      label: 'Last synced',
      value: value,
      icon: LucideIcons.clock,
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ActivityProvider activity;

  const _ActionButtons({required this.activity});

  @override
  Widget build(BuildContext context) {
    final unavailable =
        activity.trackingStatus ==
        ActivityTrackingStatus.healthConnectUnavailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed:
              activity.isSyncing
                  ? null
                  : unavailable
                  ? activity.openInstallOrUpdate
                  : activity.startTracking,
          icon:
              activity.isSyncing
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Icon(unavailable ? LucideIcons.download : LucideIcons.link),
          label: Text(
            unavailable ? 'Install or update Health Connect' : 'Connect',
          ),
        ),
      ],
    );
  }
}
