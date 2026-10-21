/// Stable Firestore keys for optional guest-review details.
/// Display labels live in l10n (`reviewDetail*`).
abstract final class ReviewDetailOptions {
  static const minWaterTempC = -2;
  static const maxWaterTempC = 40;

  static const diverLevels = <String>[
    'open_water',
    'advanced',
    'rescue_plus',
    'instructor',
    'freediver',
  ];

  static const diveCountBands = <String>[
    'dives_under_50',
    'dives_50_200',
    'dives_200_plus',
  ];

  static const visibility = <String>[
    'vis_poor',
    'vis_ok',
    'vis_good',
    'vis_excellent',
  ];

  static const currents = <String>[
    'current_mild',
    'current_ok',
    'current_strong',
  ];

  static const guideCrowds = <String>[
    'crowd_relaxed',
    'crowd_ok',
    'crowd_busy',
  ];

  static const audiences = <String>[
    'audience_beginner',
    'audience_experienced',
    'audience_couple',
    'audience_family',
    'audience_photo',
    'audience_freediver',
    'audience_tech',
  ];

  static const revisitIntents = <String>[
    'revisit_yes',
    'revisit_no',
    'revisit_unsure',
  ];

  static bool isDiverLevel(String? value) =>
      value != null && diverLevels.contains(value);

  static bool isDiveCountBand(String? value) =>
      value != null && diveCountBands.contains(value);

  static bool isVisibility(String? value) =>
      value != null && visibility.contains(value);

  static bool isCurrent(String? value) =>
      value != null && currents.contains(value);

  static bool isGuideCrowd(String? value) =>
      value != null && guideCrowds.contains(value);

  static bool isAudience(String? value) =>
      value != null && audiences.contains(value);

  static bool isRevisitIntent(String? value) =>
      value != null && revisitIntents.contains(value);

  static bool isWaterTempOk(num? value) {
    if (value == null) {
      return true;
    }
    return value >= minWaterTempC && value <= maxWaterTempC;
  }
}

/// Optional detail payload attached to a guest review write.
class ReviewDetails {
  const ReviewDetails({
    this.diverLevel,
    this.diveCountBand,
    this.visibility,
    this.current,
    this.waterTempC,
    this.guideCrowd,
    this.recommendFor = const [],
    this.revisitIntent,
  });

  final String? diverLevel;
  final String? diveCountBand;
  final String? visibility;
  final String? current;
  final double? waterTempC;
  final String? guideCrowd;
  final List<String> recommendFor;
  final String? revisitIntent;

  bool get isEmpty =>
      (diverLevel == null || diverLevel!.isEmpty) &&
      (diveCountBand == null || diveCountBand!.isEmpty) &&
      (visibility == null || visibility!.isEmpty) &&
      (current == null || current!.isEmpty) &&
      waterTempC == null &&
      (guideCrowd == null || guideCrowd!.isEmpty) &&
      recommendFor.isEmpty &&
      (revisitIntent == null || revisitIntent!.isEmpty);

  /// Fields to merge into a Firestore review document (omit empties).
  Map<String, dynamic> toFirestoreFields() {
    return {
      if (diverLevel != null && diverLevel!.isNotEmpty) 'diver_level': diverLevel,
      if (diveCountBand != null && diveCountBand!.isNotEmpty)
        'dive_count_band': diveCountBand,
      if (visibility != null && visibility!.isNotEmpty) 'visibility': visibility,
      if (current != null && current!.isNotEmpty) 'current': current,
      if (waterTempC != null) 'water_temp_c': waterTempC,
      if (guideCrowd != null && guideCrowd!.isNotEmpty) 'guide_crowd': guideCrowd,
      if (recommendFor.isNotEmpty) 'recommend_for': recommendFor,
      if (revisitIntent != null && revisitIntent!.isNotEmpty)
        'revisit_intent': revisitIntent,
    };
  }

  factory ReviewDetails.fromMap(Map<String, dynamic> data) {
    final rawAudience = data['recommend_for'];
    final audiences = <String>[];
    if (rawAudience is List) {
      for (final item in rawAudience) {
        if (item is String && item.trim().isNotEmpty) {
          audiences.add(item.trim());
        }
      }
    }
    return ReviewDetails(
      diverLevel: (data['diver_level'] as String?)?.trim(),
      diveCountBand: (data['dive_count_band'] as String?)?.trim(),
      visibility: (data['visibility'] as String?)?.trim(),
      current: (data['current'] as String?)?.trim(),
      waterTempC: (data['water_temp_c'] as num?)?.toDouble(),
      guideCrowd: (data['guide_crowd'] as String?)?.trim(),
      recommendFor: audiences,
      revisitIntent: (data['revisit_intent'] as String?)?.trim(),
    );
  }
}
