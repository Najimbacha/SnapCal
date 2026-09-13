import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_typography.dart';
import '../../../providers/water_provider.dart';

const _hydrationAccent = Color(0xFF3B9BE8);
const _hydrationInk = Color(0xFF1C1917);
const _hydrationMuted = Color(0xFF777370);
const _hydrationLine = Color(0xFFEDE9E1);
const _hydrationPaper = Color(0xFFFBFCFA);

void showHydrationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HydrationSheet(),
  );
}

class _HydrationSheet extends ConsumerStatefulWidget {
  const _HydrationSheet();

  @override
  ConsumerState<_HydrationSheet> createState() => _HydrationSheetState();
}

class _HydrationSheetState extends ConsumerState<_HydrationSheet> {
  static const _presets = [100, 250, 500];

  int _selectedMl = 250;
  int? _lastAddMl;
  bool _busy = false;
  Timer? _undoTimer;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    await ref.read(waterProvider.notifier).addWater(_selectedMl);
    if (!mounted) return;

    _undoTimer?.cancel();
    setState(() {
      _busy = false;
      _lastAddMl = _selectedMl;
    });
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _lastAddMl = null);
    });
  }

  Future<void> _undo() async {
    final lastAdd = _lastAddMl;
    if (_busy || lastAdd == null) return;
    HapticFeedback.lightImpact();
    _undoTimer?.cancel();
    setState(() {
      _busy = true;
      _lastAddMl = null;
    });

    await ref.read(waterProvider.notifier).removeWater(lastAdd);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = math.min(media.size.height * 0.72, 560.0);
    final state =
        ref.watch(waterProvider).valueOrNull ?? const WaterState(todayTotal: 0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        height: height,
        color: isDark ? Colors.black : _hydrationPaper,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _Grabber()),
                const SizedBox(height: 14),
                _Header(onClose: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 18),
                _ProgressCard(state: state),
                const SizedBox(height: 14),
                _PresetRow(
                  presets: _presets,
                  selected: _selectedMl,
                  unit: l10n.water_unit_ml,
                  onSelect: (ml) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMl = ml);
                  },
                ),
                const SizedBox(height: 14),
                _AddButton(
                  label: l10n.water_add_amount(_selectedMl),
                  busy: _busy,
                  onTap: _add,
                ),
                SizedBox(
                  height: 40,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _lastAddMl == null ? 0 : 1,
                      child: TextButton(
                        onPressed: _lastAddMl == null ? null : _undo,
                        child: Text(
                          l10n.water_undo,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? Colors.white70 : _hydrationMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _hydrationInk;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hydrationAccent.withValues(alpha: isDark ? 0.22 : 0.13),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.droplets,
            color: _hydrationAccent,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.water_hydration,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                LucideIcons.x,
                size: 20,
                color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final WaterState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _hydrationInk;
    final muted = isDark ? Colors.white60 : _hydrationMuted;
    final goal = math.max(state.goal, 1);
    final progress = (state.todayTotal / goal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final number = numberFormat.format(state.todayTotal);
    final goalText = numberFormat.format(goal);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : _hydrationLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: number,
                        style: AppTypography.displayLarge.copyWith(
                          color: ink,
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: ' ${l10n.water_unit_ml}',
                        style: AppTypography.titleSmall.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _hydrationAccent.withValues(
                    alpha: isDark ? 0.24 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pct%',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? const Color(0xFF9BD6FF) : _hydrationAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.home_metric_of_goal(goalText, l10n.water_unit_ml),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: value,
                    backgroundColor: _hydrationAccent.withValues(
                      alpha: isDark ? 0.18 : 0.11,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _hydrationAccent,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.presets,
    required this.selected,
    required this.unit,
    required this.onSelect,
  });

  final List<int> presets;
  final int selected;
  final String unit;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < presets.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _PresetChip(
              ml: presets[i],
              unit: unit,
              selected: presets[i] == selected,
              onTap: () => onSelect(presets[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.ml,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  final int ml;
  final String unit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _hydrationInk;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color:
              selected
                  ? _hydrationAccent.withValues(alpha: isDark ? 0.24 : 0.1)
                  : isDark
                  ? Colors.white.withValues(alpha: 0.045)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? _hydrationAccent.withValues(alpha: 0.5)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : _hydrationLine,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$ml',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: selected ? _hydrationAccent : ink,
                fontSize: 18,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color:
                    selected
                        ? _hydrationAccent.withValues(alpha: 0.75)
                        : ink.withValues(alpha: isDark ? 0.55 : 0.45),
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.busy ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hydrationAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child:
                widget.busy
                    ? const SizedBox(
                      key: ValueKey('busy'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Row(
                      key: const ValueKey('ready'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.plus,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
