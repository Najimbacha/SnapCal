import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/wazn_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/config_service.dart';
import '../../data/services/feedback_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/motion/visible_gate.dart';

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
                      _AppBadge(isDark: isDark),
                      const SizedBox(height: 20),
                      // The name rises a letter at a time.
                      Semantics(
                        label: 'Wazn',
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.ltr,
                            children: [
                              for (final (i, letter)
                                  in 'Wazn'.split('').indexed)
                                Reveal(
                                  delay: Duration(milliseconds: 380 + 55 * i),
                                  offset: const Offset(0, 14),
                                  curve: AppMotion.springCurve,
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF1C1917),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Reveal(
                        delay: const Duration(milliseconds: 640),
                        offset: const Offset(0, 8),
                        child: Text(
                          l10n.about_tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? Colors.white38
                                    : const Color(0xFFB4AFA8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Reveal(
                        delay: const Duration(milliseconds: 780),
                        offset: Offset.zero,
                        scale: .7,
                        curve: AppMotion.springCurve,
                        child: Container(
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
                    Reveal(
                      delay: Duration(milliseconds: 900),
                      child: _AboutLink(
                        icon: WaznIcons.shield,
                        title: l10n.settings_privacy,
                        subtitle: l10n.settings_privacy_desc,
                        onTap:
                            // The gist this pointed at still named AI providers
                            // the service no longer uses; the server hosts the
                            // current policy.
                            () => launchUrl(
                              Uri.parse(
                                '${ConfigService().backendProxyUrl}/privacy',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Reveal(
                      delay: Duration(milliseconds: 970),
                      child: _AboutLink(
                        icon: WaznIcons.fileText,
                        title: l10n.settings_terms,
                        subtitle: l10n.settings_terms_desc,
                        onTap:
                            () => launchUrl(
                              // snapcal.app never existed; the server hosts the terms.
                              Uri.parse(
                                '${ConfigService().backendProxyUrl}/terms',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // The app ships other people's software -- FFmpeg and the
                    // rest -- whose licences require their notices to be
                    // shown. Nothing showed them.
                    Reveal(
                      delay: Duration(milliseconds: 1040),
                      child: _AboutLink(
                        icon: WaznIcons.weight,
                        title: l10n.settings_licenses,
                        subtitle: l10n.settings_licenses_desc,
                        onTap:
                            () => showLicensePage(
                              context: context,
                              applicationName: 'Wazn',
                              applicationVersion: version,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Reveal(
                      delay: Duration(milliseconds: 1110),
                      child: _FollowUsSection(),
                    ),
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

/// The app icon. It pops in with a small tilt and sends out a soft ring;
/// tapping it does the ring again.
class _AppBadge extends StatefulWidget {
  const _AppBadge({required this.isDark});

  final bool isDark;

  @override
  State<_AppBadge> createState() => _AppBadgeState();
}

class _AppBadgeState extends State<_AppBadge>
    with TickerProviderStateMixin, VisibleGate {
  late final AnimationController _enter;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _enter.value = 1;
        return;
      }
      _enter.forward().whenComplete(() {
        if (mounted) _pulse.forward(from: 0);
      });
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _tap() {
    if (AppMotion.reduceMotion(context)) return;
    HapticFeedback.lightImpact();
    _pulse.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final icon = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
      ),
    );
    return GestureDetector(
      onTap: _tap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _pulse]),
        builder: (context, child) {
          final t = _enter.value;
          final pop = AppMotion.springCurve.transform(t);
          final p = _pulse.value;
          // A press-and-release on each pulse.
          final squeeze = 1 - 0.06 * math.sin(math.pi * (p * 2).clamp(0, 1));
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (p > 0 && p < 1)
                Transform.scale(
                  scale: 1 + 0.45 * Curves.easeOutCubic.transform(p),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: 0.9 * (1 - p),
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              Opacity(
                opacity: (t * 2).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: -0.17 * (1 - pop),
                  child: Transform.scale(
                    scale: (0.4 + 0.6 * pop) * squeeze,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: icon,
      ),
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
              WaznIcons.chevronRight,
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
            l10n.about_follow_us.toUpperCase(),
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
                icon: WaznIcons.camera,
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
                icon: WaznIcons.facebook,
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
                icon: WaznIcons.mail,
                iconColor: AppColors.primary,
                title: l10n.about_email_us,
                subtitle: FeedbackService.supportEmail,
                onTap:
                    () => launchUrl(
                      Uri.parse('mailto:${FeedbackService.supportEmail}'),
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

class _FollowTile extends StatefulWidget {
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
  State<_FollowTile> createState() => _FollowTileState();
}

/// The icon gives a little bounce as the link opens.
class _FollowTileState extends State<_FollowTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final iconColor = widget.iconColor;
    final isDark = widget.isDark;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!AppMotion.reduceMotion(context)) _bounce.forward(from: 0);
              widget.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _bounce,
                    builder: (context, child) {
                      final t = _bounce.value;
                      // Dips, overshoots, settles.
                      final scale =
                          t == 0
                              ? 1.0
                              : 1 - 0.2 * math.sin(math.pi * t * 2) * (1 - t);
                      final tilt = -0.14 * math.sin(math.pi * t * 2) * (1 - t);
                      return Transform.rotate(
                        angle: tilt,
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(
                          alpha: isDark ? 0.20 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: settingsText(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.subtitle,
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
                    WaznIcons.chevronRight,
                    size: 14,
                    color: settingsSubtext(context).withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!widget.isLast)
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
