import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/weight_entry_modal.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Settings',
      subtitle:
          'Keep your goals, body profile, and preferences easy to adjust.',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Selector<AuthProvider, _AuthSnapshot>(
            selector:
                (_, auth) => _AuthSnapshot(
                  isAnonymous: auth.isAnonymous,
                  displayName: auth.user?.displayName,
                  email: auth.user?.email,
                ),
            builder: (context, auth, _) => _ProfileCard(auth: auth),
          ),
          const SizedBox(height: 18),
          const SectionLabel(title: 'Body profile'),
          const SizedBox(height: 10),
          _ProfileSection(
            children: [
              Selector<MetricsProvider, double?>(
                selector: (_, metrics) => metrics.currentWeight,
                builder:
                    (context, weight, _) => _SettingRow(
                      icon: LucideIcons.scale,
                      accent: AppColors.carbs,
                      title: 'Current weight',
                      value:
                          weight != null
                              ? '${weight.toStringAsFixed(1)} kg'
                              : 'Set weight',
                      onTap:
                          () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const WeightEntryModal(),
                          ),
                    ),
              ),
              Selector<SettingsProvider, double?>(
                selector: (_, s) => s.height,
                builder:
                    (context, height, _) => _SettingRow(
                      icon: LucideIcons.ruler,
                      accent: AppColors.protein,
                      title: 'Height',
                      value:
                          height != null
                              ? '${height.round()} cm'
                              : 'Set height',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: 'Height',
                            currentValue: height?.round() ?? 170,
                            unit: 'cm',
                            onSave:
                                (value) => context
                                    .read<SettingsProvider>()
                                    .updateBodyProfile(
                                      height: value.toDouble(),
                                    ),
                          ),
                    ),
              ),
              Selector<SettingsProvider, double?>(
                selector: (_, s) => s.targetWeight,
                builder:
                    (context, targetWeight, _) => _SettingRow(
                      icon: LucideIcons.target,
                      accent: AppColors.fat,
                      title: 'Target weight',
                      value:
                          targetWeight != null
                              ? '${targetWeight.toStringAsFixed(1)} kg'
                              : 'Set target',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: 'Target weight',
                            currentValue: targetWeight?.round() ?? 70,
                            unit: 'kg',
                            onSave:
                                (value) => context
                                    .read<SettingsProvider>()
                                    .updateBodyProfile(
                                      targetWeight: value.toDouble(),
                                    ),
                          ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel(title: 'Nutrition goals'),
          const SizedBox(height: 10),
          _ProfileSection(
            children: [
              Selector<SettingsProvider, int>(
                selector: (_, s) => s.dailyCalorieGoal,
                builder:
                    (context, value, _) => _SettingRow(
                      icon: LucideIcons.flame,
                      accent: AppColors.primary,
                      title: 'Daily calories',
                      value: '$value kcal',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: 'Daily calories',
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
                      accent: AppColors.protein,
                      title: 'Protein',
                      value: '${value}g',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: 'Protein',
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
                      accent: AppColors.carbs,
                      title: 'Carbs',
                      value: '${value}g',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: 'Carbs',
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
                      accent: AppColors.fat,
                      title: 'Fat',
                      value: '${value}g',
                      onTap:
                          () => _showNumberDialog(
                            context,
                            title: 'Fat',
                            currentValue: value,
                            unit: 'g',
                            onSave:
                                context.read<SettingsProvider>().updateFatGoal,
                          ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RecalculateButton(),
          const SizedBox(height: 18),
          const SectionLabel(title: 'Preferences'),
          const SizedBox(height: 10),
          _ProfileSection(
            children: [
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.notificationsEnabled,
                builder:
                    (context, value, _) => _SwitchRow(
                      icon: LucideIcons.bell,
                      accent: AppColors.primary,
                      title: 'Notifications',
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
                      accent: AppColors.carbs,
                      title: 'Meal reminders',
                      value: value,
                      onChanged:
                          context.read<SettingsProvider>().toggleMealReminders,
                    ),
              ),
              Selector<SettingsProvider, String>(
                selector: (_, s) => s.themeMode,
                builder: (context, mode, _) => _ThemeRow(currentMode: mode),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel(title: 'Account'),
          const SizedBox(height: 10),
          _ProfileSection(
            children: [
              Selector<SettingsProvider, bool>(
                selector: (_, s) => s.isPro,
                builder:
                    (context, isPro, _) => _SettingRow(
                      icon: LucideIcons.crown,
                      accent: AppColors.warning,
                      title: 'Subscription',
                      value: isPro ? 'Pro active' : 'Manage plan',
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
                      title: isAnonymous ? 'Create account' : 'Sign out',
                      value:
                          isAnonymous
                              ? 'Sync your data'
                              : 'Leave this device session',
                      onTap: () async {
                        if (isAnonymous) {
                          context.push('/auth');
                          return;
                        }
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) context.go('/auth');
                      },
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'SnapCal v1.0.0',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ],
      ),
    );
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
            title: Text(title),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(suffixText: unit),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value == null || value <= 0) return;
                  Navigator.pop(dialogContext);
                  onSave(value);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final _AuthSnapshot auth;

  const _ProfileCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              LucideIcons.user,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isAnonymous
                      ? 'Guest user'
                      : (auth.displayName ?? 'SnapCal user'),
                  style: AppTypography.heading3,
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isAnonymous
                      ? 'Sign in later if you want sync.'
                      : (auth.email ?? 'Signed in'),
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
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
      padding: EdgeInsets.zero,
      child: Column(
        children:
            children
                .expand(
                  (child) => [
                    child,
                    if (child != children.last)
                      Divider(height: 1, color: Theme.of(context).dividerColor),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
      title: Text(title, style: AppTypography.labelLarge),
      subtitle: Text(value, style: AppTypography.bodySmall),
      trailing: const Icon(LucideIcons.chevronRight, size: 16),
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
      title: Text(title, style: AppTypography.labelLarge),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.protein.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.sunMoon,
              color: AppColors.protein,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text('Theme', style: AppTypography.labelLarge)),
          Wrap(
            spacing: 6,
            children: [
              for (final option in const [
                ('system', 'Auto'),
                ('light', 'Light'),
                ('dark', 'Dark'),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: currentMode == option.$1,
                  onSelected: (_) => settings.setThemeMode(option.$1),
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

  const _AuthSnapshot({
    required this.isAnonymous,
    this.displayName,
    this.email,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AuthSnapshot &&
          isAnonymous == other.isAnonymous &&
          displayName == other.displayName &&
          email == other.email;

  @override
  int get hashCode => Object.hash(isAnonymous, displayName, email);
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
        const SnackBar(
          content: Text('Log your weight first to recalculate.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await settingsProvider.recalculatePlan(
      currentWeightKg: currentWeight,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Plan updated! ${settingsProvider.dailyCalorieGoal} kcal/day'
              : 'Complete your profile first (age, gender, height, target).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.tonalIcon(
      onPressed: _isLoading ? null : _recalculate,
      icon: _isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSecondaryContainer,
              ),
            )
          : const Icon(LucideIcons.refreshCw, size: 18),
      label: Text(
        _isLoading ? 'Recalculating…' : 'Recalculate My Plan',
        style: AppTypography.labelLarge,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
