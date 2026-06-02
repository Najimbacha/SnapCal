import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/premium_conversion_service.dart';
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
      text: 'Meal Review',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      if (_items.length == 1 && _items.first.name == 'Food') {
        _items = [_items.first.copyWith(name: l10n.result_food)];
        if (_mealTitleController.text == 'Food') {
          _mealTitleController.text = 'Meal Review';
        }
      }
    }
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
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _editItem(int index) async {
    final edited = await showModalBottomSheet<_ReviewFoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _FoodEditSheet(
            item: _items[index],
            isPro: context.read<SettingsProvider>().isPro,
          ),
    );
    if (edited == null) return;
    setState(() => _items[index] = edited);
  }

  Future<void> _addManualFood() async {
    final added = await showModalBottomSheet<_ReviewFoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _FoodEditSheet(
            item: _ReviewFoodItem.empty(),
            isPro: context.read<SettingsProvider>().isPro,
          ),
    );
    if (added == null) return;
    setState(() => _items.add(added));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const photoHeight = 180.0;
    final sheetTop = photoHeight - 18.0;

    return SizedBox(
      height: media.size.height,
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
                height: photoHeight,
                child: _PhotoPreview(
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
                child: _buildReviewSheet(media.padding.bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSheet(double bottomPadding) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = context.read<SettingsProvider>().isPro;
    final sheetBg =
        isDark ? const Color(0xFF14130F) : const Color(0xFFFAFAF8);
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF1C1917);
    final textSecondary =
        isDark ? Colors.white38 : const Color(0xFFB4AFA8);
    final textMuted =
        isDark ? Colors.white54 : const Color(0xFFA8A29E);
    final dividerColor =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);

    Color foodColor(int index) {
      const colors = [
        Color(0xFFE8644A), Color(0xFFF0A03C),
        Color(0xFF7C9A6D), Color(0xFF4F8CC9),
        Color(0xFFD18B47), Color(0xFFA855F7),
      ];
      return colors[index % colors.length];
    }

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Title + calorie counter row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meal Review',
                            style: AppTypography.titleMedium.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estimated from photo',
                            style: AppTypography.labelSmall.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_totalCalories',
                              style: AppTypography.headlineSmall.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 32,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'kcal',
                              style: AppTypography.titleMedium.copyWith(
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_items.length} ${_items.length == 1 ? 'item' : 'items'}',
                          style: AppTypography.labelSmall.copyWith(
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Accent bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Macro preview card
                GestureDetector(
                  onTap: isPro
                      ? null
                      : () => PremiumConversionService().openPaywall(
                        context,
                        PaywallEntryPoint.macroDetails,
                        featureName: 'result_macros',
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Theme.of(context).colorScheme.primary.withValues(alpha: isPro ? 0.06 : 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _macroMini('Protein', _totalProtein, const Color(0xFF7C9A6D), isDark, showValue: isPro),
                              const SizedBox(width: 4),
                              _macroMini('Carbs', _totalCarbs, const Color(0xFF4F8CC9), isDark, showValue: isPro),
                              const SizedBox(width: 4),
                              _macroMini('Fat', _totalFat, const Color(0xFFD18B47), isDark, showValue: isPro),
                            ],
                          ),
                        ),
                        if (!isPro) ...[
                          const SizedBox(width: 8),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: isDark ? Colors.white24 : const Color(0xFFD6D3D1),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Food items header
                Row(
                  children: [
                    Text(
                      'Detected foods',
                      style: AppTypography.labelSmall.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_items.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Food items list
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isLast = index == _items.length - 1;
                  final dotColor = foodColor(index);
                  return GestureDetector(
                    onTap: () => _editItem(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: isLast
                              ? BorderSide.none
                              : BorderSide(color: dividerColor, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.portion,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${item.calories}',
                            style: AppTypography.titleSmall.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'kcal',
                            style: AppTypography.labelSmall.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                              color: isDark ? Colors.white38 : const Color(0xFFD6D3D1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),

                // Add Item button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: GestureDetector(
                    onTap: _addManualFood,
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.result_add_item,
                          style: AppTypography.titleSmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isPro) ...[
                  const SizedBox(height: 24),

                  // Nutrition Details (locked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.result_nutrition_details,
                              style: AppTypography.labelSmall.copyWith(
                                color: textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppColors.premiumGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _macroLockColumn(l10n.result_protein, isDark)),
                            Expanded(child: _macroLockColumn(l10n.result_carbs, isDark)),
                            Expanded(child: _macroLockColumn(l10n.result_fat, isDark)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => PremiumConversionService().openPaywall(
                            context,
                            PaywallEntryPoint.macroDetails,
                            featureName: 'result_nutrition',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.result_unlock_nutrition,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom save button
          Container(
            padding: EdgeInsets.fromLTRB(22, 8, 22, bottomPadding + 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  shadowColor: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.result_add_to_log} · $_totalCalories kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
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

  Widget _macroLockColumn(String label, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Icon(
          LucideIcons.lock,
          size: 12,
          color: isDark ? Colors.white24 : const Color(0xFFD6D3D1),
        ),
      ],
    );
  }
}

// ── Photo preview ──────────────────────────────────────────────────────────

class _PhotoPreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onBack;

  const _PhotoPreview({required this.imageBytes, required this.onBack});

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
        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.30),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.06),
              ],
            ),
          ),
        ),
        // Bottom fade for smooth sheet transition
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.04),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: onBack,
                    customBorder: const CircleBorder(),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Retake',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Food edit sheet ────────────────────────────────────────────────────────

class _FoodEditSheet extends StatefulWidget {
  final _ReviewFoodItem item;
  final bool isPro;

  const _FoodEditSheet({required this.item, required this.isPro});

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
    _portion.addListener(_onPortionChanged);
  }

  double _parsePortionValue(String text) {
    final match = RegExp(r'^([\d.]+)').firstMatch(text.trim());
    if (match == null) return 0;
    return double.tryParse(match.group(1)!) ?? 0;
  }

  void _onPortionChanged() {
    final baseValue = _parsePortionValue(widget.item.portion);
    final newValue = _parsePortionValue(_portion.text);
    if (newValue <= 0 || baseValue <= 0) return;
    final multiplier = newValue / baseValue;
    if ((multiplier - 1.0).abs() < 0.01) return;

    _calories.text = (widget.item.calories * multiplier).round().toString();
    _protein.text = (widget.item.protein * multiplier).round().toString();
    _carbs.text = (widget.item.carbs * multiplier).round().toString();
    _fat.text = (widget.item.fat * multiplier).round().toString();
  }

  @override
  void dispose() {
    _portion.removeListener(_onPortionChanged);
    _name.dispose();
    _portion.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(
      context,
      _ReviewFoodItem(
        name: _name.text.trim().isEmpty ? l10n.result_food : _name.text.trim(),
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
    final l10n = AppLocalizations.of(context)!;
    return _EditSheetFrame(
      title: l10n.result_food_details,
      bottom: bottom,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EditField(label: l10n.result_food, controller: _name),
            _PortionSelector(
              controller: _portion,
              label: l10n.result_portion_label,
            ),
            _EditField(
              label: l10n.result_calories,
              controller: _calories,
              keyboardType: TextInputType.number,
            ),
            if (widget.isPro) ...[
              Row(
                children: [
                  Expanded(
                    child: _EditField(
                      label: l10n.result_carbs,
                      controller: _carbs,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EditField(
                      label: l10n.result_protein,
                      controller: _protein,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _EditField(
                label: l10n.result_fat,
                controller: _fat,
                keyboardType: TextInputType.number,
              ),
            ] else
              _LockedMacroEditPrompt(
                onTap:
                    () => PremiumConversionService().openPaywall(
                      context,
                      PaywallEntryPoint.macroDetails,
                      featureName: 'result_edit_macros',
                    ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.common_done,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

// ── Portion selector ───────────────────────────────────────────────────────

class _PortionSelector extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const _PortionSelector({
    required this.controller,
    required this.label,
  });

  @override
  State<_PortionSelector> createState() => _PortionSelectorState();
}

class _PortionSelectorState extends State<_PortionSelector> {
  final _portions = ['1 cup', '1 serving', '100g', '1 piece'];
  String? _selected;
  bool _showCustom = false;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
    final current = widget.controller.text;
    if (_portions.contains(current)) {
      _selected = current;
    } else if (current.isNotEmpty && current != '100.0g') {
      _showCustom = true;
      _customController.text = current;
    } else {
      _selected = '100g';
      widget.controller.text = '100g';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._portions.map(
                (p) => ChoiceChip(
                  label: Text(
                    p,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          _selected == p ? FontWeight.w600 : FontWeight.w500,
                      color:
                          _selected == p
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF78716C)),
                    ),
                  ),
                  selected: _selected == p,
                  selectedColor: primary,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    setState(() {
                      _selected = p;
                      _showCustom = false;
                      widget.controller.text = p;
                    });
                  },
                ),
              ),
              if (!_showCustom)
                ChoiceChip(
                  label: Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF78716C),
                    ),
                  ),
                  selected: false,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    setState(() {
                      _selected = null;
                      _showCustom = true;
                      widget.controller.text = '';
                    });
                  },
                ),
            ],
          ),
          if (_showCustom)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: _customController,
                autofocus: true,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1C1917),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 2 cups',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => widget.controller.text = v,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Locked macro edit prompt ────────────────────────────────────────────────

class _LockedMacroEditPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const _LockedMacroEditPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              LucideIcons.lock,
              size: 14,
              color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.result_unlock_nutrition,
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit sheet frame ────────────────────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14130F) : const Color(0xFFFDFDFD),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1C1917),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit field ──────────────────────────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            autofocus: autofocus,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1C1917),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review food item data model ─────────────────────────────────────────────

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

  _ReviewFoodItem copyWith({
    String? name,
    String? portion,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
  }) {
    return _ReviewFoodItem(
      name: name ?? this.name,
      portion: portion ?? this.portion,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

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

// ── Macro preview helper for result screen ─────────────────────────────────

Widget _macroMini(String label, int value, Color color, bool isDark, {bool showValue = false}) {
  if (showValue) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value}g',
            style: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  return Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.10 : 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: (value / 100).clamp(0.0, 1.0),
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.35 : 0.40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.lock,
              size: 10,
              color: isDark ? Colors.white24 : const Color(0xFFD6D3D1),
            ),
            const SizedBox(width: 3),
            Text(
              '${value}g',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
