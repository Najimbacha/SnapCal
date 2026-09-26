import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../widgets/motion/reveal.dart';
import '../../../widgets/motion/lift_when_ready.dart';
import '../../../widgets/wazn_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';

class EditMealModal extends StatefulWidget {
  final Meal meal;
  final Function(Meal) onSave;
  final VoidCallback onDelete;
  final VoidCallback? onCancel;
  final bool isNew;

  const EditMealModal({
    super.key,
    required this.meal,
    required this.onSave,
    required this.onDelete,
    this.onCancel,
    this.isNew = false,
  });

  @override
  State<EditMealModal> createState() => _EditMealModalState();
}

class _EditMealModalState extends State<EditMealModal>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _portionController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late String _mealType;

  /// The meal's numbers count up from zero as the sheet opens. Touching any
  /// field, or saving, puts them straight at their real values.
  late final AnimationController _countIn;
  late final Map<TextEditingController, int> _countTargets;
  bool _countStarted = false;

  /// The tick on Save, shown before the sheet goes.
  late final AnimationController _saved;
  Meal? _pendingSave;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.foodName);
    _caloriesController = TextEditingController(
      text: _initialNumber(widget.meal.calories),
    );
    _portionController = TextEditingController(text: widget.meal.portion ?? '');
    _proteinController = TextEditingController(
      text: _initialNumber(widget.meal.macros.protein),
    );
    _carbsController = TextEditingController(
      text: _initialNumber(widget.meal.macros.carbs),
    );
    _fatController = TextEditingController(
      text: _initialNumber(widget.meal.macros.fat),
    );
    const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final initialType = widget.meal.mealType?.toLowerCase();
    _mealType = mealTypes.firstWhere(
      (type) => type.toLowerCase() == initialType,
      orElse: () => 'Snack',
    );
    _countTargets = {
      if (!widget.isNew) ...{
        _caloriesController: widget.meal.calories,
        _proteinController: widget.meal.macros.protein,
        _carbsController: widget.meal.macros.carbs,
        _fatController: widget.meal.macros.fat,
      },
    }..removeWhere((_, value) => value <= 0);
    _countIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..addListener(_showCount);
    _saved = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener((status) {
      final meal = _pendingSave;
      if (status == AnimationStatus.completed && meal != null && mounted) {
        widget.onSave(meal);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_countStarted) return;
    _countStarted = true;
    if (_countTargets.isEmpty || AppMotion.reduceMotion(context)) return;
    for (final controller in _countTargets.keys) {
      controller.text = '0';
    }
    _countIn.forward();
  }

  void _showCount() {
    final t = const Interval(
      .2,
      1,
      curve: Curves.easeOutCubic,
    ).transform(_countIn.value);
    for (final MapEntry(key: controller, value: target)
        in _countTargets.entries) {
      controller.text = '${(target * t).round()}';
    }
  }

  /// Puts every counting number at its real value at once.
  void _finishCount() {
    if (!_countIn.isAnimating) return;
    _countIn.stop();
    _countIn.value = 1;
  }

  String _initialNumber(int value) {
    return widget.isNew && value == 0 ? '' : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _portionController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _countIn.dispose();
    _saved.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_pendingSave != null) return;
    _finishCount();
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim()) ?? 0;
    final macros = widget.meal.macros.copyWith(
      protein: int.tryParse(_proteinController.text) ?? 0,
      carbs: int.tryParse(_carbsController.text) ?? 0,
      fat: int.tryParse(_fatController.text) ?? 0,
    );
    // A correction replaces the scan's numbers. The planner rebuilds meals
    // from per-100g and weight, and went on using the AI's figures after the
    // user had fixed them.
    final old = widget.meal;
    final corrected =
        !widget.isNew &&
        (calories != old.calories ||
            macros.protein != old.macros.protein ||
            macros.carbs != old.macros.carbs ||
            macros.fat != old.macros.fat);
    final updatedMeal = old.copyWith(
      foodName:
          name.isEmpty ? AppLocalizations.of(context)!.log_unknown_food : name,
      calories: calories,
      portion: _portionController.text,
      mealType: _mealType,
      macros: macros,
      userCorrected: corrected ? true : null,
      clearNutritionBasis: corrected,
    );
    // A tick first, then the sheet goes.
    if (AppMotion.reduceMotion(context)) {
      widget.onSave(updatedMeal);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _pendingSave = updatedMeal);
    _saved.forward();
  }

  /// A name and a calorie figure -- and zero is a figure: water, black coffee
  /// and diet drinks are real entries. Editing is held to the same rule, so a
  /// cleared field cannot turn a meal into "Unknown food, 0 kcal".
  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      int.tryParse(_caloriesController.text.trim()) != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final surfaceColor =
        isDark ? const Color(0xFF1C1B1E) : const Color(0xFFFCFCFA);
    final availableHeight =
        media.size.height - media.padding.top - media.viewInsets.bottom - 12;
    final sheetHeight = math.min(media.size.height * 0.88, availableHeight);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 14, 14),
              child: Row(
                children: [
                  Reveal(
                    delay: const Duration(milliseconds: 150),
                    offset: Offset.zero,
                    scale: .4,
                    curve: AppMotion.springCurve,
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.isNew ? WaznIcons.plus : WaznIcons.edit,
                        size: 19,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isNew ? l10n.log_log_new_meal : l10n.log_edit_meal,
                      style: AppTypography.titleMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: widget.onCancel ?? () => Navigator.pop(context),
                    icon: const Icon(WaznIcons.close),
                    color: context.textSecondaryColor,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.dividerColor),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                // Any field taken in hand stops the numbers counting in.
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onFocusChange: (focused) {
                    if (focused) _finishCount();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _cascade([
                      _MealTypeSelector(
                        selectedType: _mealType,
                        onSelected: (type) => setState(() => _mealType = type),
                      ),
                      const SizedBox(height: 20),
                      _MealTextField(
                        controller: _nameController,
                        label: l10n.log_food_name,
                        hint: l10n.log_food_hint,
                        icon: WaznIcons.meal,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      _MealTextField(
                        controller: _portionController,
                        label: l10n.log_portion_desc,
                        hint: l10n.log_portion_hint,
                        icon: WaznIcons.weight,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Icon(
                            WaznIcons.activity,
                            size: 17,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.result_macronutrients,
                            style: AppTypography.titleSmall.copyWith(
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _NutritionPanel(
                        caloriesController: _caloriesController,
                        proteinController: _proteinController,
                        carbsController: _carbsController,
                        fatController: _fatController,
                        onCaloriesChanged: (_) => setState(() {}),
                      ),
                      if (!widget.isNew &&
                          widget.meal.id != 'temp' &&
                          widget.meal.id != 'new') ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => _showDeleteConfirmation(context),
                          icon: const Icon(WaznIcons.delete, size: 17),
                          label: Text(l10n.log_delete_entry),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                math.max(12, media.padding.bottom),
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: context.dividerColor)),
              ),
              child: LiftWhenReady(
                ready: _canSave,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canSave ? _handleSave : null,
                    style: ElevatedButton.styleFrom(
                      animationDuration: AppMotion.standard,
                      backgroundColor: context.primaryColor,
                      disabledBackgroundColor: context.primaryColor.withValues(
                        alpha: 0.28,
                      ),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.8,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.standard,
                      transitionBuilder:
                          (child, animation) => ScaleTransition(
                            scale: CurvedAnimation(
                              parent: animation,
                              curve: AppMotion.springCurve,
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child:
                          _pendingSave != null
                              ? const Icon(
                                WaznIcons.check,
                                key: ValueKey('edit-meal-saved'),
                                size: 24,
                              )
                              : Row(
                                key: const ValueKey('edit-meal-save'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(WaznIcons.check, size: 19),
                                  const SizedBox(width: 8),
                                  Text(l10n.log_save_entry),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The form's rows rise into place one after another.
  List<Widget> _cascade(List<Widget> children) => [
    for (var i = 0; i < children.length; i++)
      Reveal(
        delay: Duration(milliseconds: 90 + 40 * i),
        offset: const Offset(0, 18),
        child: children[i],
      ),
  ];

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calm = AppMotion.reduceMotion(context);
    // The question pops up gently instead of just fading in.
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: calm ? 0 : 420),
      transitionBuilder:
          (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween(begin: .86, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: AppMotion.springCurve,
                  reverseCurve: Curves.easeIn,
                ),
              ),
              child: child,
            ),
          ),
      pageBuilder:
          (context, _, _) => AlertDialog(
            icon: const _WobblingBin(),
            backgroundColor: context.surfaceContainerColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.log_delete_meal_title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            content: Text(
              l10n.log_delete_meal_body,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.common_keep_it),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
                child: Text(
                  l10n.common_delete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({
    required this.selectedType,
    required this.onSelected,
  });

  final String selectedType;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      ('Breakfast', l10n.result_meal_breakfast, WaznIcons.breakfast),
      ('Lunch', l10n.result_meal_lunch, WaznIcons.lunch),
      ('Dinner', l10n.result_meal_dinner, WaznIcons.dinner),
      ('Snack', l10n.result_meal_snack, WaznIcons.snack),
    ];

    final selectedIndex = math.max(
      0,
      options.indexWhere((option) => option.$1 == selectedType),
    );

    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF1F2EF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // One pill that glides to the choice, rather than each option
          // lighting up in place.
          AnimatedAlign(
            key: const ValueKey('meal-type-pill'),
            alignment: AlignmentDirectional(-1 + 2 * selectedIndex / 3, 0),
            duration: AppMotion.maybeZero(
              context,
              const Duration(milliseconds: 480),
            ),
            curve: AppMotion.springCurve,
            child: FractionallySizedBox(
              widthFactor: 1 / 4,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.surfaceContainerColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final option in options)
                Expanded(
                  child: Semantics(
                    selected: selectedType == option.$1,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelected(option.$1),
                      borderRadius: BorderRadius.circular(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Bounce(
                            active: selectedType == option.$1,
                            child: Icon(
                              option.$3,
                              size: 15,
                              color:
                                  selectedType == option.$1
                                      ? context.primaryColor
                                      : context.textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              option.$2,
                              style: AppTypography.labelSmall.copyWith(
                                color:
                                    selectedType == option.$1
                                        ? context.textPrimaryColor
                                        : context.textSecondaryColor,
                                fontWeight:
                                    selectedType == option.$1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gives its child a small springy bounce each time it becomes [active].
class _Bounce extends StatefulWidget {
  const _Bounce({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void didUpdateWidget(_Bounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        !oldWidget.active &&
        !AppMotion.reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final wave = math.sin(_controller.value * math.pi);
      return Transform.rotate(
        angle: -.14 * wave,
        child: Transform.scale(scale: 1 + .3 * wave, child: child),
      );
    },
  );
}

class _MealTextField extends StatelessWidget {
  const _MealTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: context.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: context.textMutedColor),
            filled: true,
            fillColor:
                context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.035)
                    : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.primaryColor, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _NutritionPanel extends StatelessWidget {
  const _NutritionPanel({
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.onCaloriesChanged,
  });

  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final ValueChanged<String> onCaloriesChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF7F8F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  WaznIcons.calories,
                  size: 18,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  l10n.log_calories_kcal,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 112,
                child: _NumberField(
                  controller: caloriesController,
                  suffix: l10n.settings_kcal_unit,
                  onChanged: onCaloriesChanged,
                  emphasized: true,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: context.dividerColor),
          ),
          Row(
            children: [
              Expanded(
                child: _MacroNumberField(
                  label: l10n.result_protein,
                  controller: proteinController,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroNumberField(
                  label: l10n.result_carbs,
                  controller: carbsController,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroNumberField(
                  label: l10n.result_fat,
                  controller: fatController,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),
          _MacroSplit(
            protein: proteinController,
            carbs: carbsController,
            fat: fatController,
          ),
        ],
      ),
    );
  }
}

/// How the meal's calories divide between protein, carbs and fat, as one
/// thin bar that reshapes while the numbers are typed.
class _MacroSplit extends StatelessWidget {
  const _MacroSplit({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: Listenable.merge([protein, carbs, fat]),
      builder: (context, _) {
        final kcal = [
          (int.tryParse(protein.text) ?? 0) * 4,
          (int.tryParse(carbs.text) ?? 0) * 4,
          (int.tryParse(fat.text) ?? 0) * 9,
        ];
        final total = kcal.fold<int>(0, (a, b) => a + b);
        if (total == 0) return const SizedBox.shrink();
        final shares = [for (final k in kcal) k / total];
        const colors = [AppColors.protein, AppColors.carbs, AppColors.fat];
        final labels = [
          l10n.result_protein,
          l10n.result_carbs,
          l10n.result_fat,
        ];
        final duration = AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 520),
        );
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Two 2px gaps between three segments.
                  final width = constraints.maxWidth - 4;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 2),
                            AnimatedContainer(
                              key: ValueKey('macro-split-$i'),
                              duration: duration,
                              curve: Curves.easeOutCubic,
                              width: width * shares[i],
                              color: colors[i],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 3; i++)
                    Flexible(
                      child: Text(
                        '${labels[i]} ${(shares[i] * 100).round()}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MacroNumberField extends StatelessWidget {
  const _MacroNumberField({
    required this.label,
    required this.controller,
    required this.color,
  });

  final String label;
  final TextEditingController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _NumberField(controller: controller, suffix: 'g'),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.suffix,
    this.onChanged,
    this.emphasized = false,
  });

  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String>? onChanged;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: AppTypography.titleSmall.copyWith(
        color: context.textPrimaryColor,
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
        fontSize: emphasized ? 16 : 14,
      ),
      decoration: InputDecoration(
        hintText: '0',
        suffixText: suffix,
        suffixStyle: AppTypography.labelSmall.copyWith(
          color: context.textMutedColor,
          fontSize: 10,
        ),
        filled: true,
        fillColor:
            context.isDarkMode
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.primaryColor, width: 1.4),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}

/// The bin on the delete question, which gives a small shake as it appears.
class _WobblingBin extends StatelessWidget {
  const _WobblingBin();

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 760)),
      builder:
          (context, t, child) => Transform.rotate(
            // Starts after the dialog has landed, then dies away.
            angle:
                t < .35
                    ? 0
                    : math.sin((t - .35) / .65 * math.pi * 3) *
                        .22 *
                        (1 - (t - .35) / .65),
            child: child,
          ),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(WaznIcons.delete, color: error, size: 21),
      ),
    );
  }
}
