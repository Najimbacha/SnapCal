import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_motion.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/core/theme/theme_colors.dart';
import 'package:snapcal/data/models/meal_template.dart';
import 'package:snapcal/providers/template_provider.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/wazn_icons.dart';

/// A saved routine in the Add food row: a pill with its emoji and name.
/// Tapping logs every food in it at once, with a tick on the pill;
/// pressing and holding offers rename and delete. A routine saved a moment
/// ago pops in with a "New" tag.
class RoutineCard extends StatefulWidget {
  const RoutineCard({
    super.key,
    required this.template,
    required this.onLog,
    required this.onOptions,
    this.isNew = false,
  });

  final MealTemplate template;
  final Future<void> Function() onLog;
  final VoidCallback onOptions;
  final bool isNew;

  @override
  State<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  bool _done = false;
  bool _busy = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy) return;
    _busy = true;
    try {
      await widget.onLog();
      if (!mounted) return;
      setState(() => _done = true);
      _reset?.cancel();
      _reset = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _done = false);
      });
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final t = widget.template;
    final accent = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);

    final summary = l10n.routine_summary(t.items.length, '${t.totalCalories}');
    Widget card = Container(
      height: 40,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 6, 0),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
          context.cardColor,
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.emoji, style: const TextStyle(fontSize: 16, height: 1)),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              t.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
          if (widget.isNew) ...[
            const SizedBox(width: 6),
            Container(
              key: const ValueKey('routine-new-tag'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF047857),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                l10n.routine_new.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
          const SizedBox(width: 7),
          // Plus, turning into a tick once the routine is logged.
          AnimatedSwitcher(
            duration: AppMotion.maybeZero(
              context,
              const Duration(milliseconds: 320),
            ),
            transitionBuilder:
                (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.springCurve,
                  ),
                  child: RotationTransition(
                    turns: Tween(begin: -.25, end: 0.0).animate(animation),
                    child: child,
                  ),
                ),
            child: Container(
              key: ValueKey(_done),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _done ? AppColors.primary : accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _done ? WaznIcons.check : WaznIcons.plus,
                size: 14,
                // The dark-mode mint needs dark ink, not white.
                color:
                    !_done && isDark ? const Color(0xFF053B2B) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isNew) {
      // Arrives with a little spring.
      card = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 520),
        ),
        curve: AppMotion.springCurve,
        builder:
            (context, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(scale: .6 + .4 * v, child: child),
            ),
        child: card,
      );
    }

    return Semantics(
      button: true,
      label: '${t.emoji} ${t.name}, $summary',
      child: GestureDetector(
        key: ValueKey('routine-${t.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onOptions();
        },
        child: card,
      ),
    );
  }
}

/// Rename or delete a routine. Deleting offers Undo.
void showRoutineOptions(BuildContext context, MealTemplate template) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoutineOptionsSheet(template: template),
  );
}

class _RoutineOptionsSheet extends ConsumerWidget {
  final MealTemplate template;

  const _RoutineOptionsSheet({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    Widget row(IconData icon, String label, Color color, VoidCallback onTap) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1B1F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: context.textMutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            '${template.emoji} ${template.name}',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.routine_summary(
              template.items.length,
              '${template.totalCalories}',
            ),
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          row(
            WaznIcons.edit,
            l10n.routine_rename,
            context.textPrimaryColor,
            () {
              Navigator.pop(context);
              _rename(context, ref, template);
            },
          ),
          Divider(height: 1, color: context.dividerColor.withValues(alpha: .3)),
          row(WaznIcons.delete, l10n.routine_delete, AppColors.error, () async {
            final messenger = ScaffoldMessenger.of(context);
            final notifier = ref.read(templatesProvider.notifier);
            Navigator.pop(context);
            await notifier.deleteTemplate(template.id);
            showAppToast(
              messenger,
              kind: ToastKind.undo,
              title: l10n.feature_templates_deleted,
              detail: template.name,
              actionLabel: l10n.result_undo,
              onAction: () => notifier.restoreTemplate(template),
            );
          }),
        ],
      ),
    );
  }
}

Future<void> _rename(
  BuildContext context,
  WidgetRef ref,
  MealTemplate template,
) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: template.name);
  final name = await showDialog<String>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(l10n.routine_rename),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 40,
            decoration: InputDecoration(
              hintText: l10n.feature_templates_name_hint,
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.common_save),
            ),
          ],
        ),
  );
  controller.dispose();
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty || trimmed == template.name) return;
  await ref
      .read(templatesProvider.notifier)
      .updateTemplate(template.id, name: trimmed);
}
