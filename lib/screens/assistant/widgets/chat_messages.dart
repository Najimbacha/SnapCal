import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/assistant_service.dart';
import '../../../widgets/app_icon.dart';
import 'ai_orb.dart';
import 'chat_recipe_card.dart';

/// User message — a calm right-aligned bubble with a subtle tint.
class ChatUserBubble extends StatelessWidget {
  final String content;
  final bool hasImage;
  const ChatUserBubble({
    super.key,
    required this.content,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.08);
    final fg = context.textPrimaryColor;

    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasImage) ...[
                    Icon(
                      AppSymbols.image,
                      size: 14,
                      color: fg.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: MarkdownBody(
                      data: content,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTypography.bodyMedium.copyWith(
                          color: fg,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI response — no bubble. Avatar (mini orb) on the left, content on the
/// background. This is the calm, conversational default.
class ChatAiMessage extends StatelessWidget {
  final String title;
  final String content;
  final String type;
  final Map<String, int>? macros;
  final List<AssistantAction>? actions;
  final bool isFirst;

  const ChatAiMessage({
    super.key,
    required this.title,
    required this.content,
    this.type = 'coaching',
    this.macros,
    this.actions,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRecipe =
        type == 'recipe' || _ParsedRecipe.looksLikeRecipe(content);

    if (isRecipe) {
      return Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 12),
              child: AiOrbMini(),
            ),
            Expanded(
              child: ChatRecipeCard(
                title: _ParsedRecipe.displayTitle(
                  title,
                  content,
                  '',
                  'Recipe plan',
                ),
                content: content,
                macros: macros,
              ),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textPrimaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 12),
            child: AiOrbMini(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      height: 1.55,
                      fontSize: 14.5,
                    ),
                    strong: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                    listBullet: AppTypography.bodyMedium.copyWith(
                      color: AppColors.homeCoachAccent,
                      fontWeight: FontWeight.w900,
                    ),
                    h1: AppTypography.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                    h2: AppTypography.titleSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                    h3: AppTypography.titleSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                    code: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.85),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions!
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              a.label,
                              style: AppTypography.labelMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imports the parsed recipe from the recipe card file.
typedef _ParsedRecipe = ParsedRecipe;
