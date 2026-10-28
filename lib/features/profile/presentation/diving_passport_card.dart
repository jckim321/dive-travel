import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/region_neon.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// How many unvisited catalog regions to hint at. Capped so the cover
/// stays a passport, not a full atlas.
int divingPassportMysteryCount(List<DiveRegion> regions) {
  if (regions.isEmpty) {
    return 0;
  }
  final seen = {for (final region in regions) region.id};
  var missing = 0;
  for (final known in RegionCatalog.known) {
    if (!seen.contains(known.id)) {
      missing++;
    }
  }
  if (missing > 3) {
    return 3;
  }
  return missing;
}

class DivingPassportCard extends StatelessWidget {
  const DivingPassportCard({super.key, required this.regions});

  final List<DiveRegion> regions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mysteries = divingPassportMysteryCount(regions);
    return DecoratedBox(
      key: const Key('profile-diving-passport'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16344A),
            AppTheme.navy,
            Color(0xFF071421),
          ],
        ),
        border: Border.all(color: AppTheme.gold, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x590B1F33),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profileDivingPassportTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.profileDivingPassportRegions(regions.length),
                  key: const Key('profile-passport-region-count'),
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (regions.isEmpty)
              Text(
                l10n.homeMapEmptyPrompt,
                key: const Key('profile-passport-empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.goldSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final region in regions)
                    _RegionStamp(region: region),
                  for (var i = 0; i < mysteries; i++)
                    _MysteryStamp(index: i),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RegionStamp extends StatelessWidget {
  const _RegionStamp({required this.region});

  final DiveRegion region;

  @override
  Widget build(BuildContext context) {
    final ink = regionNeonColor(region.logCount);
    return SizedBox(
      width: 76,
      height: 76,
      child: DecoratedBox(
        key: Key('profile-passport-stamp-${region.id}'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ink.withValues(alpha: 0.16),
          border: Border.all(color: ink, width: 2.4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                region.name,
                key: Key('profile-passport-name-${region.id}'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${region.logCount}',
                key: Key('profile-passport-count-${region.id}'),
                style: TextStyle(
                  color: ink,
                  fontSize: 13,
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

class _MysteryStamp extends StatelessWidget {
  const _MysteryStamp({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('profile-passport-mystery-$index'),
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: const _DashedCirclePainter(),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              color: AppTheme.goldSoft,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dash = 4.0;
    const gap = 3.0;
    final radius = size.shortestSide / 2 - 2;
    final center = Offset(size.width / 2, size.height / 2);
    final step = dash + gap;
    final turns = (2 * math.pi * radius / step).floor();
    for (var i = 0; i < turns; i++) {
      final start = i * step / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dash / radius,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
