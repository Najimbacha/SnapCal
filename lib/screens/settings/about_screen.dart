import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_page_scaffold.dart';

import 'widgets/settings_kit.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version =
            info != null ? 'v${info.version}+${info.buildNumber}' : '';
        return AppPageScaffold(
          title: l10n.settings_about_title,
          scrollable: true,
          padding: EdgeInsets.zero,
          backgroundColor: settingsBg(context),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isDark
                              ? [
                                const Color(0xFF1A1A2E),
                                const Color(0xFF0D0D1A),
                              ]
                              : [
                                AppColors.primary.withValues(alpha: 0.06),
                                AppColors.primary.withValues(alpha: 0.02),
                              ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.3 : 0.15,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/icon/icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SnapCal',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1C1917),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AI-Powered Calorie Tracker',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.15 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          version,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AboutLink(
                      icon: LucideIcons.shield,
                      title: l10n.settings_privacy,
                      subtitle: l10n.settings_privacy_desc,
                      onTap:
                          () => launchUrl(
                            Uri.parse(
                              'https://gist.githubusercontent.com/Najimbacha/ab1c18844431efb2c5701e36f1ab0ff0/raw',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _AboutLink(
                      icon: LucideIcons.fileText,
                      title: l10n.settings_terms,
                      subtitle: l10n.settings_terms_desc,
                      onTap:
                          () => launchUrl(
                            Uri.parse('https://snapcal.app/terms'),
                            mode: LaunchMode.externalApplication,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const _FollowUsSection(),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Made with ❤️',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white24 : const Color(0xFFD6D3D1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AboutLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AboutLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.06,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: isDark ? Colors.white24 : const Color(0xFFD6D3D1),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUsSection extends StatelessWidget {
  const _FollowUsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'FOLLOW US',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? Colors.white54 : const Color(0xFFB4AFA8),
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.08) : kSettingsLine,
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              _FollowTile(
                icon: LucideIcons.camera,
                iconColor: const Color(0xFFE1306C),
                title: 'Instagram',
                subtitle: l10n.about_instagram_desc,
                onTap:
                    () => launchUrl(
                      Uri.parse('https://www.instagram.com/snap_calories/'),
                      mode: LaunchMode.externalApplication,
                    ),
                isDark: isDark,
                isLast: false,
              ),
              _FollowTile(
                icon: LucideIcons.facebook,
                iconColor: const Color(0xFF1877F2),
                title: 'Facebook',
                subtitle: l10n.about_facebook_desc,
                onTap:
                    () => launchUrl(
                      Uri.parse('https://www.facebook.com/Snapcalories'),
                      mode: LaunchMode.externalApplication,
                    ),
                isDark: isDark,
                isLast: false,
              ),
              _FollowTile(
                icon: LucideIcons.mail,
                iconColor: AppColors.primary,
                title: l10n.about_email_us,
                subtitle: 'iamnajimbacha@gmail.com',
                onTap:
                    () => launchUrl(
                      Uri.parse('mailto:iamnajimbacha@gmail.com'),
                      mode: LaunchMode.externalApplication,
                    ),
                isDark: isDark,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FollowTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final bool isLast;

  const _FollowTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            color: settingsText(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: AppTypography.labelSmall.copyWith(
                            color: settingsSubtext(context),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: settingsSubtext(context).withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color:
                isDark ? Colors.white.withValues(alpha: 0.06) : kSettingsLine,
            indent: 66,
          ),
      ],
    );
  }
}
