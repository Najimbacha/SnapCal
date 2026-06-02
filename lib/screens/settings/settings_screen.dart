import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/services/subscription_service.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../widgets/auth_modal.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../data/services/report_pdf_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import '../sync/sync_data_screen.dart';
import 'widgets/weight_entry_modal.dart';
import '../../widgets/premium_prompt_card.dart';

const _settingsBgLight = Color(0xFFF9F8F5);
const _settingsBgDark = Color(0xFF14130F);
const _settingsInk = Color(0xFF1C1917);
const _settingsMuted = Color(0xFFA8A29E);
const _settingsLine = Color(0xFFE8E4DC);
const _settingsGreen = Color(0xFF1A3D2B);
const _settingsGreenText = Color(0xFF16733A);

Color _settingsBg(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? _settingsBgDark
      : _settingsBgLight;
}

Color _settingsText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : _settingsInk;
}

Color _settingsSubtext(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white54
      : _settingsMuted;
}

class SettingsScreen extends StatelessWidget {
  final bool? showBack;
  const SettingsScreen({super.key, this.showBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_title,
      isPremium: context.select<SettingsProvider, bool>((p) => p.isPro),
      showHeader: true,
      forceShowBackButton: showBack,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: _settingsBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Selector<AuthProvider, _AuthSnapshot>(
            selector:
                (_, auth) => _AuthSnapshot(
                  isAnonymous: auth.isAnonymous,
                  displayName: auth.user?.displayName,
                  email: auth.user?.email,
                  photoURL: auth.user?.photoURL,
                ),
            builder: (context, auth, _) => _ProfileCard(auth: auth),
          ),
          Selector<SettingsProvider, bool>(
            selector: (_, s) => s.isPro,
            builder: (context, isPro, _) {
              if (isPro) return const SizedBox(height: 24);
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  const SizedBox(height: 20),
                  PremiumPromptCard(
                    title: 'SnapCal Pro',
                    subtitle: l10n.settings_upgrade_desc,
                    buttonText: l10n.settings_upgrade_pro,
                    icon: LucideIcons.sparkles,
                    style: PremiumPromptStyle.mini,
                    onTap:
                        () => PremiumConversionService().openPaywall(
                          context,
                          PaywallEntryPoint.settings,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
          _SettingsSectionFrame(
            title: AppLocalizations.of(context)!.settings_core_config,
            accent: AppColors.primary,
            children: [
              _CategoryRow(
                icon: LucideIcons.user,
                accent: AppColors.protein,
                title: AppLocalizations.of(context)!.settings_body_profile,
                subtitle:
                    AppLocalizations.of(
                      context,
                    )!.settings_category_body_profile_sub,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _BodyProfileScreen(),
                      ),
                    ),
              ),
              _CategoryRow(
                icon: LucideIcons.flame,
                accent: AppColors.fat,
                title: AppLocalizations.of(context)!.settings_nutrition_goals,
                subtitle:
                    AppLocalizations.of(
                      context,
                    )!.settings_category_nutrition_sub,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _NutritionGoalsScreen(),
                      ),
                    ),
              ),
              _CategoryRow(
                icon: LucideIcons.settings,
                accent: AppColors.sky,
                title: AppLocalizations.of(context)!.settings_preferences,
                subtitle:
                    AppLocalizations.of(
                      context,
                    )!.settings_category_preferences_sub,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _PreferencesScreen(),
                      ),
                    ),
              ),
              _CategoryRow(
                icon: LucideIcons.trophy,
                accent: AppColors.amber,
                title: AppLocalizations.of(context)!.feature_achievements_title,
                subtitle:
                    AppLocalizations.of(
                      context,
                    )!.settings_category_achievements_sub,
                onTap: () => context.push('/achievements'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<ActivityProvider>(
            builder: (context, activity, _) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsSectionFrame(
                    title: l10n.settings_step_tracking,
                    accent: AppColors.sky,
                    children: [
                      _SwitchRow(
                        icon: LucideIcons.watch,
                        accent:
                            activity.isConnected
                                ? AppColors.success
                                : AppColors.sky,
                        title: 'Health Connect',
                        subtitle:
                            activity.isSyncing
                                ? l10n.settings_syncing_activity
                                : _getLocalStatus(
                                  context,
                                  activity.statusLabel(),
                                ),
                        value: activity.isConnected,
                        onChanged:
                            activity.isSyncing
                                ? (_) {}
                                : (enabled) {
                                  if (enabled) {
                                    activity.startTracking();
                                  } else {
                                    activity.disconnect();
                                  }
                                },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SettingsSectionFrame(
            title: AppLocalizations.of(context)!.settings_data_security,
            accent: AppColors.protein,
            children: [
              _CategoryRow(
                icon: LucideIcons.userCircle,
                accent: AppColors.protein,
                title: AppLocalizations.of(context)!.settings_account,
                subtitle:
                    AppLocalizations.of(context)!.settings_category_account_sub,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _AccountScreen()),
                    ),
              ),
              _CategoryRow(
                icon: LucideIcons.hardDrive,
                accent: AppColors.sky,
                title: AppLocalizations.of(context)!.settings_data_sync,
                subtitle:
                    AppLocalizations.of(
                      context,
                    )!.settings_category_data_sync_sub,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _DataSyncScreen(),
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSectionFrame(
            title: AppLocalizations.of(context)!.settings_information,
            accent: AppColors.amber,
            children: [
              _CategoryRow(
                icon: LucideIcons.info,
                accent: AppColors.amber,
                title: AppLocalizations.of(context)!.settings_about,
                subtitle:
                    AppLocalizations.of(context)!.settings_category_about_sub,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _AboutScreen()),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

void _showNumberDialog(
  BuildContext context, {
  required String title,
  required int currentValue,
  required String unit,
  required Future<void> Function(int) onSave,
}) {
  final controller = TextEditingController(text: currentValue.toString());

  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          backgroundColor: _settingsBg(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            title,
            style: AppTypography.heading3.copyWith(
              color: _settingsText(context),
              fontSize: 22,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.settings_enter_value(title),
                style: AppTypography.bodySmall.copyWith(
                  color: _settingsSubtext(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _settingsGreenText,
                ),
                decoration: InputDecoration(
                  suffixText: _getLocalOption(context, unit),
                  suffixStyle: AppTypography.titleMedium,
                  filled: true,
                  fillColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : _settingsLine.withValues(alpha: 0.48),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.of(context)!.common_cancel,
                style: TextStyle(color: _settingsSubtext(context)),
              ),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value == null || value <= 0) return;
                Navigator.pop(dialogContext);
                onSave(value);
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: _settingsGreen,
                foregroundColor: const Color(0xFFF0FDF4),
              ),
              child: Text(AppLocalizations.of(context)!.common_confirm),
            ),
          ],
        ),
  );
}

void _showNameDialog(BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);

  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          backgroundColor: _settingsBg(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            AppLocalizations.of(context)!.settings_display_name,
            style: AppTypography.heading3.copyWith(
              color: _settingsText(context),
              fontSize: 22,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.settings_how_to_call,
                style: AppTypography.bodySmall.copyWith(
                  color: _settingsSubtext(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _settingsGreenText,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : _settingsLine.withValues(alpha: 0.48),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.of(context)!.common_cancel,
                style: TextStyle(color: _settingsSubtext(context)),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext);
                context.read<AuthProvider>().updateDisplayName(name);
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: _settingsGreen,
                foregroundColor: const Color(0xFFF0FDF4),
              ),
              child: Text(AppLocalizations.of(context)!.settings_save_name),
            ),
          ],
        ),
  );
}

void _showGenderSelector(BuildContext context, SettingsProvider settings) {
  final currentWeightKg = context.read<MetricsProvider>().currentWeight;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) => _SelectionSheet(
          title: AppLocalizations.of(context)!.settings_gender,
          options: const ['male', 'female', 'other'],
          currentValue: settings.gender ?? 'male',
          onSelect:
              (value) => settings.updateBodyProfile(
                gender: value,
                currentWeightKg: currentWeightKg,
              ),
        ),
  );
}

void _showUnitSelector(BuildContext context, SettingsProvider settings) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SelectionSheet(
              title: AppLocalizations.of(context)!.settings_weight_unit,
              options: const ['kg', 'lb'],
              currentValue: settings.weightUnit,
              onSelect: (value) => settings.updateUnits(weightUnit: value),
            ),
            _SelectionSheet(
              title: AppLocalizations.of(context)!.settings_height_unit,
              options: const ['cm', 'in'],
              currentValue: settings.heightUnit,
              onSelect: (value) => settings.updateUnits(heightUnit: value),
            ),
          ],
        ),
  );
}

Future<void> _selectTime(
  BuildContext context,
  SettingsProvider settings,
  String type,
) async {
  final current =
      type == 'breakfast'
          ? settings.breakfastTime
          : type == 'lunch'
          ? settings.lunchTime
          : settings.dinnerTime;

  final parts = current.split(':');
  final initial = TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 8,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
  );

  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _settingsGreenText),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (type == 'breakfast') {
      await settings.updateReminderTimes(breakfast: timeStr);
    } else if (type == 'lunch') {
      await settings.updateReminderTimes(lunch: timeStr);
    } else {
      await settings.updateReminderTimes(dinner: timeStr);
    }
  }
}

class _SelectionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String currentValue;
  final Function(String) onSelect;

  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _settingsBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading3),
          const SizedBox(height: 20),
          ...options.map(
            (opt) => ListTile(
              title: Text(
                _getLocalOption(context, opt),
                style: AppTypography.titleMedium.copyWith(
                  color: _settingsText(context),
                ),
              ),
              trailing:
                  opt == currentValue
                      ? const Icon(LucideIcons.check, color: _settingsGreenText)
                      : null,
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _getLanguageName(String code) {
  switch (code) {
    case 'ar':
      return 'العربية';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    default:
      return 'English';
  }
}

void _showLanguageSelector(BuildContext context, SettingsProvider settings) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: _settingsBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : _settingsLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.settings_select_language,
                  style: AppTypography.heading3.copyWith(
                    color: _settingsText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.settings_language_desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: _settingsSubtext(context),
                  ),
                ),
                const SizedBox(height: 24),
                _LanguageTile(
                  title: 'English',
                  subtitle: AppLocalizations.of(context)!.settings_lang_en_desc,
                  code: 'en',
                  selected: settings.languageCode == 'en',
                  onTap: () {
                    settings.setLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _LanguageTile(
                  title: 'العربية',
                  subtitle: AppLocalizations.of(context)!.settings_lang_ar_desc,
                  code: 'ar',
                  selected: settings.languageCode == 'ar',
                  onTap: () {
                    settings.setLanguage('ar');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _LanguageTile(
                  title: 'Español',
                  subtitle: AppLocalizations.of(context)!.settings_lang_es_desc,
                  code: 'es',
                  selected: settings.languageCode == 'es',
                  onTap: () {
                    settings.setLanguage('es');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _LanguageTile(
                  title: 'Français',
                  subtitle: AppLocalizations.of(context)!.settings_lang_fr_desc,
                  code: 'fr',
                  selected: settings.languageCode == 'fr',
                  onTap: () {
                    settings.setLanguage('fr');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected
                  ? _settingsGreenText.withValues(alpha: isDark ? 0.16 : 0.09)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0x00FFFFFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? _settingsGreenText.withValues(alpha: 0.24)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _settingsLine),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    selected
                        ? _settingsGreenText
                        : _settingsMuted.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Text(
                code.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          selected
                              ? _settingsGreenText
                              : _settingsText(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: _settingsSubtext(context),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(LucideIcons.checkCircle2, color: _settingsGreenText),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent =
        accent == AppColors.error ? accent : _settingsGreenText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(
                    alpha: isDark ? 0.14 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, color: effectiveAccent, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: _settingsText(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: _settingsSubtext(context),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: _settingsSubtext(context).withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent =
        accent == AppColors.error ? accent : _settingsGreenText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: effectiveAccent.withValues(alpha: isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: effectiveAccent, size: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: _settingsText(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: _settingsSubtext(context),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.3,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _settingsGreenText,
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final String currentMode;

  const _ThemeRow({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      (
        'system',
        AppLocalizations.of(context)!.settings_theme_system,
        LucideIcons.smartphone,
      ),
      (
        'light',
        AppLocalizations.of(context)!.settings_theme_light,
        LucideIcons.sun,
      ),
      (
        'dark',
        AppLocalizations.of(context)!.settings_theme_dark,
        LucideIcons.moon,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Label row ───
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _settingsGreenText.withValues(
                    alpha: isDark ? 0.14 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.sunMoon,
                    color: _settingsGreenText,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                AppLocalizations.of(context)!.settings_appearance,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: _settingsText(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ─── Segmented picker — full width below, indented past icon ───
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : _settingsLine.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children:
                    options.map((opt) {
                      final isSelected = currentMode == opt.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            settings.setThemeMode(opt.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? (isDark
                                          ? Colors.white.withValues(alpha: 0.09)
                                          : _settingsBgLight)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.15 : 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  opt.$3,
                                  size: 13,
                                  color:
                                      isSelected
                                          ? _settingsGreenText
                                          : _settingsSubtext(context),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  opt.$2,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontSize: 11.5,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? _settingsGreenText
                                            : _settingsSubtext(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSnapshot {
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoURL;

  const _AuthSnapshot({
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoURL,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AuthSnapshot &&
          isAnonymous == other.isAnonymous &&
          displayName == other.displayName &&
          email == other.email &&
          photoURL == other.photoURL;

  @override
  int get hashCode => Object.hash(isAnonymous, displayName, email, photoURL);
}

class _SettingsSectionFrame extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;

  const _SettingsSectionFrame({
    required this.title,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? Colors.white54 : const Color(0xFFB4AFA8),
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
        ),
        _SettingsSurface(
          accent: accent,
          padding: EdgeInsets.zero,
          child: Column(
            children:
                children
                    .expand(
                      (child) => [
                        child,
                        if (child != children.last)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : _settingsLine,
                            indent: 52,
                          ),
                      ],
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  const _SettingsSurface({
    required this.child,
    required this.accent,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0x00FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : _settingsLine,
          width: 0.8,
        ),
      ),
      child: child,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final _AuthSnapshot auth;
  const _ProfileCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final isGuest = auth.isAnonymous;
    final isPro = context.select<SettingsProvider, bool>((p) => p.isPro);

    if (isGuest) {
      return _GuestCard(isPro: isPro);
    }

    final l10n = AppLocalizations.of(context)!;
    final hasName = auth.displayName != null && auth.displayName!.isNotEmpty;
    String displayName = auth.displayName ?? '';
    if (!hasName && auth.email != null) {
      displayName = auth.email!.split('@')[0];
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }
    if (displayName.isEmpty) {
      displayName = l10n.settings_member;
    }

    return _MemberCard(auth: auth, displayName: displayName, isPro: isPro);
  }
}

class _GuestCard extends StatelessWidget {
  final bool isPro;
  const _GuestCard({required this.isPro});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaleTap(
      onTap: () => AuthModal.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0x00FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.08) : _settingsLine,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // Neutral grey avatar circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _settingsGreenText.withValues(
                  alpha: isDark ? 0.16 : 0.09,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  LucideIcons.user,
                  color: _settingsGreenText,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.settings_guest_account,
                    style: AppTypography.heading3.copyWith(
                      color: _settingsText(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.settings_guest_subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: _settingsSubtext(context),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _settingsGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _settingsGreenText.withValues(alpha: 0.14),
                  width: 0.8,
                ),
              ),
              child: Text(
                l10n.settings_sign_in,
                style: AppTypography.labelSmall.copyWith(
                  color: _settingsGreenText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final _AuthSnapshot auth;
  final String displayName;
  final bool isPro;

  const _MemberCard({
    required this.auth,
    required this.displayName,
    required this.isPro,
  });

  // Returns 1–2 uppercase initials from a display name
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _initials(displayName);

    return AppScaleTap(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const _AccountScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0x00FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.08) : _settingsLine,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // Avatar: photo or initials gradient
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child:
                    auth.photoURL != null
                        ? Image.network(
                          auth.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  _InitialsAvatar(initials: initials),
                        )
                        : _InitialsAvatar(initials: initials),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading3.copyWith(
                            color: _settingsText(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _settingsGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _settingsGreenText.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.gem,
                                color: _settingsGreenText,
                                size: 8,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                l10n.settings_emerald_badge.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: _settingsGreenText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    auth.email ?? l10n.settings_member,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: _settingsSubtext(context),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: _settingsSubtext(context).withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient initials avatar used when no profile photo is available.
class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: _settingsGreen,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent =
        accent == AppColors.error ? accent : _settingsGreenText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Consistent rounded-square icon — iOS Settings style
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(
                    alpha: isDark ? 0.14 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, color: effectiveAccent, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: _settingsText(context),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: _settingsSubtext(context),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.3,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: _settingsSubtext(context).withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyProfileScreen extends StatelessWidget {
  const _BodyProfileScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_body_profile_title,
      subtitle: l10n.settings_body_profile_desc,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: _settingsBg(context),
      child: Column(
        children: [
          const _WeightProgressBar(),
          const SizedBox(height: 24),
          _SettingsSectionFrame(
            title: l10n.onboarding_basic_intro_eyebrow, // "PERSONAL DETAILS"
            accent: AppColors.primary,
            children: [
              Selector<AuthProvider, String?>(
                selector: (_, auth) => auth.user?.displayName,
                builder:
                    (context, name, _) => _SettingRow(
                      icon: LucideIcons.user,
                      accent: AppColors.primary,
                      title: l10n.settings_display_name_label,
                      value: name ?? l10n.settings_set_name,
                      onTap: () => _showNameDialog(context, name ?? ''),
                    ),
              ),
              Consumer<SettingsProvider>(
                builder:
                    (context, settings, _) => Column(
                      children: [
                        _SettingRow(
                          icon: LucideIcons.calendar,
                          accent: AppColors.primary,
                          title: l10n.settings_age,
                          value: settings.age?.toString() ?? '--',
                          onTap:
                              () => _showNumberDialog(
                                context,
                                title: l10n.settings_age,
                                currentValue: settings.age ?? 25,
                                unit: 'yrs',
                                onSave:
                                    (value) => settings.updateBodyProfile(
                                      age: value,
                                      currentWeightKg:
                                          context
                                              .read<MetricsProvider>()
                                              .currentWeight,
                                    ),
                              ),
                        ),
                        _SettingRow(
                          icon: LucideIcons.userCircle,
                          accent: AppColors.primary,
                          title: l10n.settings_gender,
                          value:
                              settings.gender != null
                                  ? _getLocalGender(context, settings.gender!)
                                  : '--',
                          onTap: () => _showGenderSelector(context, settings),
                        ),
                      ],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSectionFrame(
            title: l10n.home_body_stats, // "Body Stats"
            accent: AppColors.primary,
            children: [
              Selector<MetricsProvider, (double?, String)>(
                selector:
                    (_, m) => (
                      m.currentWeight,
                      context.read<SettingsProvider>().weightUnit,
                    ),
                builder: (context, data, _) {
                  double? displayWeight = data.$1;
                  if (displayWeight != null && data.$2 == 'lb') {
                    displayWeight = displayWeight * 2.20462;
                  }
                  return _SettingRow(
                    icon: LucideIcons.scale,
                    accent: AppColors.primary,
                    title: l10n.settings_current_weight,
                    value:
                        displayWeight != null
                            ? '${displayWeight.toStringAsFixed(1)} ${_getLocalUnit(context, data.$2)}'
                            : l10n.settings_set_weight,
                    onTap:
                        () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const WeightEntryModal(),
                        ),
                  );
                },
              ),
              Selector<SettingsProvider, (double?, String)>(
                selector: (_, s) => (s.targetWeight, s.weightUnit),
                builder: (context, data, _) {
                  double? displayTarget = data.$1;
                  if (displayTarget != null && data.$2 == 'lb') {
                    displayTarget = displayTarget * 2.20462;
                  }
                  return _SettingRow(
                    icon: LucideIcons.target,
                    accent: AppColors.primary,
                    title: l10n.settings_target_weight,
                    value:
                        displayTarget != null
                            ? '${displayTarget.toStringAsFixed(1)} ${_getLocalUnit(context, data.$2)}'
                            : l10n.settings_set_target,
                    onTap:
                        () => _showNumberDialog(
                          context,
                          title: l10n.settings_target_weight,
                          currentValue:
                              displayTarget?.round() ??
                              (data.$2 == 'lb' ? 154 : 70),
                          unit: data.$2,
                          onSave: (value) {
                            double kg = value.toDouble();
                            if (data.$2 == 'lb') kg = value / 2.20462;
                            return context
                                .read<SettingsProvider>()
                                .updateBodyProfile(
                                  targetWeight: kg,
                                  currentWeightKg:
                                      context
                                          .read<MetricsProvider>()
                                          .currentWeight,
                                );
                          },
                        ),
                  );
                },
              ),
              Selector<SettingsProvider, (double?, String)>(
                selector: (_, s) => (s.height, s.heightUnit),
                builder: (context, data, _) {
                  double? displayHeight = data.$1;
                  if (displayHeight != null && data.$2 == 'in') {
                    displayHeight = displayHeight / 2.54;
                  }
                  return _SettingRow(
                    icon: LucideIcons.ruler,
                    accent: AppColors.primary,
                    title: l10n.settings_height,
                    value:
                        displayHeight != null
                            ? '${displayHeight.round()} ${_getLocalUnit(context, data.$2)}'
                            : l10n.settings_set_height,
                    onTap:
                        () => _showNumberDialog(
                          context,
                          title: l10n.settings_height,
                          currentValue:
                              displayHeight?.round() ??
                              (data.$2 == 'in' ? 67 : 170),
                          unit: data.$2,
                          onSave: (value) {
                            double cm = value.toDouble();
                            if (data.$2 == 'in') cm = value * 2.54;
                            return context
                                .read<SettingsProvider>()
                                .updateBodyProfile(
                                  height: cm,
                                  currentWeightKg:
                                      context
                                          .read<MetricsProvider>()
                                          .currentWeight,
                                );
                          },
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSectionFrame(
            title: l10n.settings_units, // "Units"
            accent: AppColors.primary,
            children: [
              Consumer<SettingsProvider>(
                builder:
                    (context, settings, _) => _SettingRow(
                      icon: LucideIcons.settings,
                      accent: AppColors.primary,
                      title: l10n.settings_units,
                      value:
                          '${_getLocalUnit(context, settings.weightUnit).toUpperCase()} / ${_getLocalUnit(context, settings.heightUnit).toUpperCase()}',
                      onTap: () => _showUnitSelector(context, settings),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionGoalsScreen extends StatelessWidget {
  const _NutritionGoalsScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPro = context.select<SettingsProvider, bool>((s) => s.isPro);
    return AppPageScaffold(
      title: l10n.settings_nutrition_goals_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: _settingsBg(context),
      child: Column(
        children: [
          if (isPro)
            const _MacroCalorieRelationshipCard()
          else
            _LockedMacroGoalsCard(
              onTap:
                  () => PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.macroDetails,
                    featureName: 'settings_macro_split',
                  ),
            ),
          const SizedBox(height: 24),
          _SettingsSectionFrame(
            title: l10n.settings_nutrition_goals, // "Nutrition Goals"
            accent: AppColors.primary,
            children: [
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyCalorieGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.flame,
                      accent: AppColors.primary,
                      title: l10n.settings_daily_calories,
                      value: '$value ${l10n.settings_kcal_unit}',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: l10n.settings_daily_calories,
                            currentValue: value,
                            unit: 'kcal',
                            onSave:
                                context
                                    .read<SettingsProvider>()
                                    .updateCalorieGoal,
                          ),
                    ),
              ),
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyProteinGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.beef,
                      accent: AppColors.primary,
                      title: l10n.settings_protein,
                      value:
                          isPro
                              ? '$value${l10n.settings_grams_unit}'
                              : l10n.macro_locked_placeholder,
                      onTap:
                          isPro
                              ? () => _showNumberDialog(
                                context,
                                title: l10n.settings_protein,
                                currentValue: value,
                                unit: 'g',
                                onSave:
                                    context
                                        .read<SettingsProvider>()
                                        .updateProteinGoal,
                              )
                              : () => PremiumConversionService().openPaywall(
                                context,
                                PaywallEntryPoint.macroDetails,
                                featureName: 'settings_protein_goal',
                              ),
                    ),
              ),
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyCarbGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.wheat,
                      accent: AppColors.primary,
                      title: l10n.settings_carbs,
                      value:
                          isPro
                              ? '$value${l10n.settings_grams_unit}'
                              : l10n.macro_locked_placeholder,
                      onTap:
                          isPro
                              ? () => _showNumberDialog(
                                context,
                                title: l10n.settings_carbs,
                                currentValue: value,
                                unit: 'g',
                                onSave:
                                    context
                                        .read<SettingsProvider>()
                                        .updateCarbGoal,
                              )
                              : () => PremiumConversionService().openPaywall(
                                context,
                                PaywallEntryPoint.macroDetails,
                                featureName: 'settings_carb_goal',
                              ),
                    ),
              ),
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyFatGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.droplets,
                      accent: AppColors.primary,
                      title: l10n.settings_fat,
                      value:
                          isPro
                              ? '$value${l10n.settings_grams_unit}'
                              : l10n.macro_locked_placeholder,
                      onTap:
                          isPro
                              ? () => _showNumberDialog(
                                context,
                                title: l10n.settings_fat,
                                currentValue: value,
                                unit: 'g',
                                onSave:
                                    context
                                        .read<SettingsProvider>()
                                        .updateFatGoal,
                              )
                              : () => PremiumConversionService().openPaywall(
                                context,
                                PaywallEntryPoint.macroDetails,
                                featureName: 'settings_fat_goal',
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

class _PreferencesScreen extends StatelessWidget {
  const _PreferencesScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_preferences_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: _settingsBg(context),
      child: Column(
        children: [
          _SettingsSectionFrame(
            title: l10n.settings_notifications, // "Notifications"
            accent: AppColors.primary,
            children: [
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.notificationsEnabled,
                builder:
                    (context, value, _) => _SwitchRow(
                      icon: LucideIcons.bell,
                      accent: AppColors.primary,
                      title: l10n.settings_notifications,
                      value: value,
                      onChanged:
                          context.read<SettingsProvider>().toggleNotifications,
                    ),
              ),
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.mealRemindersEnabled,
                builder:
                    (context, value, _) => _SwitchRow(
                      icon: LucideIcons.clock3,
                      accent: AppColors.primary,
                      title: l10n.settings_meal_reminders,
                      value: value,
                      onChanged:
                          context.read<SettingsProvider>().toggleMealReminders,
                    ),
              ),
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.dailyMotivationEnabled,
                builder:
                    (context, value, _) => _SwitchRow(
                      icon: LucideIcons.sparkles,
                      accent: AppColors.primary,
                      title: l10n.settings_daily_motivation,
                      value: value,
                      onChanged:
                          context
                              .read<SettingsProvider>()
                              .toggleDailyMotivation,
                    ),
              ),
            ],
          ),
          Selector<SettingsProvider, bool>(
            selector: (_, s) => s.mealRemindersEnabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 24),
                  _SettingsSectionFrame(
                    title: l10n.settings_meal_reminders, // "Meal Reminders"
                    accent: AppColors.primary,
                    children: [
                      Consumer<SettingsProvider>(
                        builder:
                            (context, settings, _) => Column(
                              children: [
                                _SettingRow(
                                  icon: LucideIcons.egg,
                                  accent: AppColors.primary,
                                  title: l10n.settings_breakfast_time,
                                  value: settings.breakfastTime,
                                  onTap:
                                      () => _selectTime(
                                        context,
                                        settings,
                                        'breakfast',
                                      ),
                                ),
                                _SettingRow(
                                  icon: LucideIcons.utensils,
                                  accent: AppColors.primary,
                                  title: l10n.settings_lunch_time,
                                  value: settings.lunchTime,
                                  onTap:
                                      () => _selectTime(
                                        context,
                                        settings,
                                        'lunch',
                                      ),
                                ),
                                _SettingRow(
                                  icon: LucideIcons.moon,
                                  accent: AppColors.primary,
                                  title: l10n.settings_dinner_time,
                                  value: settings.dinnerTime,
                                  onTap:
                                      () => _selectTime(
                                        context,
                                        settings,
                                        'dinner',
                                      ),
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SettingsSectionFrame(
            title: l10n.settings_appearance, // "App Appearance"
            accent: AppColors.primary,
            children: [
              Consumer<SettingsProvider>(
                builder:
                    (context, settings, _) => Column(
                      children: [
                        _ThemeRow(currentMode: settings.themeMode),
                        _SettingRow(
                          icon: LucideIcons.languages,
                          accent: AppColors.primary,
                          title: l10n.settings_language,
                          value: _getLanguageName(settings.languageCode),
                          onTap: () => _showLanguageSelector(context, settings),
                        ),
                      ],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_account_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: _settingsBg(context),
      child: Column(
        children: [
          _SettingsSectionFrame(
            title: l10n.settings_account, // "Account"
            accent: AppColors.primary,
            children: [
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.isPro,
                builder:
                    (context, isPro, _) => _SettingRow(
                      icon: LucideIcons.crown,
                      accent: AppColors.warning,
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
                    ),
              ),
              Selector<AuthProvider, bool>(
                selector: (_, auth) => auth.isAnonymous,
                builder:
                    (context, isAnonymous, _) => _SettingRow(
                      icon:
                          isAnonymous
                              ? LucideIcons.userPlus
                              : LucideIcons.logOut,
                      accent: isAnonymous ? AppColors.primary : AppColors.error,
                      title:
                          isAnonymous
                              ? l10n.settings_create_account
                              : l10n.common_sign_out,
                      value:
                          isAnonymous
                              ? l10n.settings_sync_data_desc
                              : l10n.settings_sign_out_desc,
                      onTap: () => _handleSignOut(context),
                    ),
              ),
              Selector<AuthProvider, bool>(
                selector: (_, auth) => !auth.isAnonymous,
                builder: (context, canDelete, _) {
                  if (!canDelete) return const SizedBox.shrink();
                  return _SettingRow(
                    icon: LucideIcons.trash2,
                    accent: AppColors.error,
                    title: l10n.common_delete_account,
                    value: l10n.common_delete_account_confirm,
                    onTap: () => _showDeleteConfirmation(context),
                  );
                },
              ),
              _SettingRow(
                icon: LucideIcons.refreshCw,
                accent: AppColors.primary,
                title: l10n.paywall_restore,
                value: l10n.premium_restore_success,
                onTap: () => _handleRestore(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = context.read<SettingsProvider>();
    final subService = SubscriptionService();

    HapticFeedback.mediumImpact();

    final result = await subService.restorePurchasesDetailed();
    if (!context.mounted) return;
    switch (result.status) {
      case SubscriptionStatus.active:
        settingsProvider.refresh();
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

  Future<void> _handleSignOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAnonymous) {
      AuthModal.show(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.common_sign_out),
            content: Text(
              AppLocalizations.of(context)!.common_sign_out_confirm,
            ),
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

    await auth.signOut();
    if (context.mounted) {
      final settings = context.read<SettingsProvider>();
      final meal = context.read<MealProvider>();
      final water = context.read<WaterProvider>();
      final metrics = context.read<MetricsProvider>();
      final assistant = context.read<AssistantProvider>();
      final planner = context.read<PlannerProvider>();

      await settings.clear();
      await meal.clear();
      await water.clear();
      await metrics.clear();
      await assistant.clear();
      await planner.clear();

      if (context.mounted) context.go('/auth');
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
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
        final auth = context.read<AuthProvider>();
        await auth.deleteAccount();

        if (context.mounted) {
          final settings = context.read<SettingsProvider>();
          final meal = context.read<MealProvider>();
          final water = context.read<WaterProvider>();
          final metrics = context.read<MetricsProvider>();
          final assistant = context.read<AssistantProvider>();
          final planner = context.read<PlannerProvider>();

          await settings.clear();
          await meal.clear();
          await water.clear();
          await metrics.clear();
          await assistant.clear();
          await planner.clear();

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
}

class _DataSyncScreen extends StatelessWidget {
  const _DataSyncScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_data_sync_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: _settingsBg(context),
      child: Column(
        children: [
          _SettingsSectionFrame(
            title: l10n.settings_data_sync_title, // "Data & Sync"
            accent: AppColors.primary,
            children: [
              _SettingRow(
                icon: LucideIcons.download,
                accent: AppColors.primary,
                title: l10n.settings_export_data,
                value: l10n.settings_export_desc,
                onTap: () async {
                  final mealProvider = context.read<MealProvider>();
                  final settingsProvider = context.read<SettingsProvider>();
                  final authProvider = context.read<AuthProvider>();

                  if (!settingsProvider.isPro) {
                    PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.reportInsight,
                      featureName: 'pdf_export',
                    );
                    return;
                  }

                  final userName =
                      authProvider.user?.displayName ??
                      authProvider.user?.email?.split('@').first ??
                      'Valued User';

                  await ReportPdfService.generateAndShareReport(
                    userName: userName,
                    meals: mealProvider.getReportMeals(
                      isPro: settingsProvider.isPro,
                    ),
                    settings: settingsProvider,
                    streak: settingsProvider.currentStreak,
                  );
                },
              ),
              _SettingRow(
                icon: LucideIcons.cloud,
                accent: AppColors.primary,
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

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_about_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: _settingsBg(context),
      child: Column(
        children: [
          _SettingsSectionFrame(
            title: l10n.settings_about_title, // "About"
            accent: AppColors.primary,
            children: [
              _SettingRow(
                icon: LucideIcons.shield,
                accent: AppColors.primary,
                title: l10n.settings_privacy,
                value: l10n.settings_privacy_desc,
                onTap:
                    () => launchUrl(
                      Uri.parse('https://snapcal.app/privacy'),
                      mode: LaunchMode.externalApplication,
                    ),
              ),
              _SettingRow(
                icon: LucideIcons.fileText,
                accent: AppColors.primary,
                title: l10n.settings_terms,
                value: l10n.settings_terms_desc,
                onTap:
                    () => launchUrl(
                      Uri.parse('https://snapcal.app/terms'),
                      mode: LaunchMode.externalApplication,
                    ),
              ),
              _SettingRow(
                icon: LucideIcons.sparkles,
                accent: AppColors.primary,
                title: l10n.settings_about_app,
                value: 'v1.0.0',
                onTap:
                    () => showAboutDialog(
                      context: context,
                      applicationName: 'SnapCal',
                      applicationVersion: '1.0.0',
                      applicationLegalese: l10n.settings_legalese,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightProgressBar extends StatelessWidget {
  const _WeightProgressBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<MetricsProvider, SettingsProvider>(
      builder: (context, metrics, settings, _) {
        final unit = settings.weightUnit;
        final startWeightKg = settings.startingWeight;
        final currentWeightKg = metrics.currentWeight ?? startWeightKg;
        final targetWeightKg = settings.targetWeight;

        if (startWeightKg == null ||
            targetWeightKg == null ||
            currentWeightKg == null) {
          return const SizedBox.shrink();
        }

        // Convert weights for display
        final double startWeight =
            unit == 'lb' ? startWeightKg * 2.20462 : startWeightKg;
        final double currentWeight =
            unit == 'lb' ? currentWeightKg * 2.20462 : currentWeightKg;
        final double targetWeight =
            unit == 'lb' ? targetWeightKg * 2.20462 : targetWeightKg;

        // Calculate progress percentage
        double progress = 0.0;
        final diffTotal = (startWeight - targetWeight).abs();
        if (diffTotal > 0.01) {
          if (targetWeight < startWeight) {
            // Weight loss goal
            progress =
                (startWeight - currentWeight) / (startWeight - targetWeight);
          } else {
            // Weight gain goal
            progress =
                (currentWeight - startWeight) / (targetWeight - startWeight);
          }
          progress = progress.clamp(0.0, 1.0);
        }

        final leftToGoal = (currentWeight - targetWeight).abs();
        final isLoss = targetWeight < startWeight;

        final l10n = AppLocalizations.of(context)!;
        return _SettingsSurface(
          accent: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isLoss
                        ? l10n.settings_weight_loss_progress
                        : l10n.settings_weight_gain_progress,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _settingsText(context),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _settingsGreenText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : _settingsLine,
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(color: _settingsGreenText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Values legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _WeightLabel(
                    label: l10n.settings_weight_start,
                    value:
                        '${startWeight.toStringAsFixed(1)} ${_getLocalUnit(context, unit)}',
                    alignment: CrossAxisAlignment.start,
                  ),
                  _WeightLabel(
                    label: l10n.settings_weight_current,
                    value:
                        '${currentWeight.toStringAsFixed(1)} ${_getLocalUnit(context, unit)}',
                    isHighlight: true,
                    alignment: CrossAxisAlignment.center,
                  ),
                  _WeightLabel(
                    label: l10n.settings_weight_target,
                    value:
                        '${targetWeight.toStringAsFixed(1)} ${_getLocalUnit(context, unit)}',
                    alignment: CrossAxisAlignment.end,
                  ),
                ],
              ),
              if (leftToGoal > 0.05) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : _settingsLine,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    leftToGoal <= 0.1
                        ? l10n.settings_goal_reached
                        : l10n.settings_left_to_reach_target(
                          leftToGoal.toStringAsFixed(1),
                          _getLocalUnit(context, unit),
                        ),
                    style: AppTypography.labelSmall.copyWith(
                      color: _settingsSubtext(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WeightLabel extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final CrossAxisAlignment alignment;

  const _WeightLabel({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isHighlight ? _settingsGreenText : _settingsSubtext(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            color:
                isHighlight
                    ? _settingsText(context)
                    : _settingsSubtext(context),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MacroCalorieRelationshipCard extends StatelessWidget {
  const _MacroCalorieRelationshipCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final pGrams = settings.dailyProteinGoal;
        final cGrams = settings.dailyCarbGoal;
        final fGrams = settings.dailyFatGoal;

        final pKcal = pGrams * 4.0;
        final cKcal = cGrams * 4.0;
        final fKcal = fGrams * 9.0;
        final totalKcal = pKcal + cKcal + fKcal;

        double pPct = 0.33;
        double cPct = 0.33;
        double fPct = 0.34;

        if (totalKcal > 0) {
          pPct = pKcal / totalKcal;
          cPct = cKcal / totalKcal;
          fPct = fKcal / totalKcal;
        }

        final l10n = AppLocalizations.of(context)!;
        return _SettingsSurface(
          accent: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settings_macro_calorie_split,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _settingsText(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settings_macro_calorie_split_desc,
                style: AppTypography.labelSmall.copyWith(
                  color: _settingsSubtext(context),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              // Segmented bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (pPct > 0)
                        Expanded(
                          flex: (pPct * 1000).round(),
                          child: Container(color: _settingsGreenText),
                        ),
                      if (cPct > 0)
                        Expanded(
                          flex: (cPct * 1000).round(),
                          child: Container(
                            color: _settingsGreenText.withValues(alpha: 0.58),
                          ),
                        ),
                      if (fPct > 0)
                        Expanded(
                          flex: (fPct * 1000).round(),
                          child: Container(
                            color: _settingsGreenText.withValues(alpha: 0.32),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MacroLegendItem(
                    label: l10n.settings_protein,
                    grams: '$pGrams${l10n.settings_grams_unit}',
                    kcal: '${pKcal.round()} ${l10n.settings_kcal_unit}',
                    percentage: '${(pPct * 100).round()}%',
                    color: _settingsGreenText,
                  ),
                  _MacroLegendItem(
                    label: l10n.settings_carbs,
                    grams: '$cGrams${l10n.settings_grams_unit}',
                    kcal: '${cKcal.round()} ${l10n.settings_kcal_unit}',
                    percentage: '${(cPct * 100).round()}%',
                    color: _settingsGreenText.withValues(alpha: 0.58),
                  ),
                  _MacroLegendItem(
                    label: l10n.settings_fat,
                    grams: '$fGrams${l10n.settings_grams_unit}',
                    kcal: '${fKcal.round()} ${l10n.settings_kcal_unit}',
                    percentage: '${(fPct * 100).round()}%',
                    color: _settingsGreenText.withValues(alpha: 0.32),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LockedMacroGoalsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LockedMacroGoalsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaleTap(
      onTap: onTap,
      child: _SettingsSurface(
        accent: AppColors.primary,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _settingsGreenText.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.lock,
                color: _settingsGreenText,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.macro_locked_title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _settingsText(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.macro_locked_body,
                    style: AppTypography.labelSmall.copyWith(
                      color: _settingsSubtext(context),
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              LucideIcons.chevronRight,
              color: _settingsSubtext(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroLegendItem extends StatelessWidget {
  final String label;
  final String grams;
  final String kcal;
  final String percentage;
  final Color color;

  const _MacroLegendItem({
    required this.label,
    required this.grams,
    required this.kcal,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: _settingsSubtext(context),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          grams,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: _settingsText(context),
            fontSize: 14,
          ),
        ),
        Text(
          '$kcal ($percentage)',
          style: AppTypography.labelSmall.copyWith(
            color: _settingsSubtext(context),
            fontSize: 10,
          ),
        ),
      ],
    );
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

String _getLocalStatus(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status.toLowerCase()) {
    case 'tracking enabled':
    case 'enabled':
    case 'connected':
      return l10n.settings_status_enabled;
    case 'no health connect data today':
      return 'No Health Connect data today';
    case 'permission denied':
    case 'denied':
      return l10n.settings_status_denied;
    case 'unsupported device':
    case 'unsupported':
    case 'health connect unavailable':
      return l10n.settings_status_unsupported;
    case 'tracking error':
    case 'error':
      return l10n.settings_status_error;
    case 'tracking off':
    case 'off':
    case 'not connected':
    default:
      return l10n.settings_status_off;
  }
}

String _getLocalGender(BuildContext context, String gender) {
  final l10n = AppLocalizations.of(context)!;
  switch (gender.toLowerCase()) {
    case 'male':
      return l10n.settings_gender_male;
    case 'female':
      return l10n.settings_gender_female;
    case 'other':
      return l10n.settings_gender_other;
    default:
      return gender;
  }
}

String _getLocalUnit(BuildContext context, String unit) {
  final l10n = AppLocalizations.of(context)!;
  switch (unit.toLowerCase()) {
    case 'kg':
      return l10n.settings_unit_kg;
    case 'lb':
      return l10n.settings_unit_lb;
    case 'cm':
      return l10n.settings_unit_cm;
    case 'in':
      return l10n.settings_unit_in;
    default:
      return unit;
  }
}

String _getLocalOption(BuildContext context, String option) {
  final l10n = AppLocalizations.of(context)!;
  final normalized = option.toLowerCase();
  if (normalized == 'male' || normalized == 'female' || normalized == 'other') {
    return _getLocalGender(context, normalized);
  }
  if (normalized == 'kg' ||
      normalized == 'lb' ||
      normalized == 'cm' ||
      normalized == 'in') {
    return _getLocalUnit(context, normalized);
  }
  if (normalized == 'yrs') {
    return l10n.settings_age_unit;
  }
  if (normalized == 'kcal') {
    return l10n.settings_kcal_unit;
  }
  if (normalized == 'g') {
    return l10n.settings_grams_unit;
  }
  return option;
}
