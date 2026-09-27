import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
import '../../core/theme/app_motion.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/motion/done_tick.dart';
import '../../widgets/motion/reveal.dart';
import '../sync/sync_data_screen.dart';

import 'widgets/settings_kit.dart';
import '../../widgets/wazn_icons.dart';
import '../../widgets/app_toast.dart';

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
          Reveal(
            child: SettingsSection(
              title: l10n.settings_data_sync_title, // "Data & Sync"
              children: [const _ExportRow(), const _CloudSyncRow()],
            ),
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

  /// The last report was made; the row says so, with a tick, until the page
  /// is left.
  bool _ready = false;

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

    setState(() {
      _busy = true;
      _ready = false;
    });
    var ok = false;
    try {
      final repo = await ref.read(mealRepositoryProvider.future);
      await ReportPdfService.generateAndShareReport(
        userName: userName,
        meals: repo.getAllMeals(),
        settings: settingsVal ?? UserSettings.defaults(),
        streak: settingsVal?.currentStreak ?? 0,
      );
      ok = true;
    } catch (e) {
      debugPrint('PDF export failed: $e');
      showAppToast(messenger, kind: ToastKind.error, title: l10n.report_failed);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _ready = ok;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsRow(
      icon: WaznIcons.download,
      title: l10n.settings_export_data,
      value:
          _busy
              ? l10n.settings_export_making
              : _ready
              ? l10n.settings_export_ready
              : l10n.settings_export_desc,
      trailing:
          _busy
              ? const _FillingRing(key: ValueKey('export-busy'))
              : _ready
              ? const DoneTick(
                key: ValueKey('export-done'),
                color: kSettingsGreenText,
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
class _CloudSyncRow extends ConsumerStatefulWidget {
  const _CloudSyncRow();

  @override
  ConsumerState<_CloudSyncRow> createState() => _CloudSyncRowState();
}

class _CloudSyncRowState extends ConsumerState<_CloudSyncRow> {
  /// A manual sync just finished: the row ticks and says so for a moment
  /// before going back to its usual status.
  bool _justSynced = false;
  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(cloudSyncProvider.notifier).syncNow(manual: true);
    if (!mounted) return;
    if (!ok) {
      showAppToast(
        messenger,
        kind: ToastKind.error,
        title: l10n.sync_status_failed,
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _justSynced = true);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _justSynced = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null || user.isAnonymous) {
      return SettingsRow(
        icon: WaznIcons.cloud,
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
        if (_justSynced && !sync.isSyncing) {
          status = l10n.sync_status_done;
        } else if (sync.isSyncing) {
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
          icon: WaznIcons.cloud,
          title: l10n.sync_status_title,
          subtitle: email == null ? null : l10n.sync_signed_in_as(email),
          value: status,
          trailing:
              sync.isSyncing
                  ? const _SpinningSync(key: ValueKey('sync-busy'))
                  : _justSynced
                  ? const DoneTick(
                    key: ValueKey('sync-done'),
                    color: kSettingsGreenText,
                  )
                  : null,
          onTap: sync.isSyncing ? null : _syncNow,
        );
      },
    );
  }
}

/// A ring that fills while a report is made. How long that takes is not
/// known, so it eases towards nine tenths and waits there; the row swaps it
/// for a tick when the report is done.
class _FillingRing extends StatelessWidget {
  const _FillingRing({super.key});

  @override
  Widget build(BuildContext context) {
    final calm = AppMotion.reduceMotion(context);
    return SizedBox(
      width: 20,
      height: 20,
      child:
          calm
              ? const CircularProgressIndicator(
                strokeWidth: 2.4,
                color: kSettingsGreenText,
              )
              : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: .9),
                duration: const Duration(seconds: 3),
                curve: Curves.easeOutCubic,
                builder:
                    (context, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 2.4,
                      strokeCap: StrokeCap.round,
                      color: kSettingsGreenText,
                      backgroundColor: kSettingsGreenText.withValues(
                        alpha: 0.15,
                      ),
                    ),
              ),
    );
  }
}

/// The sync arrows, turning while a sync runs.
class _SpinningSync extends StatefulWidget {
  const _SpinningSync({super.key});

  @override
  State<_SpinningSync> createState() => _SpinningSyncState();
}

class _SpinningSyncState extends State<_SpinningSync>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _turn,
      child: const Icon(WaznIcons.refresh, size: 18, color: kSettingsGreenText),
    );
  }
}
