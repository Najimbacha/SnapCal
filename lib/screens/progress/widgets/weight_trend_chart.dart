import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/body_metric.dart';

class WeightTrendChart extends StatelessWidget {
  final List<BodyMetric> metrics;
  final double? targetWeight;

  const WeightTrendChart({
    super.key,
    required this.metrics,
    this.targetWeight,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter and sort for display (Oldest to Newest for the line)
    final displayMetrics = metrics.reversed.toList();
    final weights = displayMetrics.map((m) => m.weight).toList();
    
    final minWeight = weights.reduce(math.min);
    final maxWeight = weights.reduce(math.max);
    
    // Add some padding to the range
    final rangePadding = (maxWeight - minWeight) * 0.2;
    final minY = (minWeight - rangePadding).floorToDouble();
    final maxY = (maxWeight + rangePadding).ceilToDouble();

    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Weight Trend',
                style: AppTypography.labelLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                '${displayMetrics.last.weight.toStringAsFixed(1)} kg',
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ChartPainter(
                weights: weights,
                minY: minY,
                maxY: maxY,
                color: colorScheme.primary,
                labelColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DateLabel(displayMetrics.first.date),
              _DateLabel(displayMetrics.last.date),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final DateTime date;
  const _DateLabel(this.date);

  @override
  Widget build(BuildContext context) {
    return Text(
      '${date.day}/${date.month}',
      style: AppTypography.labelSmall.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> weights;
  final double minY;
  final double maxY;
  final Color color;
  final Color labelColor;

  _ChartPainter({
    required this.weights,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;

    final double width = size.width;
    final double height = size.height;
    final double stepX = width / (weights.length - 1);
    final double rangeY = maxY - minY;

    double getY(double weight) {
      return height - ((weight - minY) / rangeY * height);
    }

    // Draw Grid Lines (simplified)
    final gridPaint = Paint()
      ..color = labelColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    canvas.drawLine(Offset(0, getY(minY)), Offset(width, getY(minY)), gridPaint);
    canvas.drawLine(Offset(0, getY(maxY)), Offset(width, getY(maxY)), gridPaint);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < weights.length; i++) {
      final x = i * stepX;
      final y = getY(weights[i]);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, height);
        fillPath.lineTo(x, y);
      } else {
        // Smooth curve using Bezier
        final prevX = (i - 1) * stepX;
        final prevY = getY(weights[i - 1]);
        final controlX1 = prevX + (x - prevX) / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + (x - prevX) / 2;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }

      if (i == weights.length - 1) {
        fillPath.lineTo(x, height);
        fillPath.close();
      }
    }

    // Draw Fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw Points
    final pointPaint = Paint()..color = color;
    final pointBgPaint = Paint()..color = Colors.white;
    for (int i = 0; i < weights.length; i++) {
      final x = i * stepX;
      final y = getY(weights[i]);
      canvas.drawCircle(Offset(x, y), 5, pointBgPaint);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
