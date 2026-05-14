import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import '../../l10n/generated/app_localizations.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isWalking = activity.status == 'walking';

    return AppPageScaffold(
      title: l10n.home_metric_activity,
      scrollable: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            // --- MAIN STEP COUNT ---
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isWalking)
                      AppPulse(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ).animate().fadeIn(),
                    const SizedBox(width: 8),
                    Text(
                      isWalking ? 'LIVE TRACKING' : 'STATIONARY',
                      style: AppTypography.labelSmall.copyWith(
                        color:
                            isWalking
                                ? AppColors.primary
                                : context.textMutedColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                      '${activity.steps}',
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -4,
                        height: 1,
                        color: context.textPrimaryColor,
                      ),
                    )
                    .animate(key: ValueKey(activity.steps))
                    .scale(duration: 200.ms, curve: Curves.easeOut),
                Text(
                  'steps today'.toUpperCase(),
                  style: AppTypography.labelMedium.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // --- STATS ROW ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.surfaceContainerColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SimpleStat(
                      label: 'CALORIES',
                      value: '${activity.burnedCalories}',
                      unit: 'kcal',
                      icon: LucideIcons.flame,
                      color: Colors.orange,
                    ),
                  ),
                  _Divider(),
                  Expanded(
                    child: _SimpleStat(
                      label: 'GOAL',
                      value: '10k',
                      unit: 'steps',
                      icon: LucideIcons.target,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- MOTIVATION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _getMotivationalMessage(activity.steps, l10n),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- STATUS & PERMISSIONS ---
            Text(
              'TRACKING ENGINE',
              style: AppTypography.labelSmall.copyWith(
                color: context.textMutedColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        activity.isTracking
                            ? LucideIcons.shieldCheck
                            : LucideIcons.shieldAlert,
                        color:
                            activity.isTracking ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.isTracking
                                  ? 'Active & Encrypted'
                                  : 'Permission Required',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              activity.isTracking
                                  ? 'Your steps are synced in real-time.'
                                  : 'Enable tracking to see your progress.',
                              style: AppTypography.bodySmall.copyWith(
                                color: context.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!activity.isTracking) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => activity.authorize(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Authorize Tracking',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getMotivationalMessage(int steps, AppLocalizations l10n) {
    if (steps < 2000) return l10n.activity_motivation_low;
    if (steps < 5000) return l10n.activity_motivation_mid;
    if (steps < 8000) return l10n.activity_motivation_high;
    return l10n.activity_motivation_elite;
  }
}

class _SimpleStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SimpleStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          unit.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: context.dividerColor.withValues(alpha: 0.1),
    );
  }
}
