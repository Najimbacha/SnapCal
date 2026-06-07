import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// Three animated dots that suggest the AI is composing a response.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.35);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: false))
              .fadeIn(
                duration: 600.ms,
                delay: (i * 200).ms,
              )
              .fadeOut(
                duration: 600.ms,
                delay: (900 + i * 200).ms,
              ),
        );
      }),
    );
  }
}

/// Inline status used in the chat header — shows the orb + label.
class ChatStatusPill extends StatelessWidget {
  final String label;
  final bool isThinking;
  const ChatStatusPill({
    super.key,
    required this.label,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isThinking
                  ? AppColors.homeCoachAccent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4)),
            ),
          )
              .animate(
                onPlay: (c) =>
                    isThinking ? c.repeat(reverse: true) : c.stop(),
              )
              .scaleXY(
                duration: 700.ms,
                begin: 1,
                end: isThinking ? 1.6 : 1.0,
              )
              .fadeOut(
                duration: 700.ms,
              ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
