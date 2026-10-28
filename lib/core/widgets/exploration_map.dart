import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/region_neon.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';
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

  /// About 215px tall on a phone, so the ocean sits under the shorter hero.
  static const _aspect = 1.75;

  static const _sandFill = Color(0xFFF6EBD4);
  static const _sandStroke = Color(0xD9FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
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
                      const RepaintBoundary(
                        child: CustomPaint(
                          painter: WorldOutlinePainter(
                            fill: _sandFill,
                            stroke: _sandStroke,
                          ),
                        ),
                      ),
                      const CustomPaint(
                        key: Key('exploration-map-sun'),
                        painter: ExplorationSunPainter(),
                      ),
                      for (final region in regions) _marker(region, size),
                      if (regions.isEmpty)
                        Align(
                          alignment: const Alignment(0, -0.12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              AppLocalizations.of(context).homeMapEmptyPrompt,
                              key: const Key('exploration-map-empty'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
        ),
        const Positioned(
          left: 2,
          top: 0,
          child: IgnorePointer(
            child: CustomPaint(
              key: Key('exploration-map-diver'),
              size: Size(56, 58),
              painter: _PeekingDiverPainter(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _marker(DiveRegion region, Size size) {
    final point = projectLonLat(region.longitude, region.latitude, size);
    final diameter = region.isGolden ? 22.0 : 16.0;
    return Positioned(
      left: point.dx - diameter / 2,
      top: point.dy - diameter / 2,
      child: PulsingMarker(
        color: regionNeonColor(region.logCount),
        isGolden: region.isGolden,
        doubleRing: regionNeonHasDoubleRing(region.logCount),
        softGlow: regionNeonHasGlow(region.logCount),
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

/// Daylight in the upper-right corner: a disk and wedges that thin out
/// and fade to nothing across the top half of the ocean.
class ExplorationSunPainter extends CustomPainter {
  const ExplorationSunPainter();

  static const rayCount = 7;

  /// Opacity beside the disk. The tip is [rayTipOpacity].
  static const rayOpacity = 0.4;
  static const rayTipOpacity = 0.0;

  /// Half-width of a wedge at the sun. The far end is a point.
  static const rayBaseHalfWidth = 4.0;
  static const diskRadius = 22.0;

  static Offset originFor(Size size) => Offset(size.width - 26, 18);

  /// Ends of the fan. The steepest ray reaches the midline of the ocean.
  static List<Offset> rayEnds(Size size) {
    final origin = originFor(size);
    final ends = <Offset>[];
    for (var i = 0; i < rayCount; i++) {
      final t = i / (rayCount - 1);
      final angle = 0.16 + t * 1.28;
      final midY = size.height * 0.52;
      final needed = (midY - origin.dy) / math.sin(angle);
      final length = needed.clamp(size.shortestSide * 0.42, size.width * 0.96);
      ends.add(
        origin + Offset(-math.cos(angle) * length, math.sin(angle) * length),
      );
    }
    return ends;
  }

  /// Base, tip, base. The tip is a single point so the wedge fades out.
  static List<Offset> rayVertices(Offset origin, Offset end) {
    final delta = end - origin;
    final length = delta.distance;
    if (length == 0) {
      return [origin, end, origin];
    }
    final perp = Offset(-delta.dy / length, delta.dx / length);
    return [
      origin + perp * rayBaseHalfWidth,
      end,
      origin - perp * rayBaseHalfWidth,
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = originFor(size);
    final glowRadius = size.shortestSide * 0.72;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x99FFF6C8),
          Color(0x44FFE08A),
          Color(0x00FFF6C8),
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: glowRadius));
    canvas.drawCircle(origin, glowRadius, glow);

    for (final end in rayEnds(size)) {
      final vertices = rayVertices(origin, end);
      final wedge = Path()
        ..moveTo(vertices[0].dx, vertices[0].dy)
        ..lineTo(vertices[1].dx, vertices[1].dy)
        ..lineTo(vertices[2].dx, vertices[2].dy)
        ..close();
      final delta = end - origin;
      final length = delta.distance;
      final fadeStart = length == 0
          ? origin
          : origin + delta / length * diskRadius;
      canvas.drawPath(
        wedge,
        Paint()
          ..shader = ui.Gradient.linear(
            fadeStart,
            end,
            [
              const Color(0xFFFFF6D0).withValues(alpha: rayOpacity),
              const Color(0xFFFFF6D0).withValues(alpha: rayTipOpacity),
            ],
          ),
      );
    }
    canvas.drawCircle(
      origin,
      diskRadius,
      Paint()..color = const Color(0xFFFFF8DC),
    );
    canvas.drawCircle(
      origin,
      diskRadius * 0.58,
      Paint()..color = const Color(0xFFFFE08A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mask and face leaning over the top-left brass rim.
class _PeekingDiverPainter extends CustomPainter {
  const _PeekingDiverPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final head = Offset(size.width * 0.54, 20);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 36, size.width - 14, 22),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0xFF14344C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14, 34, size.width - 28, 8),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1E5674),
    );

    canvas.drawCircle(head, 17, Paint()..color = const Color(0xFF102838));
    canvas.drawCircle(
      head.translate(0, 1.5),
      13.5,
      Paint()..color = const Color(0xFFF2CDB4),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: head.translate(0, 0.4),
          width: 24,
          height: 13,
        ),
        const Radius.circular(6.5),
      ),
      Paint()..color = const Color(0xFF0C1C2A),
    );
    final glass = Paint()..color = const Color(0xFFB7E4F2);
    final leftLens = head.translate(-5.2, 0.2);
    final rightLens = head.translate(5.2, 0.2);
    canvas.drawOval(
      Rect.fromCenter(center: leftLens, width: 9, height: 8),
      glass,
    );
    canvas.drawOval(
      Rect.fromCenter(center: rightLens, width: 9, height: 8),
      glass,
    );
    final eye = Paint()..color = const Color(0xFF1A2834);
    canvas.drawCircle(leftLens.translate(0, 0.4), 1.3, eye);
    canvas.drawCircle(rightLens.translate(0, 0.4), 1.3, eye);
    final glint = Paint()..color = const Color(0xCCFFFFFF);
    canvas.drawCircle(leftLens.translate(-1.6, -1.4), 1.1, glint);
    canvas.drawCircle(rightLens.translate(-1.6, -1.4), 1.1, glint);

    final smile = Path()
      ..moveTo(head.dx - 3.2, head.dy + 7.2)
      ..quadraticBezierTo(
        head.dx,
        head.dy + 10.2,
        head.dx + 3.2,
        head.dy + 7.2,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF8C5344)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
