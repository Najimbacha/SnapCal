import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../data/models/meal.dart';
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
  bool _localizedDefaultTitleApplied = false;
  Future<String>? _mealInsightFuture;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      if (!_localizedDefaultTitleApplied &&
          _items.length != 1 &&
          _mealTitleController.text == 'Feast') {
        _mealTitleController.text = l10n.result_feast;
        _localizedDefaultTitleApplied = true;
      }
      if (_items.length == 1 && _items.first.name == 'Food') {
        _items = [_items.first.copyWith(name: l10n.result_food)];
        if (_mealTitleController.text == 'Food') {
          _mealTitleController.text = l10n.result_food;
        }
      }
    }

    final settings = context.read<SettingsProvider>();
    if (settings.isPro && _mealInsightFuture == null) {
      _mealInsightFuture = AIService().generateMealInsight(
        meal: _buildInsightMeal(),
        settings: settings.settings,
        languageCode: settings.languageCode,
      );
    }
  }

  Meal _buildInsightMeal() {
    final name =
        _mealTitleController.text.trim().isEmpty
            ? _items.first.name
            : _mealTitleController.text.trim();
    return Meal(
      id: 'preview',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      dateString: app_date.DateUtils.getTodayString(),
      foodName: name,
      calories: _totalCalories,
      macros: Macros(
        protein: _totalProtein,
        carbs: _totalCarbs,
        fat: _totalFat,
      ),
      portion: _items.map((item) => item.portion).join(', '),
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
            title: AppLocalizations.of(context)!.result_meal_name,
            controller: controller,
            hintText: AppLocalizations.of(context)!.result_feast,
          ),
    );
    if (value == null || value.trim().isEmpty) return;
    setState(() => _mealTitleController.text = value.trim());
  }

  Future<void> _editItem(int index) async {
    debugPrint('_editItem called for index $index');
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
                  mealInsightFuture: _mealInsightFuture,
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
  final Future<String>? mealInsightFuture;
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
    required this.mealInsightFuture,
    required this.onEditTitle,
    required this.onEditItem,
    required this.onAddFood,
    required this.bottomPadding,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFFDFDFD),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          if (!isDark)
            const Positioned(top: 0, left: 0, right: 0, child: _ZigZagEdge()),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(26, 14, 26, 22),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mealTitleController.text.trim().isEmpty
                                    ? 'FEAST'
                                    : mealTitleController.text
                                        .trim()
                                        .toUpperCase(),
                                style: AppTypography.headlineSmall.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: onEditTitle,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              LucideIcons.edit3,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _ReceiptDivider(),
                    const SizedBox(height: 12),
                    _MacroBillSummary(
                      calories: totalCalories,
                      carbs: totalCarbs,
                      protein: totalProtein,
                      fat: totalFat,
                    ),
                    if (settings.isPro && mealInsightFuture != null) ...[
                      const SizedBox(height: 12),
                      _AiMealInsightCard(insight: mealInsightFuture!),
                    ] else if (!settings.isPro) ...[
                      const SizedBox(height: 12),
                      _PremiumInsightStrip(
                        onTap:
                            () => PremiumConversionService().openPaywall(
                              context,
                              PaywallEntryPoint.mealInsight,
                              featureName: 'meal_result',
                            ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const _ReceiptDivider(),
                    const SizedBox(height: 10),
                    // Perforated Divider
                    const _ReceiptDivider(),
                    const SizedBox(height: 12),

                    ...List.generate(items.length, (index) {
                      final item = items[index];
                      return _FoodReviewRow(
                        item: item,
                        onTap: () => onEditItem(index),
                      );
                    }),

                    const SizedBox(height: 8),
                    const _ReceiptDivider(),
                    const SizedBox(height: 18),
                    _MoreFoodButton(onTap: onAddFood),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(26, 8, 26, bottomPadding + 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed: isSaving ? null : onSave,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.premiumGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Container(
                            alignment: Alignment.center,
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
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ], // End of Column children
          ), // End of Column
        ], // End of Stack children
      ), // End of Stack
    ); // End of Container
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.name.toUpperCase(),
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _DottedLeader(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.calories}',
                  style: AppTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace', // Gives it that receipt feel
                  ),
                ),
                Text(
                  ' KCAL',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.portion.toLowerCase(),
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumInsightStrip extends StatelessWidget {
  final VoidCallback onTap;

  const _PremiumInsightStrip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : AppColors.primary).withValues(
                alpha: isDark ? 0.055 : 0.045,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.24 : 0.18,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.result_ai_meal_insight,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.result_ai_meal_body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.74,
                          ),
                          fontSize: 11,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    'PRO',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontSize: 10,
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

class _AiMealInsightCard extends StatelessWidget {
  final Future<String> insight;

  const _AiMealInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: insight,
      builder: (context, snapshot) {
        final text =
            snapshot.connectionState == ConnectionState.done
                ? snapshot.data ??
                    AppLocalizations.of(context)!.result_ai_meal_body
                : AppLocalizations.of(context)!.feature_insights_generating;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.sparkles,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.result_ai_meal_insight,
                      style: AppTypography.labelMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DottedLeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 2.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1.5,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.result_add_new_item,
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBillSummary extends StatelessWidget {
  final int calories, carbs, protein, fat;
  const _MacroBillSummary({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _SummaryLine(
          label: l10n.result_total_calories,
          value: '$calories',
          unit: 'KCAL',
          color: AppColors.primary,
          isHero: true,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SummaryLine(
                label: l10n.result_carbs,
                value: '${carbs}g',
                color: AppColors.carbs,
                icon: LucideIcons.wheat,
                small: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryLine(
                label: l10n.result_protein,
                value: '${protein}g',
                color: AppColors.protein,
                icon: LucideIcons.beef,
                small: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryLine(
                label: l10n.result_fat,
                value: '${fat}g',
                color: AppColors.fat,
                icon: LucideIcons.droplets,
                small: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label, value;
  final String? unit;
  final Color color;
  final bool small;
  final bool isHero;
  final IconData? icon;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.unit,
    required this.color,
    this.small = false,
    this.isHero = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isHero) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.2),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1.2,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTypography.displaySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    fontSize: 28,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit ?? '',
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w900,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZigZagEdge extends StatelessWidget {
  const _ZigZagEdge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Row(
        children: List.generate(
          20,
          (index) => Expanded(child: CustomPaint(painter: _TrianglePainter())),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFFDFDFD)
          ..style = PaintingStyle.fill;
    final path =
        Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditField(label: l10n.result_food, controller: _name),
          _EditField(label: l10n.result_portion_label, controller: _portion),
          Row(
            children: [
              Expanded(
                child: _EditField(
                  label: l10n.result_calories,
                  controller: _calories,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditField(
                  label: l10n.result_carbs,
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
                  label: l10n.result_protein,
                  controller: _protein,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditField(
                  label: l10n.result_fat,
                  controller: _fat,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    l10n.common_done,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
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
              child: Text(AppLocalizations.of(context)!.common_done),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 12, 26, 26),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
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
                style: AppTypography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            autofocus: autofocus,
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.3 : 0.4,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
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
