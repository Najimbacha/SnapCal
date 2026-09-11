import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../providers/settings_provider.dart';
import '../../data/models/user_settings.dart';
import '../../widgets/app_page_scaffold.dart';

import 'widgets/settings_kit.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_preferences_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        children: [
          const _NotificationsBlockedBanner(),
          SettingsSection(
            title: l10n.settings_notifications, // "Notifications"
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final value =
                      ref
                          .watch(settingsProvider)
                          .valueOrNull
                          ?.notificationsEnabled ??
                      true;
                  return SettingsSwitchRow(
                    icon: LucideIcons.bell,
                    title: l10n.settings_notifications,
                    value: value,
                    onChanged:
                        ref.read(settingsProvider.notifier).toggleNotifications,
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final value =
                      ref
                          .watch(settingsProvider)
                          .valueOrNull
                          ?.mealRemindersEnabled ??
                      true;
                  return SettingsSwitchRow(
                    icon: LucideIcons.clock3,
                    title: l10n.settings_meal_reminders,
                    value: value,
                    onChanged:
                        ref.read(settingsProvider.notifier).toggleMealReminders,
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final value =
                      ref
                          .watch(settingsProvider)
                          .valueOrNull
                          ?.dailyMotivationEnabled ??
                      false;
                  return SettingsSwitchRow(
                    icon: LucideIcons.sparkles,
                    title: l10n.settings_daily_motivation,
                    value: value,
                    onChanged:
                        ref
                            .read(settingsProvider.notifier)
                            .toggleDailyMotivation,
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final value =
                      ref
                          .watch(settingsProvider)
                          .valueOrNull
                          ?.foodRemindersEnabled ??
                      false;
                  return SettingsSwitchRow(
                    icon: LucideIcons.camera,
                    title: l10n.settings_food_reminders,
                    subtitle: l10n.settings_food_reminders_subtitle,
                    value: value,
                    onChanged:
                        ref.read(settingsProvider.notifier).toggleFoodReminders,
                  );
                },
              ),
            ],
          ),
          Consumer(
            builder: (context, ref, _) {
              final enabled =
                  ref
                      .watch(settingsProvider)
                      .valueOrNull
                      ?.mealRemindersEnabled ??
                  true;
              if (!enabled) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 24),
                  SettingsSection(
                    title: l10n.settings_meal_reminders, // "Meal Reminders"
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final settings =
                              ref.watch(settingsProvider).valueOrNull;
                          if (settings == null) return const SizedBox.shrink();
                          return Column(
                            children: [
                              SettingsRow(
                                icon: LucideIcons.egg,
                                title: l10n.settings_breakfast_time,
                                value: formatReminderTime(
                                  context,
                                  settings.breakfastTime,
                                ),
                                onTap:
                                    () => selectTime(
                                      context,
                                      settings,
                                      ref,
                                      'breakfast',
                                    ),
                              ),
                              SettingsRow(
                                icon: LucideIcons.utensils,
                                title: l10n.settings_lunch_time,
                                value: formatReminderTime(
                                  context,
                                  settings.lunchTime,
                                ),
                                onTap:
                                    () => selectTime(
                                      context,
                                      settings,
                                      ref,
                                      'lunch',
                                    ),
                              ),
                              SettingsRow(
                                icon: LucideIcons.moon,
                                title: l10n.settings_dinner_time,
                                value: formatReminderTime(
                                  context,
                                  settings.dinnerTime,
                                ),
                                onTap:
                                    () => selectTime(
                                      context,
                                      settings,
                                      ref,
                                      'dinner',
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_appearance, // "App Appearance"
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(settingsProvider).valueOrNull;
                  return Column(
                    children: [
                      SettingsThemeRow(
                        currentMode: settings?.themeMode ?? 'system',
                      ),
                      SettingsRow(
                        icon: LucideIcons.languages,
                        title: l10n.settings_language,
                        value: getLanguageName(settings?.languageCode ?? 'en'),
                        onTap:
                            () => showLanguageSelector(
                              context,
                              settings ?? UserSettings.defaults(),
                              ref,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Says so when the phone is blocking SnapCal's notifications.
///
/// Every switch on this screen used to read "on" while the phone dropped
/// everything, with nothing to say why reminders never came or how to fix it.
class _NotificationsBlockedBanner extends ConsumerStatefulWidget {
  const _NotificationsBlockedBanner();

  @override
  ConsumerState<_NotificationsBlockedBanner> createState() =>
      _NotificationsBlockedBannerState();
}

class _NotificationsBlockedBannerState
    extends ConsumerState<_NotificationsBlockedBanner>
    with WidgetsBindingObserver {
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the phone's settings: look again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    try {
      final status = await Permission.notification.status;
      if (!mounted) return;
      setState(() => _blocked = !status.isGranted && !status.isProvisional);
    } catch (_) {
      // No permission plugin (tests): nothing to report.
    }
  }

  Future<void> _fix() async {
    try {
      var status = await Permission.notification.status;
      if (!status.isPermanentlyDenied) {
        status = await Permission.notification.request();
      }
      if (!status.isGranted) await openAppSettings();
    } catch (_) {}
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        ref.watch(settingsProvider).valueOrNull?.notificationsEnabled ?? true;
    if (!_blocked || !enabled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SettingsSurface(
        padding: EdgeInsets.zero,
        child: SettingsRow(
          icon: LucideIcons.bellOff,
          title: l10n.notif_blocked_title,
          subtitle: l10n.notif_blocked_body,
          destructive: true,
          onTap: _fix,
        ),
      ),
    );
  }
}
