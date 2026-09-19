import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/widgets/world_land_rings.dart';

Offset projectLonLat(double longitude, double latitude, Size size) {
  return Offset(
    ((longitude + 180) / 360) * size.width,
    ((90 - latitude) / 180) * size.height,
  );
}

class WorldOutlinePainter extends CustomPainter {
  const WorldOutlinePainter({
    required this.fill,
    required this.stroke,
  });

  final Color fill;
  final Color stroke;

  static Size? _cachedSize;
  static Path? _cachedPath;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeJoin = StrokeJoin.round;
    final path = _pathFor(size);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Path _pathFor(Size size) {
    if (_cachedPath != null && _cachedSize == size) {
      return _cachedPath!;
    }
    final path = Path();
    for (final ring in worldLandRings) {
      if (ring.length < 3) {
        continue;
      }
      final first = projectLonLat(ring.first[0], ring.first[1], size);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < ring.length; i++) {
        final point = projectLonLat(ring[i][0], ring[i][1], size);
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    _cachedSize = size;
    _cachedPath = path;
    return path;
  }

  @override
  bool shouldRepaint(covariant WorldOutlinePainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.stroke != stroke;
  }
}
