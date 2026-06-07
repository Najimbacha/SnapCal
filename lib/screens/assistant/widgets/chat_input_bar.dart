import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/app_icon.dart';

/// A floating glass input bar that sits above the keyboard.
///
/// - Rounded 28px
/// - Subtle border + soft shadow
/// - Left attach image button (shows a preview chip when an image is attached)
/// - Right gradient send button (highlighted when text is non-empty)
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Uint8List? attachedImage;
  final bool enabled;
  final ValueChanged<String> onSubmit;
  final VoidCallback onAttachImage;
  final VoidCallback onRemoveImage;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.attachedImage,
    required this.enabled,
    required this.onSubmit,
    required this.onAttachImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = controller.text.trim().isNotEmpty;
    final canSend = enabled && (hasText || attachedImage != null);

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachedImage != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        attachedImage!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: onRemoveImage,
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            AppSymbols.x,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard
                  : context.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : context.cardBorderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.4 : 0.06,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _CircleIconButton(
                    icon: AppSymbols.camera,
                    onTap: enabled ? onAttachImage : null,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        return TextField(
                          controller: controller,
                          enabled: enabled,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          cursorColor: AppColors.homeCoachAccent,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimaryColor,
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: enabled
                                ? 'Ask your coach anything…'
                                : 'Upgrade to continue…',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.textMutedColor,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) {
                            if (canSend) onSubmit(controller.text);
                          },
                          onChanged: (_) => (context as Element).markNeedsBuild(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SendButton(
                    canSend: canSend,
                    onTap: () {
                      if (canSend) onSubmit(controller.text);
                    },
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? context.textMutedColor
              : context.textSecondaryColor,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool canSend;
  final VoidCallback onTap;
  const _SendButton({required this.canSend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.homeCoachAccent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: canSend
              ? LinearGradient(
                  colors: [
                    accent,
                    accent.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canSend
              ? null
              : AppColors.homeCoachAccent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          AppSymbols.arrowUp,
          size: 18,
          color: canSend
              ? Colors.white
              : accent.withValues(alpha: 0.5),
        ),
      ).animate(target: canSend ? 1 : 0).scaleXY(
            duration: 200.ms,
            begin: 1,
            end: 1.0,
          ),
    );
  }
}
