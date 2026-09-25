import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../widgets/wazn_icons.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_motion.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/providers/achievements_provider.dart';
import 'package:snapcal/widgets/app_page_scaffold.dart';
import 'widgets/badge_card.dart';
import 'widgets/badge_celebration.dart';
import 'widgets/badge_detail_sheet.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  static const _celebratedKey = 'achievements_celebrated';

  /// Badges earned since they were last celebrated. They wait on the grid
  /// looking locked until their celebration hands them back in gold.
  final Set<String> _pending = {};
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_open()));
  }

  Future<void> _open() async {
    await ref.read(achievementsProvider.notifier).refreshAchievements();
    if (!mounted) return;
    final earned = [
      for (final a in ref.read(achievementsProvider).valueOrNull ?? const [])
        if (a.isUnlocked) a,
    ]..sort((a, b) => (a.unlockedAt ?? 0).compareTo(b.unlockedAt ?? 0));
    final prefs = await SharedPreferences.getInstance();
    var celebrated = prefs.getStringList(_celebratedKey)?.toSet();
    if (celebrated == null) {
      // The first visit after this arrived: badges earned long ago are not
      // news; only the last day's are.
      final cutoff =
          DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch;
      celebrated = {
        for (final a in earned)
          if ((a.unlockedAt ?? 0) < cutoff) a.id,
      };
    }
    final fresh = [
      for (final a in earned)
        if (!celebrated.contains(a.id)) a,
    ];
    await prefs.setStringList(_celebratedKey, [for (final a in earned) a.id]);
    if (fresh.isEmpty || !mounted) return;
    setState(() => _pending.addAll(fresh.map((a) => a.id)));
    // Let the grid arrive before the first celebration.
    await Future<void>.delayed(
      AppMotion.maybeZero(context, const Duration(milliseconds: 900)),
    );
    for (final badge in fresh.take(3)) {
      if (!mounted) return;
      final scroll = AppMotion.maybeZero(
        context,
        const Duration(milliseconds: 350),
      );
      final spot = _keys[badge.id]?.currentContext;
      if (spot != null && spot.mounted) {
        await Scrollable.ensureVisible(spot, alignment: .5, duration: scroll);
      }
      if (!mounted) return;
      await celebrateBadge(context, badge);
      if (!mounted) return;
      // Back in its place, it turns over to gold.
      setState(() => _pending.remove(badge.id));
    }
    if (mounted) setState(_pending.clear);
  }

  @override
  Widget build(BuildContext context) {
    // Watched, not read once: a badge unlocked while this screen is open now
    // appears, and the counts are not stuck at zero before the box opens.
    ref.watch(achievementsProvider);
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
            pending: _pending,
            keys: _keys,
            startIndex: 0,
            title: l10n.achievement_category_consistency,
            icon: WaznIcons.calendar,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.consistency,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            pending: _pending,
            keys: _keys,
            startIndex: _countBefore(AchievementCategory.precision),
            title: l10n.achievement_category_precision,
            icon: WaznIcons.goal,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.precision,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            pending: _pending,
            keys: _keys,
            startIndex: _countBefore(AchievementCategory.hydration),
            title: l10n.achievement_category_hydration,
            icon: WaznIcons.water,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.hydration,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            pending: _pending,
            keys: _keys,
            startIndex: _countBefore(AchievementCategory.logging),
            title: l10n.achievement_category_logging,
            icon: WaznIcons.camera,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.logging,
            ),
          ),
          const SizedBox(height: 32),
          _CategorySection(
            pending: _pending,
            keys: _keys,
            startIndex: _countBefore(AchievementCategory.progress),
            title: l10n.achievement_category_progress,
            icon: WaznIcons.trend,
            achievements: achievementsNotifier.byCategory(
              AchievementCategory.progress,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  int _countBefore(AchievementCategory category) {
    final notifier = ref.read(achievementsProvider.notifier);
    return [
      for (final c in AchievementCategory.values.takeWhile(
        (c) => c != category,
      ))
        notifier.byCategory(c).length,
    ].fold(0, (a, b) => a + b);
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Achievement> achievements;
  final Set<String> pending;
  final Map<String, GlobalKey> keys;

  /// Where this section's badges fall in the screen's arrival order.
  final int startIndex;

  const _CategorySection({
    required this.title,
    required this.icon,
    required this.achievements,
    required this.pending,
    required this.keys,
    required this.startIndex,
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
            final badge = achievements[index];
            return BadgeCard(
              key: keys.putIfAbsent(badge.id, GlobalKey.new),
              achievement: badge,
              index: startIndex + index,
              pending: pending.contains(badge.id),
              onTap: () => showBadgeDetail(context, badge),
            );
          },
        ),
      ],
    );
  }
}
