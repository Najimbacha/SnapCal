import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../data/services/pro_feature_service.dart';
import '../../../data/services/scan_gate_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/settings_provider.dart';

const _presetWeights = <int>[50, 100, 150, 200, 250, 300, 400, 500];
const _freeTierLimit = 3;

int _snapWeight(int g) {
  if (g <= 0) return 10;
  if (g <= 10) return g;
  if (g <= 50) return ((g + 2) ~/ 5) * 5;
  if (g <= 100) return ((g + 4) ~/ 5) * 5;
  if (g <= 300) return ((g + 9) ~/ 10) * 10;
  if (g <= 1000) return ((g + 24) ~/ 25) * 25;
  return ((g + 49) ~/ 50) * 50;
}

int _stepFor(int g) {
  if (g <= 30) return 5;
  if (g <= 100) return 10;
  if (g <= 300) return 25;
  if (g <= 1000) return 50;
  return 100;
}

String _confidenceLabel(AppLocalizations l10n, double c) {
  if (c >= 0.85) return '';
  if (c >= 0.60) return '';
  if (c >= 0.40) return l10n.result_confidence_estimated;
  return l10n.result_confidence_low;
}

Color _confidenceColor(double c) {
  if (c >= 0.85) return const Color(0xFF34C759);
  if (c >= 0.60) return AppColors.primary;
  if (c >= 0.40) return const Color(0xFFFF9500);
  return const Color(0xFFFF3B30);
}

class _Item {
  static int _uidSeed = 0;

  _Item({
    int? uid,
    required this.name,
    required this.weightG,
    this.confidence,
    this.matched = true,
    this.per100g,
    this.healthScore = 5,
    this.insights = const [],
  }) : uid = uid ?? _uidSeed++;

  final int uid;
  String name;
  double weightG;
  double? confidence;
  bool matched;
  Map<String, dynamic>? per100g;
  int healthScore;
  List<String> insights;

  int get calories => _calc('calories');
  int get protein => _calc('protein');
  int get carbs => _calc('carbs');
  int get fat => _calc('fat');

  int _calc(String field) {
    if (per100g == null || !matched) return 0;
    final val = per100g![field];
    if (val == null) return 0;
    return ((val is num ? val.toDouble() : 0) * weightG / 100).round();
  }

  factory _Item.from(NutritionResult r) {
    final hasNutrition = r.nutritionPer100g != null && r.matched;
    var weight = 150.0;
    Map<String, dynamic>? per100g;

    if (hasNutrition) {
      weight = (r.weightG ?? 150).toDouble();
      per100g = r.nutritionPer100g;
    } else if (r.calories > 0) {
      final portionMatch = RegExp(r'(\d+)').firstMatch(r.portion);
      weight =
          (portionMatch != null
              ? double.tryParse(portionMatch.group(1)!)
              : r.weightG) ??
          150;
      if (weight > 0) {
        final factor = 100 / weight;
        // Keep per-100g values as exact doubles: rounding here, then scaling
        // back up in _calc, double-rounds and visibly drifts the macros
        // (160 kcal became 161, protein 4 g became 5 g).
        per100g = {
          'calories': r.calories * factor,
          'protein': r.protein * factor,
          'carbs': r.carbs * factor,
          'fat': r.fat * factor,
        };
      }
    } else {
      weight = (r.weightG ?? 150).toDouble();
    }

    return _Item(
      name: r.foodName,
      weightG: weight,
      confidence: r.confidence,
      matched: hasNutrition || r.calories > 0,
      per100g: per100g,
      healthScore: r.healthScore,
      insights: r.insights,
    );
  }

  static const String blankName = '';

  static _Item blank() => _Item(name: blankName, weightG: 100);

  _Item copy({
    String? name,
    double? weightG,
    double? confidence,
    bool? matched,
  }) => _Item(
    uid: uid,
    name: name ?? this.name,
    weightG: weightG ?? this.weightG,
    confidence: confidence ?? this.confidence,
    matched: matched ?? this.matched,
    per100g: per100g,
    healthScore: healthScore,
    insights: insights,
  );
}

void _haptic() => HapticFeedback.selectionClick();

String _fmt(int v) {
  if (v < 1000) return '$v';
  return v.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

String _capitalize(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}

String _healthLabel(AppLocalizations l10n, int score) {
  if (score >= 9) return l10n.result_health_excellent;
  if (score >= 7) return l10n.result_health_good;
  if (score >= 5) return l10n.result_health_okay;
  if (score >= 3) return l10n.result_health_poor;
  return l10n.result_health_bad;
}

class ResultModal extends ConsumerStatefulWidget {
  final Uint8List? imageBytes;
  final NutritionResult? result;
  final List<NutritionResult>? results;
  final void Function(String, int, int, int, int, String?) onSave;
  final void Function(List<NutritionResult> selected)? onSaveAll;
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
  ConsumerState<ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends ConsumerState<ResultModal> {
  late List<_Item> _items;
  bool _saving = false;
  late final int _remainingScans;

  @override
  void initState() {
    super.initState();
    final r = widget.results ?? (widget.result == null ? [] : [widget.result!]);
    _items = r.map(_Item.from).toList();
    if (_items.isEmpty) _items.add(_Item.blank());
    _remainingScans = ScanGateService().getRemainingScans(
      ref.read(effectiveIsProProvider),
    );
  }

  int get _kcal => _items.fold(0, (s, i) => s + i.calories);
  int get _p => _items.fold(0, (s, i) => s + i.protein);
  int get _c => _items.fold(0, (s, i) => s + i.carbs);
  int get _f => _items.fold(0, (s, i) => s + i.fat);

  int? get _healthScore {
    final scored = _items.where((i) => i.matched && i.per100g != null).toList();
    if (scored.isEmpty) return null;
    return (scored.fold<int>(0, (s, i) => s + i.healthScore) / scored.length)
        .round()
        .clamp(1, 10);
  }

  int? _sharePctOf(_Item item) {
    if (_items.length < 2 || _kcal <= 0) return null;
    if (!item.matched || item.per100g == null) return null;
    return ((item.calories / _kcal * 100).round()).clamp(0, 100);
  }

  String _title(AppLocalizations l10n) {
    if (_items.isEmpty) return l10n.result_no_items;
    if (_items.length > 1) return l10n.result_foods_detected(_items.length);
    final n = _items.first.name.trim();
    return n.isEmpty ? l10n.result_food_item : _capitalize(n);
  }

  bool get _hasContent =>
      _kcal > 0 || _items.any((i) => i.name.trim().isNotEmpty);

  void _adjWt(int i, int delta) {
    setState(() {
      final cur = _items[i].weightG;
      final next = _snapWeight((cur + delta).round().clamp(5, 2000));
      _items[i] = _items[i].copy(weightG: next.toDouble());
    });
    _haptic();
  }

  void _setWt(int i, double g) {
    setState(
      () =>
          _items[i] = _items[i].copy(
            weightG: _snapWeight(g.round()).toDouble(),
          ),
    );
    _haptic();
  }

  void _add() {
    setState(() => _items.add(_Item.blank()));
    _haptic();
  }

  void _del(int i, {required bool withUndo}) {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final removed = _items[i];
    final index = i;
    setState(() => _items.removeAt(i));
    if (!withUndo) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        content: Text(
          l10n.result_removed(
            removed.name.trim().isEmpty
                ? l10n.result_food_item
                : _capitalize(removed.name),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        action: SnackBarAction(
          label: l10n.result_undo,
          onPressed: () {
            if (!mounted) return;
            setState(() {
              final idx = index.clamp(0, _items.length).toInt();
              _items.insert(idx, removed);
            });
          },
        ),
      ),
    );
  }

  Future<void> _rename(int i) async {
    final l10n = AppLocalizations.of(context)!;
    final n = await showDialog<String>(
      context: context,
      builder:
          (_) => _TextPromptDialog(
            title: l10n.result_rename,
            initialText: _items[i].name,
            hintText: l10n.result_food_name,
          ),
    );
    if (n != null && n.isNotEmpty && mounted) {
      setState(() => _items[i] = _items[i].copy(name: n));
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context)!;
    final d = Theme.of(context).brightness == Brightness.dark;
    final res = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: d ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.result_discard_title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: d ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            content: Text(
              l10n.result_discard_body,
              style: TextStyle(
                fontSize: 14,
                color: d ? Colors.white54 : const Color(0xFF8E8E93),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  l10n.result_keep_editing,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.result_discard,
                  style: const TextStyle(
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
    return res ?? false;
  }

  void _handleBack() async {
    if (_saving) return;
    if (_hasContent && !await _confirmDiscard()) return;
    if (!mounted) return;
    _retake();
  }

  void _retake() {
    Navigator.of(context).pop();
    widget.onCancel();
  }

  Future<void> _save() async {
    if (_items.isEmpty || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    // Brief pause so the success checkmark is perceived before routing home.
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    if (_items.length == 1 || widget.onSaveAll == null) {
      final i = _items.first;
      widget.onSave(
        i.name,
        i.calories,
        i.protein,
        i.carbs,
        i.fat,
        '${i.weightG.round()}g',
      );
    } else {
      widget.onSaveAll!(
        _items
            .map(
              (i) => NutritionResult(
                foodName: i.name,
                portion: '${i.weightG.round()}g',
                calories: i.calories,
                protein: i.protein,
                carbs: i.carbs,
                fat: i.fat,
                healthScore: i.healthScore,
                insights: i.insights,
                weightG: i.weightG,
                matched: i.matched,
                nutritionPer100g: i.per100g,
                nutritionActual:
                    i.matched && i.per100g != null
                        ? {
                          'calories': i.calories,
                          'protein': i.protein,
                          'carbs': i.carbs,
                          'fat': i.fat,
                        }
                        : null,
              ),
            )
            .toList(),
      );
    }
    Navigator.of(context).pop();
  }

  void _openPaywall(BuildContext context) {
    PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.macroDetails,
      featureName: 'scan_result_macros',
    );
  }

  Color _accentFor(_Item i) {
    if (!i.matched || i.per100g == null) return AppColors.primary;
    final p = i.protein;
    final c = i.carbs;
    final f = i.fat;
    if (p >= c && p >= f) return AppColors.protein;
    if (c >= p && c >= f) return AppColors.carbs;
    return AppColors.fat;
  }

  void _openPhoto() {
    final bytes = widget.imageBytes;
    if (bytes == null) return;
    _haptic();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder:
          (ctx) => GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
          ),
    );
  }

  Future<void> _typeWeight(int i) async {
    final l10n = AppLocalizations.of(context)!;
    final raw = await showDialog<String>(
      context: context,
      builder:
          (_) => _TextPromptDialog(
            title: l10n.result_set_weight,
            initialText: _items[i].weightG.round().toString(),
            suffixText: 'g',
            digitsOnly: true,
          ),
    );
    final v = raw == null ? null : int.tryParse(raw);
    if (v != null && mounted) _setWt(i, v.toDouble().clamp(5, 5000));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = Theme.of(context).brightness == Brightness.dark;
    final pro = ref.watch(effectiveIsProProvider);
    final showMacros = const ProFeatureService().canSeeMacros(isPro: pro);
    final b = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, l10n, d),
              _macroStrip(context, l10n, d, showMacros),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  // The save bar already absorbs the bottom safe-area inset.
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if (_items.isNotEmpty) ...[
                      Text(
                        l10n.result_tap_to_adjust,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: d ? Colors.white38 : const Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_shareBar() != null) ...[
                      _shareBar()!,
                      const SizedBox(height: 12),
                    ],
                    ..._items.asMap().entries.map(
                      (e) => _FoodCard(
                        key: ValueKey('food-${e.value.uid}'),
                        item: e.value,
                        index: e.key,
                        isDark: d,
                        accent: _accentFor(e.value),
                        sharePct: _sharePctOf(e.value),
                        showMacros: showMacros,
                        onWeightDelta: (delta) => _adjWt(e.key, delta),
                        onWeightSet: (g) => _setWt(e.key, g),
                        onWeightType: () => _typeWeight(e.key),
                        onRename: () => _rename(e.key),
                        onDelete: () => _del(e.key, withUndo: true),
                      ),
                    ),
                    if (_items.isEmpty) _emptyState(l10n, d),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _add,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: (d ? Colors.white : const Color(0xFFC7C7CC))
                                .withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.plus,
                                size: 16,
                                color:
                                    d
                                        ? Colors.white54
                                        : const Color(0xFF8E8E93),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.result_add_item,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      d
                                          ? Colors.white54
                                          : const Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!pro) ...[
                      const SizedBox(height: 16),
                      _upgradeBanner(context, l10n, d),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _saveBar(context, l10n, d, pro, b),
      ),
    );
  }

  /// Compact header: the photo is a thumbnail, not a stage. Total height is
  /// roughly 110px so the item list starts above the fold on every device.
  Widget _header(BuildContext context, AppLocalizations l10n, bool d) {
    final ink = d ? Colors.white : const Color(0xFF1C1C1E);
    final muted = d ? Colors.white54 : const Color(0xFF8E8E93);
    final score = _healthScore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _handleBack,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(LucideIcons.chevronLeft, size: 24, color: ink),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _retake,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (d ? Colors.white : Colors.black).withValues(
                        alpha: 0.14,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.camera, size: 14, color: muted),
                      const SizedBox(width: 6),
                      Text(
                        l10n.result_retake,
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: widget.imageBytes == null ? null : _openPhoto,
                  child: Container(
                    width: 58,
                    height: 58,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color:
                          d ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        widget.imageBytes != null
                            ? Image.memory(
                              widget.imageBytes!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, _, _) => const SizedBox.shrink(),
                            )
                            : Icon(
                              LucideIcons.utensils,
                              size: 22,
                              color: muted,
                            ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _title(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          _CountUp(
                            value: _kcal,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: ink,
                              height: 1.0,
                              letterSpacing: -1.0,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              score == null
                                  ? 'kcal'
                                  : 'kcal · $score/10 ${_healthLabel(l10n, score)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Macro grams for everyone the flag allows; composition percentages for
  /// everyone else. No blur — a locked number is stated, never obscured.
  Widget _macroStrip(
    BuildContext context,
    AppLocalizations l10n,
    bool d,
    bool showMacros,
  ) {
    final cals = (_p * 4) + (_c * 4) + (_f * 9);
    double share(int grams, int perGram) =>
        cals <= 0 ? 0 : (grams * perGram) / cals;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MacroChip(
                  label: l10n.result_protein,
                  grams: _p,
                  share: share(_p, 4),
                  color: AppColors.protein,
                  isDark: d,
                  showGrams: showMacros,
                  onLockedTap: () => _openPaywall(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: l10n.result_carbs,
                  grams: _c,
                  share: share(_c, 4),
                  color: AppColors.carbs,
                  isDark: d,
                  showGrams: showMacros,
                  onLockedTap: () => _openPaywall(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: l10n.result_fat,
                  grams: _f,
                  share: share(_f, 9),
                  color: AppColors.fat,
                  isDark: d,
                  showGrams: showMacros,
                  onLockedTap: () => _openPaywall(context),
                ),
              ),
            ],
          ),
          if (showMacros && (_p + _c + _f) > 0) ...[
            const SizedBox(height: 10),
            _MacroProportionBar(
              protein: _p,
              carbs: _c,
              fat: _f,
              isDark: d,
            ),
          ],
        ],
      ),
    );
  }

  Widget _saveBar(
    BuildContext context,
    AppLocalizations l10n,
    bool d,
    bool pro,
    double b,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, b + 10),
      decoration: BoxDecoration(
        color: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        border: Border(
          top: BorderSide(
            color: (d ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!pro) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.zap,
                  size: 12,
                  color: const Color(
                    0xFFFFB800,
                  ).withValues(alpha: _remainingScans > 0 ? 1 : 0.45),
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.result_scans_left(_remainingScans, _freeTierLimit),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: d ? Colors.white54 : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder:
                  (child, anim) => ScaleTransition(scale: anim, child: child),
              child: DecoratedBox(
                key: ValueKey(_saving),
                decoration: BoxDecoration(
                  color: _saving ? const Color(0xFF34C759) : AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      _saving
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.check,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.result_added,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          : Text(
                            _kcal > 0
                                ? l10n.result_add_to_log_kcal(_fmt(_kcal))
                                : l10n.result_save_log,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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

  Widget? _shareBar() {
    if (_items.length < 2 || _kcal <= 0) return null;
    final segments = <Widget>[];
    for (final i in _items) {
      if (i.calories <= 0) continue;
      segments.add(
        Expanded(
          flex: i.calories,
          child: ColoredBox(
            color: _accentFor(i),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }
    if (segments.length < 2) return null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Row(
          children: [
            for (var j = 0; j < segments.length; j++) ...[
              if (j > 0) const SizedBox(width: 2),
              segments[j],
            ],
          ],
        ),
      ),
    );
  }

  /// The ask, at the moment it lands hardest.
  ///
  /// A scan the user just watched succeed is the peak of the session — they
  /// have a real plate on screen with real numbers against it. So the banner
  /// leads with this meal rather than a feature list, and shows the macros it
  /// is talking about. An ambient "unlock deeper insights" card asks for money
  /// before the user has been shown anything; this one asks right after.
  Widget _upgradeBanner(BuildContext context, AppLocalizations l10n, bool d) {
    final chips = <(String, int, Color)>[
      (l10n.result_protein, _p, AppColors.protein),
      (l10n.result_carbs, _c, AppColors.carbs),
      (l10n.result_fat, _f, AppColors.fat),
    ];

    return GestureDetector(
      onTap: () => _openPaywall(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: d ? 0.12 : 0.06),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.32)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.result_unlock_personal_title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: d ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.result_unlock_personal_body,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color:
                              d ? Colors.white60 : const Color(0xFF6E6E73),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: d ? Colors.white38 : const Color(0xFFC7C7CC),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // The meal's own numbers, so the offer is visibly about this plate.
            Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: chips[i].$3.withValues(alpha: d ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${chips[i].$1} ${chips[i].$2}g',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: d ? Colors.white : const Color(0xFF1C1C1E),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n, bool d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          l10n.result_no_items_detected,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: d ? Colors.white38 : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

/// Shared single-field prompt (rename, set weight). The dialog *owns* its
/// controller: disposing from the caller raced the pop animation, rebuilding a
/// live TextField against a disposed controller. State.dispose runs only after
/// the route has fully unmounted.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initialText,
    this.hintText,
    this.suffixText,
    this.digitsOnly = false,
  });

  final String title;
  final String initialText;
  final String? hintText;
  final String? suffixText;
  final bool digitsOnly;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _popWith() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: d ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: d ? Colors.white : const Color(0xFF1C1C1E),
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType:
            widget.digitsOnly
                ? const TextInputType.numberWithOptions(decimal: false)
                : TextInputType.text,
        inputFormatters:
            widget.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: d ? Colors.white : const Color(0xFF1C1C1E),
        ),
        decoration: InputDecoration(
          suffixText: widget.suffixText,
          hintText: widget.hintText,
          filled: true,
          fillColor:
              d
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF2F2F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _popWith(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.result_cancel,
            style: TextStyle(
              color: d ? Colors.white54 : const Color(0xFF8E8E93),
            ),
          ),
        ),
        TextButton(
          onPressed: () => _popWith(),
          child: Text(
            l10n.result_save,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// One macro readout. When [showGrams] is false the grams are withheld but the
/// composition share is still shown — stated plainly, never blurred.
class _MacroChip extends StatelessWidget {
  final String label;
  final int grams;
  final double share;
  final Color color;
  final bool isDark;
  final bool showGrams;
  final VoidCallback onLockedTap;

  const _MacroChip({
    required this.label,
    required this.grams,
    required this.share,
    required this.color,
    required this.isDark,
    required this.showGrams,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    final pct = (share.clamp(0.0, 1.0) * 100).round();

    final body = Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
      decoration: BoxDecoration(
        color:
            d
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.85),
        border: Border.all(
          color: (d ? Colors.white : Colors.black).withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: d ? Colors.white60 : const Color(0xFF6D6D72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              showGrams ? '$grams g' : '$pct%',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.05,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: share.clamp(0.0, 1.0)),
                builder:
                    (context, v, _) => Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: color.withValues(alpha: d ? 0.16 : 0.18),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: v,
                          heightFactor: 1,
                          child: ColoredBox(color: color),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );

    if (showGrams) return body;
    return GestureDetector(
      onTap: onLockedTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}

class _CountUp extends StatefulWidget {
  final int value;
  final TextStyle style;

  const _CountUp({required this.value, required this.style});

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animateTo(widget.value.toDouble(), from: 0);
  }

  void _animateTo(double target, {required double from}) {
    _anim = Tween<double>(
      begin: from,
      end: target,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _CountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final current =
          _ctrl.isAnimating ? _anim.value : oldWidget.value.toDouble();
      _animateTo(widget.value.toDouble(), from: current);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (context, _) => Text(_fmt(_anim.value.round()), style: widget.style),
    );
  }
}

class _FoodCard extends StatefulWidget {
  final _Item item;
  final int index;
  final bool isDark;
  final bool showMacros;
  final Color accent;
  final int? sharePct;
  final void Function(int delta) onWeightDelta;
  final void Function(double g) onWeightSet;
  final VoidCallback onWeightType;
  final VoidCallback onRename, onDelete;

  const _FoodCard({
    super.key,
    required this.item,
    required this.index,
    required this.isDark,
    required this.accent,
    required this.sharePct,
    required this.showMacros,
    required this.onWeightDelta,
    required this.onWeightSet,
    required this.onWeightType,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<_FoodCard>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    _haptic();
    setState(() {
      _open = !_open;
      if (_open) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  /// Portion presets scaled to the item, so the chips are always plausible
  /// options for *this* food rather than a fixed 50–500g ladder.
  List<int> _presetsFor(int base) {
    if (base <= 30) return const <int>[10, 15, 20, 25, 30];
    if (base <= 100) return const <int>[25, 50, 75, 100, 125, 150];
    if (base <= 300) return const <int>[100, 150, 200, 250, 300];
    final scaled =
        _presetWeights
            .where((p) => p >= base * 0.4 && p <= base * 2.5)
            .take(5)
            .toList();
    return scaled.isEmpty ? _presetWeights.take(5).toList() : scaled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.isDark;
    final accent = widget.accent;
    final item = widget.item;
    final step = _stepFor(item.weightG.round());
    final unsupported = !item.matched || item.per100g == null;
    final confLabel =
        item.confidence != null
            ? _confidenceLabel(l10n, item.confidence!)
            : null;
    final confColor =
        item.confidence != null ? _confidenceColor(item.confidence!) : null;
    final presets = _presetsFor(item.weightG.round());

    // Slider range tracks the item instead of spanning 5–2000g for everything,
    // so a 140g portion is adjustable at usable precision.
    final sliderMax = (item.weightG * 3).clamp(120.0, 3000.0).roundToDouble();
    final sliderValue = item.weightG.clamp(5.0, sliderMax);

    return Dismissible(
      key: ValueKey('dismiss-food-${item.uid}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(LucideIcons.trash2, size: 20, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                d
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.75),
            border: Border.all(
              color: (d ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: Container(color: accent.withValues(alpha: 0.6)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Collapsed row: one job, one tap target — expand. ──
                  GestureDetector(
                    key: const ValueKey('card-header'),
                    onTap: _toggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.index + 1}',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.name.trim().isEmpty
                                            ? l10n.result_food_item
                                            : _capitalize(item.name),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              d
                                                  ? Colors.white
                                                  : const Color(0xFF1C1C1E),
                                        ),
                                      ),
                                    ),
                                    if (confLabel != null &&
                                        confLabel.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: confColor!.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          confLabel,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: confColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                if (unsupported)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF9500,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.alertTriangle,
                                          size: 10,
                                          color: Color(0xFFFF9500),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.result_not_matched,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFF9500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Text(
                                        '${_fmt(item.calories)} kcal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (widget.showMacros) ...[
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            'P${item.protein} · C${item.carbs} · F${item.fat}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  d
                                                      ? Colors.white38
                                                      : const Color(0xFF8E8E93),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (widget.sharePct != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${widget.sharePct}%',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Static readout while collapsed. No stepper here, so
                          // a near-miss can't fire the wrong action.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (d ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${item.weightG.round()} g',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:
                                    unsupported
                                        ? (d
                                            ? Colors.white24
                                            : const Color(0xFFC7C7CC))
                                        : (d
                                            ? Colors.white
                                            : const Color(0xFF1C1C1E)),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: Icon(
                              LucideIcons.moreVertical,
                              size: 16,
                              color: d ? Colors.white38 : const Color(0xFF8E8E93),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),
                            onSelected: (val) {
                              if (val == 'rename') {
                                widget.onRename();
                              } else if (val == 'delete') {
                                widget.onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.pencil,
                                      size: 14,
                                      color: d ? Colors.white70 : const Color(0xFF1C1C1E),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.result_rename,
                                      style: TextStyle(
                                        color: d ? Colors.white : const Color(0xFF1C1C1E),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.trash2,
                                      size: 14,
                                      color: Color(0xFFFF3B30),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.result_discard,
                                      style: const TextStyle(
                                        color: Color(0xFFFF3B30),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: _open ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color:
                                  d ? Colors.white38 : const Color(0xFFC7C7CC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Expanded: full-size controls with room to breathe. ──
                  SizeTransition(
                    sizeFactor: _anim,
                    axisAlignment: -1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child:
                          unsupported
                              ? _unmatchedBody(l10n, d)
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    height: 1,
                                    color: (d ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.07),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Text(
                                        l10n.result_portion,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color:
                                              d
                                                  ? Colors.white38
                                                  : const Color(0xFF8E8E93),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Tap the value to type an exact weight.
                                      GestureDetector(
                                        onTap: widget.onWeightType,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: accent.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${item.weightG.round()} g',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: accent,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(
                                                LucideIcons.pencil,
                                                size: 11,
                                                color: accent,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Presets first — this is the primary path.
                                  SizedBox(
                                    height: 34,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: presets.length,
                                      separatorBuilder:
                                          (_, _) => const SizedBox(width: 6),
                                      itemBuilder:
                                          (context, i) => _WtChip(
                                            label: '${presets[i]}g',
                                            selected:
                                                item.weightG.round() ==
                                                presets[i],
                                            onTap:
                                                () => widget.onWeightSet(
                                                  presets[i].toDouble(),
                                                ),
                                            isDark: d,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Fine adjustment, scaled to this item.
                                  Row(
                                    children: [
                                      _StepBtn(
                                        icon: LucideIcons.minus,
                                        isDark: d,
                                        onTap:
                                            () => widget.onWeightDelta(-step),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(
                                            context,
                                          ).copyWith(
                                            trackHeight: 3,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                  enabledThumbRadius: 8,
                                                ),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                                  overlayRadius: 18,
                                                ),
                                          ),
                                          child: Slider(
                                            value: sliderValue,
                                            min: 5,
                                            max: sliderMax,
                                            activeColor: accent,
                                            inactiveColor: (d
                                                    ? Colors.white
                                                    : Colors.black)
                                                .withValues(alpha: 0.1),
                                            onChanged:
                                                (v) => widget.onWeightSet(v),
                                          ),
                                        ),
                                      ),
                                      _StepBtn(
                                        icon: LucideIcons.plus,
                                        isDark: d,
                                        onTap: () => widget.onWeightDelta(step),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (widget.showMacros) ...[
                                        _dot(
                                          'P',
                                          item.protein,
                                          AppColors.protein,
                                          d,
                                        ),
                                        const SizedBox(width: 14),
                                        _dot(
                                          'C',
                                          item.carbs,
                                          AppColors.carbs,
                                          d,
                                        ),
                                        const SizedBox(width: 14),
                                        _dot('F', item.fat, AppColors.fat, d),
                                      ],
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: widget.onRename,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            LucideIcons.pencil,
                                            size: 17,
                                            color:
                                                d
                                                    ? Colors.white38
                                                    : const Color(0xFF8E8E93),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        key: const ValueKey('card-delete'),
                                        onTap: widget.onDelete,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            LucideIcons.trash2,
                                            size: 17,
                                            color: Color(0xFFFF3B30),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unmatchedBody(AppLocalizations l10n, bool d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          color: (d ? Colors.white : Colors.black).withValues(alpha: 0.07),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.result_not_in_database,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRename,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  l10n.result_assign_food,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: widget.onDelete,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.trash2,
                  size: 17,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot(String label, int grams, Color c, bool d) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $grams g',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: d ? Colors.white38 : const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (d ? Colors.white : Colors.black).withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15,
          color: d ? Colors.white70 : const Color(0xFF6D6D72),
        ),
      ),
    );
  }
}

class _WtChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _WtChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color:
                selected
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.35)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFC7C7CC).withValues(alpha: 0.4)),
          ),
        ),
        child: Center(
          child: Text(
            selected ? '$label \u2713' : label,
            style: TextStyle(
              color:
                  selected
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? Colors.white38 : const Color(0xFF8E8E93)),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroProportionBar extends StatelessWidget {
  final int protein;
  final int carbs;
  final int fat;
  final bool isDark;

  const _MacroProportionBar({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isDark,
  });

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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

