import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../data/services/sync_queue_service.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/cloud_sync_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../data/services/report_pdf_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../sync/sync_data_screen.dart';

import 'widgets/settings_kit.dart';

class DataSyncScreen extends ConsumerWidget {
  const DataSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_data_sync_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        children: [
          SettingsSection(
            title: l10n.settings_data_sync_title, // "Data & Sync"
            children: [const _ExportRow(), const _CloudSyncRow()],
          ),
        ],
      ),
    );
  }
}

/// The PDF export. It had no busy state and no error handling: a failure
/// said nothing, and a second tap started a second report.
class _ExportRow extends ConsumerStatefulWidget {
  const _ExportRow();

  @override
  ConsumerState<_ExportRow> createState() => _ExportRowState();
}

class _ExportRowState extends ConsumerState<_ExportRow> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    if (!ref.read(effectiveIsProProvider)) {
      PremiumConversionService().openPaywall(
        context,
        PaywallEntryPoint.reportInsight,
        featureName: 'pdf_export',
      );
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final settingsVal = ref.read(settingsProvider).valueOrNull;
    final authUser = ref.read(authStateProvider).valueOrNull;
    final name = authUser?.displayName?.trim();
    final userName =
        (name != null && name.isNotEmpty)
            ? name
            : authUser?.email?.split('@').first ?? l10n.report_guest_user;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(mealRepositoryProvider.future);
      await ReportPdfService.generateAndShareReport(
        userName: userName,
        meals: repo.getAllMeals(),
        settings: settingsVal ?? UserSettings.defaults(),
        streak: settingsVal?.currentStreak ?? 0,
      );
    } catch (e) {
      debugPrint('PDF export failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.report_failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsRow(
      icon: LucideIcons.download,
      title: l10n.settings_export_data,
      value: l10n.settings_export_desc,
      trailing:
          _busy
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : null,
      onTap: _busy ? null : _export,
    );
  }
}

/// A guest is offered the sign-in screen; a signed-in user sees what has
/// synced, and taps to sync now.
///
/// This row used to open the sign-in screen for everyone. A signed-in user who
/// picked a different account there switched accounts without the sign-out
/// wipe, so one person's meals stayed on the phone and were uploaded into the
/// other person's account when edited.
class _CloudSyncRow extends ConsumerWidget {
  const _CloudSyncRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null || user.isAnonymous) {
      return SettingsRow(
        icon: LucideIcons.cloud,
        title: l10n.settings_data_sync_title,
        value: l10n.settings_cloud_sync_desc,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SyncDataScreen(
                      onSkip: () => Navigator.pop(context),
                      onAuthSuccess: () => Navigator.pop(context),
                    ),
              ),
            ),
      );
    }

    final sync = ref.watch(cloudSyncProvider);
    final locale = Localizations.localeOf(context).toString();
    final email = user.email;

    return ListenableBuilder(
      listenable: SyncQueueService(),
      builder: (context, _) {
        final pending = SyncQueueService().pendingCount;
        final lastSyncedAt = sync.lastSyncedAt;
        final String status;
        if (sync.isSyncing) {
          status = l10n.sync_status_syncing;
        } else if (sync.phase == CloudSyncPhase.failed) {
          status = l10n.sync_status_failed;
        } else if (pending > 0) {
          status = l10n.sync_status_pending(pending);
        } else if (lastSyncedAt != null) {
          status = l10n.sync_status_last(
            DateFormat.MMMd(locale).add_jm().format(lastSyncedAt),
          );
        } else {
          status = l10n.sync_status_never;
        }

        return SettingsRow(
          icon: LucideIcons.cloud,
          title: l10n.sync_status_title,
          subtitle: email == null ? null : l10n.sync_signed_in_as(email),
          value: status,
          onTap:
              sync.isSyncing
                  ? null
                  : () async {
                    final ok = await ref
                        .read(cloudSyncProvider.notifier)
                        .syncNow(manual: true);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? l10n.sync_status_done : l10n.sync_status_failed,
                        ),
                      ),
                    );
                  },
        );
      },
    );
  }
}
