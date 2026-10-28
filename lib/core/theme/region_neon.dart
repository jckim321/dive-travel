import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';

/// Teal that steps up with dives in one region. Gold starts at
/// [AppRegionThresholds.goldenLogCount], the same line the home map uses.
const regionNeonTeal = Color(0xFF3EBEBE);
const regionNeonBrightTeal = Color(0xFF7EE8E0);
const regionNeonGold = Color(0xFFC4922A);

enum RegionNeonTier { teal, brightTeal, gold, goldRing, goldGlow }

RegionNeonTier regionNeonTier(int logCount) {
  if (logCount >= AppRegionThresholds.glowLogCount) {
    return RegionNeonTier.goldGlow;
  }
  if (logCount >= AppRegionThresholds.doubleRingLogCount) {
    return RegionNeonTier.goldRing;
  }
  if (logCount >= AppRegionThresholds.goldenLogCount) {
    return RegionNeonTier.gold;
  }
  if (logCount >= AppRegionThresholds.brightTealLogCount) {
    return RegionNeonTier.brightTeal;
  }
  return RegionNeonTier.teal;
}

Color regionNeonColor(int logCount) {
  switch (regionNeonTier(logCount)) {
    case RegionNeonTier.teal:
      return regionNeonTeal;
    case RegionNeonTier.brightTeal:
      return regionNeonBrightTeal;
    case RegionNeonTier.gold:
    case RegionNeonTier.goldRing:
    case RegionNeonTier.goldGlow:
      return regionNeonGold;
  }
}

bool regionNeonHasDoubleRing(int logCount) {
  final tier = regionNeonTier(logCount);
  return tier == RegionNeonTier.goldRing || tier == RegionNeonTier.goldGlow;
}

bool regionNeonHasGlow(int logCount) =>
    regionNeonTier(logCount) == RegionNeonTier.goldGlow;
