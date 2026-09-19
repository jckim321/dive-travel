import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';

class ContinentRadar extends StatelessWidget {
  const ContinentRadar({
    super.key,
    required this.values,
  });

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: const Size(220, 220),
      painter: _RadarPainter(
        values: [
          for (final id in ContinentId.all) (values[id] ?? 0).clamp(0.0, 1.0),
        ],
        color: color,
        gridColor: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;
    final count = values.length;
    final angle = (2 * math.pi) / count;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final ring in [0.33, 0.66, 1.0]) {
      final path = Path();
      for (var i = 0; i < count; i++) {
        final point = _point(center, radius * ring, angle * i - math.pi / 2);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final fill = Path();
    for (var i = 0; i < count; i++) {
      final point = _point(
        center,
        radius * values[i],
        angle * i - math.pi / 2,
      );
      if (i == 0) {
        fill.moveTo(point.dx, point.dy);
      } else {
        fill.lineTo(point.dx, point.dy);
      }
    }
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      fill,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Offset _point(Offset center, double radius, double angle) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
