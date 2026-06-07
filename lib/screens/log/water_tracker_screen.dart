import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/water_provider.dart';

const _waterBgTop = Color(0xFFE3F7FF);
const _waterBgBottom = Color(0xFFC9EAFF);
const _waterBlue = Color(0xFF1687F2);
const _waterBlueDeep = Color(0xFF0B68D7);
const _waterInk = Color(0xFF10213A);
const _waterMuted = Color(0xFF7A8EA8);

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  int _selectedAmount = 200;

  static const _cupOptions = [
    _CupOption('Small glass', 200, Icons.local_drink_outlined),
    _CupOption('Medium glass', 240, Icons.local_drink_outlined),
    _CupOption('Large glass', 350, Icons.local_drink),
    _CupOption('Water bottle', 500, Icons.water),
  ];

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/log');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _waterBgBottom,
      ),
      child: Scaffold(
        backgroundColor: _waterBgBottom,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_waterBgTop, _waterBgBottom],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: _WaterBackgroundBubbles()),
            SafeArea(
              child: Consumer<WaterProvider>(
                builder: (context, water, _) {
                  final goal = math.max(water.goal, 1);
                  final total = water.total;
                  final progress = (total / goal).clamp(0.0, 1.0);

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(0, 12, 0, bottomInset + 36),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _WaterHeader(onBack: _goBack),
                      ),
                      const SizedBox(height: 16),
                      _WaterHeroCard(
                        total: total,
                        goal: goal,
                        progress: progress,
                        selectedAmount: _selectedAmount,
                        options: _cupOptions,
                        isProcessing: water.isLoading,
                        onAmountChanged:
                            (amount) => setState(() {
                              _selectedAmount = amount;
                            }),
                        onAdd: () => water.addWater(_selectedAmount),
                        onRemove: () => water.removeWater(_selectedAmount),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _WaterHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new, onTap: onBack),
        const Spacer(),
        const Text(
          'Hydration',
          style: TextStyle(
            color: _waterInk,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        _CircleIconButton(icon: Icons.more_horiz, onTap: () {}),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: _waterInk),
        ),
      ),
    );
  }
}

class _WaterHeroCard extends StatelessWidget {
  final int total;
  final int goal;
  final double progress;
  final int selectedAmount;
  final List<_CupOption> options;
  final bool isProcessing;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _WaterHeroCard({
    required this.total,
    required this.goal,
    required this.progress,
    required this.selectedAmount,
    required this.options,
    required this.isProcessing,
    required this.onAmountChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final height = math.max(MediaQuery.sizeOf(context).height - 126, 620.0);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _waterBlueDeep.withValues(alpha: 0.16),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WaterWavePainter(progress: progress),
              ),
            ),
            Positioned(
              left: 18,
              top: 34,
              bottom: 104,
              child: _WaterRuler(goal: goal),
            ),
            Positioned(
              top: 34,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Daily water',
                    style: TextStyle(
                      color: _waterMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: _waterBlue,
                      fontSize: 48,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/$goal ml',
                    style: const TextStyle(
                      color: _waterInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StepperControl(
                    selectedAmount: selectedAmount,
                    onAdd: onAdd,
                    onRemove: onRemove,
                  ),
                  const SizedBox(height: 16),
                  _CupAmountStrip(
                    options: options,
                    selectedAmount: selectedAmount,
                    onChanged: onAmountChanged,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 32,
              child: _WaterProgressFooter(
                progress: progress,
                selectedAmount: selectedAmount,
                isProcessing: isProcessing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  final int selectedAmount;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _StepperControl({
    required this.selectedAmount,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _waterBlue.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onRemove),
          Container(
            height: 28,
            constraints: const BoxConstraints(minWidth: 72),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _waterBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '+$selectedAmount ml',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: SizedBox(
          width: 31,
          height: 30,
          child: Icon(icon, color: _waterBlueDeep, size: 18),
        ),
      ),
    );
  }
}

class _WaterProgressFooter extends StatelessWidget {
  final double progress;
  final int selectedAmount;
  final bool isProcessing;

  const _WaterProgressFooter({
    required this.progress,
    required this.selectedAmount,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _waterBlue.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop, color: _waterBlue, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isProcessing ? 'Updating...' : '$percent% complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selected cup: $selectedAmount ml',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaterRuler extends StatelessWidget {
  final int goal;

  const _WaterRuler({required this.goal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Stack(
        children: [
          Positioned(
            left: 28,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: _waterInk.withValues(alpha: 0.18),
            ),
          ),
          ...List.generate(9, (index) {
            final top = index * 31.0;
            final isMajor = index % 2 == 0;
            return Positioned(
              top: top,
              left: 20,
              child: Row(
                children: [
                  Container(
                    width: isMajor ? 18 : 10,
                    height: 1.3,
                    color: _waterInk.withValues(alpha: isMajor ? 0.54 : 0.32),
                  ),
                  if (index == 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      '$goal ml',
                      style: const TextStyle(
                        color: _waterMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CupAmountStrip extends StatelessWidget {
  final List<_CupOption> options;
  final int selectedAmount;
  final ValueChanged<int> onChanged;

  const _CupAmountStrip({
    required this.options,
    required this.selectedAmount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            options.map((option) {
              final selected = option.amountMl == selectedAmount;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CupAmountChip(
                  option: option,
                  selected: selected,
                  onTap: () => onChanged(option.amountMl),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _CupAmountChip extends StatelessWidget {
  final _CupOption option;
  final bool selected;
  final VoidCallback onTap;

  const _CupAmountChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? _waterBlue.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? _waterBlue.withValues(alpha: 0.38)
                      : Colors.white.withValues(alpha: 0.82),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, color: _waterBlue, size: 17),
              const SizedBox(width: 7),
              Text(
                '${option.amountMl} ml',
                style: const TextStyle(
                  color: _waterBlueDeep,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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
  final int amountMl;
  final IconData icon;

  const _CupOption(this.label, this.amountMl, this.icon);
}

class _WaterWavePainter extends CustomPainter {
  final double progress;

  const _WaterWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final waterTop = size.height * (1 - (0.18 + progress * 0.62));
    final wavePaint =
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF75CEFF), _waterBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, waterTop, size.width, size.height));

    final path = Path()..moveTo(0, waterTop);
    for (double x = 0; x <= size.width; x += 6) {
      final y =
          waterTop +
          math.sin((x / size.width * math.pi * 3.2) + 0.8) * 15 +
          math.sin((x / size.width * math.pi * 6.0)) * 5;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, wavePaint);

    final highlightPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.48)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final highlight = Path()..moveTo(0, waterTop + 9);
    for (double x = 0; x <= size.width; x += 6) {
      highlight.lineTo(
        x,
        waterTop + 9 + math.sin((x / size.width * math.pi * 3.2) + 0.8) * 10,
      );
    }
    canvas.drawPath(highlight, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WaterBackgroundBubbles extends StatelessWidget {
  const _WaterBackgroundBubbles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _Bubble(left: 28, top: 24, size: 34, alpha: 0.22),
        _Bubble(right: 36, top: 112, size: 14, alpha: 0.22),
        _Bubble(left: 42, bottom: 132, size: 38, alpha: 0.24),
        _Bubble(right: 68, bottom: 250, size: 48, alpha: 0.18),
        _Bubble(left: 210, bottom: 64, size: 18, alpha: 0.20),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final double alpha;

  const _Bubble({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
          border: Border.all(color: _waterBlue.withValues(alpha: 0.10)),
        ),
      ),
    );
  }
}
