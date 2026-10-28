import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';

/// Teal neon that warms to gold as dives in one region reach the map's
/// golden-marker line ([AppRegionThresholds.goldenLogCount]).
const regionNeonTeal = Color(0xFF3EBEBE);
const regionNeonGold = Color(0xFFC4922A);

Color regionNeonColor(int logCount) {
  final t = (logCount / AppRegionThresholds.goldenLogCount).clamp(0.0, 1.0);
  return Color.lerp(regionNeonTeal, regionNeonGold, t)!;
}
