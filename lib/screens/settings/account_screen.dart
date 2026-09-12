import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/services/subscription_service.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/auth_notifier_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/planner_provider.dart';
import '../../widgets/auth_modal.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../widgets/app_page_scaffold.dart';

import 'widgets/settings_kit.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_account_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        children: [
          SettingsSection(
            title: l10n.settings_account, // "Account"
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final isPro = ref.watch(effectiveIsProProvider);
                  return SettingsRow(
                    icon: LucideIcons.crown,
                    title: l10n.settings_subscription,
                    value:
                        isPro
                            ? l10n.settings_pro_active
                            : l10n.settings_manage_plan,
                    // A Pro user was shown the buy screen again. What they
                    // need is the plan they already have, in the store.
                    onTap:
                        isPro
                            ? manageSubscription
                            : () => PremiumConversionService().openPaywall(
                              context,
                              PaywallEntryPoint.settings,
                              featureName: 'subscription',
                            ),
                  );
                },
              ),
              SettingsRow(
                icon:
                    ref.watch(isAnonymousProvider)
                        ? LucideIcons.userPlus
                        : LucideIcons.logOut,
                title:
                    ref.watch(isAnonymousProvider)
                        ? l10n.settings_create_account
                        : l10n.common_sign_out,
                value:
                    ref.watch(isAnonymousProvider)
                        ? l10n.settings_sync_data_desc
                        : l10n.settings_sign_out_desc,
                onTap: () => confirmAndSignOut(context, ref),
              ),
              if (!ref.watch(isAnonymousProvider))
                SettingsRow(
                  icon: LucideIcons.trash2,
                  title: l10n.common_delete_account,
                  value: l10n.common_delete_account_confirm,
                  onTap: () => confirmAndDeleteAccount(context, ref),
                ),
              SettingsRow(
                icon: LucideIcons.refreshCw,
                title: l10n.paywall_restore,
                // This said "Purchases Restored!" before anything was tapped.
                value: l10n.settings_restore_desc,
                onTap: () => _handleRestore(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final subService = SubscriptionService();

    // A second tap used to fall through to the service's own in-flight guard,
    // which answers `pending` -- so an impatient double-tap produced "Restore
    // is processing, Pro will unlock when the store confirms it" for a restore
    // that was merely duplicated. Stop at the door instead.
    if (subService.isRestoreInFlight) return;

    HapticFeedback.mediumImpact();

    // This row has no busy state of its own, and a restore can take several
    // seconds against the store. Say something immediately so the tap is
    // visibly acknowledged.
    _showSubscriptionSnackBar(
      messenger,
      l10n.premium_loading,
      color: AppColors.primary,
      icon: LucideIcons.refreshCw,
    );

    final result = await subService.restorePurchasesDetailed();
    if (!context.mounted) return;
    switch (result.status) {
      case SubscriptionStatus.active:
        ref.invalidate(settingsProvider);
        _showSubscriptionSnackBar(
          messenger,
          l10n.premium_restore_success,
          color: AppColors.primary,
          icon: LucideIcons.sparkles,
        );
        return;
      case SubscriptionStatus.pending:
        _showSubscriptionSnackBar(
          messenger,
          _settingsSubscriptionCopy(
            context,
            _SettingsSubscriptionCopyKey.restorePending,
          ),
          color: AppColors.warning,
          icon: LucideIcons.clock,
        );
        return;
      case SubscriptionStatus.cancelled:
        _showSubscriptionSnackBar(
          messenger,
          _settingsSubscriptionCopy(
            context,
            _SettingsSubscriptionCopyKey.restoreCancelled,
          ),
          color: AppColors.primary,
          icon: LucideIcons.checkCircle2,
        );
        return;
      case SubscriptionStatus.noPurchase:
        _showSubscriptionSnackBar(
          messenger,
          l10n.premium_restore_empty,
          color: AppColors.warning,
          icon: LucideIcons.refreshCw,
        );
        return;
      case SubscriptionStatus.offline:
        _showSubscriptionSnackBar(
          messenger,
          _settingsSubscriptionCopy(
            context,
            _SettingsSubscriptionCopyKey.restoreOffline,
          ),
          color: AppColors.warning,
          icon: LucideIcons.wifiOff,
        );
        return;
      case SubscriptionStatus.storeUnavailable:
        _showSubscriptionSnackBar(
          messenger,
          _settingsSubscriptionCopy(
            context,
            _SettingsSubscriptionCopyKey.storeSlow,
          ),
          color: AppColors.warning,
          icon: LucideIcons.clock,
        );
        return;
      case SubscriptionStatus.failed:
        _showSubscriptionSnackBar(
          messenger,
          _settingsSubscriptionCopy(
            context,
            _SettingsSubscriptionCopyKey.restoreFailed,
          ),
          color: AppColors.warning,
          icon: LucideIcons.refreshCw,
        );
        return;
    }
  }
}

enum _SettingsSubscriptionCopyKey {
  restorePending,
  restoreCancelled,
  restoreOffline,
  storeSlow,
  restoreFailed,
}

String _settingsSubscriptionCopy(
  BuildContext context,
  _SettingsSubscriptionCopyKey key,
) {
  final locale = AppLocalizations.of(context)!.localeName.split('_').first;
  final copy = switch (locale) {
    'ar' => <_SettingsSubscriptionCopyKey, String>{
      _SettingsSubscriptionCopyKey.restorePending:
          'الاستعادة قيد المعالجة. سيتم تفعيل Pro تلقائيا بعد تأكيد المتجر.',
      _SettingsSubscriptionCopyKey.restoreCancelled:
          'تم إلغاء الاستعادة. لم يتم تغيير الاشتراك.',
      _SettingsSubscriptionCopyKey.restoreOffline:
          'لا يمكن التحقق الآن. حاول مرة أخرى عند عودة الاتصال.',
      _SettingsSubscriptionCopyKey.storeSlow:
          'المتجر يستغرق وقتا أطول من المعتاد. إذا اكتمل الدفع، سيتم تفعيل Pro تلقائيا.',
      _SettingsSubscriptionCopyKey.restoreFailed:
          'تعذرت الاستعادة الآن. تحقق من الاتصال وحاول مرة أخرى.',
    },
    'es' => <_SettingsSubscriptionCopyKey, String>{
      _SettingsSubscriptionCopyKey.restorePending:
          'La restauración se está procesando. Pro se activará automáticamente cuando la tienda la confirme.',
      _SettingsSubscriptionCopyKey.restoreCancelled:
          'Restauración cancelada. Tu suscripción no cambió.',
      _SettingsSubscriptionCopyKey.restoreOffline:
          'No podemos verificarlo ahora. Inténtalo de nuevo cuando vuelva la conexión.',
      _SettingsSubscriptionCopyKey.storeSlow:
          'La tienda está tardando más de lo normal. Si el pago se completó, Pro se activará automáticamente.',
      _SettingsSubscriptionCopyKey.restoreFailed:
          'No pudimos restaurar ahora. Revisa tu conexión e inténtalo de nuevo.',
    },
    'fr' => <_SettingsSubscriptionCopyKey, String>{
      _SettingsSubscriptionCopyKey.restorePending:
          'La restauration est en cours. Pro sera activé automatiquement après confirmation du store.',
      _SettingsSubscriptionCopyKey.restoreCancelled:
          'Restauration annulée. Votre abonnement n’a pas changé.',
      _SettingsSubscriptionCopyKey.restoreOffline:
          'Vérification impossible pour le moment. Réessayez lorsque la connexion revient.',
      _SettingsSubscriptionCopyKey.storeSlow:
          'Le store prend plus de temps que prévu. Si le paiement a abouti, Pro sera activé automatiquement.',
      _SettingsSubscriptionCopyKey.restoreFailed:
          'Restauration impossible pour le moment. Vérifiez votre connexion et réessayez.',
    },
    _ => <_SettingsSubscriptionCopyKey, String>{
      _SettingsSubscriptionCopyKey.restorePending:
          'Restore is processing. Pro will unlock automatically when the store confirms it.',
      _SettingsSubscriptionCopyKey.restoreCancelled:
          'Restore cancelled. Your subscription was not changed.',
      _SettingsSubscriptionCopyKey.restoreOffline:
          'We cannot verify right now. Try again when your connection returns.',
      _SettingsSubscriptionCopyKey.storeSlow:
          'The store is taking longer than usual. If payment completed, Pro will unlock automatically.',
      _SettingsSubscriptionCopyKey.restoreFailed:
          'We could not restore right now. Check your connection and try again.',
    },
  };
  return copy[key]!;
}

void _showSubscriptionSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  required Color color,
  required IconData icon,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  // Top-level so the Settings root's destructive zone reuses one flow.
  final isAnonymousUser = ref.read(isAnonymousProvider);
  if (isAnonymousUser) {
    AuthModal.show(context);
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.common_sign_out),
          content: Text(AppLocalizations.of(context)!.common_sign_out_confirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(AppLocalizations.of(context)!.common_sign_out),
            ),
          ],
        ),
  );

  if (confirmed != true) return;

  await ref.read(authNotifierProvider.notifier).signOut();
  if (context.mounted) {
    ref.invalidate(settingsProvider);
    ref.invalidate(mealLogProvider);
    ref.invalidate(waterProvider);
    ref.invalidate(bodyMetricsProvider);
    ref.invalidate(assistantProvider);
    ref.invalidate(plannerProvider);
    ref.invalidate(plannerNotifierProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(stepGoalProvider);

    // Home, not the sign-in wall.
    //
    // This sent the user to '/auth' with go(), which replaces the stack, so
    // there was nothing to go back to -- and AuthScreen has no close. Worse,
    // main.dart signs the user back in anonymously the moment auth goes null,
    // and the router only releases '/auth' for a user who is NOT anonymous.
    // So signing out left you on a login screen you could not leave except by
    // killing the app. Signing out of a free tier means becoming a guest
    // again, and a guest belongs in the app.
    if (context.mounted) context.go('/');
  }
}

/// Opens the store's page for the subscription the user already has.
Future<void> manageSubscription() async {
  final url = await SubscriptionService().subscriptionManagementUrl();
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final isPro = ref.read(effectiveIsProProvider);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(l10n.common_delete_account),
        // Deleting the account leaves a store subscription running, and
        // charging, until it is cancelled there.
        content: Text(
          isPro
              ? '${l10n.common_delete_account_confirm}\n\n${l10n.settings_delete_subscription_note}'
              : l10n.common_delete_account_confirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.common_delete_permanently),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  // The server deletes everything, which can take up to a minute while the
  // free server wakes. The screen used to sit still after "Delete".
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder:
          (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(l10n.settings_deleting_account)),
                ],
              ),
            ),
          ),
    ),
  );

  try {
    await ref.read(authNotifierProvider.notifier).deleteAccount();
  } catch (e) {
    // This used to go home as though the account were gone, whatever
    // had happened.
    debugPrint('Account deletion failed: $e');
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.settings_delete_failed),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  navigator.pop();
  if (context.mounted) {
    ref.invalidate(settingsProvider);
    ref.invalidate(mealLogProvider);
    ref.invalidate(waterProvider);
    ref.invalidate(bodyMetricsProvider);
    ref.invalidate(assistantProvider);
    ref.invalidate(plannerProvider);
    ref.invalidate(plannerNotifierProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(stepGoalProvider);
  }
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.settings_account_deleted)),
  );
  // Same as sign-out above: a deleted account is signed back in
  // anonymously, and an anonymous user cannot leave '/auth'.
  if (context.mounted) context.go('/');
}
