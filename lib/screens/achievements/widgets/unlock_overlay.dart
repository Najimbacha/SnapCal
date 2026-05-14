import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class UnlockOverlay extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const UnlockOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<UnlockOverlay> createState() => _UnlockOverlayState();
}

class _UnlockOverlayState extends State<UnlockOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _confettiController.play();
    _animController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _getLocalizedTitle(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'achievement_first_flame':
        return l10n.achievement_first_flame;
      case 'achievement_consistency_king':
        return l10n.achievement_consistency_king;
      case 'achievement_iron_will':
        return l10n.achievement_iron_will;
      case 'achievement_unstoppable':
        return l10n.achievement_unstoppable;
      case 'achievement_bullseye':
        return l10n.achievement_bullseye;
      case 'achievement_precision_pro':
        return l10n.achievement_precision_pro;
      case 'achievement_macro_master':
        return l10n.achievement_macro_master;
      case 'achievement_perfect_week':
        return l10n.achievement_perfect_week;
      case 'achievement_first_sip':
        return l10n.achievement_first_sip;
      case 'achievement_hydration_hero':
        return l10n.achievement_hydration_hero;
      case 'achievement_ocean_mode':
        return l10n.achievement_ocean_mode;
      case 'achievement_first_snap':
        return l10n.achievement_first_snap;
      case 'achievement_snap_master':
        return l10n.achievement_snap_master;
      case 'achievement_snap_legend':
        return l10n.achievement_snap_legend;
      case 'achievement_first_checkin':
        return l10n.achievement_first_checkin;
      case 'achievement_transformation':
        return l10n.achievement_transformation;
      case 'achievement_journey_video':
        return l10n.achievement_journey_video;
      default:
        return key;
    }
  }

  String _getLocalizedDesc(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'achievement_first_flame_desc':
        return l10n.achievement_first_flame_desc;
      case 'achievement_consistency_king_desc':
        return l10n.achievement_consistency_king_desc;
      case 'achievement_iron_will_desc':
        return l10n.achievement_iron_will_desc;
      case 'achievement_unstoppable_desc':
        return l10n.achievement_unstoppable_desc;
      case 'achievement_bullseye_desc':
        return l10n.achievement_bullseye_desc;
      case 'achievement_precision_pro_desc':
        return l10n.achievement_precision_pro_desc;
      case 'achievement_macro_master_desc':
        return l10n.achievement_macro_master_desc;
      case 'achievement_perfect_week_desc':
        return l10n.achievement_perfect_week_desc;
      case 'achievement_first_sip_desc':
        return l10n.achievement_first_sip_desc;
      case 'achievement_hydration_hero_desc':
        return l10n.achievement_hydration_hero_desc;
      case 'achievement_ocean_mode_desc':
        return l10n.achievement_ocean_mode_desc;
      case 'achievement_first_snap_desc':
        return l10n.achievement_first_snap_desc;
      case 'achievement_snap_master_desc':
        return l10n.achievement_snap_master_desc;
      case 'achievement_snap_legend_desc':
        return l10n.achievement_snap_legend_desc;
      case 'achievement_first_checkin_desc':
        return l10n.achievement_first_checkin_desc;
      case 'achievement_transformation_desc':
        return l10n.achievement_transformation_desc;
      case 'achievement_journey_video_desc':
        return l10n.achievement_journey_video_desc;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Backdrop
        GestureDetector(
          onTap: widget.onDismiss,
          child: Container(color: Colors.black.withValues(alpha: 0.8)),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              AppColors.primary,
            ],
          ),
        ),

        // Badge Content
        FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.feature_achievements_unlocked_title,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                    border: Border.all(color: AppColors.primary, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.achievement.emoji,
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _getLocalizedTitle(context, widget.achievement.titleKey),
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _getLocalizedDesc(
                      context,
                      widget.achievement.descriptionKey,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    l10n.common_continue.toUpperCase(),
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
