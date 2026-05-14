import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/gemini_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class ResultModal extends StatefulWidget {
  final Uint8List? imageBytes;
  final NutritionResult? result;
  final List<NutritionResult>? results;
  final Function(
    String name,
    int calories,
    int protein,
    int carbs,
    int fat,
    String? portion,
  )
  onSave;
  final Function(List<NutritionResult> selected)? onSaveAll;
  final VoidCallback onCancel;

  const ResultModal({
    super.key,
    this.imageBytes,
    this.result,
    this.results,
    required this.onSave,
    this.onSaveAll,
    required this.onCancel,
  });

  @override
  State<ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends State<ResultModal> {
  late final TextEditingController _mealTitleController;
  late List<_ReviewFoodItem> _items;
  bool _isSaving = false;

  int get _totalCalories => _items.fold(0, (sum, item) => sum + item.calories);
  int get _totalProtein => _items.fold(0, (sum, item) => sum + item.protein);
  int get _totalCarbs => _items.fold(0, (sum, item) => sum + item.carbs);
  int get _totalFat => _items.fold(0, (sum, item) => sum + item.fat);

  @override
  void initState() {
    super.initState();
    final results =
        widget.results ??
        (widget.result == null ? <NutritionResult>[] : [widget.result!]);

    _items =
        results
            .map((result) => _ReviewFoodItem.fromNutritionResult(result))
            .toList();

    if (_items.isEmpty) {
      _items = [_ReviewFoodItem.empty()];
    }

    _mealTitleController = TextEditingController(
      text: _items.length == 1 ? _items.first.name : 'Feast',
    );
  }

  @override
  void dispose() {
    _mealTitleController.dispose();
    super.dispose();
  }

  void _save() {
    if (_items.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    if (_items.length == 1 || widget.onSaveAll == null) {
      final item = _items.first;
      _dismissForSave();
      widget.onSave(
        item.name,
        item.calories,
        item.protein,
        item.carbs,
        item.fat,
        item.portion,
      );
      return;
    }

    final selectedItems =
        _items
            .map(
              (item) => NutritionResult(
                foodName: item.name,
                portion: item.portion,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
              ),
            )
            .toList();

    _dismissForSave();
    widget.onSaveAll!(selectedItems);
  }

  void _dismissForSave() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _editMealTitle() async {
    final controller = TextEditingController(text: _mealTitleController.text);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _TextEditSheet(
            title: 'Meal name',
            controller: controller,
            hintText: 'Feast',
          ),
    );
    if (value == null || value.trim().isEmpty) return;
    setState(() => _mealTitleController.text = value.trim());
  }

  Future<void> _editItem(int index) async {
    final edited = await showModalBottomSheet<_ReviewFoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoodEditSheet(item: _items[index]),
    );
    if (edited == null) return;
    setState(() => _items[index] = edited);
  }

  Future<void> _addManualFood() async {
    final added = await showModalBottomSheet<_ReviewFoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoodEditSheet(item: _ReviewFoodItem.empty()),
    );
    if (added == null) return;
    setState(() => _items.add(added));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height * 0.94;
    final sheetTop = height * 0.25;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: context.backgroundColor,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: sheetTop + 42,
                child: _PhotoHeader(
                  imageBytes: widget.imageBytes,
                  onBack: () {
                    Navigator.pop(context);
                    widget.onCancel();
                  },
                ),
              ),
              Positioned(
                top: sheetTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: _ReviewSheet(
                  mealTitleController: _mealTitleController,
                  totalCalories: _totalCalories,
                  totalCarbs: _totalCarbs,
                  totalProtein: _totalProtein,
                  totalFat: _totalFat,
                  items: _items,
                  onEditTitle: _editMealTitle,
                  onEditItem: _editItem,
                  onAddFood: _addManualFood,
                  bottomPadding: media.padding.bottom,
                  onSave: _save,
                  isSaving: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onBack;

  const _PhotoHeader({required this.imageBytes, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageBytes != null)
          Image.memory(imageBytes!, fit: BoxFit.cover)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.32),
                  AppColors.sky.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.10),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _HeaderIconButton(
                icon: LucideIcons.chevronLeft,
                onTap: onBack,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.18),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  final TextEditingController mealTitleController;
  final int totalCalories;
  final int totalCarbs;
  final int totalProtein;
  final int totalFat;
  final List<_ReviewFoodItem> items;
  final VoidCallback onEditTitle;
  final ValueChanged<int> onEditItem;
  final VoidCallback onAddFood;
  final double bottomPadding;
  final VoidCallback onSave;
  final bool isSaving;

  const _ReviewSheet({
    required this.mealTitleController,
    required this.totalCalories,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.items,
    required this.onEditTitle,
    required this.onEditItem,
    required this.onAddFood,
    required this.bottomPadding,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
              physics: const BouncingScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mealTitleController.text.trim().isEmpty
                            ? 'Feast'
                            : mealTitleController.text.trim(),
                        style: AppTypography.headlineSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onEditTitle,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          LucideIcons.edit3,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: l10n?.result_calories ?? 'Calories',
                        value: '${totalCalories}kcal',
                        color: const Color(0xFFEAF4FF),
                        textColor: const Color(0xFF0F2A44),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        label: l10n?.result_carbs ?? 'Carbs',
                        value: '${totalCarbs.toStringAsFixed(0)}g',
                        color: const Color(0xFFE5F7D5),
                        textColor: const Color(0xFF274B24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        label: l10n?.result_protein ?? 'Protein',
                        value: '${totalProtein.toStringAsFixed(0)}g',
                        color: const Color(0xFFFBE8D8),
                        textColor: const Color(0xFF4B2B17),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        label: l10n?.result_fat ?? 'Fat',
                        value: '${totalFat.toStringAsFixed(0)}g',
                        color: const Color(0xFFFFF4D3),
                        textColor: const Color(0xFF4D3A0F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  return _FoodReviewRow(
                    item: item,
                    onTap: () => onEditItem(index),
                  );
                }),
                const SizedBox(height: 18),
                _MoreFoodButton(onTap: onAddFood),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(26, 12, 26, bottomPadding + 18),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: isSaving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  disabledBackgroundColor: const Color(
                    0xFF1E88E5,
                  ).withValues(alpha: 0.68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          l10n?.snap_log_meal ?? 'Log this meal',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
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

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? color.withValues(alpha: 0.18)
                : color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : textColor.withValues(alpha: 0.68),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : textColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodReviewRow extends StatelessWidget {
  final _ReviewFoodItem item;
  final VoidCallback onTap;

  const _FoodReviewRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${item.calories}kcal / ${item.portion}',
              style: AppTypography.titleMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreFoodButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreFoodButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colorScheme.outline.withValues(alpha: 0.36),
          radius: 18,
        ),
        child: Container(
          height: 74,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)?.log_add_manually ??
                    'Add manually',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 8).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _FoodEditSheet extends StatefulWidget {
  final _ReviewFoodItem item;

  const _FoodEditSheet({required this.item});

  @override
  State<_FoodEditSheet> createState() => _FoodEditSheetState();
}

class _FoodEditSheetState extends State<_FoodEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _portion;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _portion = TextEditingController(text: widget.item.portion);
    _calories = TextEditingController(text: widget.item.calories.toString());
    _protein = TextEditingController(text: widget.item.protein.toString());
    _carbs = TextEditingController(text: widget.item.carbs.toString());
    _fat = TextEditingController(text: widget.item.fat.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _portion.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      _ReviewFoodItem(
        name: _name.text.trim().isEmpty ? 'Food' : _name.text.trim(),
        portion: _portion.text.trim().isEmpty ? '100.0g' : _portion.text.trim(),
        calories: int.tryParse(_calories.text) ?? 0,
        protein: int.tryParse(_protein.text) ?? 0,
        carbs: int.tryParse(_carbs.text) ?? 0,
        fat: int.tryParse(_fat.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return _EditSheetFrame(
      title: 'Food details',
      bottom: bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditField(label: 'Food', controller: _name),
          _EditField(label: 'Portion', controller: _portion),
          Row(
            children: [
              Expanded(
                child: _EditField(
                  label: 'Calories',
                  controller: _calories,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditField(
                  label: 'Carbs',
                  controller: _carbs,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _EditField(
                  label: 'Protein',
                  controller: _protein,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditField(
                  label: 'Fat',
                  controller: _fat,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(onPressed: _submit, child: const Text('Done')),
          ),
        ],
      ),
    );
  }
}

class _TextEditSheet extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hintText;

  const _TextEditSheet({
    required this.title,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return _EditSheetFrame(
      title: title,
      bottom: bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditField(
            label: title,
            controller: controller,
            hintText: hintText,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSheetFrame extends StatelessWidget {
  final String title;
  final double bottom;
  final Widget child;

  const _EditSheetFrame({
    required this.title,
    required this.bottom,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool autofocus;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hintText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        autofocus: autofocus,
        decoration: InputDecoration(labelText: label, hintText: hintText),
      ),
    );
  }
}

class _ReviewFoodItem {
  final String name;
  final String portion;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const _ReviewFoodItem({
    required this.name,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory _ReviewFoodItem.fromNutritionResult(NutritionResult result) {
    return _ReviewFoodItem(
      name: result.foodName,
      portion: result.portion,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
    );
  }

  factory _ReviewFoodItem.empty() {
    return const _ReviewFoodItem(
      name: 'Food',
      portion: '100.0g',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
  }
}
