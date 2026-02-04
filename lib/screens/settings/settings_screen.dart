import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // True Black
      body: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(color: Colors.black),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildProfileHeader(auth, context),
                      const SizedBox(height: 32),

                      _buildSectionHeader('NUTRITION GOALS'),
                      _buildInsetGroup(
                        children: [
                          _buildGoalTile(
                            context,
                            'Daily Calories',
                            '${settings.dailyCalorieGoal} kcal',
                            LucideIcons.flame,
                            const Color(0xFFFF453A), // Red
                            () => _showGoalDialog(
                              context,
                              'Calories',
                              settings.dailyCalorieGoal,
                              settings.updateCalorieGoal,
                            ),
                          ),
                          _buildDivider(),
                          _buildGoalTile(
                            context,
                            'Protein',
                            '${settings.dailyProteinGoal}g',
                            LucideIcons.beef,
                            const Color(0xFF30D158), // Green
                            () => _showGoalDialog(
                              context,
                              'Protein',
                              settings.dailyProteinGoal,
                              settings.updateProteinGoal,
                            ),
                          ),
                          _buildDivider(),
                          _buildGoalTile(
                            context,
                            'Carbs',
                            '${settings.dailyCarbGoal}g',
                            LucideIcons.apple,
                            const Color(0xFF0A84FF), // Blue
                            () => _showGoalDialog(
                              context,
                              'Carbs',
                              settings.dailyCarbGoal,
                              settings.updateCarbGoal,
                            ),
                          ),
                          _buildDivider(),
                          _buildGoalTile(
                            context,
                            'Fats',
                            '${settings.dailyFatGoal}g',
                            LucideIcons.droplets,
                            const Color(0xFFFF9F0A), // Orange
                            () => _showGoalDialog(
                              context,
                              'Fat',
                              settings.dailyFatGoal,
                              settings.updateFatGoal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader('PREFERENCES'),
                      _buildInsetGroup(
                        children: [
                          _buildSwitchTile(
                            'Notifications',
                            LucideIcons.bell,
                            const Color(0xFFFF375F), // Pink
                            settings.notificationsEnabled,
                            settings.toggleNotifications,
                          ),
                          if (settings.notificationsEnabled) ...[
                            _buildDivider(),
                            _buildSwitchTile(
                              'Meal Reminders',
                              LucideIcons.clock,
                              const Color(0xFFBF5AF2), // Purple
                              settings.mealRemindersEnabled,
                              settings.toggleMealReminders,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader('SUPPORT'),
                      _buildInsetGroup(
                        children: [
                          _buildSimpleTile(
                            LucideIcons.helpCircle,
                            'Help Center',
                            const Color(0xFF64D2FF), // Cyan
                          ),
                          _buildDivider(),
                          _buildSimpleTile(
                            LucideIcons.shieldCheck,
                            'Privacy Policy',
                            const Color(0xFF32D74B), // Green
                          ),
                          _buildDivider(),
                          _buildSimpleTile(
                            LucideIcons.info,
                            'About SnapCal',
                            const Color(0xFF8E8E93), // Gray
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      if (!auth.isAnonymous)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => _handleLogout(auth, context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Color(0xFFFF453A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 48),
                      Text(
                        'SnapCal v1.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 48),
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

  Widget _buildProfileHeader(AuthProvider auth, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isAnonymous
                      ? 'Guest User'
                      : (auth.user?.displayName ?? 'SnapCal User'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isAnonymous
                      ? 'Sign in to sync data'
                      : (auth.user?.email ?? 'Premium Account'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (auth.isAnonymous)
            IconButton(
              onPressed: () => context.push('/auth'),
              icon: const Icon(
                LucideIcons.chevronRight,
                color: Color(0xFF8E8E93),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInsetGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.white.withOpacity(0.15),
      indent: 56, // Align with text start
    );
  }

  // Helper for dialogs not fully implemented in snippet but keep the contract
  void _showGoalDialog(
    BuildContext context,
    String title,
    int current,
    Function(int) onSave,
  ) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            title: Text(
              'Set $title Goal',
              style: const TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                suffixText: title == 'Calories' ? 'kcal' : 'g',
                suffixStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null && value > 0) {
                    onSave(value);
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Color(0xFF0A84FF)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Color(0xFF8E8E93),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    Color iconColor,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      activeColor: const Color(0xFF30D158), // iOS Green
      secondary: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSimpleTile(IconData icon, String title, Color iconColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: Color(0xFF8E8E93),
      ),
    );
  }

  Future<void> _handleLogout(AuthProvider auth, BuildContext context) async {
    await auth.signOut();
    if (context.mounted) context.go('/auth');
  }
}
