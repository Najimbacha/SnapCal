import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/app_icon.dart';

const _reviewBg = Color(0xFFF7F4EE);
const _reviewInk = Color(0xFF111813);
const _reviewMuted = Color(0xFF637068);
const _reviewLine = Color(0xFFE7EBE6);
const _servingMultipliers = [0.7, 1.0, 1.3, 1.6];

List<String> _portionLabelsForName(String name) {
  final value = name.toLowerCase();
  if (value.contains('sauce') ||
      value.contains('ketchup') ||
      value.contains('mayo') ||
      value.contains('dressing')) {
    return const ['Light', 'Normal', 'Extra'];
  }
  if (value.contains('rice') ||
      value.contains('fries') ||
      value.contains('pasta') ||
      value.contains('nuts') ||
      value.contains('salad')) {
    return const ['50g', '100g', '150g', '200g'];
  }
  if (value.contains('slider')) {
    return const ['1 slider', '2 sliders', '3 sliders', '4 sliders'];
  }
  if (value.contains('burger') ||
      value.contains('chicken') ||
      value.contains('wing') ||
      value.contains('piece')) {
    return const ['1 piece', '2 pieces', '3 pieces', '4 pieces'];
  }
  return const ['Small', 'Regular', 'Large'];
}

class _ReviewFoodItem {
  final String name;
  final int baseCalories;
  final int baseProtein;
  final int baseCarbs;
  final int baseFat;
  final int servingIndex;

  const _ReviewFoodItem({
    required this.name,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    this.servingIndex = 1,
  });

  int get calories =>
      (baseCalories * _servingMultipliers[servingIndex]).round();
  int get protein => (baseProtein * _servingMultipliers[servingIndex]).round();
  int get carbs => (baseCarbs * _servingMultipliers[servingIndex]).round();
  int get fat => (baseFat * _servingMultipliers[servingIndex]).round();
  List<String> get servingLabels => _portionLabelsForName(name);
  String get servingLabel {
    final labels = servingLabels;
    return labels[servingIndex.clamp(0, labels.length - 1)];
  }

  factory _ReviewFoodItem.fromNutritionResult(NutritionResult result) {
    return _ReviewFoodItem(
      name: result.foodName,
      baseCalories: result.calories,
      baseProtein: result.protein,
      baseCarbs: result.carbs,
      baseFat: result.fat,
    );
  }

  factory _ReviewFoodItem.empty() {
    return const _ReviewFoodItem(
      name: 'Food item',
      baseCalories: 0,
      baseProtein: 0,
      baseCarbs: 0,
      baseFat: 0,
    );
  }

  _ReviewFoodItem copyWith({String? name, int? servingIndex}) {
    return _ReviewFoodItem(
      name: name ?? this.name,
      baseCalories: baseCalories,
      baseProtein: baseProtein,
      baseCarbs: baseCarbs,
      baseFat: baseFat,
      servingIndex: servingIndex ?? this.servingIndex,
    );
  }
}

class ResultModal extends StatefulWidget {
  final Uint8List? imageBytes;
  final NutritionResult? result;
  final List<NutritionResult>? results;
  final Function(String, int, int, int, int, String?) onSave;
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
  late List<_ReviewFoodItem> _items;
  bool _isSaving = false;
  double _entryOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    final results =
        widget.results ??
        (widget.result == null ? <NutritionResult>[] : [widget.result!]);
    _items = results.map(_ReviewFoodItem.fromNutritionResult).toList();
    if (_items.isEmpty) _items = [_ReviewFoodItem.empty()];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _entryOpacity = 1.0);
      }
    });
  }

  int get _totalCalories => _items.fold(0, (sum, item) => sum + item.calories);
  int get _totalProtein => _items.fold(0, (sum, item) => sum + item.protein);
  int get _totalCarbs => _items.fold(0, (sum, item) => sum + item.carbs);
  int get _totalFat => _items.fold(0, (sum, item) => sum + item.fat);

  @override
  void dispose() {
    super.dispose();
  }

  void _updateServing(int index, int servingIndex) {
    setState(() {
      _items[index] = _items[index].copyWith(servingIndex: servingIndex);
    });
  }

  void _addItem() {
    setState(() {
      _items.add(_ReviewFoodItem.empty());
    });
  }

  void _deleteItem(int index) {
    if (index < 0 || index >= _items.length) return;
    HapticFeedback.lightImpact();
    setState(() {
      _items.removeAt(index);
    });
  }

  void _renameItem(int index) async {
    if (index < 0 || index >= _items.length) return;
    final controller = TextEditingController(text: _items[index].name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Food',
              style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _reviewInk)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white : _reviewInk,
                fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Enter food name',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : _reviewMuted),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF5F3EF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : _reviewMuted,
                      fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text('Save',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.dispose();
    });
    if (newName != null && newName.isNotEmpty && mounted) {
      setState(() {
        _items[index] = _items[index].copyWith(name: newName);
      });
    }
  }

  void _save() {
    if (_items.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    if (_items.length == 1 || widget.onSaveAll == null) {
      final item = _items.first;
      widget.onSave(
        item.name,
        item.calories,
        item.protein,
        item.carbs,
        item.fat,
        item.servingLabel,
      );
    } else {
      widget.onSaveAll!(
        _items
            .map(
              (item) => NutritionResult(
                foodName: item.name,
                portion: item.servingLabel,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
              ),
            )
            .toList(),
      );
    }
    Navigator.of(context).pop();
  }

  void _retake() {
    Navigator.of(context).pop();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = context.watch<SettingsProvider>().isPro;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final bg = isDark ? const Color(0xFF14130F) : _reviewBg;
    final surface = isDark ? const Color(0xFF1A1A1E) : Colors.white;
    final ink = isDark ? Colors.white : _reviewInk;
    final muted = isDark ? Colors.white54 : _reviewMuted;
    final previewHeight = (MediaQuery.sizeOf(context).height * 0.25).clamp(150.0, 200.0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: previewHeight,
            child: _PhotoPreview(
              imageBytes: widget.imageBytes,
              height: previewHeight,
              onBack: _retake,
              totalCalories: _totalCalories,
            ),
          ),
          Positioned(
            top: previewHeight - 18, left: 0, right: 0, bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 24, offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 5,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: muted.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                      opacity: _entryOpacity,
                      duration: const Duration(milliseconds: 400),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 20),
                        children: [
                          _ReviewSummary(
                            calories: _totalCalories,
                            protein: _totalProtein,
                            carbs: _totalCarbs,
                            fat: _totalFat,
                            isPro: isPro,
                            isDark: isDark,
                            ink: ink,
                            muted: muted,
                          ),
                          const SizedBox(height: 10),
                          Container(height: 1, color: _reviewLine.withValues(alpha: 0.4)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Detected Foods',
                                style: AppTypography.titleMedium.copyWith(
                                  color: ink, fontSize: 15,
                                  fontWeight: FontWeight.w900, letterSpacing: -0.2,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFF0F0EE),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${_items.length}',
                                  style: TextStyle(
                                    color: muted, fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(_items.length, (index) {
                            return _FoodReviewCard(
                              item: _items[index],
                              ink: ink,
                              muted: muted,
                              surface: surface,
                              isDark: isDark,
                              imageBytes: widget.imageBytes,
                              index: index,
                              onServingChanged:
                                  (servingIndex) =>
                                      _updateServing(index, servingIndex),
                              onRename: () => _renameItem(index),
                              onDelete: () => _deleteItem(index),
                            );
                          }),
                          if (_items.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF0F0EE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(AppSymbols.meal, size: 24,
                                        color: muted.withValues(alpha: 0.4)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('No items detected',
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: muted, fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('Add one below to log your meal',
                                      style: AppTypography.bodySmall.copyWith(
                                          color: muted.withValues(alpha: 0.6),
                                          fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(AppSymbols.add, size: 14),
                            label: const Text('Add Item'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    ),
                    _SaveButton(
                      isSaving: _isSaving,
                      totalCalories: _totalCalories,
                      itemCount: _items.length,
                      onPressed: _save,
                      bottomPadding: bottom,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final int totalCalories;
  final int itemCount;
  final VoidCallback onPressed;
  final double bottomPadding;

  const _SaveButton({
    required this.isSaving,
    required this.totalCalories,
    required this.itemCount,
    required this.onPressed,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : _reviewLine.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.85),
                AppColors.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isSaving ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Add To Log',
                          style: AppTypography.titleSmall.copyWith(
                              color: Colors.white, fontSize: 14,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$totalCalories',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(width: 2),
                            Text('kcal',
                                style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
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

class _ReviewSummary extends StatelessWidget {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final bool isPro;
  final bool isDark;
  final Color ink;
  final Color muted;

  const _ReviewSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isPro,
    required this.isDark,
    required this.ink,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF0F0EE),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppSymbols.sparkles, size: 11,
                  color: isDark ? Colors.white70 : const Color(0xFF29314A)),
              const SizedBox(width: 5),
              Text('AI Estimated',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF29314A),
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$calories',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w200,
            color: ink,
            height: 0.90,
            letterSpacing: -3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Total Calories',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: muted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MacroCircle(label: 'Protein', value: protein,
                color: AppColors.protein, locked: !isPro),
            const SizedBox(width: 20),
            _MacroCircle(label: 'Carbs', value: carbs,
                color: AppColors.carbs, locked: !isPro),
            const SizedBox(width: 20),
            _MacroCircle(label: 'Fat', value: fat,
                color: AppColors.fat, locked: !isPro),
          ],
        ),
        if (!isPro) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => PremiumConversionService().openPaywall(
                context, PaywallEntryPoint.macroDetails,
                featureName: 'scan_result_macros'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppSymbols.crown, size: 14,
                      color: isDark ? Colors.white54 : const Color(0xFFA0884A)),
                  const SizedBox(width: 6),
                  Text('Unlock macro details',
                      style: TextStyle(
                          color: muted, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(AppSymbols.chevronRight, size: 12, color: muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (isPro && (protein + carbs + fat) > 0) ...[
          const SizedBox(height: 12),
          _MacroProportionBar(protein: protein, carbs: carbs, fat: fat),
        ],
      ],
    );
  }
}

class _MacroCircle extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool locked;

  const _MacroCircle({
    required this.label,
    required this.value,
    required this.color,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.10),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: locked
              ? Icon(AppSymbols.lock, size: 16, color: color.withValues(alpha: 0.5))
              : Text('${value}g',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _reviewMuted,
            )),
        ],
      );
  }
}

class _MacroProportionBar extends StatelessWidget {
  final int protein;
  final int carbs;
  final int fat;
  const _MacroProportionBar({required this.protein, required this.carbs, required this.fat});

  @override
  Widget build(BuildContext context) {
    final total = protein + carbs + fat;
    if (total == 0) return const SizedBox.shrink();
    final pFrac = protein / total;
    final cFrac = carbs / total;
    final fFrac = fat / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (pFrac * 1000).round().clamp(1, 1000),
                  child: Container(color: AppColors.protein),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: (cFrac * 1000).round().clamp(1, 1000),
                  child: Container(color: AppColors.carbs),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: (fFrac * 1000).round().clamp(1, 1000),
                  child: Container(color: AppColors.fat),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodReviewCard extends StatefulWidget {
  final _ReviewFoodItem item;
  final Color ink;
  final Color muted;
  final Color surface;
  final bool isDark;
  final Uint8List? imageBytes;
  final int index;
  final ValueChanged<int> onServingChanged;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _FoodReviewCard({
    required this.item, required this.ink, required this.muted,
    required this.surface, required this.isDark,
    required this.imageBytes, required this.index,
    required this.onServingChanged, required this.onRename, required this.onDelete,
  });

  @override
  State<_FoodReviewCard> createState() => _FoodReviewCardState();
}

class _FoodReviewCardState extends State<_FoodReviewCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final portionLabels = widget.item.servingLabels;
    final borderColor = _expanded
        ? AppColors.primary.withValues(alpha: 0.3)
        : widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : _reviewLine;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: _expanded ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.0 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _toggleExpand,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: widget.ink, fontSize: 14,
                            fontWeight: FontWeight.w900, letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${widget.item.calories} kcal',
                                style: const TextStyle(
                                  color: AppColors.primary, fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· ${widget.item.servingLabel}',
                              style: TextStyle(
                                color: widget.muted, fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 28, height: 28,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: Icon(AppSymbols.moreHorizontal,
                          color: widget.muted, size: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: widget.isDark ? const Color(0xFF2A2A2E) : Colors.white,
                      elevation: 4,
                      onSelected: (value) {
                        if (value == 'rename') widget.onRename();
                        if (value == 'delete') widget.onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename', height: 38,
                          child: Row(
                            children: [
                              Icon(AppSymbols.edit, size: 14, color: widget.ink),
                              const SizedBox(width: 8),
                              Text('Rename', style: TextStyle(
                                  color: widget.ink, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete', height: 38,
                          child: Row(
                            children: [
                              const Icon(AppSymbols.trash2, size: 14,
                                  color: Color(0xFFD84B2A)),
                              const SizedBox(width: 8),
                              const Text('Remove', style: TextStyle(
                                  color: Color(0xFFD84B2A), fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: portionLabels.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 5),
                        itemBuilder: (context, i) {
                          return _PortionChip(
                            label: portionLabels[i],
                            selected: widget.item.servingIndex == i,
                            onTap: () => widget.onServingChanged(i),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MacroDot(label: '${widget.item.calories} kcal',
                            color: AppColors.primary),
                        const SizedBox(width: 14),
                        _MacroDot(label: '${widget.item.protein}g Protein',
                            color: AppColors.protein),
                        const SizedBox(width: 14),
                        _MacroDot(label: '${widget.item.carbs}g Carbs',
                            color: AppColors.carbs),
                        const SizedBox(width: 14),
                        _MacroDot(label: '${widget.item.fat}g Fat',
                            color: AppColors.fat),
                      ],
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


class _MacroDot extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: _reviewMuted)),
      ],
    );
  }
}

class _PortionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PortionChip({
    required this.label, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.36)
                : _reviewMuted.withValues(alpha: 0.20),
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              selected ? '$label \u2713' : label,
              key: ValueKey('$label-$selected'),
              style: TextStyle(
                color: selected ? AppColors.primary : _reviewMuted,
                fontSize: 11, fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final double height;
  final VoidCallback onBack;
  final int totalCalories;

  const _PhotoPreview({
    required this.imageBytes, required this.height, required this.onBack,
    this.totalCalories = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Theme.of(context).colorScheme.surfaceContainer),
          if (hasImage)
            Positioned.fill(
              child: Image.memory(
                imageBytes!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          // Gradient overlay for depth
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),
          // Calorie pill on image
          if (totalCalories > 0)
            Positioned(
              bottom: 20, left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '$totalCalories kcal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16, right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36, height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(
                      AppSymbols.back, size: 16, color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppSymbols.camera, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Retake', style: TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
