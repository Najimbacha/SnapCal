import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/water_provider.dart';
const _waterBlue = Color(0xFF3B82F6);
const _waterLight = Color(0xFFE0F2FE);

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with TickerProviderStateMixin {
  int _selectedMl = 200;
  late AnimationController _waveController;
  late AnimationController _fillBounceController;
  late Animation<double> _fillBounce;
  bool _isAdding = false;

  static const _cupOptions = [
    _CupOption('Small', 200, LucideIcons.glassWater),
    _CupOption('Medium', 300, LucideIcons.glassWater),
    _CupOption('Large', 500, LucideIcons.beer),
    _CupOption('Bottle', 750, LucideIcons.wine),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _fillBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fillBounce = CurvedAnimation(
      parent: _fillBounceController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillBounceController.dispose();
    super.dispose();
  }

  Future<void> _addWater(WaterProvider water) async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    HapticFeedback.mediumImpact();
    await water.addWater(_selectedMl);
    _fillBounceController.forward(from: 0);
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.black87),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/log');
              }
            },
          ),
          title: const Text(
            'Hydration',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.info, color: Colors.grey, size: 22),
              onPressed: () {},
            ),
          ],
        ),
        body: Consumer<WaterProvider>(
          builder: (context, water, _) {
            final goal = math.max(water.goal, 1);
            final total = water.total;
            final progress = (total / goal).clamp(0.0, 1.0);
            final remaining = math.max(0, goal - total);

            return Column(
              children: [
                // ── Hero wave card ──────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_waveController, _fillBounce]),
                  builder: (context, _) {
                    final displayProgress =
                        (progress * _fillBounce.value).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _waterLight,
                              _waterLight.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Wave canvas
                              CustomPaint(
                                size: const Size(double.infinity, 220),
                                painter: _WaterHeroPainter(
                                  progress: displayProgress,
                                  waveValue: _waveController.value,
                                ),
                              ),
                              // Center content
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$total',
                                      style: const TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                        color: _waterBlue,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'of ${goal}ml',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _waterBlue.withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Percentage badge
                              Positioned(
                                right: 16,
                                top: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _waterBlue.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${(progress * 100).round()}%',
                                    style: const TextStyle(
                                      color: _waterBlue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 6),

                // ── Status text ─────────────────────────────────────────
                Text(
                  remaining > 0
                      ? '$remaining ml remaining today'
                      : 'Daily goal reached! 🎉',
                  style: TextStyle(
                    color: remaining > 0 ? Colors.grey.shade500 : _waterBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Preset cards ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _cupOptions.map((opt) {
                      final isSelected = _selectedMl == opt.ml;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedMl = opt.ml);
                            HapticFeedback.selectionClick();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? _waterLight : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? _waterBlue.withOpacity(0.4)
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  opt.icon,
                                  size: 24,
                                  color: isSelected ? _waterBlue : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${opt.ml}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? _waterBlue : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'ml',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? _waterBlue : Colors.grey,
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

                const SizedBox(height: 20),

                // ── Add button ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _isAdding ? null : () => _addWater(water),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _waterBlue.withOpacity(0.85),
                            _waterBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _waterBlue.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isAdding
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.plus,
                                      color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add $_selectedMl ml',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Quick log buttons ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickLogButton(
                          icon: LucideIcons.minus,
                          label: 'Remove',
                          onTap: water.todaysWaterMl > 0
                              ? () {
                                  HapticFeedback.lightImpact();
                                  water.removeWater(_selectedMl);
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickLogButton(
                          icon: LucideIcons.rotateCw,
                          label: 'Reset',
                          onTap: water.todaysWaterMl > 0
                              ? () => _showResetDialog(water)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showResetDialog(WaterProvider water) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset water?'),
        content: const Text('This will clear all water logged today.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              water.resetToday();
              Navigator.pop(ctx);
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero wave painter
// ─────────────────────────────────────────────────────────────────────────────

class _WaterHeroPainter extends CustomPainter {
  final double progress;
  final double waveValue;

  _WaterHeroPainter({required this.progress, required this.waveValue});

  @override
  void paint(Canvas canvas, Size size) {
    final fillH = size.height * (1 - progress);

    // Background bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.3);
    for (int i = 0; i < 6; i++) {
      final x = (i * 37.0 + waveValue * 20) % size.width;
      final y = (i * 45.0) % (size.height * 0.7) + 20;
      canvas.drawCircle(Offset(x, y), 4 + (i % 3) * 2, bubblePaint);
    }

    // Water body
    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _waterBlue.withOpacity(0.3),
          _waterBlue.withOpacity(0.6),
          _waterBlue,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 1) {
      final wave = math.sin((x / size.width * 2 * math.pi) + waveValue * 2) * 6 +
          math.sin((x / size.width * 4 * math.pi) + waveValue * 3) * 3;
      path.lineTo(x, fillH + wave);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, waterPaint);

    // Wave highlight line
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final hlPath = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final wave = math.sin((x / size.width * 2 * math.pi) + waveValue * 2) * 6 +
          math.sin((x / size.width * 4 * math.pi) + waveValue * 3) * 3;
      if (x == 0) {
        hlPath.moveTo(x, fillH + wave);
      } else {
        hlPath.lineTo(x, fillH + wave);
      }
    }
    canvas.drawPath(hlPath, highlightPaint);

    // Droplets at surface
    final dropPaint = Paint()
      ..color = Colors.white.withOpacity(0.4);
    for (int i = 0; i < 3; i++) {
      final dx = size.width * (0.2 + i * 0.3);
      final dy = fillH + math.sin((dx / size.width * 2 * math.pi) + waveValue * 2) * 6;
      canvas.drawCircle(Offset(dx, dy + 2), 2.5, dropPaint);
    }
  }

  @override
  bool shouldRepaint(_WaterHeroPainter old) =>
      old.progress != progress || old.waveValue != waveValue;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Quick log button
// ─────────────────────────────────────────────────────────────────────────────

class _QuickLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickLogButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: onTap != null ? Colors.black54 : Colors.grey.shade300,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onTap != null ? Colors.black54 : Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CupOption {
  final String label;
  final int ml;
  final IconData icon;
  const _CupOption(this.label, this.ml, this.icon);
}
