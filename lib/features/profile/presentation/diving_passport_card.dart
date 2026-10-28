import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/region_neon.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const divingPassportPreviewLimit = 12;

/// How many unvisited catalog regions to hint at. Hidden once the cover
/// already holds a full row of stamps.
int divingPassportMysteryCount(List<DiveRegion> regions) {
  if (regions.isEmpty || regions.length >= divingPassportPreviewLimit) {
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

/// Highest dive counts first. Names break ties so the order stays stable.
List<DiveRegion> divingPassportStamps(List<DiveRegion> regions) {
  final sorted = [...regions];
  sorted.sort((a, b) {
    final byCount = b.logCount.compareTo(a.logCount);
    if (byCount != 0) {
      return byCount;
    }
    return a.name.compareTo(b.name);
  });
  return sorted;
}

/// 1000회부터는 도장 안에 들어가게 한 자리로 줄입니다. 1200 → 1.2k, 1000 → 1k.
String divingPassportCountLabel(int count) {
  if (count < 1000) {
    return '$count';
  }
  var text = (count / 1000).toStringAsFixed(1);
  if (text.endsWith('.0')) {
    text = text.substring(0, text.length - 2);
  }
  return '${text}k';
}

String divingPassportDiveTotal(int count) {
  return NumberFormat('#,###', 'en_US').format(count);
}

class DivingPassportCard extends StatefulWidget {
  const DivingPassportCard({super.key, required this.regions});

  final List<DiveRegion> regions;

  @override
  State<DivingPassportCard> createState() => _DivingPassportCardState();
}

class _DivingPassportCardState extends State<DivingPassportCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final regions = widget.regions;
    final sorted = divingPassportStamps(regions);
    final showToggle = sorted.length > divingPassportPreviewLimit;
    final visible = _expanded || !showToggle
        ? sorted
        : sorted.sublist(0, divingPassportPreviewLimit);
    final mysteries = divingPassportMysteryCount(regions);
    final totalDives = regions.fold<int>(
      0,
      (sum, region) => sum + region.logCount,
    );
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.profileDivingPassportDives(
                        divingPassportDiveTotal(totalDives),
                      ),
                      key: const Key('profile-passport-dive-total'),
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
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
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final region in visible)
                    _RegionStamp(region: region),
                  for (var i = 0; i < mysteries; i++)
                    _MysteryStamp(index: i),
                ],
              ),
              if (showToggle)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    key: const Key('profile-passport-show-all'),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? l10n.profileDivingPassportShowLess
                          : l10n.profileDivingPassportShowAll(regions.length),
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
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
    final doubleRing = regionNeonHasDoubleRing(region.logCount);
    final glow = regionNeonHasGlow(region.logCount);
    final face = DecoratedBox(
      key: Key('profile-passport-stamp-${region.id}'),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ink.withValues(alpha: 0.16),
        border: Border.all(color: ink, width: doubleRing ? 2.2 : 2.4),
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
              divingPassportCountLabel(region.logCount),
              key: Key('profile-passport-count-${region.id}'),
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
    return SizedBox(
      width: 76,
      height: 76,
      child: DecoratedBox(
        key: Key('profile-passport-tier-${region.id}'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: doubleRing ? Border.all(color: ink, width: 1.4) : null,
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: ink.withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(doubleRing ? 3 : 0),
          child: face,
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
