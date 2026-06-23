import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/activity_provider.dart';
import '../../../widgets/app_icon.dart';

void showActivityHealthConnectSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SheetScaffold(),
  );
}

class _SheetScaffold extends ConsumerWidget {
  const _SheetScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityVal = ref.watch(activityProvider).valueOrNull;
    final isConnected = activityVal?.healthConnected ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.only(bottom: 16 + bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEFCF7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            if (isConnected) const _ConnectedState() else const _DisconnectedState(),
          ],
        ),
      ),
    );
  }
}

// ── Disconnected State ───────────────────────────────────────

class _DisconnectedState extends ConsumerWidget {
  const _DisconnectedState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityProvider);
    final activityVal = activityAsync.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(AppSymbols.heartPulse, size: 34, color: AppColors.green),
          ),
          const SizedBox(height: 20),
          Text(
            'Health Connect',
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1C1917),
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
              color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          _StatusBadge(activityVal: activityVal, isLoading: activityAsync.isLoading),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await ref.read(activityProvider.notifier).authorize();
                  ref.invalidate(activityProvider);
                },
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
  final ActivitySummary? activityVal;
  final bool isLoading;
  const _StatusBadge({required this.activityVal, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String label;
    Color color;
    if (activityVal?.healthConnected == true) {
      label = 'Connected';
      color = AppColors.green;
    } else if (isLoading) {
      label = 'Checking...';
      color = isDark ? Colors.white38 : const Color(0xFFB4AFA8);
    } else {
      label = 'Not Connected';
      color = isDark ? Colors.white38 : const Color(0xFFB4AFA8);
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

class _ConnectedState extends ConsumerWidget {
  const _ConnectedState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityVal = ref.watch(activityProvider).valueOrNull;
    final steps = activityVal?.steps ?? 0;
    final calories = (activityVal?.activeCalories ?? 0).toInt();
    final stepProgress = steps / math.max(10000, 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          Text(
            'Activity',
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1C1917),
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            child: _ActivityRing(progress: stepProgress, steps: steps),
          ),
          const SizedBox(height: 6),
          Text(
            'Steps Today',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$calories kcal burned',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          if (steps >= 200) ...[
            const SizedBox(height: 6),
            Text(
              '${(steps / 100).round()} min walk',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white24 : const Color(0xFFD6D3D1),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _LastSyncBadge(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
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
                  color: isDark ? Colors.white : const Color(0xFF1C1917),
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
                  color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
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

class _LastSyncBadge extends ConsumerWidget {
  const _LastSyncBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activityAsync = ref.watch(activityProvider);
    final ago = activityAsync.isLoading ? 'Syncing...' : _ago(null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Last synced $ago',
        style: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
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
