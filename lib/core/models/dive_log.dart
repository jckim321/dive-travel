enum DiveMix {
  air,
  nitrox32,
  nitrox36,
}

extension DiveMixX on DiveMix {
  String get storageId => switch (this) {
        DiveMix.air => 'air',
        DiveMix.nitrox32 => 'nx32',
        DiveMix.nitrox36 => 'nx36',
      };

  static DiveMix parse(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'nx32' || '32%' || '32% (nitrox 1)' => DiveMix.nitrox32,
      'nx36' || '36%' || '36% (nitrox 2)' => DiveMix.nitrox36,
      _ => DiveMix.air,
    };
  }
}

class DiveProfile {
  const DiveProfile({
    this.maxDepthM,
    this.avgDepthM,
    this.minutes,
    this.startBar,
    this.endBar,
    this.tankLiters,
    this.tempC,
    this.mix = DiveMix.air,
  });

  final double? maxDepthM;
  final double? avgDepthM;
  final int? minutes;
  final int? startBar;
  final int? endBar;
  final double? tankLiters;
  final double? tempC;
  final DiveMix mix;

  double get workingDepthM => avgDepthM ?? maxDepthM ?? 0;

  /// Surface air consumption in L/min. Null when inputs are incomplete.
  double? get sacLitersPerMin {
    final mins = minutes ?? 0;
    final start = startBar ?? 0;
    final end = endBar ?? 0;
    final liters = tankLiters ?? 0;
    final used = start - end;
    if (mins <= 0 || used <= 0 || liters <= 0) {
      return null;
    }
    final ata = (workingDepthM / 10) + 1;
    if (ata <= 0) {
      return null;
    }
    return (used * liters) / mins / ata;
  }

  double get remainingBarRatio {
    final start = (startBar ?? 0).clamp(1, 300);
    final end = (endBar ?? 0).clamp(0, start);
    return end / start;
  }

  static DiveProfile? tryParse(Map<String, dynamic> data) {
    double? n(String key) {
      final value = data[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    int? i(String key) {
      final value = n(key);
      return value?.round();
    }

    final mixRaw = data['o2_mix'] as String?;
    final profile = DiveProfile(
      maxDepthM: n('max_depth_m'),
      avgDepthM: n('avg_depth_m'),
      minutes: i('minutes'),
      startBar: i('start_bar'),
      endBar: i('end_bar'),
      tankLiters: n('tank_liters'),
      tempC: n('temp_c'),
      mix: DiveMixX.parse(mixRaw),
    );
    final hasAny = profile.maxDepthM != null ||
        profile.avgDepthM != null ||
        profile.minutes != null ||
        profile.startBar != null ||
        profile.endBar != null ||
        profile.tankLiters != null ||
        profile.tempC != null ||
        mixRaw != null;
    return hasAny ? profile : null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (maxDepthM != null) 'max_depth_m': maxDepthM,
      if (avgDepthM != null) 'avg_depth_m': avgDepthM,
      if (minutes != null) 'minutes': minutes,
      if (startBar != null) 'start_bar': startBar,
      if (endBar != null) 'end_bar': endBar,
      if (tankLiters != null) 'tank_liters': tankLiters,
      if (tempC != null) 'temp_c': tempC,
      'o2_mix': mix.storageId,
      'self_registered': true,
    };
  }
}

class DiveLog {
  const DiveLog({
    required this.id,
    required this.siteName,
    required this.divedAt,
    required this.memo,
    this.regionId,
    this.photoUrl,
    this.profile,
    this.createdAt,
  });

  final String id;
  final String siteName;
  final DateTime divedAt;
  final String memo;
  final String? regionId;
  final String? photoUrl;
  final DiveProfile? profile;
  final DateTime? createdAt;

  DateTime get writtenAt => createdAt ?? divedAt;
}
