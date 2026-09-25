import 'dart:math' as math;

import '../../data/services/feedback_service.dart';
import '../../data/services/app_review_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/wazn_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/ui_blocks.dart';
import '../home/widgets/activity_health_connect_sheet.dart';
import 'account_screen.dart';
import 'widgets/settings_kit.dart';
import '../../core/theme/app_motion.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/motion/shine_sweep.dart';

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
    final isPro = ref.watch(effectiveIsProProvider);
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
              return Reveal(
                child: _ProfileCard(
                  auth: SettingsAuthSnapshot(
                    isAnonymous: auth?.isAnonymous ?? true,
                    displayName: auth?.displayName,
                    email: auth?.email,
                    photoURL: auth?.photoURL,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (isPro)
            Reveal(
              delay: const Duration(milliseconds: 70),
              child: SettingsSurface(
                padding: EdgeInsets.zero,
                child: SettingsRow(
                  title: 'Wazn Pro',
                  value: l10n.settings_manage_plan,
                  icon: WaznIcons.pro,
                  onTap:
                      () => PremiumConversionService().openPaywall(
                        context,
                        PaywallEntryPoint.settings,
                      ),
                ),
              ),
            )
          else
            Reveal(
              delay: const Duration(milliseconds: 70),
              child: _ProUpsellCard(
                onTap:
                    () => PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.settings,
                    ),
              ),
            ),
          const SizedBox(height: 24),
          // Progress and Achievements had no way in: their links went with
          // an older Stats screen, so nobody could reach either.
          const Reveal(
            delay: Duration(milliseconds: 105),
            child: _JourneySection(),
          ),
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 140),
            child: SettingsSection(
              title: l10n.settings_core_config,
              children: [
                SettingsRow(
                  icon: WaznIcons.profile,
                  title: l10n.settings_body_profile,
                  value: bodyValue,
                  onTap: () => context.push('/settings/body-profile'),
                ),
                SettingsRow(
                  icon: WaznIcons.calories,
                  title: l10n.settings_nutrition_goals,
                  value:
                      settings == null
                          ? null
                          : '${settings.dailyCalorieGoal} ${l10n.settings_kcal_unit}',
                  onTap: () => context.push('/settings/nutrition-goals'),
                ),
                SettingsRow(
                  icon: WaznIcons.settings,
                  title: l10n.settings_preferences,
                  value: settingsLanguageName(settings?.languageCode),
                  onTap: () => context.push('/settings/preferences'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 210),
            child: SettingsSection(
              title: l10n.settings_data_security,
              children: [
                SettingsRow(
                  icon: WaznIcons.watch,
                  title: 'Health Connect',
                  value:
                      healthConnected
                          ? l10n.settings_status_connected
                          : l10n.settings_status_not_connected,
                  onTap: () => showActivityHealthConnectSheet(context),
                ),
                SettingsRow(
                  icon: WaznIcons.hardDrive,
                  title: l10n.settings_data_sync,
                  onTap: () => context.push('/settings/data-sync'),
                ),
                SettingsRow(
                  icon: WaznIcons.profile,
                  title: l10n.settings_account,
                  // No "Create account" here: the profile card at the top of
                  // this same screen already makes that offer, and two doors to
                  // one room make a screen feel padded.
                  onTap: () => context.push('/settings/account'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 280),
            child: SettingsSection(
              title: l10n.settings_information,
              children: [
                SettingsRow(
                  icon: WaznIcons.info,
                  title: l10n.settings_about,
                  onTap: () => context.push('/settings/about'),
                ),
                // Google Play only: there is no App Store listing to open yet.
                if (defaultTargetPlatform == TargetPlatform.android)
                  SettingsRow(
                    icon: WaznIcons.star,
                    title: l10n.settings_rate_app,
                    onTap:
                        () => AppReviewService.instance().openStoreRatingPage(),
                  ),
                SettingsRow(
                  icon: WaznIcons.mail,
                  title: l10n.settings_send_feedback,
                  onTap: () => FeedbackService.send(context),
                ),
              ],
            ),
          ),
          if (!isAnonymous) ...[
            const SizedBox(height: 24),
            SettingsSurface(
              padding: EdgeInsets.zero,
              child: SettingsRow(
                icon: WaznIcons.logOut,
                title: l10n.common_sign_out,
                destructive: true,
                onTap: () => confirmAndSignOut(context, ref),
              ),
            ),
          ],
          if (kDebugMode) ...[const SizedBox(height: 24), _DebugProToggle()],
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
                effectivePro ? WaznIcons.shieldCheck : WaznIcons.bug,
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
                WaznIcons.chevronRight,
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
    final isPro = ref.watch(effectiveIsProProvider);

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

/// The signed-out account row.
///
/// Shaped like the account row at the top of every settings screen the user
/// has already used: avatar, one line naming the action, one line of reason,
/// a chevron, and the whole row tappable. It previously carried a title, a
/// subtitle AND a button — three elements for one decision, with two
/// overlapping tap targets, one of which (the card) was invisible.
///
/// The title names the action rather than the state: nobody thinks of
/// themselves as a "Guest Account", they think "I'm not signed in".
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
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kSettingsGreenText.withValues(
                  alpha: isDark ? 0.16 : 0.09,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  WaznIcons.profile,
                  color: kSettingsGreenText,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.settings_sign_in,
                    style: AppTypography.heading3.copyWith(
                      color: settingsText(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settings_guest_sync,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: settingsSubtext(context),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              WaznIcons.chevronRight,
              size: 18,
              color: settingsSubtext(context).withValues(alpha: 0.7),
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
            // Avatar: photo or initials gradient. Pops in as Profile opens.
            Reveal(
              delay: const Duration(milliseconds: 120),
              offset: Offset.zero,
              scale: .4,
              curve: AppMotion.springCurve,
              child: Container(
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
                                WaznIcons.pro,
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
              WaznIcons.chevronRight,
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

/// The free-user Pro offer. A plain "Manage plan" row reads as a setting the
/// user already owns; this is a committed, tappable upgrade surface that names
/// the tier and its payoff, using the same premium gradient as the paywall and
/// the home upgrade chip.
class _ProUpsellCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProUpsellCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaleTap(
      onTap: onTap,
      child: ShineSweep(
        delay: const Duration(milliseconds: 684),
        sweep: const Duration(milliseconds: 1116),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        AppColors.primary.withValues(alpha: 0.22),
                        AppColors.primary.withValues(alpha: 0.05),
                      ]
                      : [const Color(0xFFD9F2E7), const Color(0xFFF4FBF8)],
              stops: const [0.0, 0.85],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.24),
            ),
            boxShadow:
                isDark
                    ? null
                    : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(WaznIcons.pro, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Wazn Pro',
                      style: AppTypography.titleMedium.copyWith(
                        color: settingsText(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.settings_upgrade_desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: settingsSubtext(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(
                        alpha: isDark ? 0.38 : 0.28,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.home_upgrade_chip,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      WaznIcons.chevronRight,
                      size: 13,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One soft band of light that sweeps across its child a moment after it
/// first shows, to draw the eye to the Pro offer once, not keep flashing.

/// Your weight line and your badges, each a row that opens its own screen.
class _JourneySection extends ConsumerWidget {
  const _JourneySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Newest first.
    final metrics = ref.watch(bodyMetricsProvider).valueOrNull ?? const [];
    final badges = ref.watch(achievementsProvider).valueOrNull ?? const [];
    final earned =
        badges.where((a) => a.isUnlocked).toList()
          ..sort((a, b) => (b.unlockedAt ?? 0).compareTo(a.unlockedAt ?? 0));
    final weights = [
      for (final m in metrics.take(8).toList().reversed) m.weight,
    ];
    final chevron = Icon(
      WaznIcons.chevronRight,
      size: 14,
      color: settingsSubtext(context).withValues(alpha: 0.55),
    );
    return SettingsSection(
      title: l10n.settings_your_journey,
      children: [
        SettingsRow(
          key: const ValueKey('settings-progress'),
          icon: WaznIcons.trend,
          title: l10n.settings_progress,
          subtitle:
              metrics.isEmpty
                  ? l10n.settings_progress_empty
                  : '${metrics.first.weight.toStringAsFixed(1)} ${l10n.settings_unit_kg}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (weights.length > 1) ...[
                _Sparkline(weights: weights),
                const SizedBox(width: 10),
              ],
              chevron,
            ],
          ),
          onTap: () => context.push('/progress'),
        ),
        SettingsRow(
          key: const ValueKey('settings-achievements'),
          icon: WaznIcons.star,
          title: l10n.feature_achievements_title,
          subtitle: l10n.settings_achievements_earned(
            '${earned.length}',
            '${badges.length}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (earned.isNotEmpty) ...[
                _BadgeStack(emojis: [for (final a in earned.take(3)) a.emoji]),
                const SizedBox(width: 10),
              ],
              chevron,
            ],
          ),
          onTap: () => context.push('/achievements'),
        ),
      ],
    );
  }
}

/// A small weight line that draws itself in from the left.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.weights});

  final List<double> weights;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 900),
        ),
        curve: const Interval(.3, 1, curve: Curves.easeInOutCubic),
        builder:
            (context, t, _) => CustomPaint(
              size: const Size(56, 22),
              painter: _SparkPainter(weights, t, kSettingsGreenText),
            ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.weights, this.progress, this.color);

  final List<double> weights;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2 || progress <= 0) return;
    final hi = weights.reduce(math.max), lo = weights.reduce(math.min);
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < weights.length; i++) {
      final x = i * size.width / (weights.length - 1);
      final y = 2 + (hi - weights[i]) / span * (size.height - 4);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.progress != progress ||
      old.color != color ||
      !listEquals(old.weights, weights);
}

/// The latest badges, overlapping, each popping in after the last.
class _BadgeStack extends StatelessWidget {
  const _BadgeStack({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).scaffoldBackgroundColor;
    return ExcludeSemantics(
      child: SizedBox(
        width: 22.0 + 16 * (emojis.length - 1),
        height: 24,
        child: Stack(
          children: [
            for (var i = 0; i < emojis.length; i++)
              PositionedDirectional(
                start: 16.0 * i,
                child: Reveal(
                  delay: Duration(milliseconds: 350 + 110 * i),
                  offset: Offset.zero,
                  scale: .3,
                  curve: AppMotion.springCurve,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFBEFD6),
                      border: Border.all(color: ring, width: 2),
                    ),
                    child: Text(
                      emojis[i],
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
