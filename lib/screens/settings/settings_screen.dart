import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'widgets/weight_entry_modal.dart';
import '../../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: context.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Settings',
                style: AppTypography.heading1.copyWith(
                  color: context.textPrimaryColor,
                  letterSpacing: -1,
                ),
              ),
              background: Container(color: context.backgroundColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Header - only rebuilds when auth changes
                  Selector<AuthProvider, _AuthSnapshot>(
                    selector:
                        (_, auth) => _AuthSnapshot(
                          isAnonymous: auth.isAnonymous,
                          displayName: auth.user?.displayName,
                          email: auth.user?.email,
                        ),
                    builder:
                        (context, authSnap, _) =>
                            _buildProfileHeader(authSnap, context)
                                .animate()
                                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                                .slideY(begin: 0.1, duration: 400.ms),
                  ),
                  const SizedBox(height: 32),

                  // Body Profile Section - only rebuilds when relevant values change
                  ..._buildBodyProfileSection(context),

                  // Nutrition Goals Section - only rebuilds when goals change
                  ..._buildNutritionGoalsSection(context),

                  // Preferences Section
                  ..._buildPreferencesSection(context),

                  // Appearance Section
                  ..._buildAppearanceSection(context),

                  // Subscription Section
                  ..._buildSubscriptionSection(context),

                  // Support Section
                  ..._buildSupportSection(context),

                  const SizedBox(height: 32),
                  // Sign Out button
                  Selector<AuthProvider, bool>(
                    selector: (_, auth) => auth.isAnonymous,
                    builder: (context, isAnonymous, _) {
                      if (isAnonymous) return const SizedBox.shrink();
                      return GlassContainer(
                        padding: EdgeInsets.zero,
                        borderRadius: 20,
                        backgroundColor: Colors.transparent,
                        borderColor: AppColors.error.withOpacity(0.2),
                        child: TextButton(
                          onPressed: () => _handleLogout(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.logOut,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sign Out',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 400.ms);
                    },
                  ),

                  const SizedBox(height: 48),
                  Text(
                    'SnapCal v1.0.0',
                    style: AppTypography.labelSmall.copyWith(
                      color: context.textMutedColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body Profile Section ─────────────────────────────────────────
  List<Widget> _buildBodyProfileSection(BuildContext context) {
    return _buildSettingsSection('BODY PROFILE', context, [
      // Current Weight - only rebuilds when weight changes
      Selector<MetricsProvider, double?>(
        selector: (_, m) => m.currentWeight,
        builder:
            (context, weight, _) => _buildGoalTile(
              context,
              'Current Weight',
              weight != null ? '${weight.toStringAsFixed(1)} kg' : 'Set Weight',
              LucideIcons.scale,
              const Color(0xFF6B4DFF),
              () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const WeightEntryModal(),
              ),
            ),
      ),
      _buildDivider(context),
      // Height
      Selector<SettingsProvider, double?>(
        selector: (_, s) => s.height,
        builder:
            (context, height, _) => _buildGoalTile(
              context,
              'Height',
              height != null ? '${height.round()} cm' : 'Set Height',
              LucideIcons.ruler,
              const Color(0xFF5E5CE6),
              () => _showGoalDialog(
                context,
                'Height',
                height?.toInt() ?? 170,
                (val) => context.read<SettingsProvider>().updateBodyProfile(
                  height: val.toDouble(),
                ),
                unit: 'cm',
              ),
            ),
      ),
      _buildDivider(context),
      // Target Weight
      Selector<SettingsProvider, double?>(
        selector: (_, s) => s.targetWeight,
        builder:
            (context, targetWeight, _) => _buildGoalTile(
              context,
              'Target Weight',
              targetWeight != null ? '${targetWeight} kg' : 'Set Target',
              LucideIcons.target,
              const Color(0xFFFF2D55),
              () => _showGoalDialog(
                context,
                'Target Weight',
                targetWeight?.toInt() ?? 70,
                (val) => context.read<SettingsProvider>().updateBodyProfile(
                  targetWeight: val.toDouble(),
                ),
                unit: 'kg',
              ),
            ),
      ),
    ], delay: 100);
  }

  // ─── Nutrition Goals Section ──────────────────────────────────────
  List<Widget> _buildNutritionGoalsSection(BuildContext context) {
    return _buildSettingsSection('NUTRITION GOALS', context, [
      // Daily Calories - only rebuilds when calorie goal changes
      Selector<SettingsProvider, int>(
        selector: (_, s) => s.dailyCalorieGoal,
        builder:
            (context, calorieGoal, _) => _buildGoalTile(
              context,
              'Daily Calories',
              '$calorieGoal kcal',
              LucideIcons.flame,
              const Color(0xFFFF453A),
              () => _showGoalDialog(
                context,
                'Calories',
                calorieGoal,
                context.read<SettingsProvider>().updateCalorieGoal,
              ),
            ),
      ),
      _buildDivider(context),
      // Protein
      Selector<SettingsProvider, int>(
        selector: (_, s) => s.dailyProteinGoal,
        builder:
            (context, proteinGoal, _) => _buildGoalTile(
              context,
              'Protein',
              '${proteinGoal}g',
              LucideIcons.beef,
              const Color(0xFF30D158),
              () => _showGoalDialog(
                context,
                'Protein',
                proteinGoal,
                context.read<SettingsProvider>().updateProteinGoal,
              ),
            ),
      ),
      _buildDivider(context),
      // Carbs
      Selector<SettingsProvider, int>(
        selector: (_, s) => s.dailyCarbGoal,
        builder:
            (context, carbGoal, _) => _buildGoalTile(
              context,
              'Carbs',
              '${carbGoal}g',
              LucideIcons.apple,
              const Color(0xFF0A84FF),
              () => _showGoalDialog(
                context,
                'Carbs',
                carbGoal,
                context.read<SettingsProvider>().updateCarbGoal,
              ),
            ),
      ),
      _buildDivider(context),
      // Fats
      Selector<SettingsProvider, int>(
        selector: (_, s) => s.dailyFatGoal,
        builder:
            (context, fatGoal, _) => _buildGoalTile(
              context,
              'Fats',
              '${fatGoal}g',
              LucideIcons.droplets,
              const Color(0xFFFF9F0A),
              () => _showGoalDialog(
                context,
                'Fat',
                fatGoal,
                context.read<SettingsProvider>().updateFatGoal,
              ),
            ),
      ),
    ], delay: 200);
  }

  // ─── Preferences Section ──────────────────────────────────────────
  List<Widget> _buildPreferencesSection(BuildContext context) {
    return _buildSettingsSection('PREFERENCES', context, [
      Selector<SettingsProvider, bool>(
        selector: (_, s) => s.notificationsEnabled,
        builder:
            (context, notifEnabled, _) => Column(
              children: [
                _buildSwitchTile(
                  context,
                  'Notifications',
                  LucideIcons.bell,
                  const Color(0xFFFF375F),
                  notifEnabled,
                  context.read<SettingsProvider>().toggleNotifications,
                ),
                if (notifEnabled) ...[
                  _buildDivider(context),
                  Selector<SettingsProvider, bool>(
                    selector: (_, s) => s.mealRemindersEnabled,
                    builder:
                        (context, mealReminders, _) => _buildSwitchTile(
                          context,
                          'Meal Reminders',
                          LucideIcons.clock,
                          const Color(0xFFBF5AF2),
                          mealReminders,
                          context.read<SettingsProvider>().toggleMealReminders,
                        ),
                  ),
                ],
              ],
            ),
      ),
    ], delay: 300);
  }

  // ─── Appearance Section ───────────────────────────────────────────
  List<Widget> _buildAppearanceSection(BuildContext context) {
    return _buildSettingsSection('APPEARANCE', context, [
      Selector<SettingsProvider, String>(
        selector: (_, s) => s.themeMode,
        builder:
            (context, themeMode, _) => _buildThemeSelector(context, themeMode),
      ),
    ], delay: 400);
  }

  // ─── Subscription Section ─────────────────────────────────────────
  List<Widget> _buildSubscriptionSection(BuildContext context) {
    return _buildSettingsSection('SUBSCRIPTION', context, [
      Selector<SettingsProvider, bool>(
        selector: (_, s) => s.isPro,
        builder:
            (context, isPro, _) => ListTile(
              onTap: () => context.push('/paywall'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: GlassContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: 12,
                backgroundColor:
                    isPro
                        ? const Color(0xFFFFD60A).withOpacity(0.2)
                        : context.surfaceLightColor.withOpacity(0.5),
                borderColor:
                    isPro
                        ? const Color(0xFFFFD60A).withOpacity(0.5)
                        : context.glassBorderColor,
                child: Icon(
                  LucideIcons.crown,
                  color:
                      isPro
                          ? const Color(0xFFFFD60A)
                          : context.textPrimaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                'Manage Subscription',
                style: AppTypography.bodyLarge.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF30D158), Color(0xFF28A745)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: context.textMutedColor,
                  ),
                ],
              ),
            ),
      ),
    ], delay: 500);
  }

  // ─── Support Section ──────────────────────────────────────────────
  List<Widget> _buildSupportSection(BuildContext context) {
    return _buildSettingsSection('SUPPORT', context, [
      _buildSimpleTile(
        context,
        LucideIcons.helpCircle,
        'Help Center',
        const Color(0xFF64D2FF),
      ),
      _buildDivider(context),
      _buildSimpleTile(
        context,
        LucideIcons.shieldCheck,
        'Privacy Policy',
        const Color(0xFF32D74B),
      ),
      _buildDivider(context),
      _buildSimpleTile(
        context,
        LucideIcons.info,
        'About SnapCal',
        const Color(0xFF8E8E93),
      ),
    ], delay: 600);
  }

  // ─── Shared Builders ──────────────────────────────────────────────
  List<Widget> _buildSettingsSection(
    String title,
    BuildContext context,
    List<Widget> children, {
    int delay = 0,
  }) {
    return [
      _buildSectionHeader(title, context),
      GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: 24,
            backgroundColor: context.surfaceColor.withOpacity(0.4),
            child: Column(children: children),
          )
          .animate()
          .fadeIn(delay: delay.ms, duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.05, duration: 400.ms),
      const SizedBox(height: 32),
    ];
  }

  Widget _buildProfileHeader(_AuthSnapshot auth, BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 28,
      backgroundColor: context.surfaceColor.withOpacity(0.6),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: context.glassBorderColor),
            ),
            child: Icon(LucideIcons.user, size: 36, color: AppColors.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isAnonymous
                      ? 'Guest User'
                      : (auth.displayName ?? 'SnapCal User'),
                  style: AppTypography.heading3.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceLightColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    auth.isAnonymous
                        ? 'Sign in to sync data'
                        : (auth.email ?? 'Premium Account'),
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (auth.isAnonymous)
            GlassContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: 12,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              borderColor: AppColors.primary.withOpacity(0.2),
              child: IconButton(
                onPressed: () => context.push('/auth'),
                icon: const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: context.textSecondaryColor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: context.glassBorderColor.withOpacity(0.3),
      indent: 64,
    );
  }

  void _showGoalDialog(
    BuildContext context,
    String title,
    int current,
    Function(int) onSave, {
    String? unit,
  }) {
    final controller = TextEditingController(text: current.toString());

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: dialogContext.surfaceLightColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Set $title Goal',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                hintStyle: TextStyle(color: dialogContext.textMutedColor),
                suffixText: unit ?? (title == 'Calories' ? 'kcal' : 'g'),
                suffixStyle: AppTypography.bodySmall.copyWith(
                  color: dialogContext.textSecondaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dialogContext.glassBorderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.dispose();
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: dialogContext.textSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text);
                    if (value != null && value > 0) {
                      Navigator.pop(dialogContext);
                      // Call onSave AFTER closing the dialog to avoid rebuild conflicts
                      Future.microtask(() => onSave(value));
                    }
                    controller.dispose();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildGoalTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: GlassContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 12,
        backgroundColor: iconColor.withOpacity(0.1),
        borderColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: context.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: context.textMutedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      activeColor: const Color(0xFF30D158),
      secondary: GlassContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 12,
        backgroundColor: iconColor.withOpacity(0.1),
        borderColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: context.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSimpleTile(
    BuildContext context,
    IconData icon,
    String title,
    Color iconColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: GlassContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 12,
        backgroundColor: iconColor.withOpacity(0.1),
        borderColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: context.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: context.textMutedColor,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, String currentMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 12,
            backgroundColor: const Color(0xFF5E5CE6).withOpacity(0.1),
            borderColor: const Color(0xFF5E5CE6).withOpacity(0.2),
            child: const Icon(
              LucideIcons.sun,
              color: Color(0xFF5E5CE6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Theme',
            style: AppTypography.bodyLarge.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.all(4),
            borderRadius: 16,
            backgroundColor: context.surfaceLightColor.withOpacity(0.5),
            borderColor: context.glassBorderColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _themeOption(
                  context,
                  currentMode,
                  'system',
                  LucideIcons.smartphone,
                  'Auto',
                ),
                _themeOption(
                  context,
                  currentMode,
                  'light',
                  LucideIcons.sun,
                  'Light',
                ),
                _themeOption(
                  context,
                  currentMode,
                  'dark',
                  LucideIcons.moon,
                  'Dark',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    String currentMode,
    String mode,
    IconData icon,
    String label,
  ) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => context.read<SettingsProvider>().setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : context.textMutedColor,
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    if (context.mounted) context.go('/auth');
  }
}

/// Lightweight snapshot to avoid rebuilding on every AuthProvider change
class _AuthSnapshot {
  final bool isAnonymous;
  final String? displayName;
  final String? email;

  _AuthSnapshot({required this.isAnonymous, this.displayName, this.email});

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
