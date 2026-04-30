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
import '../../core/utils/responsive_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Settings',
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
          const SizedBox(height: 16),
          Selector<SettingsProvider, bool>(
            selector: (_, s) => s.isPro,
            builder: (context, isPro, _) {
              if (isPro) return const SizedBox.shrink();
              return const _UpgradeProCard();
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const SectionLabel(title: 'Core Configuration'),
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
                  title: 'Body Profile',
                  subtitle: 'Update your stats and goals',
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
                  title: 'Nutrition Goals',
                  subtitle: 'Daily calorie and macro targets',
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
                  title: 'Preferences',
                  subtitle: 'App theme and notification settings',
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
            child: const SectionLabel(title: 'Data & Security'),
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
                  title: 'Account',
                  subtitle: 'Membership and profile security',
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
                  title: 'Data & Sync',
                  subtitle: 'Export and cloud backup options',
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
            child: const SectionLabel(title: 'Information'),
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
                  title: 'About',
                  subtitle: 'Terms, privacy, and app info',
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
                'SNAPCAL PREMIUM v1.0.0',
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
                'Enter your $title below',
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
                'Cancel',
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
              child: const Text('Confirm'),
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
            'Display Name',
            style: AppTypography.heading3.copyWith(fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How should we call you?',
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
                'Cancel',
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
              child: const Text('Save Name'),
            ),
          ],
        ),
  );
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(icon, color: accent, size: 22),
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
                        letterSpacing: -0.5,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTypography.labelMedium.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
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
    final colorScheme = Theme.of(context).colorScheme;
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
            activeColor: AppColors.primary,
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
                  'App Appearance',
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
              for (final option in const [
                ('system', 'System'),
                ('light', 'Light'),
                ('dark', 'Dark'),
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
        const SnackBar(content: Text('Log your weight first to recalculate.')),
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
                "I just optimized my nutrition plan. Please explain why these specific calories and macros were chosen for me based on my profile.",
          );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete your profile first (age, gender, height, target).'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            _isLoading ? 'Optimizing Plan…' : 'Optimize My Nutrition Plan',
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
  const _ProfileCard({required this.auth, super.key});

  @override
  Widget build(BuildContext context) {
    final hasName = auth.displayName != null && auth.displayName!.isNotEmpty;
    final isGuest = auth.isAnonymous;
    
    String displayName = auth.displayName ?? '';
    if (!hasName && auth.email != null) {
      displayName = auth.email!.split('@')[0];
      // Capitalize first letter
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }
    if (displayName.isEmpty) displayName = 'SnapCal Member';

    return GestureDetector(
      onTap: isGuest ? () => context.push('/auth') : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isGuest 
            ? LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.wellnessGlow,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isGuest ? Colors.black : AppColors.primary).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                isGuest ? LucideIcons.userPlus : LucideIcons.sparkles,
                size: 100,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: auth.photoURL != null
                        ? Image.network(auth.photoURL!, fit: BoxFit.cover)
                        : Center(
                            child: Icon(
                              LucideIcons.user,
                              color: AppColors.primary,
                              size: 26,
                            ),
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
                        isGuest ? 'Guest Account' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (context.select<SettingsProvider, bool>((p) => p.isPro))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PRO',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          if (isGuest)
                            _ActionPill(
                              label: 'Sign up or Sign in',
                              icon: LucideIcons.userPlus,
                              onTap: () => context.push('/auth'),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                auth.email ?? 'Premium Life',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyProfileScreen extends StatelessWidget {
  const _BodyProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Body Profile',
      subtitle: 'Manage your physical metrics and goals.',
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
                      title: 'Display Name',
                      value: name ?? 'Set name',
                      onTap: () => _showNameDialog(context, name ?? ''),
                    ),
              ),
              Selector<MetricsProvider, double?>(
                selector: (_, metrics) => metrics.currentWeight,
                builder:
                    (context, weight, _) => _SettingRow(
                      icon: LucideIcons.scale,
                      accent: AppColors.primary,
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
                      accent: AppColors.primary,
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
                      accent: AppColors.primary,
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
        ],
      ),
    );
  }
}

class _NutritionGoalsScreen extends StatelessWidget {
  const _NutritionGoalsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Nutrition Goals',
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
                      accent: AppColors.primary,
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
                      accent: AppColors.primary,
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
                      accent: AppColors.primary,
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
          const SizedBox(height: 24),
          _RecalculateButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PreferencesScreen extends StatelessWidget {
  const _PreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Preferences',
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
                      accent: AppColors.primary,
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
        ],
      ),
    );
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Account',
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
                    title: 'Delete Account',
                    value: 'Permanently remove all data',
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await auth.signOut();
    if (context.mounted) {
      // Clear all local data providers
      await context.read<SettingsProvider>().clear();
      await context.read<MealProvider>().clear();
      await context.read<WaterProvider>().clear();
      await context.read<MetricsProvider>().clear();
      await context.read<AssistantProvider>().clear();
      await context.read<PlannerProvider>().clear();
      
      context.go('/auth');
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and will delete all your meal logs, weight history, and settings from our servers. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final auth = context.read<AuthProvider>();
        await auth.deleteAccount();
        
        if (context.mounted) {
          // Clear all local data after successful deletion
          await context.read<SettingsProvider>().clear();
          await context.read<MealProvider>().clear();
          await context.read<WaterProvider>().clear();
          await context.read<MetricsProvider>().clear();
          await context.read<AssistantProvider>().clear();
          await context.read<PlannerProvider>().clear();
          
          context.go('/auth');
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
      title: 'Data & Sync',
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              _SettingRow(
                icon: LucideIcons.download,
                accent: AppColors.primary,
                title: 'Export data',
                value: 'Download your meals & metrics',
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
                title: 'Cloud sync',
                value: 'Sign in to back up your data',
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
      title: 'About',
      scrollable: true,
      child: Column(
        children: [
          _ProfileSection(
            children: [
              _SettingRow(
                icon: LucideIcons.shield,
                accent: AppColors.primary,
                title: 'Privacy policy',
                value: 'How we handle your data',
                onTap:
                    () => launchUrl(
                      Uri.parse('https://snapcal.app/privacy'),
                      mode: LaunchMode.externalApplication,
                    ),
              ),
              _SettingRow(
                icon: LucideIcons.fileText,
                accent: AppColors.primary,
                title: 'Terms of service',
                value: 'Usage terms & conditions',
                onTap:
                    () => launchUrl(
                      Uri.parse('https://snapcal.app/terms'),
                      mode: LaunchMode.externalApplication,
                    ),
              ),
              _SettingRow(
                icon: LucideIcons.sparkles,
                accent: AppColors.primary,
                title: 'About SnapCal',
                value: 'v1.0.0',
                onTap:
                    () => showAboutDialog(
                      context: context,
                      applicationName: 'SnapCal',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          '© 2026 SnapCal. All rights reserved.',
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
  const _UpgradeProCard({super.key});

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
                    'Upgrade to Pro',
                    style: AppTypography.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Unlock unlimited scans & AI coach',
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

