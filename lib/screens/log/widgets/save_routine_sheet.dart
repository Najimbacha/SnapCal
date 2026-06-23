import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/template_provider.dart';
import 'package:snapcal/widgets/glass_card.dart';

class SaveRoutineSheet extends ConsumerStatefulWidget {
  final List<Meal> meals;

  const SaveRoutineSheet({super.key, required this.meals});

  @override
  ConsumerState<SaveRoutineSheet> createState() => _SaveRoutineSheetState();
}

class _SaveRoutineSheetState extends ConsumerState<SaveRoutineSheet> {
  late final TextEditingController _nameController;
  String _selectedEmoji = '🍽️';
  bool _isSaving = false;

  final List<String> _emojiOptions = [
    '🍽️',
    '🍳',
    '🥗',
    '🥣',
    '🥪',
    '🥤',
    '🍎',
    '🥩',
    '🥑',
    '🥞',
    '🍔',
    '🍕',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(templatesProvider.notifier).saveTemplate(
        name: name,
        emoji: _selectedEmoji,
        meals: widget.meals,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.feature_templates_logged),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isPro = ref.watch(settingsProvider).valueOrNull?.isPro ?? false;
    final templateNotifier = ref.watch(templatesProvider.notifier);

    final canAdd = templateNotifier.canAddTemplate(isPro);

    return GlassCard(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.feature_templates_save_prompt,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.feature_templates_save_desc(widget.meals.length),
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            if (!canAdd) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.star, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.feature_templates_limit_reached,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojiOptions.length,
                itemBuilder: (context, index) {
                  final emoji = _emojiOptions[index];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border:
                            isSelected
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: canAdd,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.feature_templates_name_hint,
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    canAdd && _nameController.text.isNotEmpty ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          l10n.feature_templates_save_btn,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



