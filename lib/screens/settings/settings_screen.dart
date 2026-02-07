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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Consumer3<SettingsProvider, AuthProvider, MetricsProvider>(
        builder: (context, settings, auth, metrics, child) {
          return CustomScrollView(
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
                      _buildProfileHeader(auth, context)
                          .animate()
                          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.1, duration: 400.ms),
                      const SizedBox(height: 32),

                      ..._buildSettingsSection('BODY PROFILE', context, [
                        _buildGoalTile(
                          context,
                          'Current Weight',
                          metrics.currentWeight != null
                              ? '${metrics.currentWeight!.toStringAsFixed(1)} kg'
                              : 'Set Weight',
                          LucideIcons.scale,
                          const Color(0xFF6B4DFF),
                          () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const WeightEntryModal(),
                          ),
                        ),
                        _buildDivider(context),
                        _buildGoalTile(
                          context,
                          'Height',
                          settings.height != null
                              ? '${settings.height!.round()} cm'
                              : 'Set Height',
                          LucideIcons.ruler,
                          const Color(0xFF5E5CE6),
                          () => _showGoalDialog(
                            context,
                            'Height',
                            settings.height?.toInt() ?? 170,
                            (val) => settings.updateBodyProfile(
                              height: val.toDouble(),
                            ),
                            unit: 'cm',
                          ),
                        ),
                        _buildDivider(context),
                        _buildGoalTile(
                          context,
                          'Target Weight',
                          settings.targetWeight != null
                              ? '${settings.targetWeight} kg'
                              : 'Set Target',
                          LucideIcons.target,
                          const Color(0xFFFF2D55),
                          () => _showGoalDialog(
                            context,
                            'Target Weight',
                            settings.targetWeight?.toInt() ?? 70,
                            (val) => settings.updateBodyProfile(
                              targetWeight: val.toDouble(),
                            ),
                            unit: 'kg',
                          ),
                        ),
                      ], delay: 100),

                      ..._buildSettingsSection('NUTRITION GOALS', context, [
                        _buildGoalTile(
                          context,
                          'Daily Calories',
                          '${settings.dailyCalorieGoal} kcal',
                          LucideIcons.flame,
                          const Color(0xFFFF453A),
                          () => _showGoalDialog(
                            context,
                            'Calories',
                            settings.dailyCalorieGoal,
                            settings.updateCalorieGoal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildGoalTile(
                          context,
                          'Protein',
                          '${settings.dailyProteinGoal}g',
                          LucideIcons.beef,
                          const Color(0xFF30D158),
                          () => _showGoalDialog(
                            context,
                            'Protein',
                            settings.dailyProteinGoal,
                            settings.updateProteinGoal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildGoalTile(
                          context,
                          'Carbs',
                          '${settings.dailyCarbGoal}g',
                          LucideIcons.apple,
                          const Color(0xFF0A84FF),
                          () => _showGoalDialog(
                            context,
                            'Carbs',
                            settings.dailyCarbGoal,
                            settings.updateCarbGoal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildGoalTile(
                          context,
                          'Fats',
                          '${settings.dailyFatGoal}g',
                          LucideIcons.droplets,
                          const Color(0xFFFF9F0A),
                          () => _showGoalDialog(
                            context,
                            'Fat',
                            settings.dailyFatGoal,
                            settings.updateFatGoal,
                          ),
                        ),
                      ], delay: 200),

                      ..._buildSettingsSection('PREFERENCES', context, [
                        _buildSwitchTile(
                          context,
                          'Notifications',
                          LucideIcons.bell,
                          const Color(0xFFFF375F),
                          settings.notificationsEnabled,
                          settings.toggleNotifications,
                        ),
                        if (settings.notificationsEnabled) ...[
                          _buildDivider(context),
                          _buildSwitchTile(
                            context,
                            'Meal Reminders',
                            LucideIcons.clock,
                            const Color(0xFFBF5AF2),
                            settings.mealRemindersEnabled,
                            settings.toggleMealReminders,
                          ),
                        ],
                      ], delay: 300),

                      ..._buildSettingsSection('APPEARANCE', context, [
                        _buildThemeSelector(context, settings),
                      ], delay: 400),

                      ..._buildSettingsSection('SUBSCRIPTION', context, [
                        ListTile(
                          onTap: () => context.push('/paywall'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: GlassContainer(
                            padding: const EdgeInsets.all(8),
                            borderRadius: 12,
                            backgroundColor:
                                settings.isPro
                                    ? const Color(0xFFFFD60A).withOpacity(0.2)
                                    : context.surfaceLightColor.withOpacity(
                                      0.5,
                                    ),
                            borderColor:
                                settings.isPro
                                    ? const Color(0xFFFFD60A).withOpacity(0.5)
                                    : context.glassBorderColor,
                            child: Icon(
                              LucideIcons.crown,
                              color:
                                  settings.isPro
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
                              if (settings.isPro)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF30D158),
                                        Color(0xFF28A745),
                                      ],
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
                      ], delay: 500),

                      ..._buildSettingsSection('SUPPORT', context, [
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
                      ], delay: 600),

                      const SizedBox(height: 32),
                      if (!auth.isAnonymous)
                        GlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: 20,
                          backgroundColor: Colors.transparent,
                          borderColor: AppColors.error.withOpacity(0.2),
                          child: TextButton(
                            onPressed: () => _handleLogout(auth, context),
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
                        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

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
          );
        },
      ),
    );
  }

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

  Widget _buildProfileHeader(AuthProvider auth, BuildContext context) {
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
                      : (auth.user?.displayName ?? 'SnapCal User'),
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
                        : (auth.user?.email ?? 'Premium Account'),
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
          (context) => AlertDialog(
            backgroundColor: context.surfaceLightColor,
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
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                hintStyle: TextStyle(color: context.textMutedColor),
                suffixText: unit ?? (title == 'Calories' ? 'kcal' : 'g'),
                suffixStyle: AppTypography.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.glassBorderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: context.textSecondaryColor,
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
                      onSave(value);
                      Navigator.pop(context);
                    }
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

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settings) {
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
                  settings,
                  'system',
                  LucideIcons.smartphone,
                  'Auto',
                ),
                _themeOption(
                  context,
                  settings,
                  'light',
                  LucideIcons.sun,
                  'Light',
                ),
                _themeOption(
                  context,
                  settings,
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
    SettingsProvider settings,
    String mode,
    IconData icon,
    String label,
  ) {
    final isSelected = settings.themeMode == mode;
    return GestureDetector(
      onTap: () => settings.setThemeMode(mode),
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

  Future<void> _handleLogout(AuthProvider auth, BuildContext context) async {
    await auth.signOut();
    if (context.mounted) context.go('/auth');
  }
}
