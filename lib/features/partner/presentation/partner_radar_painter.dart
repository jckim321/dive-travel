import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';

/// Empty 4-axis diamond (radar) frame — no data values drawn.
class PartnerRadarPainter extends CustomPainter {
  const PartnerRadarPainter({
    this.axisColor = PartnerTheme.borderStrong,
    this.fillColor = PartnerTheme.border,
  });

  final Color axisColor;
  final Color fillColor;

  static const _axes = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final grid = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final scale in [0.35, 0.7, 1.0]) {
      final path = Path();
      for (var i = 0; i < _axes; i++) {
        final p = _point(center, radius * scale, i);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < _axes; i++) {
      final p = _point(center, radius, i);
      canvas.drawLine(center, p, axis);
    }
  }

  Offset _point(Offset center, double r, int index) {
    // Top, right, bottom, left.
    final angle = -math.pi / 2 + (index * math.pi / 2);
    return Offset(
      center.dx + r * math.cos(angle),
      center.dy + r * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant PartnerRadarPainter oldDelegate) {
    return oldDelegate.axisColor != axisColor ||
        oldDelegate.fillColor != fillColor;
  }
}
