import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../core/theme/app_typography.dart';
import '../providers/assistant_provider.dart';
import '../providers/metrics_provider.dart';
import '../providers/settings_provider.dart';

class OptimizePlanButton extends ConsumerStatefulWidget {
  final bool compact;

  const OptimizePlanButton({super.key, this.compact = false});

  @override
  ConsumerState<OptimizePlanButton> createState() => _OptimizePlanButtonState();
}

class _OptimizePlanButtonState extends ConsumerState<OptimizePlanButton> {
  bool _isLoading = false;

  Future<void> _recalculate() async {
    final metricsNotifier = ref.read(bodyMetricsProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentWeight = metricsNotifier.currentWeight;

    if (currentWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.settings_log_weight_first,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await settingsNotifier.recalculatePlan(
      currentWeightKg: currentWeight,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      context.push('/assistant');
      ref.read(assistantProvider.notifier).fetchRecommendations(
        AppLocalizations.of(context)!.settings_recalculate_query,
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.settings_complete_profile_first,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    const deepForest = Color(0xFF0A2114);

    final LinearGradient btnGradient;
    final Border? btnBorder;
    final Color textColor;
    final List<BoxShadow> shadow;

    if (isDark) {
      btnGradient = const LinearGradient(
        colors: [
          Color(0xFFF5D67B), // Light Gold
          Color(0xFFD4AF37), // Metallic Gold
          Color(0xFFB88E2F), // Dark Gold
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      btnBorder = null;
      textColor = deepForest;
      shadow = [
        BoxShadow(
          color: goldColor.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      btnGradient = const LinearGradient(
        colors: [
          Color(0xFFFCF8EF), // Soft champagne
          Color(0xFFF9F0DF), // Richer cream
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      btnBorder = Border.all(
        color: const Color(0xFFE5C060), // Soft gold border
        width: 1.2,
      );
      textColor = const Color(0xFF1A3D2B); // Deep Forest Green text
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    if (widget.compact) {
      return IconButton(
        tooltip: AppLocalizations.of(context)!.settings_optimize_btn,
        onPressed: _isLoading ? null : _recalculate,
        style: IconButton.styleFrom(
          backgroundColor:
              isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFFCF8EF),
          foregroundColor: textColor,
          minimumSize: const Size(36, 36),
          fixedSize: const Size(36, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE8E4DC),
            ),
          ),
        ),
        icon:
            _isLoading
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: textColor,
                  ),
                )
                : Icon(LucideIcons.sparkles, size: 17),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: btnGradient,
        border: btnBorder,
        boxShadow: shadow,
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
                    color: textColor,
                  ),
                )
                : Icon(LucideIcons.sparkles, size: 20, color: textColor),
        label: Text(
          _isLoading
              ? AppLocalizations.of(context)!.settings_optimizing
              : AppLocalizations.of(context)!.settings_optimize_btn,
          style: AppTypography.labelLarge.copyWith(
            color: textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

