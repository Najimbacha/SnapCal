import 'package:flutter/material.dart';
import 'package:snapcal/widgets/app_icon.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';

/// Recipe card used inside AI chat messages — minimal, premium feel.
class ChatRecipeCard extends StatelessWidget {
  final String title;
  final String content;
  final Map<String, int>? macros;

  const ChatRecipeCard({
    super.key,
    required this.title,
    required this.content,
    this.macros,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = ParsedRecipe.fromMarkdown(content);
    final accent = AppColors.homeCoachAccent;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorderColor, width: 1),
        boxShadow: context.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.cardBorderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'RECIPE',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        AppSymbols.utensils,
                        size: 14,
                        color: context.textMutedColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (macros != null) ...[
                    const SizedBox(height: 12),
                    _MacroChips(macros: macros!),
                  ],
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: parsed.hasStructure
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parsed.ingredients.isNotEmpty) ...[
                          _Section(
                            icon: AppSymbols.utensils,
                            label: 'Ingredients',
                            child: _IngredientsWrap(
                              items: parsed.ingredients,
                            ),
                          ),
                          if (parsed.steps.isNotEmpty)
                            const SizedBox(height: 18),
                        ],
                        if (parsed.steps.isNotEmpty) ...[
                          _Section(
                            icon: AppSymbols.listChecks,
                            label: 'Steps',
                            child: _StepsList(steps: parsed.steps),
                          ),
                        ],
                        if (parsed.note.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CoachNote(note: parsed.note),
                        ],
                      ],
                    )
                  : Text(
                      parsed.fallbackText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textPrimaryColor,
                        height: 1.55,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _Section({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: context.textMutedColor),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: context.textMutedColor,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _IngredientsWrap extends StatelessWidget {
  final List<String> items;
  const _IngredientsWrap({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s,
                style: AppTypography.bodySmall.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StepsList extends StatelessWidget {
  final List<String> steps;
  const _StepsList({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.homeCoachAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: AppColors.homeCoachAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textPrimaryColor,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CoachNote extends StatelessWidget {
  final String note;
  const _CoachNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            AppSymbols.leaf,
            size: 14,
            color: AppColors.success.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: AppTypography.bodySmall.copyWith(
                color: context.textPrimaryColor,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChips extends StatelessWidget {
  final Map<String, int> macros;
  const _MacroChips({required this.macros});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Color)>[
      (
        AppSymbols.flame,
        '${macros['calories'] ?? 0}',
        'kcal',
        AppColors.calories,
      ),
      (
        AppSymbols.dumbbell,
        '${macros['protein'] ?? 0}g',
        'protein',
        AppColors.protein,
      ),
      (
        AppSymbols.wheat,
        '${macros['carbs'] ?? 0}g',
        'carbs',
        AppColors.carbs,
      ),
      (
        AppSymbols.droplet,
        '${macros['fat'] ?? 0}g',
        'fat',
        AppColors.fat,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: items[i].$4.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].$1, size: 13, color: items[i].$4),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      items[i].$2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// Lightweight parser for the AI's markdown recipe output.
class ParsedRecipe {
  final List<String> ingredients;
  final List<String> steps;
  final String note;
  final String fallbackText;

  const ParsedRecipe({
    required this.ingredients,
    required this.steps,
    required this.note,
    required this.fallbackText,
  });

  bool get hasStructure =>
      ingredients.isNotEmpty || steps.isNotEmpty || note.isNotEmpty;

  static bool looksLikeRecipe(String content) {
    final lower = content.toLowerCase();
    return lower.contains('ingredient') ||
        lower.contains('### steps') ||
        (lower.contains('combine ') && lower.contains('cook')) ||
        (lower.contains('recipe') && lower.contains('step'));
  }

  static String displayTitle(
    String title,
    String content,
    String defaultCoachTitle,
    String fallbackRecipeTitle,
  ) {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty && trimmed != defaultCoachTitle) return trimmed;
    for (final rawLine in content.split('\n')) {
      final cleaned = _clean(rawLine)
          .replaceFirst(RegExp(r'^#+\s*'), '')
          .replaceFirst(RegExp(r'^title:\s*', caseSensitive: false), '')
          .trim();
      final lower = cleaned.toLowerCase();
      if (cleaned.isEmpty ||
          lower.contains('ingredient') ||
          lower.contains('step') ||
          lower.contains('coach') ||
          lower.contains('nutrition')) {
        continue;
      }
      if (cleaned.length <= 42 && !cleaned.contains('.')) return cleaned;
    }
    return fallbackRecipeTitle;
  }

  factory ParsedRecipe.fromMarkdown(String content) {
    final ingredients = <String>[];
    final steps = <String>[];
    final noteLines = <String>[];
    var section = '';

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final normalized = line
          .replaceFirst(RegExp(r'^#+\s*'), '')
          .replaceAll('**', '')
          .trim();
      final lower = normalized.toLowerCase();
      final payload = normalized.contains(':')
          ? normalized.substring(normalized.indexOf(':') + 1).trim()
          : '';

      if (_matches(lower, const ['ingredient'])) {
        section = 'ingredients';
        if (payload.isNotEmpty) {
          ingredients.addAll(_splitPayload(payload));
        }
        continue;
      }
      if (_matches(lower, const [
        'step',
        'method',
        'instruction',
        'what to do',
        'directions',
      ])) {
        section = 'steps';
        if (payload.isNotEmpty) steps.add(_clean(payload));
        continue;
      }
      if (_matches(lower, const ['coach', 'nutrition', 'note'])) {
        section = 'note';
        if (payload.isNotEmpty) noteLines.add(_clean(payload));
        continue;
      }

      final cleaned = _clean(normalized);
      if (cleaned.isEmpty) continue;
      if (section == 'ingredients') {
        ingredients.addAll(_splitPayload(cleaned));
      } else if (section == 'steps') {
        steps.add(cleaned);
      } else if (section == 'note') {
        noteLines.add(cleaned);
      }
    }

    if (ingredients.isEmpty && steps.isEmpty) {
      _parseCompact(content, ingredients, steps);
    }

    return ParsedRecipe(
      ingredients: ingredients,
      steps: steps,
      note: noteLines.join(' '),
      fallbackText: content,
    );
  }

  static bool _matches(String lower, List<String> keywords) {
    return keywords.any(lower.contains);
  }

  static String _clean(String value) => value
      .replaceAll('**', '')
      .replaceFirst(RegExp(r'^[-*•]\s*'), '')
      .replaceFirst(RegExp(r'^\d+[\.)]\s*'), '')
      .trim();

  static List<String> _splitPayload(String value) => value
      .split(RegExp(r',|\band\b', caseSensitive: false))
      .map(_clean)
      .where((s) => s.length > 2)
      .take(10)
      .toList();

  static void _parseCompact(
    String content,
    List<String> ingredients,
    List<String> steps,
  ) {
    final sentences = content
        .replaceAll('\n', ' ')
        .split(RegExp(r'[.!?]\s*'))
        .map(_clean)
        .where((s) => s.length > 3)
        .toList();
    for (final sentence in sentences.take(5)) {
      final lower = sentence.toLowerCase();
      if (lower.startsWith('combine ') || lower.startsWith('mix ')) {
        final ingredientText = sentence
            .replaceFirst(RegExp(r'^(combine|mix)\s+', caseSensitive: false), '')
            .trim();
        ingredients.addAll(_splitPayload(ingredientText));
        steps.add(sentence);
      } else if (lower.contains('cook') ||
          lower.contains('bake') ||
          lower.contains('simmer') ||
          lower.contains('serve')) {
        steps.add(sentence);
      }
    }
    if (steps.isEmpty && sentences.isNotEmpty) {
      steps.addAll(sentences.take(3));
    }
  }
}
