import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/water_provider.dart';

const _blue = Color(0xFF3B82F6);
const _blueLight = Color(0xFFE0F2FE);

class HydrationSheet extends StatefulWidget {
  const HydrationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const HydrationSheet(),
    );
  }

  @override
  State<HydrationSheet> createState() => _HydrationSheetState();
}

class _HydrationSheetState extends State<HydrationSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  int _selectedMl = 200;
  bool _showCustom = false;
  final _customCtrl = TextEditingController(text: '250');
  bool _isAdding = false;

  static const _presets = [
    _HydrationPreset('Small glass', 200, LucideIcons.glassWater),
    _HydrationPreset('Medium glass', 300, LucideIcons.glassWater),
    _HydrationPreset('Large glass', 500, LucideIcons.beer),
    _HydrationPreset('Bottle', 750, LucideIcons.wine),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutBack,
    );
    _fillController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _addWater() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    HapticFeedback.mediumImpact();
    final ml = _showCustom ? int.tryParse(_customCtrl.text) ?? 250 : _selectedMl;
    await context.read<WaterProvider>().addWater(ml);
    _fillController.forward(from: 0);
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final amount = context.select<WaterProvider, int>((p) => p.todaysWaterMl);
    const goal = 2000;
    final progress = (amount / goal).clamp(0.0, 1.0);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          margin: EdgeInsets.only(bottom: bottomInset),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _blueLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.droplets,
                            color: _blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Hydration',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _blueLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$amount',
                            style: const TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'ml',
                            style: TextStyle(
                              color: _blue.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Wave progress bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 60,
                    child: CustomPaint(
                      painter: _WaveProgressPainter(
                        progress: progress * _fillAnimation.value,
                        waveController: _waveController,
                      ),
                      size: const Size(double.infinity, 60),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Progress label ────────────────────────────────────────
              Text(
                '${(progress * 100).round()}% of daily goal (${amount == 0 ? '2,000' : '$amount'} / 2,000 ml)',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // ── Preset cards ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _presets.map((p) {
                    final isSelected = !_showCustom && _selectedMl == p.ml;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMl = p.ml;
                            _showCustom = false;
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _blueLight : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? _blue.withOpacity(0.4)
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(p.icon,
                                  size: 24,
                                  color: isSelected ? _blue : Colors.grey.shade400),
                              const SizedBox(height: 6),
                              Text(
                                '${p.ml}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? _blue : Colors.black87,
                                ),
                              ),
                              Text(
                                'ml',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? _blue : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Custom + Add row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Custom toggle
                    GestureDetector(
                      onTap: () {
                        setState(() => _showCustom = !_showCustom);
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _showCustom ? 140 : 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _showCustom ? _blueLight : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showCustom
                                ? _blue.withOpacity(0.4)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: _showCustom
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: TextField(
                                        controller: _customCtrl,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _blue,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const Text('ml',
                                        style: TextStyle(
                                            color: _blue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12)),
                                  ],
                                ),
                              )
                            : const Center(
                                child: Icon(LucideIcons.pencil,
                                    color: Colors.grey, size: 22),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add button
                    Expanded(
                      child: GestureDetector(
                        onTap: _isAdding ? null : _addWater,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _blue.withOpacity(0.85),
                                _blue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isAdding
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _showCustom
                                            ? LucideIcons.check
                                            : LucideIcons.plus,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _showCustom
                                            ? 'Log ${_customCtrl.text.trim()} ml'
                                            : 'Log $_selectedMl ml',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Done button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Wave progress painter
// ─────────────────────────────────────────────────────────────────────────────

class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final AnimationController waveController;

  _WaveProgressPainter({
    required this.progress,
    required this.waveController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillH = size.height * (1 - progress);

    // Background
    final bgPaint = Paint()
      ..color = Colors.grey.shade100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    if (progress <= 0) return;

    // Water fill
    final waveValue = (waveController.value * 2 * math.pi);
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _blue.withOpacity(0.4),
          _blue.withOpacity(0.7),
          _blue,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, fillH);

    for (double x = 0; x <= size.width; x += 1) {
      final wave = math.sin((x / size.width * 2 * math.pi) + waveValue) * 4;
      path.lineTo(x, fillH + wave);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);

    // Drop highlight
    final dropPaint = Paint()
      ..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(
      Offset(size.width * 0.3, fillH + 10),
      3,
      dropPaint,
    );
  }

  @override
  bool shouldRepaint(_WaveProgressPainter old) =>
      old.progress != progress || old.waveController != waveController;
}

class _HydrationPreset {
  final String label;
  final int ml;
  final IconData icon;
  const _HydrationPreset(this.label, this.ml, this.icon);
}
