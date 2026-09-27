import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../providers/activity_provider.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/motion/count_up_text.dart';
import '../../../widgets/wazn_icons.dart';

void showActivityHealthConnectSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SheetScaffold(),
  );
}

class _SheetScaffold extends ConsumerWidget {
  const _SheetScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityVal = ref.watch(activityProvider).valueOrNull;
    final isConnected = activityVal?.healthConnected ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.only(bottom: 16 + bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEFCF7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Scrolls on a small phone with large text rather than cutting off.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              // Connecting hands over to today's activity with a fade and a
              // small rise, and the sheet eases to its new height.
              AnimatedSize(
                duration: AppMotion.maybeZero(
                  context,
                  const Duration(milliseconds: 320),
                ),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.maybeZero(
                    context,
                    const Duration(milliseconds: 380),
                  ),
                  transitionBuilder:
                      (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, .06),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                  child:
                      isConnected
                          ? const _ConnectedState(key: ValueKey('connected'))
                          : const _DisconnectedState(
                            key: ValueKey('disconnected'),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Disconnected State ───────────────────────────────────────

enum _LinkPhase { idle, checking, linked }

class _DisconnectedState extends ConsumerStatefulWidget {
  const _DisconnectedState({super.key});

  @override
  ConsumerState<_DisconnectedState> createState() => _DisconnectedStateState();
}

class _DisconnectedStateState extends ConsumerState<_DisconnectedState> {
  _LinkPhase _phase = _LinkPhase.idle;

  Future<void> _connect() async {
    if (_phase != _LinkPhase.idle) return;
    HapticFeedback.lightImpact();
    setState(() => _phase = _LinkPhase.checking);
    var granted = false;
    try {
      granted = await ref.read(activityProvider.notifier).authorize();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    if (!granted) {
      setState(() => _phase = _LinkPhase.idle);
      ref.invalidate(activityProvider);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _phase = _LinkPhase.linked);
    // Let the link be seen before the sheet turns to today's activity.
    if (!AppMotion.reduceMotion(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    if (mounted) ref.invalidate(activityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activityAsync = ref.watch(activityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phase =
        _phase == _LinkPhase.idle && activityAsync.isLoading
            ? _LinkPhase.checking
            : _phase;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          _LinkRow(phase: phase),
          const SizedBox(height: 18),
          _StatusBadge(phase: phase),
          const SizedBox(height: 14),
          Text(
            'Health Connect',
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1C1917),
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.hc_sync_body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('hc-connect'),
                onTap: _phase == _LinkPhase.idle ? _connect : null,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 200),
                      ),
                      child:
                          _phase == _LinkPhase.idle
                              ? Text(
                                l10n.activity_connect,
                                key: const ValueKey('label'),
                                style: AppTypography.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              )
                              : _phase == _LinkPhase.checking
                              ? const SizedBox(
                                key: ValueKey('busy'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(
                                WaznIcons.check,
                                key: ValueKey('done'),
                                color: Colors.white,
                                size: 22,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wazn's steps and Health Connect's heart, joined by a line. While it asks,
/// a dot runs along a dotted line; once linked the line draws solid and a
/// tick lands on the heart.
class _LinkRow extends StatefulWidget {
  const _LinkRow({required this.phase});

  final _LinkPhase phase;

  @override
  State<_LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<_LinkRow> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _link = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_LinkRow old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase) _sync();
  }

  void _sync() {
    final calm = AppMotion.reduceMotion(context);
    if (widget.phase == _LinkPhase.checking && !calm) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
    if (widget.phase == _LinkPhase.linked) {
      if (calm) {
        _link.value = 1;
      } else if (_link.value == 0) {
        _link.forward();
      }
    } else {
      _link.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const heart = Color(0xFFE11D48);
    Widget node(IconData icon, Color color) => Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, size: 28, color: color),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _link]),
      builder: (context, _) {
        final line = Curves.easeOutCubic.transform(
          (_link.value / .6).clamp(0.0, 1.0),
        );
        final tick = AppMotion.springCurve.transform(
          ((_link.value - .45) / .55).clamp(0.0, 1.0),
        );
        final breathe = 1 + .05 * math.sin(_pulse.value * math.pi);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: breathe,
              child: node(WaznIcons.steps, AppColors.green),
            ),
            SizedBox(
              width: 76,
              height: 16,
              child: CustomPaint(
                painter: _WirePainter(
                  pulse:
                      widget.phase == _LinkPhase.checking ? _pulse.value : -1,
                  solid: line,
                  dots: isDark ? Colors.white24 : const Color(0xFFD6D3D1),
                  color: AppColors.green,
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                node(AppSymbols.heartPulse, heart),
                if (tick > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Transform.scale(
                      scale: tick,
                      child: Container(
                        key: const ValueKey('hc-linked'),
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF047857),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          WaznIcons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WirePainter extends CustomPainter {
  const _WirePainter({
    required this.pulse,
    required this.solid,
    required this.dots,
    required this.color,
  });

  /// Where the travelling dot is, 0 to 1; negative for none.
  final double pulse;

  /// How much of the solid line is drawn.
  final double solid;
  final Color dots;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const inset = 6.0;
    final length = size.width - inset * 2;
    final dot = Paint()..color = dots;
    for (var x = inset; x <= size.width - inset; x += 10) {
      canvas.drawCircle(Offset(x, y), 1.6, dot);
    }
    if (solid > 0) {
      canvas.drawLine(
        Offset(inset, y),
        Offset(inset + length * solid, y),
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    if (pulse >= 0) {
      final t = Curves.easeInOut.transform(pulse);
      final fade = math.sin(pulse * math.pi);
      canvas.drawCircle(
        Offset(inset + length * t, y),
        4,
        Paint()..color = color.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_WirePainter old) =>
      old.pulse != pulse ||
      old.solid != solid ||
      old.dots != dots ||
      old.color != color;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.phase});

  final _LinkPhase phase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white38 : const Color(0xFFB4AFA8);
    final (label, color) = switch (phase) {
      _LinkPhase.linked => (l10n.hc_status_connected, AppColors.green),
      _LinkPhase.checking => (l10n.hc_status_checking, muted),
      _LinkPhase.idle => (l10n.hc_status_not_connected, muted),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 220),
        ),
        child: Text(
          label,
          key: ValueKey(label),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Connected State ──────────────────────────────────────────

class _ConnectedState extends ConsumerWidget {
  const _ConnectedState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final activityVal = ref.watch(activityProvider).valueOrNull;
    final steps = activityVal?.steps ?? 0;
    final calories = (activityVal?.activeCalories ?? 0).toInt();
    final caloriesEstimated = activityVal?.activeCaloriesEstimated ?? true;
    // The goal the user set, not a fixed 10,000.
    final goal =
        ref.watch(stepGoalProvider).valueOrNull ??
        ActivityRepository.defaultStepGoal;
    final stepProgress = steps / math.max(goal, 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white38 : const Color(0xFFB4AFA8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          _StatusBadge(phase: _LinkPhase.linked),
          const SizedBox(height: 12),
          Text(
            l10n.hc_activity_title,
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1C1917),
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          RepaintBoundary(
            child: _ActivityRing(progress: stepProgress, steps: steps),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.hc_steps_today,
            style: AppTypography.bodyMedium.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            caloriesEstimated
                ? l10n.hc_kcal_estimated(number.format(calories))
                : l10n.hc_kcal_burned(number.format(calories)),
            style: AppTypography.bodyMedium.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.hc_goal_progress(
              '${(stepProgress * 100).round()}',
              number.format(goal),
            ),
            key: const ValueKey('hc-goal-progress'),
            style: AppTypography.bodySmall.copyWith(
              color: muted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          const _LastSyncBadge(),
        ],
      ),
    );
  }
}

class _ActivityRing extends StatelessWidget {
  final double progress;
  final int steps;
  const _ActivityRing({required this.progress, required this.steps});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: AppMotion.maybeZero(
                context,
                const Duration(milliseconds: 1200),
              ),
              curve: Curves.easeOutCubic,
              builder:
                  (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.green,
                    ),
                  ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Counts up from nothing as the ring fills.
              CountUpText(
                value: steps,
                from: 0,
                format: number.format,
                duration: const Duration(milliseconds: 1200),
                style: AppTypography.displaySmall.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1C1917),
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                  letterSpacing: -1.2,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.log_metric_steps_unit,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LastSyncBadge extends ConsumerWidget {
  const _LastSyncBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activityAsync = ref.watch(activityProvider);
    final lastSynced = activityAsync.valueOrNull?.lastSynced;
    final text =
        activityAsync.isLoading
            ? l10n.sync_status_syncing
            : l10n.hc_last_synced(_ago(l10n, lastSynced));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _ago(AppLocalizations l10n, DateTime? dt) {
    if (dt == null) return l10n.hc_synced_never;
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return l10n.hc_synced_just_now;
    if (diff.inMinutes < 60) return l10n.hc_synced_min_ago('${diff.inMinutes}');
    return l10n.hc_synced_hours_ago('${diff.inHours}');
  }
}
