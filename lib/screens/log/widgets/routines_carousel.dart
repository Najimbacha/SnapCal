import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/theme_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/meal_template.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/template_provider.dart';
import 'package:snapcal/widgets/glass_card.dart';
import 'package:snapcal/widgets/ui_blocks.dart';

class RoutinesCarousel extends StatelessWidget {
  const RoutinesCarousel({super.key});

  void _logRoutine(BuildContext context, MealTemplate template) async {
    HapticFeedback.mediumImpact();
    final templateProvider = context.read<TemplateProvider>();
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    try {
      await templateProvider.logFromTemplate(template, mealProvider, settingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.feature_templates_logged),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showOptions(BuildContext context, MealTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoutineOptionsSheet(template: template),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateProvider = context.watch<TemplateProvider>();
    final templates = templateProvider.templates;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (templates.isEmpty) {
      return const SizedBox.shrink(); // Hide if no routines
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.feature_templates_title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _RoutineCard(
                template: template,
                onTap: () => _logRoutine(context, template),
                onLongPress: () => _showOptions(context, template),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final MealTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RoutineCard({
    required this.template,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaleTap(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Text(
                  '${template.totalCalories}',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              template.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: context.textPrimaryColor,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${template.items.length} items',
              style: AppTypography.labelSmall.copyWith(
                color: context.textMutedColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineOptionsSheet extends StatelessWidget {
  final MealTemplate template;

  const _RoutineOptionsSheet({required this.template});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textMutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${template.emoji} ${template.name}',
              style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: Text(
                AppLocalizations.of(context)!.common_delete, 
                style: AppTypography.bodyLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.w900)
              ),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final router = Navigator.of(context);
                
                await context.read<TemplateProvider>().deleteTemplate(template.id);
                router.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Routine deleted')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
