import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/bilingual_rotator.dart';
import 'package:dive_travel_app/core/widgets/pulsing_marker.dart';
import 'package:dive_travel_app/core/widgets/world_outline_painter.dart';

/// TV 패널 안에 수중 배경 + 세계 윤곽 + 로그 지역 점광을 겹칩니다.
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

  static const _aspect = 4 / 3;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.oceanDeep,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFF1A5A7A), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x44C4A35A), width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: AspectRatio(
              aspectRatio: _aspect,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -0.18),
                            radius: 1.2,
                            colors: [
                              AppTheme.oceanLight,
                              AppTheme.ocean,
                              AppTheme.oceanDeep,
                            ],
                            stops: [0.0, 0.46, 1.0],
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 0.22,
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.15),
                          cacheWidth: 720,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      const ColoredBox(color: Color(0x22052A4A)),
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: WorldOutlinePainter(
                            fill: const Color(0x28E8F4FA),
                            stroke: const Color(0xBBD7EEF8),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.12,
                              colors: [
                                Colors.transparent,
                                AppTheme.oceanDeep.withValues(alpha: 0.42),
                              ],
                            ),
                          ),
                        ),
                      ),
                      for (final region in regions)
                        _marker(region, size),
                      if (regions.isEmpty)
                        const Align(
                          alignment: Alignment(0, 0.18),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              '로그를 추가하면 여기에 불이 켜집니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                                Color(0xCC052A4A),
                              ],
                            ),
                          ),
                          child: SizedBox(height: 88, width: double.infinity),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
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
  const _MapCaption({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
