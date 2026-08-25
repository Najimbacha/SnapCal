import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/premium_prompt_card.dart';
import '../../widgets/ui_blocks.dart';
import '../home/widgets/activity_health_connect_sheet.dart';
import 'account_screen.dart';
import 'widgets/settings_kit.dart';

/// Settings root: grouped inset lists in the platform-standard pattern —
/// title rows carrying their live value, one accent, destructive action
/// isolated at the bottom.
class SettingsScreen extends ConsumerWidget {
  final bool? showBack;
  const SettingsScreen({super.key, this.showBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isPro = settings?.isPro ?? false;
    final isAnonymous =
        ref.watch(authStateProvider).valueOrNull?.isAnonymous ?? true;
    final healthConnected =
        ref.watch(activityProvider).valueOrNull?.healthConnected ?? false;

    String? bodyValue;
    if (settings != null) {
      final parts = <String>[];
      if (settings.age != null) parts.add('${settings.age}');
      if (settings.gender != null) {
        parts.add(localizeGender(context, settings.gender!));
      }
      bodyValue = parts.isEmpty ? null : parts.join(' · ');
    }

    return AppPageScaffold(
      title: l10n.settings_title,
      isPremium: isPro,
      showHeader: true,
      forceShowBackButton: showBack,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authStateProvider).valueOrNull;
              return _ProfileCard(
                auth: SettingsAuthSnapshot(
                  isAnonymous: auth?.isAnonymous ?? true,
                  displayName: auth?.displayName,
                  email: auth?.email,
                  photoURL: auth?.photoURL,
                ),
              );
            },
          ),
          if (!isPro) ...[
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
          ],
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_core_config,
            children: [
              SettingsRow(
                icon: LucideIcons.user,
                title: l10n.settings_body_profile,
                value: bodyValue,
                onTap: () => context.push('/settings/body-profile'),
              ),
              SettingsRow(
                icon: LucideIcons.flame,
                title: l10n.settings_nutrition_goals,
                value:
                    settings == null
                        ? null
                        : '${settings.dailyCalorieGoal} ${l10n.settings_kcal_unit}',
                onTap: () => context.push('/settings/nutrition-goals'),
              ),
              SettingsRow(
                icon: LucideIcons.settings,
                title: l10n.settings_preferences,
                value: settingsLanguageName(settings?.languageCode),
                onTap: () => context.push('/settings/preferences'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_data_security,
            children: [
              SettingsRow(
                icon: LucideIcons.watch,
                title: 'Health Connect',
                value:
                    healthConnected
                        ? l10n.settings_status_connected
                        : l10n.settings_status_not_connected,
                onTap: () => showActivityHealthConnectSheet(context),
              ),
              SettingsRow(
                icon: LucideIcons.hardDrive,
                title: l10n.settings_data_sync,
                onTap: () => context.push('/settings/data-sync'),
              ),
              SettingsRow(
                icon: LucideIcons.userCircle,
                title: l10n.settings_account,
                value: isAnonymous ? l10n.settings_create_account : null,
                onTap: () => context.push('/settings/account'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_information,
            children: [
              SettingsRow(
                icon: LucideIcons.info,
                title: l10n.settings_about,
                onTap: () => context.push('/settings/about'),
              ),
            ],
          ),
          if (!isAnonymous) ...[
            const SizedBox(height: 24),
            SettingsSurface(
              padding: EdgeInsets.zero,
              child: SettingsRow(
                icon: LucideIcons.logOut,
                title: l10n.common_sign_out,
                destructive: true,
                onTap: () => confirmAndSignOut(context, ref),
              ),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            _DebugProToggle(),
            const SizedBox(height: 12),
            const _DebugOnboardingButton(),
          ],
        ],
      ),
    );
  }
}

class _DebugProToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectivePro = ref.watch(effectiveIsProProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.read(debugProOverrideProvider.notifier).toggle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:
                effectivePro
                    ? const Color(0xFFE8F5E9).withValues(alpha: 0.5)
                    : const Color(0xFFFFEBEE).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  effectivePro
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                      : const Color(0xFFEF9A9A).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                effectivePro ? LucideIcons.shieldCheck : LucideIcons.bug,
                size: 20,
                color:
                    effectivePro
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug: Pro ${effectivePro ? "ON" : "OFF"}',
                      style: TextStyle(
                        color:
                            effectivePro
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to toggle (debug only)',
                      style: TextStyle(
                        color: const Color(0xFFA8A29E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: const Color(0xFFA8A29E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugOnboardingButton extends StatelessWidget {
  const _DebugOnboardingButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/onboarding'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.flag, size: 20, color: Color(0xFF1565C0)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug: Onboarding',
                      style: TextStyle(
                        color: const Color(0xFF1565C0),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Replay the onboarding flow',
                      style: TextStyle(
                        color: const Color(0xFFA8A29E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: const Color(0xFFA8A29E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final SettingsAuthSnapshot auth;
  const _ProfileCard({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = auth.isAnonymous;
    final isPro = ref.watch(settingsProvider).valueOrNull?.isPro ?? false;

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
                isDark ? Colors.white.withValues(alpha: 0.08) : kSettingsLine,
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
                color: kSettingsGreenText.withValues(
                  alpha: isDark ? 0.16 : 0.09,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  LucideIcons.user,
                  color: kSettingsGreenText,
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
                      color: settingsText(context),
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
                      color: settingsSubtext(context),
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
                color: kSettingsGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: kSettingsGreenText.withValues(alpha: 0.14),
                  width: 0.8,
                ),
              ),
              child: Text(
                l10n.settings_sign_in,
                style: AppTypography.labelSmall.copyWith(
                  color: kSettingsGreenText,
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
  final SettingsAuthSnapshot auth;
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
      onTap: () => context.push('/settings/account'),
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
                isDark ? Colors.white.withValues(alpha: 0.08) : kSettingsLine,
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
                            color: settingsText(context),
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
                            color: kSettingsGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: kSettingsGreenText.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.gem,
                                color: kSettingsGreenText,
                                size: 8,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                l10n.settings_emerald_badge.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: kSettingsGreenText,
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
                      color: settingsSubtext(context),
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
              color: settingsSubtext(context).withValues(alpha: 0.55),
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
        color: kSettingsGreen,
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
