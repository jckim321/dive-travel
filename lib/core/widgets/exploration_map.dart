import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/bilingual_rotator.dart';
import 'package:dive_travel_app/core/widgets/pulsing_marker.dart';
import 'package:dive_travel_app/core/widgets/world_outline_painter.dart';

const _kMapNumberGold = Color(0xFFF0D48A);

/// 낮 바다 위 세계 윤곽. 윤곽 좌표는 world_land_rings를 그대로 씁니다.
class ExplorationMap extends StatelessWidget {
  const ExplorationMap({
    super.key,
    required this.regions,
    required this.titleEnglish,
    required this.titleLocalized,
    required this.exploredEnglish,
    required this.exploredLocalized,
  });

  final List<DiveRegion> regions;
  final String titleEnglish;
  final String titleLocalized;
  final String exploredEnglish;
  final String exploredLocalized;

  /// Wider than the old 1.9 panel so the shelves below appear sooner.
  static const _aspect = 2.6;

  static const _sandFill = Color(0xFFF6EBD4);
  static const _sandStroke = Color(0xD9FFFFFF);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('exploration-map-porthole'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8E7B0),
            Color(0xFFD4AF57),
            Color(0xFF8C6424),
            Color(0xFFE8D48A),
          ],
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFF3A2A12), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: AspectRatio(
              aspectRatio: _aspect,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF8FD6F5),
                              Color(0xFF3EBEBE),
                              Color(0xFF1A6FBE),
                            ],
                            stops: [0.0, 0.48, 1.0],
                          ),
                        ),
                      ),
                      const CustomPaint(
                        key: Key('exploration-map-sun'),
                        painter: _SunGlowPainter(),
                      ),
                      const RepaintBoundary(
                        child: CustomPaint(
                          painter: WorldOutlinePainter(
                            fill: _sandFill,
                            stroke: _sandStroke,
                          ),
                        ),
                      ),
                      for (final region in regions) _marker(region, size),
                      if (regions.isEmpty)
                        const Align(
                          alignment: Alignment(0, -0.12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              '로그를 추가하면 여기에 불이 켜집니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF16324A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00052A4A),
                                Color(0x99052A4A),
                                Color(0xD9052A4A),
                              ],
                              stops: [0.0, 0.45, 1.0],
                            ),
                          ),
                          child: SizedBox(height: 78, width: double.infinity),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 8,
                        child: BilingualRotator(
                          english: _MapCaption(
                            title: titleEnglish,
                            subtitle: exploredEnglish,
                          ),
                          localized: _MapCaption(
                            title: titleLocalized,
                            subtitle: exploredLocalized,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 4,
                        top: 0,
                        child: IgnorePointer(
                          child: CustomPaint(
                            key: Key('exploration-map-diver'),
                            size: Size(42, 30),
                            painter: _PeekingDiverPainter(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _marker(DiveRegion region, Size size) {
    final point = projectLonLat(region.longitude, region.latitude, size);
    final diameter = region.isGolden ? 16.0 : 12.0;
    return Positioned(
      left: point.dx - diameter / 2,
      top: point.dy - diameter / 2,
      child: PulsingMarker(
        color: region.isGolden
            ? const Color(0xFFC4A35A)
            : const Color(0xFFD7F3FF),
        isGolden: region.isGolden,
        tooltip: region.isGolden
            ? '단골 우수 지역: ${region.name} (${region.logCount}로그)'
            : '${region.name} (${region.logCount}로그)',
      ),
    );
  }
}

class _MapCaption extends StatelessWidget {
  const _MapCaption({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kMapNumberGold,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

/// Soft daylight from the upper right: a glow, a disk, and a few rays.
class _SunGlowPainter extends CustomPainter {
  const _SunGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width - 26, 18);
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x99FFF6C8), Color(0x33FFE08A), Color(0x00FFF6C8)],
      ).createShader(Rect.fromCircle(center: origin, radius: 78));
    canvas.drawCircle(origin, 78, glow);

    final ray = Paint()
      ..color = const Color(0x2EFFF3C4)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final angle = 0.4 + i * 0.34;
      final length = i.isEven ? 108.0 : 72.0;
      canvas.drawLine(
        origin,
        origin + Offset(-math.cos(angle) * length, math.sin(angle) * length),
        ray,
      );
    }
    canvas.drawCircle(origin, 12, Paint()..color = const Color(0xFFFFF6D0));
    canvas.drawCircle(origin, 7, Paint()..color = const Color(0xFFFFE08A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helmet and shoulders sitting on the top rim, clear of the caption.
class _PeekingDiverPainter extends CustomPainter {
  const _PeekingDiverPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final helmet = Offset(size.width / 2, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 16, size.width - 8, 14),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1E4E6E),
    );
    canvas.drawCircle(helmet, 11, Paint()..color = const Color(0xFFF7F1E4));
    canvas.drawCircle(
      helmet,
      11,
      Paint()
        ..color = const Color(0xFFC4A35A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawOval(
      Rect.fromCenter(center: helmet.translate(0, 1), width: 14, height: 8),
      Paint()..color = const Color(0xFF16324A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
