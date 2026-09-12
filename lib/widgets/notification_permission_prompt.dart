import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../l10n/generated/app_localizations.dart';

/// Asks for notification permission once, with a reason, after onboarding.
///
/// The app used to ask the moment it first opened, before the user knew what
/// SnapCal was or why it wanted to notify them. Asked cold, many people say
/// no, and Android then stops asking -- while every reminder switch in
/// Settings went on reading "on".
class NotificationPermissionPrompt {
  NotificationPermissionPrompt._();

  static const _shownKey = 'notification_prompt_shown_v1';

  /// Shows the prompt if it has never been shown and the phone can still ask.
  /// Returns whether it was shown, so the caller can hold back other prompts.
  static Future<bool> maybeShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_shownKey) ?? false) return false;
      final status = await Permission.notification.status;
      // Already allowed (Android 12 and older never ask), or refused for good:
      // nothing to ask. Settings shows the way back in the second case.
      if (!status.isDenied) {
        await prefs.setBool(_shownKey, true);
        return false;
      }
      await prefs.setBool(_shownKey, true);
      if (!context.mounted) return false;
      final allow = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _PromptSheet(),
      );
      if (allow == true) await Permission.notification.request();
      return true;
    } catch (e) {
      debugPrint('Notification prompt skipped: $e');
      return false;
    }
  }
}

class _PromptSheet extends StatelessWidget {
  const _PromptSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.notif_prompt_title,
              textAlign: TextAlign.center,
              style: AppTypography.heading3.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notif_prompt_body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(l10n.notif_prompt_allow),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.notif_prompt_later,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
