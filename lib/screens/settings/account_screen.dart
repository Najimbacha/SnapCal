import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
                    onTap:
                        () => PremiumConversionService().openPaywall(
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
                value: l10n.premium_restore_success,
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

    if (context.mounted) context.go('/auth');
  }
}

Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.common_delete_account),
          content: Text(
            AppLocalizations.of(context)!.common_delete_account_confirm,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(
                AppLocalizations.of(context)!.common_delete_permanently,
              ),
            ),
          ],
        ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await ref.read(authNotifierProvider.notifier).deleteAccount();

      if (context.mounted) {
        ref.invalidate(settingsProvider);
        ref.invalidate(mealLogProvider);
        ref.invalidate(waterProvider);
        ref.invalidate(bodyMetricsProvider);
        ref.invalidate(assistantProvider);
        ref.invalidate(plannerProvider);

        if (context.mounted) context.go('/auth');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
