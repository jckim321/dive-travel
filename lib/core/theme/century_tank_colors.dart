import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';

/// 100·200·…·1000 구간의 탱크 색입니다. 첫 100은 오션, 100 달성 이후부터 금속 톤입니다.
abstract final class CenturyTankColors {
  static const all = <Color>[
    AppTheme.gold,
    Color(0xFFB87333),
    Color(0xFFC0C0C0),
    Color(0xFF7A93A0),
    Color(0xFF0A4A73),
    Color(0xFF1B6F8A),
    Color(0xFF3D5A80),
    Color(0xFF6B5B95),
    Color(0xFFE8D5A3),
    Color(0xFFE5E4E2),
  ];

  static Color ofIndex(int index) => all[index.clamp(0, all.length - 1)];

  static Color ofLogs(int totalLogs) {
    if (totalLogs < DiverStats.masterLogTarget) {
      return AppTheme.oceanLight;
    }
    final band = ((totalLogs - 1) / DiverStats.centuryLogs).floor();
    return ofIndex(band);
  }
}
