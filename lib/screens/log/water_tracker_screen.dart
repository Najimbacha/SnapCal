import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/water_provider.dart';

// ── Premium 2026 palette ────────────────────────────────────────────────────
const _deep = Color(0xFF0A1628);
const _surface = Color(0xFF0F1F3A);
const _cardBg = Color(0xFF152A4A);
const _blue = Color(0xFF3B82F6);
const _cyan = Color(0xFF06D6A0);
const _blueGlow = Color(0xFF60A5FA);
const _textPrimary = Color(0xFFF1F5F9);
const _textSecondary = Color(0xFF94A3B8);

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with TickerProviderStateMixin {
  int _selectedMl = 250;
  late AnimationController _waveController;
  late AnimationController _fillBounceController;
  late Animation<double> _fillBounce;

  bool _isAdding = false;

  static const _presets = [250, 350, 500, 1000];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _fillBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0,
    );
    _fillBounce = CurvedAnimation(
      parent: _fillBounceController,
      curve: Curves.elasticOut,
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
    HapticFeedback.heavyImpact();
    await water.addWater(_selectedMl);
    _fillBounceController.value = 0.7;
    _fillBounceController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _deep,
      ),
      child: Scaffold(
        backgroundColor: _deep,
        body: Consumer<WaterProvider>(
          builder: (context, water, _) {
            final goal = math.max(water.goal, 1);
            final total = water.total;
            final progress = (total / goal).clamp(0.0, 1.0);

            return Stack(
              children: [
                // ── Animated gradient background ──────────────────────
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (_, __) {
                    final pulse = 0.5 + _waveController.value * 0.5;
                    return Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(-0.3 + pulse * 0.6, 0.1),
                            radius: 1.2,
                            colors: [
                              _surface,
                              _deep,
                              _deep,
                            ],
                            stops: const [0, 0.6, 1],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ── Glass orb decorations ─────────────────────────────
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _blue.withOpacity(0.15),
                          _blue.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _cyan.withOpacity(0.08),
                          _cyan.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Safe content ─────────────────────────────────────
                SafeArea(
                  child: Column(
                    children: [
                      // ── Top bar ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/log');
                                }
                              },
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: const Icon(LucideIcons.chevronLeft,
                                    color: _textPrimary, size: 20),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _cyan,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _cyan.withOpacity(0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Today',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Title ───────────────────────────────────────
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Row(
                          children: [
                            Text(
                              'Hydration',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Hero water card ─────────────────────────────
                      AnimatedBuilder(
                        animation: Listenable.merge([_waveController, _fillBounce]),
                        builder: (_, __) {
                          final displayProgress =
                              (progress * _fillBounce.value).clamp(0.0, 1.0);
                          final pulse = 0.5 + _waveController.value * 0.5;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              height: 260,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                     color: _blue.withOpacity(0.15 + pulse * 0.15),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(31),
                                child: Stack(
                                  children: [
                                    // Wave canvas
                                    CustomPaint(
                                      painter: _WavePainter(
                                        progress: displayProgress,
                                        wave: _waveController.value,
                                        glowIntensity: pulse,
                                      ),
                                    ),
                                    // Content overlay
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            '$total',
                                            style: TextStyle(
                                              fontSize: 72,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white.withOpacity(0.95),
                                              height: 0.95,
                                              letterSpacing: -2,
                                              shadows: [
                                                Shadow(
                                                  color: _blue.withOpacity(0.3),
                                                  blurRadius: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'of ${goal}ml',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white.withOpacity(0.45),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(LucideIcons.trophy,
                                                    size: 14,
                                                    color: _cyan),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${(progress * 100).round()}% of goal',
                                                  style: TextStyle(
                                                    color:
                                                        _textPrimary.withOpacity(0.7),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // ── Preset buttons ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: _presets.map((ml) {
                            final isSel = _selectedMl == ml;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedMl = ml);
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: isSel
                                        ? LinearGradient(
                                            colors: [
                                              _blue.withOpacity(0.3),
                                              _blue.withOpacity(0.15),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSel
                                        ? null
                                        : Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSel
                                          ? _blue.withOpacity(0.5)
                                          : Colors.white.withOpacity(0.06),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: _blue.withOpacity(0.2),
                                              blurRadius: 16,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$ml',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: isSel
                                              ? Colors.white
                                              : _textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'ml',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSel
                                              ? Colors.white.withOpacity(0.7)
                                              : _textSecondary.withOpacity(0.6),
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

                      const SizedBox(height: 24),

                      // ── CTA button ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: _isAdding ? null : () => _addWater(water),
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (_, __) {
                              final pulse = 0.5 + _waveController.value * 0.5;
                              return Container(
                                height: 62,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    colors: [
                                      _blue.withOpacity(0.9),
                                      _blue,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                    color: _blue.withOpacity(0.3 + pulse * 0.2),
                                    blurRadius: 24 + pulse * 12,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.15),
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
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Quick actions row ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _QuickAction(
                              icon: LucideIcons.rotateCw,
                              label: 'Reset',
                              enabled: total > 0,
                              onTap: () => _showResetDialog(water),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                total >= goal
                                    ? '🎉 Goal crushed!'
                                    : '${goal - total} ml remaining',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textSecondary.withOpacity(0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _QuickAction(
                              icon: LucideIcons.undo2,
                              label: 'Undo',
                              enabled: total > 0,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                water.removeWater(_selectedMl);
                              },
                            ),
                          ],
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
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset water?',
            style: TextStyle(color: _textPrimary)),
        content: const Text('Clear all water logged today.',
            style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              water.resetToday();
              Navigator.pop(ctx);
            },
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Wave painter — dual sine, glow, droplets
// ─────────────────────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double progress;
  final double wave;
  final double glowIntensity;

  _WavePainter({
    required this.progress,
    required this.wave,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillH = size.height * (1 - progress);

    // Deep water body
    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _blue.withOpacity(0.2),
          _blue.withOpacity(0.4),
          _blue.withOpacity(0.7),
          _blue,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, fillH, size.width, size.height - fillH));

    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 3 * math.pi) + wave * 2) * 8;
      final s2 = math.sin((x / size.width * 5 * math.pi) + wave * 3) * 4;
      path.lineTo(x, fillH + s1 + s2);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, waterPaint);

    // Surface glow line
    final glowPaint = Paint()
      ..color = _blueGlow.withOpacity(0.3 + glowIntensity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final glowPath = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final s1 = math.sin((x / size.width * 3 * math.pi) + wave * 2) * 8;
      final s2 = math.sin((x / size.width * 5 * math.pi) + wave * 3) * 4;
      if (x == 0) glowPath.moveTo(x, fillH + s1 + s2);
      else glowPath.lineTo(x, fillH + s1 + s2);
    }
    canvas.drawPath(glowPath, glowPaint);

    // Floating particles
    if (fillH > 1) {
      final dotPaint = Paint()..color = Colors.white.withOpacity(0.25);
      for (int i = 0; i < 8; i++) {
        final dx = (i * 47.0 + wave * 30) % size.width;
        final dy = fillH * (0.3 + (i % 3) * 0.2);
        if (!dy.isNaN && !dx.isNaN) {
          final r = 1.5 + (i % 3) * 0.8;
          canvas.drawCircle(Offset(dx, dy.clamp(0, fillH)), r, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress ||
      old.wave != wave ||
      old.glowIntensity != glowIntensity;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Quick action pill
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(enabled ? 0.06 : 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(enabled ? 0.08 : 0.04),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: enabled ? _textSecondary : _textSecondary.withOpacity(0.3),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? _textSecondary : _textSecondary.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
