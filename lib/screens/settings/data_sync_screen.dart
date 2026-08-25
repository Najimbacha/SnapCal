import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../providers/auth_state_provider.dart';
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
            children: [
              SettingsRow(
                icon: LucideIcons.download,
                title: l10n.settings_export_data,
                value: l10n.settings_export_desc,
                onTap: () async {
                  final settingsVal = ref.read(settingsProvider).valueOrNull;
                  final authUser = ref.read(authStateProvider).valueOrNull;

                  if (!(settingsVal?.isPro ?? false)) {
                    PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.reportInsight,
                      featureName: 'pdf_export',
                    );
                    return;
                  }

                  final userName =
                      authUser?.displayName ??
                      authUser?.email?.split('@').first ??
                      'Valued User';

                  final repo = await ref.read(mealRepositoryProvider.future);
                  await ReportPdfService.generateAndShareReport(
                    userName: userName,
                    meals: repo.getAllMeals(),
                    settings: settingsVal ?? UserSettings.defaults(),
                    streak: settingsVal?.currentStreak ?? 0,
                  );
                },
              ),
              SettingsRow(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
