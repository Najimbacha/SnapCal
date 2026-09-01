import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user_settings.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_notifier_provider.dart';
import '../../../providers/metrics_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/ui_blocks.dart';

// Shared building blocks for the Settings area: one visual language for
// sections, rows, switches, sheets and dialogs across the root screen and
// every sub-screen.

const kSettingsBgLight = Color(0xFFF9F8F5);
const kSettingsBgDark = Color(0xFF14130F);
const kSettingsInk = Color(0xFF1C1917);
const kSettingsMuted = Color(0xFFA8A29E);
const kSettingsLine = Color(0xFFE8E4DC);
const kSettingsGreen = Color(0xFF1A3D2B);
const kSettingsGreenText = Color(0xFF16733A);

Color settingsBg(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? kSettingsBgDark
      : kSettingsBgLight;
}

Color settingsText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : kSettingsInk;
}

Color settingsSubtext(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white54
      : kSettingsMuted;
}

String? settingsLanguageName(String? code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'ar':
      return 'العربية';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    default:
      return null;
  }
}

void showSettingsNumberDialog(
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
        (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final value = int.tryParse(controller.text);
            final isValid = value != null && value > 0;

            return AlertDialog(
              backgroundColor: settingsBg(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Text(
                title,
                style: AppTypography.heading3.copyWith(
                  color: settingsText(context),
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
                      color: settingsSubtext(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: kSettingsGreenText,
                    ),
                    decoration: InputDecoration(
                      suffixText: localizeOption(context, unit),
                      suffixStyle: AppTypography.titleMedium,
                      filled: true,
                      fillColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.06)
                              : kSettingsLine.withValues(alpha: 0.48),
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
                    style: TextStyle(color: settingsSubtext(context)),
                  ),
                ),
                FilledButton(
                  onPressed:
                      isValid
                          ? () {
                            Navigator.pop(dialogContext);
                            onSave(value);
                          }
                          : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: kSettingsGreen,
                    disabledBackgroundColor: kSettingsGreen.withValues(
                      alpha: 0.35,
                    ),
                    foregroundColor: const Color(0xFFF0FDF4),
                  ),
                  child: Text(AppLocalizations.of(context)!.common_confirm),
                ),
              ],
            );
          },
        ),
  );
}

void showSettingsNameDialog(
  BuildContext context,
  WidgetRef ref,
  String currentName,
) {
  final controller = TextEditingController(text: currentName);

  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          backgroundColor: settingsBg(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            AppLocalizations.of(context)!.settings_display_name,
            style: AppTypography.heading3.copyWith(
              color: settingsText(context),
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
                  color: settingsSubtext(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: kSettingsGreenText,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : kSettingsLine.withValues(alpha: 0.48),
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
                style: TextStyle(color: settingsSubtext(context)),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext);
                ref.read(authNotifierProvider.notifier).updateDisplayName(name);
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: kSettingsGreen,
                foregroundColor: const Color(0xFFF0FDF4),
              ),
              child: Text(AppLocalizations.of(context)!.settings_save_name),
            ),
          ],
        ),
  );
}

void showGenderSelector(
  BuildContext context,
  WidgetRef ref,
  UserSettings settings,
) {
  final currentWeightKg = ref.read(bodyMetricsProvider.notifier).currentWeight;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) => SettingsSelectionSheet(
          title: AppLocalizations.of(context)!.settings_gender,
          options: const ['male', 'female', 'other'],
          currentValue: settings.gender ?? 'male',
          onSelect:
              (value) => ref
                  .read(settingsProvider.notifier)
                  .updateBodyProfile(
                    gender: value,
                    currentWeightKg: currentWeightKg,
                  ),
        ),
  );
}

void showUnitSelector(
  BuildContext context,
  UserSettings settings,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsSelectionSheet(
              title: AppLocalizations.of(context)!.settings_weight_unit,
              options: ['kg', 'lb'],
              currentValue: settings.weightUnit ?? 'kg',
              onSelect:
                  (value) => ref
                      .read(settingsProvider.notifier)
                      .updateUnits(weightUnit: value),
            ),
            const SizedBox(height: 12),
            SettingsSelectionSheet(
              title: AppLocalizations.of(context)!.settings_height_unit,
              options: ['cm', 'ft'],
              currentValue: settings.heightUnit ?? 'cm',
              onSelect:
                  (value) => ref
                      .read(settingsProvider.notifier)
                      .updateUnits(heightUnit: value),
            ),
          ],
        ),
  );
}

Future<void> selectTime(
  BuildContext context,
  UserSettings settings,
  WidgetRef ref,
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
          ).colorScheme.copyWith(primary: kSettingsGreenText),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (type == 'breakfast') {
      await ref
          .read(settingsProvider.notifier)
          .updateReminderTimes(breakfast: timeStr);
    } else if (type == 'lunch') {
      await ref
          .read(settingsProvider.notifier)
          .updateReminderTimes(lunch: timeStr);
    } else {
      await ref
          .read(settingsProvider.notifier)
          .updateReminderTimes(dinner: timeStr);
    }
  }
}

class SettingsSelectionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String currentValue;
  final Function(String) onSelect;

  const SettingsSelectionSheet({
    super.key,
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
        color: settingsBg(context),
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
                localizeOption(context, opt),
                style: AppTypography.titleMedium.copyWith(
                  color: settingsText(context),
                ),
              ),
              trailing:
                  opt == currentValue
                      ? Icon(LucideIcons.check, color: kSettingsGreenText)
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

String getLanguageName(String code) {
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

void showLanguageSelector(
  BuildContext context,
  UserSettings settings,
  WidgetRef ref,
) {
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
          color: settingsBg(context),
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
                              : kSettingsLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.settings_select_language,
                  style: AppTypography.heading3.copyWith(
                    color: settingsText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.settings_language_desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: settingsSubtext(context),
                  ),
                ),
                const SizedBox(height: 24),
                LanguageTile(
                  title: 'English',
                  subtitle: AppLocalizations.of(context)!.settings_lang_en_desc,
                  code: 'en',
                  selected: settings.languageCode == 'en',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                LanguageTile(
                  title: 'العربية',
                  subtitle: AppLocalizations.of(context)!.settings_lang_ar_desc,
                  code: 'ar',
                  selected: settings.languageCode == 'ar',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('ar');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                LanguageTile(
                  title: 'Español',
                  subtitle: AppLocalizations.of(context)!.settings_lang_es_desc,
                  code: 'es',
                  selected: settings.languageCode == 'es',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('es');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                LanguageTile(
                  title: 'Français',
                  subtitle: AppLocalizations.of(context)!.settings_lang_fr_desc,
                  code: 'fr',
                  selected: settings.languageCode == 'fr',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage('fr');
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

class LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const LanguageTile({
    super.key,
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
                  ? kSettingsGreenText.withValues(alpha: isDark ? 0.16 : 0.09)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0x00FFFFFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? kSettingsGreenText.withValues(alpha: 0.24)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : kSettingsLine),
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
                        ? kSettingsGreenText
                        : kSettingsMuted.withValues(alpha: 0.55),
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
                          selected ? kSettingsGreenText : settingsText(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: settingsSubtext(context),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(LucideIcons.checkCircle2, color: kSettingsGreenText),
          ],
        ),
      ),
    );
  }
}

/// The standard Settings row: icon, title, optional trailing value, chevron.
/// [value] carries live state ("2,000 kcal", "Connected") — never decorative
/// copy. [destructive] renders the row in the error color with no chevron.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? trailing;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.destructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = destructive ? AppColors.error : kSettingsGreenText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap == null
                ? null
                : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // A bare glyph, not a tinted well. Every row carrying the same
              // mint square made the icons read as a texture down the left
              // edge rather than as signposts — colour that marks everything
              // marks nothing. The accent is kept for the destructive row,
              // where it actually means something.
              SizedBox(
                width: 32,
                child: Icon(
                  icon,
                  size: 19,
                  color:
                      destructive
                          ? accent
                          : settingsText(context).withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color:
                        destructive ? AppColors.error : settingsText(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    fontSize: 15,
                  ),
                ),
              ),
              if (value != null && value!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: settingsSubtext(context),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (!destructive) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: settingsSubtext(context).withValues(alpha: 0.55),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = kSettingsGreenText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: accent, size: 16)),
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
                    color: settingsText(context),
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
                      color: settingsSubtext(context),
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
            activeThumbColor: kSettingsGreenText,
          ),
        ],
      ),
    );
  }
}

class SettingsThemeRow extends ConsumerWidget {
  final String currentMode;

  const SettingsThemeRow({super.key, required this.currentMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
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
                  color: kSettingsGreenText.withValues(
                    alpha: isDark ? 0.14 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.sunMoon,
                    color: kSettingsGreenText,
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
                  color: settingsText(context),
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
                        : kSettingsLine.withValues(alpha: 0.65),
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
                            settingsNotifier.setThemeMode(opt.$1);
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
                                          : kSettingsBgLight)
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
                                          ? kSettingsGreenText
                                          : settingsSubtext(context),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  opt.$2,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontSize: 12,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? kSettingsGreenText
                                            : settingsSubtext(context),
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

class SettingsAuthSnapshot {
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoURL;

  const SettingsAuthSnapshot({
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoURL,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAuthSnapshot &&
          isAnonymous == other.isAnonymous &&
          displayName == other.displayName &&
          email == other.email &&
          photoURL == other.photoURL;

  @override
  int get hashCode => Object.hash(isAnonymous, displayName, email, photoURL);
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
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
        SettingsSurface(
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
                                    : kSettingsLine,
                            indent: 62,
                            endIndent: 16,
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

class SettingsSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SettingsSurface({
    super.key,
    required this.child,
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
                : const Color(0xFFFEFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : kSettingsLine,
          width: 0.8,
        ),
      ),
      child: child,
    );
  }
}

String localizeGender(BuildContext context, String gender) {
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

String localizeUnit(BuildContext context, String unit) {
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

String localizeOption(BuildContext context, String option) {
  final l10n = AppLocalizations.of(context)!;
  final normalized = option.toLowerCase();
  if (normalized == 'male' || normalized == 'female' || normalized == 'other') {
    return localizeGender(context, normalized);
  }
  if (normalized == 'kg' ||
      normalized == 'lb' ||
      normalized == 'cm' ||
      normalized == 'in') {
    return localizeUnit(context, normalized);
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
