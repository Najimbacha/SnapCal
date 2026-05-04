import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../data/services/report_pdf_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import '../sync/sync_data_screen.dart';
import 'widgets/weight_entry_modal.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.settings_title,
      isPremium: context.select<SettingsProvider, bool>((p) => p.isPro),
      forceShowBackButton: true,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 40),
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
          const SizedBox(height: 20),
          Selector<SettingsProvider, bool>(
            selector: (_, s) => s.isPro,
            builder: (context, isPro, _) {
              if (isPro) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _UpgradeProCard(),
              );
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel(title: AppLocalizations.of(context)!.settings_core_config),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            glass: true,
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _CategoryRow(
                  icon: LucideIcons.user,
                  accent: AppColors.primary,
                  title: AppLocalizations.of(context)!.settings_body_profile,
                  subtitle: AppLocalizations.of(context)!.settings_body_profile_sub,
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
                  accent: AppColors.primary,
                  title: AppLocalizations.of(context)!.settings_nutrition_goals,
                  subtitle: AppLocalizations.of(context)!.settings_nutrition_goals_sub,
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
                  accent: AppColors.primary,
                  title: AppLocalizations.of(context)!.settings_preferences,
                  subtitle: AppLocalizations.of(context)!.settings_preferences_sub,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _PreferencesScreen(),
                        ),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel(title: AppLocalizations.of(context)!.settings_data_security),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            glass: true,
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _CategoryRow(
                  icon: LucideIcons.userCircle,
                  accent: AppColors.primary,
                  title: AppLocalizations.of(context)!.settings_account,
                  subtitle: AppLocalizations.of(context)!.settings_account_sub,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _AccountScreen(),
                        ),
                      ),
                ),
                _CategoryRow(
                  icon: LucideIcons.hardDrive,
                  accent: AppColors.primary,
                  title: AppLocalizations.of(context)!.settings_data_sync,
                  subtitle: AppLocalizations.of(context)!.settings_data_sync_sub,
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
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel(title: AppLocalizations.of(context)!.settings_information),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            glass: true,
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _CategoryRow(
                  icon: LucideIcons.info,
                  accent: AppColors.primary,
                  title: AppLocalizations.of(context)!.settings_about,
                  subtitle: AppLocalizations.of(context)!.settings_about_sub,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const _AboutScreen()),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Text(
                '${AppLocalizations.of(context)!.snap_pro_unlimited.toUpperCase()} v1.0.0',
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).hintColor,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
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
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            title,
            style: AppTypography.heading3.copyWith(fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.settings_enter_value(title),
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  suffixText: unit,
                  suffixStyle: AppTypography.titleMedium,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
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
                style: TextStyle(color: colorScheme.onSurfaceVariant),
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
              ),
              child: Text(AppLocalizations.of(context)!.common_confirm),
            ),
          ],
        ),
  );
}

void _showNameDialog(BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            AppLocalizations.of(context)!.settings_display_name,
            style: AppTypography.heading3.copyWith(fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.settings_how_to_call,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
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
                style: TextStyle(color: colorScheme.onSurfaceVariant),
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
              ),
              child: Text(AppLocalizations.of(context)!.settings_save_name),
            ),
          ],
        ),
  );
}

void _showGenderSelector(BuildContext context, SettingsProvider settings) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _SelectionSheet(
      title: AppLocalizations.of(context)!.settings_gender,
      options: const ['male', 'female', 'other'],
      currentValue: settings.gender ?? 'male',
      onSelect: (value) => settings.updateBodyProfile(gender: value),
    ),
  );
}

void _showUnitSelector(BuildContext context, SettingsProvider settings) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Column(
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

Future<void> _selectTime(BuildContext context, SettingsProvider settings, String type) async {
  final current = type == 'breakfast' 
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
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading3),
          const SizedBox(height: 20),
          ...options.map((opt) => ListTile(
            title: Text(opt.toUpperCase(), style: AppTypography.titleMedium),
            trailing: opt == currentValue 
                ? const Icon(LucideIcons.check, color: AppColors.primary) 
                : null,
            onTap: () {
              onSelect(opt);
              Navigator.pop(context);
            },
          )),
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
    builder: (context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.settings_select_language,
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.settings_language_desc,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : colorScheme.outlineVariant,
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
                      color: selected ? AppColors.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(LucideIcons.checkCircle2, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}



class _ProfileSection extends StatelessWidget {
  final List<Widget> children;

  const _ProfileSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      glass: true,
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
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                        indent: 72,
                      ),
                  ],
                )
                .toList(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.15), width: 1.5),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: AppTypography.labelSmall.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                ),
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
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.sunMoon,
                  color: AppColors.protein,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.settings_appearance,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final option in [
                ('system', AppLocalizations.of(context)!.settings_theme_system),
                ('light', AppLocalizations.of(context)!.settings_theme_light),
                ('dark', AppLocalizations.of(context)!.settings_theme_dark),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          option.$2,
                          style: TextStyle(
                            fontWeight: currentMode == option.$1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      selected: currentMode == option.$1,
                      onSelected: (_) => settings.setThemeMode(option.$1),
                      showCheckmark: false,
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

class _RecalculateButton extends StatefulWidget {
  @override
  State<_RecalculateButton> createState() => _RecalculateButtonState();
}

class _RecalculateButtonState extends State<_RecalculateButton> {
  bool _isLoading = false;

  Future<void> _recalculate() async {
    final metricsProvider = context.read<MetricsProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final currentWeight = metricsProvider.currentWeight;

    if (currentWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settings_log_weight_first)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await settingsProvider.recalculatePlan(
      currentWeightKg: currentWeight,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      // Navigate to Assistant to explain the new plan
      context.push('/assistant');
      context.read<AssistantProvider>().fetchRecommendations(
            currentCalories: context.read<MealProvider>().todaysTotalCalories,
            targetCalories: context.read<SettingsProvider>().dailyCalorieGoal,
            currentMacros: {
              'protein': context.read<MealProvider>().todaysTotalMacros.protein,
              'carbs': context.read<MealProvider>().todaysTotalMacros.carbs,
              'fat': context.read<MealProvider>().todaysTotalMacros.fat,
            },
            targetMacros: {
              'protein': context.read<SettingsProvider>().dailyProteinGoal,
              'carbs': context.read<SettingsProvider>().dailyCarbGoal,
              'fat': context.read<SettingsProvider>().dailyFatGoal,
            },
            mealNames: context.read<MealProvider>().recentMeals.map((m) => m.foodName).toList(),
            dietaryRestriction: context.read<SettingsProvider>().dietaryRestriction,
            userQuery:
                AppLocalizations.of(context)!.settings_recalculate_query,
          );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settings_complete_profile_first),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _isLoading ? null : _recalculate,
          icon:
              _isLoading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(LucideIcons.sparkles, size: 20),
          label: Text(
            _isLoading 
              ? AppLocalizations.of(context)!.settings_optimizing 
              : AppLocalizations.of(context)!.settings_optimize_btn,
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final _AuthSnapshot auth;
  const _ProfileCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final hasName = auth.displayName != null && auth.displayName!.isNotEmpty;
    final isGuest = auth.isAnonymous;
    final isPro = context.select<SettingsProvider, bool>((p) => p.isPro);
    
    String displayName = auth.displayName ?? '';
    if (!hasName && auth.email != null) {
      displayName = auth.email!.split('@')[0];
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }
    if (displayName.isEmpty) displayName = AppLocalizations.of(context)!.settings_member;

    return GestureDetector(
      onTap: isGuest ? () => context.push('/auth') : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isGuest 
            ? LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                  const Color(0xFF064E3B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (isGuest ? Colors.black : AppColors.primary).withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Icon(
                isGuest ? LucideIcons.userPlus : LucideIcons.sparkles,
                size: 120,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: auth.photoURL != null
                        ? Image.network(auth.photoURL!, fit: BoxFit.cover)
                        : Center(
                            child: Icon(
                              LucideIcons.user,
                              color: isGuest ? Colors.grey : AppColors.primary,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isGuest ? AppLocalizations.of(context)!.settings_guest_account : displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.heading3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          if (isPro)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCD34D).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: const Color(0xFFFCD34D).withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.gem,
                                    color: Color(0xFFFCD34D),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'EMERALD',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: const Color(0xFFFCD34D),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isGuest)
                        _ActionPill(
                          label: AppLocalizations.of(context)!.settings_auth_cta,
                          icon: LucideIcons.userPlus,
                          onTap: () => context.push('/auth'),
                        )
                      else
                        Text(
                          auth.email ?? 'Premium Nutrition',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 12, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                ),
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
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.settings_body_profile_title,
      subtitle: AppLocalizations.of(context)!.settings_body_profile_desc,
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              Selector<AuthProvider, String?>(
                selector: (_, auth) => auth.user?.displayName,
                builder:
                    (context, name, _) => _SettingRow(
                      icon: LucideIcons.user,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_display_name_label,
                      value: name ?? AppLocalizations.of(context)!.settings_set_name,
                      onTap: () => _showNameDialog(context, name ?? ''),
                    ),
              ),
              Selector<MetricsProvider, (double?, String)>(
                selector: (_, m) => (m.currentWeight, context.read<SettingsProvider>().weightUnit),
                builder: (context, data, _) {
                  double? displayWeight = data.$1;
                  if (displayWeight != null && data.$2 == 'lb') {
                    displayWeight = displayWeight * 2.20462;
                  }
                  return _SettingRow(
                    icon: LucideIcons.scale,
                    accent: AppColors.primary,
                    title: AppLocalizations.of(context)!.settings_current_weight,
                    value: displayWeight != null
                        ? '${displayWeight.toStringAsFixed(1)} ${data.$2}'
                        : AppLocalizations.of(context)!.settings_set_weight,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WeightEntryModal(),
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
                    title: AppLocalizations.of(context)!.settings_height,
                    value: displayHeight != null
                        ? '${displayHeight.round()} ${data.$2}'
                        : AppLocalizations.of(context)!.settings_set_height,
                    onTap: () => _showNumberDialog(
                      context,
                      title: AppLocalizations.of(context)!.settings_height,
                      currentValue: displayHeight?.round() ?? (data.$2 == 'in' ? 67 : 170),
                      unit: data.$2,
                      onSave: (value) {
                        double cm = value.toDouble();
                        if (data.$2 == 'in') cm = value * 2.54;
                        return context.read<SettingsProvider>().updateBodyProfile(height: cm);
                      },
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
                    title: AppLocalizations.of(context)!.settings_target_weight,
                    value: displayTarget != null
                        ? '${displayTarget.toStringAsFixed(1)} ${data.$2}'
                        : AppLocalizations.of(context)!.settings_set_target,
                    onTap: () => _showNumberDialog(
                      context,
                      title: AppLocalizations.of(context)!.settings_target_weight,
                      currentValue: displayTarget?.round() ?? (data.$2 == 'lb' ? 154 : 70),
                      unit: data.$2,
                      onSave: (value) {
                        double kg = value.toDouble();
                        if (data.$2 == 'lb') kg = value / 2.20462;
                        return context.read<SettingsProvider>().updateBodyProfile(targetWeight: kg);
                      },
                    ),
                  );
                },
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => Column(
                  children: [
                    _SettingRow(
                      icon: LucideIcons.calendar,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_age,
                      value: settings.age?.toString() ?? '--',
                      onTap: () => _showNumberDialog(
                        context,
                        title: AppLocalizations.of(context)!.settings_age,
                        currentValue: settings.age ?? 25,
                        unit: 'yrs',
                        onSave: (value) => settings.updateBodyProfile(age: value),
                      ),
                    ),
                    _SettingRow(
                      icon: LucideIcons.userCircle,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_gender,
                      value: settings.gender?.toUpperCase() ?? '--',
                      onTap: () => _showGenderSelector(context, settings),
                    ),
                    _SettingRow(
                      icon: LucideIcons.settings,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_units,
                      value: '${settings.weightUnit.toUpperCase()} / ${settings.heightUnit.toUpperCase()}',
                      onTap: () => _showUnitSelector(context, settings),
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

class _NutritionGoalsScreen extends StatelessWidget {
  const _NutritionGoalsScreen();
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.settings_nutrition_goals_title,
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyCalorieGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.flame,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_daily_calories,
                      value: '$value kcal',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: AppLocalizations.of(context)!.settings_daily_calories,
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
                      title: AppLocalizations.of(context)!.settings_protein,
                      value: '${value}g',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: AppLocalizations.of(context)!.settings_protein,
                            currentValue: value,
                            unit: 'g',
                            onSave:
                                context
                                    .read<SettingsProvider>()
                                    .updateProteinGoal,
                          ),
                    ),
              ),
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyCarbGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.wheat,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_carbs,
                      value: '${value}g',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: AppLocalizations.of(context)!.settings_carbs,
                            currentValue: value,
                            unit: 'g',
                            onSave:
                                context.read<SettingsProvider>().updateCarbGoal,
                          ),
                    ),
              ),
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyFatGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.droplets,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_fat,
                      value: '${value}g',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: AppLocalizations.of(context)!.settings_fat,
                            currentValue: value,
                            unit: 'g',
                            onSave:
                                context.read<SettingsProvider>().updateFatGoal,
                          ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _RecalculateButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PreferencesScreen extends StatelessWidget {
  const _PreferencesScreen();
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.settings_preferences_title,
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.notificationsEnabled,
                builder:
                    (context, value, _) => _SwitchRow(
                      icon: LucideIcons.bell,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_notifications,
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
                      title: AppLocalizations.of(context)!.settings_meal_reminders,
                      value: value,
                      onChanged:
                          context.read<SettingsProvider>().toggleMealReminders,
                    ),
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => Column(
                  children: [
                    _ThemeRow(currentMode: settings.themeMode),
                    _SettingRow(
                      icon: LucideIcons.languages,
                      accent: AppColors.primary,
                      title: AppLocalizations.of(context)!.settings_language,
                      value: _getLanguageName(settings.languageCode),
                      onTap: () => _showLanguageSelector(context, settings),
                    ),
                    if (settings.mealRemindersEnabled) ...[
                      _SettingRow(
                        icon: LucideIcons.egg,
                        accent: AppColors.primary,
                        title: AppLocalizations.of(context)!.settings_breakfast_time,
                        value: settings.breakfastTime,
                        onTap: () => _selectTime(context, settings, 'breakfast'),
                      ),
                      _SettingRow(
                        icon: LucideIcons.utensils,
                        accent: AppColors.primary,
                        title: AppLocalizations.of(context)!.settings_lunch_time,
                        value: settings.lunchTime,
                        onTap: () => _selectTime(context, settings, 'lunch'),
                      ),
                      _SettingRow(
                        icon: LucideIcons.moon,
                        accent: AppColors.primary,
                        title: AppLocalizations.of(context)!.settings_dinner_time,
                        value: settings.dinnerTime,
                        onTap: () => _selectTime(context, settings, 'dinner'),
                      ),
                    ],
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
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.settings_account_title,
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.isPro,
                builder:
                    (context, isPro, _) => _SettingRow(
                      icon: LucideIcons.crown,
                      accent: AppColors.warning,
                      title: AppLocalizations.of(context)!.settings_subscription,
                      value: isPro ? AppLocalizations.of(context)!.settings_pro_active : AppLocalizations.of(context)!.settings_manage_plan,
                      onTap: () => context.push('/paywall'),
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
                      title: isAnonymous ? AppLocalizations.of(context)!.settings_create_account : AppLocalizations.of(context)!.common_sign_out,
                      value:
                          isAnonymous
                              ? AppLocalizations.of(context)!.settings_sync_data_desc
                              : AppLocalizations.of(context)!.settings_sign_out_desc,
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
                    title: AppLocalizations.of(context)!.common_delete_account,
                    value: AppLocalizations.of(context)!.common_delete_account_confirm,
                    onTap: () => _showDeleteConfirmation(context),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAnonymous) {
      context.push('/auth');
      return;
    }

    // Show confirmation for logout if desired, or just do it
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.common_sign_out),
        content: Text(AppLocalizations.of(context)!.common_sign_out_confirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.common_cancel)),
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
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.common_delete_account),
        content: Text(
          AppLocalizations.of(context)!.common_delete_account_confirm,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.common_delete_permanently),
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
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.settings_data_sync_title,
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              _SettingRow(
                icon: LucideIcons.download,
                accent: AppColors.primary,
                title: AppLocalizations.of(context)!.settings_export_data,
                value: AppLocalizations.of(context)!.settings_export_desc,
                onTap: () async {
                  final mealProvider = context.read<MealProvider>();
                  final settingsProvider = context.read<SettingsProvider>();
                  final authProvider = context.read<AuthProvider>();
                  
                  final userName = authProvider.user?.displayName ?? 
                                   authProvider.user?.email?.split('@').first ?? 
                                   'Valued User';

                  await ReportPdfService.generateAndShareReport(
                    userName: userName,
                    meals: mealProvider.getWeeklyMeals(),
                    settings: settingsProvider,
                    streak: settingsProvider.currentStreak,
                  );
                },
              ),
              _SettingRow(
                icon: LucideIcons.cloud,
                accent: AppColors.primary,
                title: AppLocalizations.of(context)!.settings_data_sync_title,
                value: AppLocalizations.of(context)!.settings_cloud_sync_desc,
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
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.settings_about_title,
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              _SettingRow(
                icon: LucideIcons.shield,
                accent: AppColors.primary,
                title: AppLocalizations.of(context)!.settings_privacy,
                value: AppLocalizations.of(context)!.settings_privacy_desc,
                onTap:
                    () => launchUrl(
                      Uri.parse('https://snapcal.app/privacy'),
                      mode: LaunchMode.externalApplication,
                    ),
              ),
              _SettingRow(
                icon: LucideIcons.fileText,
                accent: AppColors.primary,
                title: AppLocalizations.of(context)!.settings_terms,
                value: AppLocalizations.of(context)!.settings_terms_desc,
                onTap:
                    () => launchUrl(
                      Uri.parse('https://snapcal.app/terms'),
                      mode: LaunchMode.externalApplication,
                    ),
              ),
              _SettingRow(
                icon: LucideIcons.sparkles,
                accent: AppColors.primary,
                title: AppLocalizations.of(context)!.settings_about_app,
                value: 'v1.0.0',
                onTap:
                    () => showAboutDialog(
                      context: context,
                      applicationName: 'SnapCal',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          AppLocalizations.of(context)!.settings_legalese,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeProCard extends StatelessWidget {
  const _UpgradeProCard();

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: () => context.push('/paywall'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.crown,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.settings_upgrade_pro,
                    style: AppTypography.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.settings_upgrade_desc,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

