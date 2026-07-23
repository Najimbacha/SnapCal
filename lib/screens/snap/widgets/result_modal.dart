import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../providers/settings_provider.dart';

const _presetWeights = <int>[50, 100, 150, 200, 250, 300, 400, 500];

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

String _confidenceLabel(double c) {
  if (c >= 0.85) return '';
  if (c >= 0.60) return '';
  if (c >= 0.40) return 'Estimated';
  return 'Low';
}

Color _confidenceColor(double c) {
  if (c >= 0.85) return const Color(0xFF34C759);
  if (c >= 0.60) return AppColors.primary;
  if (c >= 0.40) return const Color(0xFFFF9500);
  return const Color(0xFFFF3B30);
}

class _Item {
  _Item({
    required this.name,
    required this.weightG,
    this.confidence,
    this.matched = true,
    this.per100g,
  });

  String name;
  double weightG;
  double? confidence;
  bool matched;
  Map<String, dynamic>? per100g;

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
      weight = (portionMatch != null ? double.tryParse(portionMatch.group(1)!) : r.weightG) ?? 150;
      if (weight > 0) {
        final factor = 100 / weight;
        per100g = {
          'calories': (r.calories * factor).round(),
          'protein': (r.protein * factor).round(),
          'carbs': (r.carbs * factor).round(),
          'fat': (r.fat * factor).round(),
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
    );
  }

  static final _Item empty = _Item(name: 'Food item', weightG: 100);

  _Item copy({String? name, double? weightG, double? confidence, bool? matched}) =>
      _Item(
        name: name ?? this.name,
        weightG: weightG ?? this.weightG,
        confidence: confidence ?? this.confidence,
        matched: matched ?? this.matched,
        per100g: per100g,
      );
}

void _haptic() => HapticFeedback.selectionClick();

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

  @override
  void initState() {
    super.initState();
    final r = widget.results ?? (widget.result == null ? [] : [widget.result!]);
    _items = r.map(_Item.from).toList();
    if (_items.isEmpty) _items = [_Item.empty];
  }

  int get _kcal => _items.fold(0, (s, i) => s + i.calories);
  int get _p => _items.fold(0, (s, i) => s + i.protein);
  int get _c => _items.fold(0, (s, i) => s + i.carbs);
  int get _f => _items.fold(0, (s, i) => s + i.fat);

  void _adjWt(int i, int delta) {
    setState(() {
      final cur = _items[i].weightG;
      final next = _snapWeight((cur + delta).round().clamp(5, 2000));
      _items[i] = _items[i].copy(weightG: next.toDouble());
    });
    _haptic();
  }

  void _setWt(int i, double g) {
    setState(() => _items[i] = _items[i].copy(weightG: _snapWeight(g.round()).toDouble()));
    _haptic();
  }

  void _add() {
    setState(() => _items.add(_Item.empty));
    _haptic();
  }

  void _del(int i) {
    HapticFeedback.lightImpact();
    setState(() => _items.removeAt(i));
  }

  Future<void> _rename(int i) async {
    final c = TextEditingController(text: _items[i].name);
    final d = Theme.of(context).brightness == Brightness.dark;
    final n = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: d ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Rename', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: d ? Colors.white : const Color(0xFF1C1C1E))),
        content: TextField(controller: c, autofocus: true,
          style: TextStyle(fontSize: 15, color: d ? Colors.white : const Color(0xFF1C1C1E)),
          decoration: InputDecoration(
            hintText: 'Food name', filled: true,
            fillColor: d ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: d ? Colors.white54 : const Color(0xFF8E8E93)))),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    c.dispose();
    if (n != null && n.isNotEmpty && mounted) setState(() => _items[i] = _items[i].copy(name: n));
  }

  void _save() {
    if (_items.isEmpty || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    if (_items.length == 1 || widget.onSaveAll == null) {
      final i = _items.first;
      widget.onSave(i.name, i.calories, i.protein, i.carbs, i.fat, '${i.weightG.round()}g');
    } else {
      widget.onSaveAll!(_items.map((i) => NutritionResult(
        foodName: i.name,
        portion: '${i.weightG.round()}g',
        calories: i.calories,
        protein: i.protein,
        carbs: i.carbs,
        fat: i.fat,
        weightG: i.weightG,
        matched: i.matched,
        nutritionPer100g: i.per100g,
        nutritionActual: i.matched && i.per100g != null
            ? {'calories': i.calories, 'protein': i.protein, 'carbs': i.carbs, 'fat': i.fat}
            : null,
      )).toList());
    }
    Navigator.of(context).pop();
  }

  void _retake() { Navigator.of(context).pop(); widget.onCancel(); }

  Color _accentFor(_Item i) {
    if (!i.matched || i.per100g == null) return AppColors.primary;
    final p = i.protein;
    final c = i.carbs;
    final f = i.fat;
    if (p >= c && p >= f) return AppColors.protein;
    if (c >= p && c >= f) return AppColors.carbs;
    return AppColors.fat;
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final pro = ref.watch(effectiveIsProProvider);
    final b = MediaQuery.paddingOf(context).bottom;
    const h = 240.0;

    return Scaffold(
      backgroundColor: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true, expandedHeight: h,
            backgroundColor: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imageBytes != null)
                    Image.memory(widget.imageBytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink())
                  else
                    Container(color: d ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA)),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.55)],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20, right: 20, bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('SCAN RESULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.2)),
                            ),
                            if (_kcal > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF9500).withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.flame, size: 11, color: const Color(0xFFFFD60A)),
                                    const SizedBox(width: 3),
                                    Text('$_kcal kcal', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFFFD60A))),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _kcal > 0 ? '$_kcal' : 'No items yet',
                          style: TextStyle(
                            fontSize: _kcal > 0 ? 80 : 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 0.95,
                            letterSpacing: -4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: _retake,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                  child: Icon(LucideIcons.chevronLeft, size: 24, color: Colors.white),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _retake,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.camera, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Retake', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, b + 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _macroRow(d, pro),
                  const SizedBox(height: 28),
                  Text('FOOD ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d ? Colors.white38 : const Color(0xFF8E8E93), letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  ..._items.asMap().entries.map((e) => _FoodCard(
                    key: ValueKey('food-${e.key}'),
                    item: e.value, index: e.key, isDark: d,
                    accent: _accentFor(e.value),
                    onWeightDelta: (delta) => _adjWt(e.key, delta),
                    onWeightSet: (g) => _setWt(e.key, g),
                    onRename: () => _rename(e.key),
                    onDelete: () => _del(e.key),
                  )),
                  if (_items.isEmpty) _emptyState(d),
                  if (!pro) ...[
                    const SizedBox(height: 16),
                    _upgradeBanner(context, d),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _add,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: (d ? Colors.white : const Color(0xFFC7C7CC)).withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('+ Add Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: d ? Colors.white54 : const Color(0xFF8E8E93))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, b + 8),
        decoration: BoxDecoration(
          color: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          border: Border(top: BorderSide(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.08))),
        ),
        child: SizedBox(
          width: double.infinity, height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, foregroundColor: Colors.white,
                shadowColor: Colors.transparent, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_kcal > 0 ? 'Add to Log  \u2022  $_kcal kcal' : 'Save Log', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroRow(bool d, bool pro) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pill('Protein', _p, AppColors.protein, d, pro),
        const SizedBox(width: 10),
        _pill('Carbs', _c, AppColors.carbs, d, pro),
        const SizedBox(width: 10),
        _pill('Fat', _f, AppColors.fat, d, pro),
      ],
    );
  }

  Widget _pill(String label, int value, Color color, bool d, bool pro) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: d ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            pro
                ? Text('${value}g', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1.1))
                : Icon(LucideIcons.lock, size: 14, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _upgradeBanner(BuildContext context, bool d) {
    return GestureDetector(
      onTap: () => PremiumConversionService().openPaywall(context, PaywallEntryPoint.macroDetails, featureName: 'scan_result_macros'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: d ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(LucideIcons.gem, size: 15, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Go Pro for full macronutrient breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: d ? Colors.white : const Color(0xFF1C1C1E))),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: d ? Colors.white24 : const Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text('No items detected', style: TextStyle(fontSize: 14, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
      ),
    );
  }
}

class _FoodCard extends StatefulWidget {
  final _Item item;
  final int index;
  final bool isDark;
  final Color accent;
  final void Function(int delta) onWeightDelta;
  final void Function(double g) onWeightSet;
  final VoidCallback onRename, onDelete;

  const _FoodCard({
    super.key,
    required this.item,
    required this.index,
    required this.isDark,
    required this.accent,
    required this.onWeightDelta,
    required this.onWeightSet,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<_FoodCard> with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() { super.initState(); _ctrl = AnimationController(duration: const Duration(milliseconds: 250), vsync: this); _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() { setState(() { _open = !_open; if (_open) { _ctrl.forward(); } else { _ctrl.reverse(); } }); }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final accent = widget.accent;
    final item = widget.item;
    final step = _stepFor(item.weightG.round());
    final unsupported = !item.matched || item.per100g == null;
    final confLabel = item.confidence != null ? _confidenceLabel(item.confidence!) : null;
    final confColor = item.confidence != null ? _confidenceColor(item.confidence!) : null;

    List<int> presets;
    final base = item.weightG.round();
    if (base <= 30) {
      presets = <int>[10, 15, 20, 25, 30];
    } else if (base <= 100) {
      presets = <int>[25, 50, 75, 100, 125, 150];
    } else if (base <= 300) {
      presets = <int>[100, 150, 200, 250, 300];
    } else {
      presets = _presetWeights.where((p) => p >= base * 0.4 && p <= base * 2.5).take(5).toList();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: d ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.75),
          border: Border.all(color: (d ? Colors.white : Colors.white).withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, width: 3,
              child: Container(color: accent.withValues(alpha: 0.6)),
            ),
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('${widget.index + 1}', style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: d ? Colors.white : const Color(0xFF1C1C1E))),
                                  ),
                                  if (confLabel != null && confLabel.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: confColor!.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(confLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: confColor)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (unsupported)
                                    Text('Nutrition unavailable',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: d ? Colors.white38 : const Color(0xFF8E8E93)))
                                  else ...[
                                    Text('${item.calories} kcal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                                    const SizedBox(width: 6),
                                    Text('\u00b7 ${item.weightG.round()}g',
                                      style: TextStyle(fontSize: 12, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(_open ? LucideIcons.chevronUp : Icons.keyboard_arrow_down_rounded, size: 20, color: d ? Colors.white24 : const Color(0xFFC7C7CC)),
                      ],
                    ),
                    SizeTransition(
                      sizeFactor: _anim,
                      axisAlignment: -1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          if (!unsupported) ...[
                            Row(
                              children: [
                                _WtButton(icon: LucideIcons.minus, onTap: () => widget.onWeightDelta(-step)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('${item.weightG.round()} g',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: d ? Colors.white : const Color(0xFF1C1C1E))),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                        ),
                                        child: Slider(
                                          value: item.weightG.clamp(5, 2000),
                                          min: 5,
                                          max: 2000,
                                          divisions: 199,
                                          activeColor: accent,
                                          inactiveColor: (d ? Colors.white : Colors.black).withValues(alpha: 0.1),
                                          onChanged: (v) => widget.onWeightSet(v),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _WtButton(icon: LucideIcons.plus, onTap: () => widget.onWeightDelta(step)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 28,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: presets.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 6),
                                itemBuilder: (context, i) => _WtChip(
                                  label: '${presets[i].round()}g',
                                  selected: item.weightG.round() == presets[i].round(),
                                                  onTap: () => widget.onWeightSet(presets[i].toDouble()),
                                  isDark: d,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _dot('${item.protein}g P', AppColors.protein, d),
                                const SizedBox(width: 14),
                                _dot('${item.carbs}g C', AppColors.carbs, d),
                                const SizedBox(width: 14),
                                _dot('${item.fat}g F', AppColors.fat, d),
                                const Spacer(),
                                GestureDetector(
                                  onTap: widget.onRename,
                                  child: Icon(LucideIcons.pencil, size: 15, color: d ? Colors.white24 : const Color(0xFFC7C7CC)),
                                ),
                                const SizedBox(width: 14),
                                GestureDetector(
                                  onTap: widget.onDelete,
                                  child: Icon(LucideIcons.trash2, size: 15, color: const Color(0xFFFF3B30)),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Not in database',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFFF9500))),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: widget.onRename,
                                  child: Text('Assign food', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: widget.onDelete,
                                  child: Icon(LucideIcons.trash2, size: 15, color: const Color(0xFFFF3B30)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(String l, Color c, bool d) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
      ],
    );
  }
}

class _WtButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _WtButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: (d ? Colors.white : Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: d ? Colors.white54 : const Color(0xFF8E8E93)),
      ),
    );
  }
}

class _WtChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _WtChip({required this.label, required this.selected, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.35) : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFC7C7CC).withValues(alpha: 0.4))),
        ),
        child: Center(
          child: Text(
            selected ? '$label \u2713' : label,
            style: TextStyle(color: selected ? AppColors.primary : (isDark ? Colors.white38 : const Color(0xFF8E8E93)), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
