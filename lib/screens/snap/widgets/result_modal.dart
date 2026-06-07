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
    controller.dispose();
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
    final previewHeight = (MediaQuery.sizeOf(context).height * 0.21).clamp(154.0, 182.0);

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
                      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.045),
                      blurRadius: 20, offset: const Offset(0, -4),
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
                          const SizedBox(height: 8),
                          Container(height: 1, color: _reviewLine.withValues(alpha: 0.4)),
                          const SizedBox(height: 14),
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
                              Text(
                                '${_items.length} item${_items.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: muted, fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                                  Icon(AppSymbols.meal, size: 32,
                                      color: muted.withValues(alpha: 0.4)),
                                  const SizedBox(height: 8),
                                  Text('No items detected',
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: muted, fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('Add one below to log your meal',
                                      style: AppTypography.bodySmall.copyWith(
                                          color: muted.withValues(alpha: 0.7),
                                          fontSize: 11, fontWeight: FontWeight.w600)),
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
                          SizedBox(
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
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Add To Log',
                                            style: AppTypography.titleSmall.copyWith(
                                                color: Colors.white, fontSize: 14,
                                                fontWeight: FontWeight.w900)),
                                        const SizedBox(width: 6),
                                        Container(
                                          height: 22,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('$_totalCalories',
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
                        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Meal Review',
                style: AppTypography.titleLarge.copyWith(
                  color: muted, fontSize: 17,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF7F7F7),
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
                  Icon(AppSymbols.sparkles, size: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF29314A)),
                  const SizedBox(width: 4),
                  Text('AI detected',
                      style: AppTypography.labelLarge.copyWith(
                          color: isDark ? Colors.white70 : const Color(0xFF29314A),
                          fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$calories',
                style: AppTypography.displaySmall.copyWith(
                    color: ink, fontSize: 40, height: 0.90,
                    fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('kcal',
                  style: AppTypography.titleLarge.copyWith(
                      color: muted, fontSize: 18,
                      fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Estimated from photo',
                style: AppTypography.bodySmall.copyWith(
                    color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(width: 5),
            Icon(AppSymbols.info, size: 14,
                color: muted.withValues(alpha: 0.58)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MacroTile(label: 'Protein', value: protein,
                color: AppColors.protein, locked: !isPro)),
            const SizedBox(width: 6),
            Expanded(child: _MacroTile(label: 'Carbs', value: carbs,
                color: AppColors.carbs, locked: !isPro)),
            const SizedBox(width: 6),
            Expanded(child: _MacroTile(label: 'Fat', value: fat,
                color: AppColors.fat, locked: !isPro)),
          ],
        ),
        if (isPro && (protein + carbs + fat) > 0) ...[
          const SizedBox(height: 10),
          _MacroProportionBar(protein: protein, carbs: carbs, fat: fat),
        ],
        if (!isPro) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => PremiumConversionService().openPaywall(
                context, PaywallEntryPoint.macroDetails,
                featureName: 'scan_result_macros'),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF8E1).withValues(alpha: 0.6),
                    const Color(0xFFFFF1CC).withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFD966).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(AppSymbols.crown, size: 20,
                      color: Color(0xFFCC8800)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unlock Macro Tracking',
                            style: AppTypography.titleSmall.copyWith(
                                color: ink, fontSize: 13,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 1),
                        Text('See protein, carbs & fat in every scan',
                            style: AppTypography.bodySmall.copyWith(
                                color: muted, fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Icon(AppSymbols.chevronRight, size: 16, color: muted),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool locked;

  const _MacroTile({
    required this.label, required this.value, required this.color, required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked ? _reviewMuted : color;
    final bgAlpha = locked ? 0.04 : 0.07;
    final borderAlpha = locked ? 0.10 : 0.16;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: effectiveColor.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: locked ? 0.06 : 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(
              locked ? AppSymbols.lock : AppSymbols.check,
              size: 12, color: effectiveColor,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locked ? label : '${value}g',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveColor, fontSize: 13,
                    fontWeight: FontWeight.w900, letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  locked ? 'Locked' : label,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _reviewMuted.withValues(alpha: locked ? 0.6 : 1.0),
                    fontSize: 9, fontWeight: FontWeight.w600,
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
        const SizedBox(height: 6),
        Row(
          children: [
            _macroLabel('${(pFrac * 100).round()}% P', AppColors.protein),
            const SizedBox(width: 12),
            _macroLabel('${(cFrac * 100).round()}% C', AppColors.carbs),
            const SizedBox(width: 12),
            _macroLabel('${(fFrac * 100).round()}% F', AppColors.fat),
          ],
        ),
      ],
    );
  }

  Widget _macroLabel(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(
            color: _reviewMuted, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FoodReviewCard extends StatefulWidget {
  final _ReviewFoodItem item;
  final Color ink;
  final Color muted;
  final Uint8List? imageBytes;
  final int index;
  final ValueChanged<int> onServingChanged;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _FoodReviewCard({
    required this.item, required this.ink, required this.muted,
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
      duration: const Duration(milliseconds: 250),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final portionLabels = widget.item.servingLabels;
    final cardBg = isDark ? const Color(0xFF1A1A1E) : Colors.white;
    final borderColor = _expanded
        ? AppColors.primary.withValues(alpha: 0.3)
        : isDark
            ? Colors.white.withValues(alpha: 0.08)
            : _reviewLine;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _FoodIcon(name: widget.item.name),
                      const SizedBox(width: 10),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${widget.item.calories} kcal',
                                  style: TextStyle(
                                    color: AppColors.primary, fontSize: 12,
                                    fontWeight: FontWeight.w800,
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
                          color: isDark ? const Color(0xFF2A2A2E) : Colors.white,
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
                                  Icon(AppSymbols.trash2, size: 14,
                                      color: const Color(0xFFD84B2A)),
                                  const SizedBox(width: 8),
                                  Text('Remove', style: TextStyle(
                                      color: const Color(0xFFD84B2A), fontSize: 13,
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
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 30,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: portionLabels.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 4),
                                    itemBuilder: (context, i) {
                                      return _PortionChip(
                                        label: portionLabels[i],
                                        selected: widget.item.servingIndex == i,
                                        onTap: () =>
                                            widget.onServingChanged(i),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}

class _FoodIcon extends StatelessWidget {
  final String name;
  const _FoodIcon({required this.name});

  @override
  Widget build(BuildContext context) {
    final iconData = _foodIconFor(name);
    final (accent, bgAccent) = _foodColorFor(name);
    return Container(
      width: 40, height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, size: 20, color: accent),
    );
  }

  IconData _foodIconFor(String name) {
    final value = name.toLowerCase();
    if (value.contains('rice') || value.contains('pasta') || value.contains('noodle'))
      return AppSymbols.rice;
    if (value.contains('chicken') || value.contains('wing') || value.contains('turkey'))
      return AppSymbols.chicken;
    if (value.contains('beef') || value.contains('steak') || value.contains('burger') || value.contains('meat'))
      return AppSymbols.beef;
    if (value.contains('fish') || value.contains('salmon') || value.contains('tuna') || value.contains('shrimp'))
      return AppSymbols.fish;
    if (value.contains('egg'))
      return AppSymbols.egg;
    if (value.contains('salad') || value.contains('lettuce') || value.contains('spinach') || value.contains('veggie'))
      return AppSymbols.salad;
    if (value.contains('soup'))
      return AppSymbols.soup;
    if (value.contains('bread') || value.contains('toast') || value.contains('sandwich'))
      return AppSymbols.bread;
    if (value.contains('pizza'))
      return AppSymbols.pizza;
    if (value.contains('fruit') || value.contains('apple') || value.contains('banana') || value.contains('berry'))
      return AppSymbols.fruit;
    if (value.contains('water'))
      return AppSymbols.water;
    if (value.contains('coffee') || value.contains('tea') || value.contains('juice') || value.contains('soda') || value.contains('drink'))
      return AppSymbols.drink;
    if (value.contains('cake') || value.contains('cookie') || value.contains('dessert') || value.contains('ice cream'))
      return AppSymbols.dessert;
    if (value.contains('fry') || value.contains('chip'))
      return AppSymbols.fries;
    return AppSymbols.meal;
  }

  (Color, Color) _foodColorFor(String name) {
    final value = name.toLowerCase();
    if (value.contains('chicken') || value.contains('wing') || value.contains('turkey'))
      return (const Color(0xFFD84B2A), const Color(0xFFD84B2A).withValues(alpha: 0.10));
    if (value.contains('fish') || value.contains('salmon') || value.contains('tuna') || value.contains('shrimp'))
      return (const Color(0xFF4F8CC9), const Color(0xFF4F8CC9).withValues(alpha: 0.10));
    if (value.contains('salad') || value.contains('lettuce') || value.contains('spinach') || value.contains('veggie'))
      return (const Color(0xFF7C9A6D), const Color(0xFF7C9A6D).withValues(alpha: 0.10));
    if (value.contains('soup'))
      return (const Color(0xFFD18B47), const Color(0xFFD18B47).withValues(alpha: 0.10));
    if (value.contains('rice') || value.contains('pasta') || value.contains('noodle') || value.contains('bread') || value.contains('toast'))
      return (const Color(0xFFE8B84B), const Color(0xFFE8B84B).withValues(alpha: 0.10));
    if (value.contains('fruit') || value.contains('berry'))
      return (const Color(0xFFE8644A), const Color(0xFFE8644A).withValues(alpha: 0.10));
    if (value.contains('water'))
      return (const Color(0xFF4A90D9), const Color(0xFF4A90D9).withValues(alpha: 0.10));
    if (value.contains('drink') || value.contains('coffee') || value.contains('tea') || value.contains('juice'))
      return (const Color(0xFFA855F7), const Color(0xFFA855F7).withValues(alpha: 0.10));
    if (value.contains('dessert') || value.contains('cake') || value.contains('cookie'))
      return (const Color(0xFFE87A9C), const Color(0xFFE87A9C).withValues(alpha: 0.10));
    if (value.contains('pizza'))
      return (const Color(0xFFE8B84B), const Color(0xFFE8B84B).withValues(alpha: 0.10));
    return (AppColors.primary, AppColors.primary.withValues(alpha: 0.10));
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
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
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
          child: Text(
            selected ? '$label ✓' : label,
            style: TextStyle(
              color: selected ? AppColors.primary : _reviewMuted,
              fontSize: 11, fontWeight: FontWeight.w800,
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

  const _PhotoPreview({
    required this.imageBytes, required this.height, required this.onBack,
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
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16, right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 34, height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: const Icon(
                      AppSymbols.back, size: 16, color: _reviewInk,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppSymbols.camera, size: 14, color: _reviewInk),
                        SizedBox(width: 4),
                        Text('Retake', style: TextStyle(
                            color: _reviewInk, fontSize: 12,
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
