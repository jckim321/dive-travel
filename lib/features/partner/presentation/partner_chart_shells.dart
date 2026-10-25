import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';

/// Empty chart frames matching mockup board 25 (no fake data).
class PartnerLineChartShell extends StatelessWidget {
  const PartnerLineChartShell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(painter: _LineShellPainter()),
    );
  }
}

class PartnerSegmentBarShell extends StatelessWidget {
  const PartnerSegmentBarShell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: CustomPaint(painter: _SegmentShellPainter()),
    );
  }
}

class PartnerHorizontalBarsShell extends StatelessWidget {
  const PartnerHorizontalBarsShell({super.key, this.withAvgLine = false});

  final bool withAvgLine;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: withAvgLine ? 110 : 90,
      child: CustomPaint(painter: _HBarShellPainter(withAvgLine: withAvgLine)),
    );
  }
}

class PartnerGaugeShell extends StatelessWidget {
  const PartnerGaugeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(painter: _GaugeShellPainter()),
    );
  }
}

class PartnerRadarShell extends StatelessWidget {
  const PartnerRadarShell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(painter: _RadarShellPainter()),
    );
  }
}

class PartnerGroupedBarsShell extends StatelessWidget {
  const PartnerGroupedBarsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: CustomPaint(painter: _GroupedBarsShellPainter()),
    );
  }
}

class _LineShellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = PartnerTheme.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(8, size.height - 16),
      Offset(size.width - 8, size.height - 16),
      axis,
    );
    final path = Path()
      ..moveTo(12, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.25,
        size.width * 0.55,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.65,
        size.width - 12,
        size.height * 0.35,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = PartnerTheme.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SegmentShellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      PartnerTheme.accent,
      Color(0xFF5B9BD5),
      Color(0xFF7BC67E),
      PartnerTheme.orange,
      PartnerTheme.borderStrong,
    ];
    final widths = [0.28, 0.22, 0.18, 0.16, 0.16];
    var x = 0.0;
    for (var i = 0; i < colors.length; i++) {
      final w = size.width * widths[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, w - 2, size.height),
          const Radius.circular(4),
        ),
        Paint()..color = colors[i].withValues(alpha: 0.35),
      );
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HBarShellPainter extends CustomPainter {
  _HBarShellPainter({required this.withAvgLine});

  final bool withAvgLine;

  @override
  void paint(Canvas canvas, Size size) {
    final widths = [0.72, 0.48, 0.55];
    for (var i = 0; i < widths.length; i++) {
      final top = 12.0 + i * 28;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, size.width * widths[i], 14),
          const Radius.circular(4),
        ),
        Paint()..color = PartnerTheme.accent.withValues(alpha: 0.28),
      );
    }
    if (withAvgLine) {
      final x = size.width * 0.62;
      canvas.drawLine(
        Offset(x, 4),
        Offset(x, size.height - 4),
        Paint()
          ..color = PartnerTheme.orange.withValues(alpha: 0.7)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GaugeShellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.75);
    final r = size.width * 0.28;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = PartnerTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * 0.45,
      false,
      Paint()
        ..color = PartnerTheme.accent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarShellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.42, size.height / 2);
    final r = size.height * 0.38;
    final n = 5;
    for (final scale in [0.4, 0.7, 1.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / n;
        final p = Offset(
          c.dx + math.cos(a) * r * scale,
          c.dy + math.sin(a) * r * scale,
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = PartnerTheme.border
          ..style = PaintingStyle.stroke,
      );
    }
    final fill = Path();
    final scales = [0.55, 0.4, 0.7, 0.35, 0.5];
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      final p = Offset(
        c.dx + math.cos(a) * r * scales[i],
        c.dy + math.sin(a) * r * scales[i],
      );
      if (i == 0) {
        fill.moveTo(p.dx, p.dy);
      } else {
        fill.lineTo(p.dx, p.dy);
      }
    }
    fill.close();
    canvas.drawPath(
      fill,
      Paint()..color = PartnerTheme.accent.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      fill,
      Paint()
        ..color = PartnerTheme.accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GroupedBarsShellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const groups = 3;
    final groupW = size.width / groups;
    for (var g = 0; g < groups; g++) {
      final x0 = groupW * g + 16;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, size.height * 0.45, 18, size.height * 0.4),
          const Radius.circular(3),
        ),
        Paint()..color = PartnerTheme.accent.withValues(alpha: 0.3),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x0 + 22, size.height * 0.28, 18, size.height * 0.57),
          const Radius.circular(3),
        ),
        Paint()..color = PartnerTheme.orange.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
