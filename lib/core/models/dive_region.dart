class DiveRegion {
  const DiveRegion({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.logCount,
    required this.continent,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int logCount;
  final String continent;

  bool get isGolden => logCount >= AppRegionThresholds.goldenLogCount;

  /// 위경도를 지도 위 0~1 비율 좌표로 바꿉니다. 픽셀 하드코딩을 피합니다.
  double get mapX => ((longitude + 180) / 360).clamp(0.04, 0.96);

  double get mapY => ((90 - latitude) / 180).clamp(0.08, 0.92);

  DiveRegion copyWith({
    String? name,
    int? logCount,
  }) {
    return DiveRegion(
      id: id,
      name: name ?? this.name,
      latitude: latitude,
      longitude: longitude,
      logCount: logCount ?? this.logCount,
      continent: continent,
    );
  }
}

abstract final class AppRegionThresholds {
  static const int goldenLogCount = 20;
}

abstract final class ContinentId {
  static const asia = 'asia';
  static const africa = 'africa';
  static const oceania = 'oceania';
  static const americas = 'americas';
  static const europe = 'europe';
  static const polar = 'polar';

  static const all = <String>[
    asia,
    africa,
    oceania,
    americas,
    europe,
    polar,
  ];
}
