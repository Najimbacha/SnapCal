import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../providers/settings_provider.dart';

const _s = <double>[0.7, 1.0, 1.3, 1.6];

List<String> _portions(String name) {
  final v = name.toLowerCase();
  if (v.contains('sauce') || v.contains('ketchup') || v.contains('mayo') || v.contains('dressing')) return const ['Light', 'Normal', 'Extra'];
  if (v.contains('rice') || v.contains('fries') || v.contains('pasta') || v.contains('nuts') || v.contains('salad')) return const ['50g', '100g', '150g', '200g'];
  if (v.contains('slider')) return const ['1', '2', '3', '4'];
  if (v.contains('burger') || v.contains('chicken') || v.contains('wing') || v.contains('piece')) return const ['1', '2', '3', '4'];
  return const ['Small', 'Regular', 'Large'];
}

class _Item {
  const _Item({required this.name, required this.kcal, required this.protein, required this.carbs, required this.fat, this.serving = 1});
  final String name;
  final int kcal, protein, carbs, fat, serving;
  int get calories => (kcal * _s[serving]).round();
  int get p => (protein * _s[serving]).round();
  int get c => (carbs * _s[serving]).round();
  int get f => (fat * _s[serving]).round();
  List<String> get portionLabels => _portions(name);
  String get portionLabel => portionLabels[serving.clamp(0, portionLabels.length - 1)];
  factory _Item.from(NutritionResult r) => _Item(name: r.foodName, kcal: r.calories, protein: r.protein, carbs: r.carbs, fat: r.fat);
  static final _Item empty = _Item(name: 'Food item', kcal: 0, protein: 0, carbs: 0, fat: 0);
  _Item copy({String? name, int? serving}) => _Item(name: name ?? this.name, kcal: kcal, protein: protein, carbs: carbs, fat: fat, serving: serving ?? this.serving);
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

  @override
  void initState() {
    super.initState();
    final r = widget.results ?? (widget.result == null ? [] : [widget.result!]);
    _items = r.map(_Item.from).toList();
    if (_items.isEmpty) _items = [_Item.empty];
  }

  int get _kcal => _items.fold(0, (s, i) => s + i.calories);
  int get _p => _items.fold(0, (s, i) => s + i.p);
  int get _c => _items.fold(0, (s, i) => s + i.c);
  int get _f => _items.fold(0, (s, i) => s + i.f);

  void _serve(int i, int v) => setState(() => _items[i] = _items[i].copy(serving: v));
  void _add() => setState(() => _items.add(_Item.empty));
  void _del(int i) { HapticFeedback.lightImpact(); setState(() => _items.removeAt(i)); }

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
      widget.onSave(i.name, i.calories, i.p, i.c, i.f, i.portionLabel);
    } else {
      widget.onSaveAll!(_items.map((i) => NutritionResult(foodName: i.name, portion: i.portionLabel, calories: i.calories, protein: i.p, carbs: i.c, fat: i.f)).toList());
    }
    Navigator.of(context).pop();
  }

  void _retake() { Navigator.of(context).pop(); widget.onCancel(); }

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
                    onServing: (v) => _serve(e.key, v),
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
  final void Function(int) onServing;
  final VoidCallback onRename, onDelete;

  const _FoodCard({super.key, required this.item, required this.index, required this.isDark, required this.onServing, required this.onRename, required this.onDelete});

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

  Color get _accent {
    final p = widget.item.p;
    final c = widget.item.c;
    final f = widget.item.f;
    if (p >= c && p >= f) return AppColors.protein;
    if (c >= p && c >= f) return AppColors.carbs;
    return AppColors.fat;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final labels = widget.item.portionLabels;
    final accent = _accent;

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
                              Text(widget.item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: d ? Colors.white : const Color(0xFF1C1C1E))),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text('${widget.item.calories} kcal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                                  const SizedBox(width: 6),
                                  Text('\u00b7 ${widget.item.portionLabel}', style: TextStyle(fontSize: 12, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
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
                          SizedBox(
                            height: 30,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: labels.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 6),
                              itemBuilder: (context, i) => _ServingChip(
                                label: labels[i], selected: widget.item.serving == i,
                                onTap: () => widget.onServing(i), isDark: d,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _dot('${widget.item.p}g P', AppColors.protein, d),
                              const SizedBox(width: 14),
                              _dot('${widget.item.c}g C', AppColors.carbs, d),
                              const SizedBox(width: 14),
                              _dot('${widget.item.f}g F', AppColors.fat, d),
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

class _ServingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ServingChip({required this.label, required this.selected, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.35) : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFC7C7CC).withValues(alpha: 0.4))),
        ),
        child: Center(
          child: Text(
            selected ? '$label \u2713' : label,
            style: TextStyle(color: selected ? AppColors.primary : (isDark ? Colors.white38 : const Color(0xFF8E8E93)), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}



