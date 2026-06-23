import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/providers/achievements_provider.dart';
import 'package:snapcal/widgets/app_page_scaffold.dart';
import 'widgets/badge_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final achievementsNotifier = ref.read(achievementsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return AppPageScaffold(
      title: l10n.feature_achievements_title,
      subtitle: l10n.feature_achievements_unlocked(
        achievementsNotifier.totalUnlocked.toString(),
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategorySection(
            title: l10n.achievement_category_consistency,
            icon: LucideIcons.calendarClock,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.consistency,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            title: l10n.achievement_category_precision,
            icon: LucideIcons.target,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.precision,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            title: l10n.achievement_category_hydration,
            icon: LucideIcons.droplets,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.hydration,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            title: l10n.achievement_category_logging,
            icon: LucideIcons.camera,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.logging,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            title: l10n.achievement_category_progress,
            icon: LucideIcons.trendingUp,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.progress,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Achievement> achievements;

  const _CategorySection({
    required this.title,
    required this.icon,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return BadgeCard(achievement: achievements[index]);
          },
        ),
      ],
    );
  }
}
