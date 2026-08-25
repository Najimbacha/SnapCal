import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                                value: settings.breakfastTime,
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
                                value: settings.lunchTime,
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
                                value: settings.dinnerTime,
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
