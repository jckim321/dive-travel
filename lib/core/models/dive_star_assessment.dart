import 'package:dive_travel_app/core/data/dive_star.dart';

/// One pass/fail gate on a Dive Star audit form.
class DiveStarFormGate {
  const DiveStarFormGate({required this.id, required this.title});

  factory DiveStarFormGate.fromMap(Map<String, dynamic> data) {
    return DiveStarFormGate(
      id: (data['id'] as String? ?? '').trim(),
      title: (data['title'] as String? ?? '').trim(),
    );
  }

  final String id;
  final String title;

  Map<String, dynamic> toMap() => {'id': id, 'title': title};
}

/// One scored area (max points) on a Dive Star audit form.
class DiveStarFormArea {
  const DiveStarFormArea({
    required this.id,
    required this.title,
    required this.maxPoints,
  });

  factory DiveStarFormArea.fromMap(Map<String, dynamic> data) {
    return DiveStarFormArea(
      id: (data['id'] as String? ?? '').trim(),
      title: (data['title'] as String? ?? '').trim(),
      maxPoints: (data['max_points'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;
  final int maxPoints;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'max_points': maxPoints,
      };
}

/// Grade cutoffs stored on the form so admins can change them later.
class DiveStarFormThresholds {
  const DiveStarFormThresholds({
    this.star1MinTotal = 70,
    this.star2MinTotal = 85,
    this.star2SafetyMinRatio = 0.9,
    this.star3MinTotal = 93,
    this.star3AreaMinRatio = 0.8,
    this.safetyAreaId = 'safety',
  });

  factory DiveStarFormThresholds.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const DiveStarFormThresholds();
    }
    return DiveStarFormThresholds(
      star1MinTotal: (data['star1_min_total'] as num?)?.toInt() ?? 70,
      star2MinTotal: (data['star2_min_total'] as num?)?.toInt() ?? 85,
      star2SafetyMinRatio:
          (data['star2_safety_min_ratio'] as num?)?.toDouble() ?? 0.9,
      star3MinTotal: (data['star3_min_total'] as num?)?.toInt() ?? 93,
      star3AreaMinRatio:
          (data['star3_area_min_ratio'] as num?)?.toDouble() ?? 0.8,
      safetyAreaId: (data['safety_area_id'] as String?)?.trim().isNotEmpty == true
          ? (data['safety_area_id'] as String).trim()
          : 'safety',
    );
  }

  final int star1MinTotal;
  final int star2MinTotal;
  final double star2SafetyMinRatio;
  final int star3MinTotal;
  final double star3AreaMinRatio;
  final String safetyAreaId;

  Map<String, dynamic> toMap() => {
        'star1_min_total': star1MinTotal,
        'star2_min_total': star2MinTotal,
        'star2_safety_min_ratio': star2SafetyMinRatio,
        'star3_min_total': star3MinTotal,
        'star3_area_min_ratio': star3AreaMinRatio,
        'safety_area_id': safetyAreaId,
      };
}

/// Versioned audit form document (`dive_star_forms/{version}`).
class DiveStarForm {
  const DiveStarForm({
    required this.version,
    required this.gates,
    required this.areas,
    required this.thresholds,
    this.active = true,
  });

  factory DiveStarForm.fromDocument(String id, Map<String, dynamic> data) {
    final gatesRaw = data['gates'] as List<dynamic>? ?? const [];
    final areasRaw = data['areas'] as List<dynamic>? ?? const [];
    return DiveStarForm(
      version: (data['version'] as String?)?.trim().isNotEmpty == true
          ? (data['version'] as String).trim()
          : id,
      active: data['active'] != false,
      gates: [
        for (final item in gatesRaw)
          if (item is Map)
            DiveStarFormGate.fromMap(Map<String, dynamic>.from(item)),
      ],
      areas: [
        for (final item in areasRaw)
          if (item is Map)
            DiveStarFormArea.fromMap(Map<String, dynamic>.from(item)),
      ],
      thresholds: DiveStarFormThresholds.fromMap(
        data['thresholds'] is Map
            ? Map<String, dynamic>.from(data['thresholds'] as Map)
            : null,
      ),
    );
  }

  /// Built-in v1 seed when Firestore has no form yet.
  factory DiveStarForm.v1() {
    return const DiveStarForm(
      version: 'v1',
      active: true,
      gates: [
        DiveStarFormGate(
          id: 'business_license',
          title: '사업자 등록·영업 허가',
        ),
        DiveStarFormGate(
          id: 'instructor_cert',
          title: '인정 단체 소속 강사·가이드 자격 확인',
        ),
        DiveStarFormGate(
          id: 'liability_insurance',
          title: '배상책임보험 가입',
        ),
        DiveStarFormGate(
          id: 'emergency_kits',
          title: '산소 키트·응급처치 키트·AED 보유',
        ),
        DiveStarFormGate(
          id: 'eap_chamber',
          title: '비상대응계획(EAP)과 가까운 챔버·병원 정보 보유',
        ),
        DiveStarFormGate(
          id: 'air_quality',
          title: '컴프레서 공기질 검사 기록(최근 6개월)',
        ),
        DiveStarFormGate(
          id: 'tank_inspection',
          title: '탱크 육안·수압검사 기록',
        ),
      ],
      areas: [
        DiveStarFormArea(id: 'safety', title: '안전·리스크 관리', maxPoints: 25),
        DiveStarFormArea(id: 'service', title: '다이빙 서비스', maxPoints: 20),
        DiveStarFormArea(id: 'equipment', title: '장비·시설', maxPoints: 15),
        DiveStarFormArea(id: 'hospitality', title: '숙박·식사·편의', maxPoints: 15),
        DiveStarFormArea(id: 'environment', title: '환경·지역 책임', maxPoints: 10),
        DiveStarFormArea(id: 'experience', title: '고객 경험·소통', maxPoints: 10),
        DiveStarFormArea(id: 'reviews', title: '일반 후기 지표', maxPoints: 5),
      ],
      thresholds: DiveStarFormThresholds(),
    );
  }

  final String version;
  final bool active;
  final List<DiveStarFormGate> gates;
  final List<DiveStarFormArea> areas;
  final DiveStarFormThresholds thresholds;

  Map<String, dynamic> toMap() => {
        'version': version,
        'active': active,
        'gates': [for (final g in gates) g.toMap()],
        'areas': [for (final a in areas) a.toMap()],
        'thresholds': thresholds.toMap(),
      };

  DiveStarFormArea? areaById(String id) {
    for (final area in areas) {
      if (area.id == id) {
        return area;
      }
    }
    return null;
  }
}

enum DiveStarAssessmentType {
  onsite,
  mystery;

  static DiveStarAssessmentType parse(dynamic raw) {
    final value = (raw as String?)?.trim().toLowerCase() ?? '';
    if (value == 'mystery') {
      return DiveStarAssessmentType.mystery;
    }
    return DiveStarAssessmentType.onsite;
  }

  String get firestoreValue => name;
}

/// Computed totals for one filled assessment (does not write to the shop).
class DiveStarScoreResult {
  const DiveStarScoreResult({
    required this.totalScore,
    required this.candidateGrade,
    required this.gatesPassed,
  });

  final int totalScore;
  final int candidateGrade;
  final bool gatesPassed;
}

/// Pure scoring from a form version + answers.
abstract final class DiveStarScoring {
  static DiveStarScoreResult evaluate({
    required DiveStarForm form,
    required Map<String, bool> gates,
    required Map<String, int> scores,
  }) {
    final gatesPassed = form.gates.every((gate) => gates[gate.id] == true);

    var total = 0;
    for (final area in form.areas) {
      final raw = scores[area.id] ?? 0;
      total += raw.clamp(0, area.maxPoints);
    }

    if (!gatesPassed) {
      return DiveStarScoreResult(
        totalScore: total,
        candidateGrade: 0,
        gatesPassed: false,
      );
    }

    final t = form.thresholds;
    final safety = form.areaById(t.safetyAreaId);
    final safetyScore = (scores[t.safetyAreaId] ?? 0).clamp(
      0,
      safety?.maxPoints ?? 0,
    );
    final safetyOk = safety == null ||
        safety.maxPoints <= 0 ||
        safetyScore >= safety.maxPoints * t.star2SafetyMinRatio;

    final allAreasOk = form.areas.every((area) {
      if (area.maxPoints <= 0) {
        return true;
      }
      final score = (scores[area.id] ?? 0).clamp(0, area.maxPoints);
      return score >= area.maxPoints * t.star3AreaMinRatio;
    });

    var grade = 0;
    if (total >= t.star1MinTotal) {
      grade = 1;
    }
    if (total >= t.star2MinTotal && safetyOk) {
      grade = 2;
    }
    if (total >= t.star3MinTotal && allAreasOk) {
      grade = 3;
    }

    return DiveStarScoreResult(
      totalScore: total,
      candidateGrade: DiveStar.clampGrade(grade),
      gatesPassed: true,
    );
  }
}

/// One saved audit for a shop (`shops/{id}/dive_star_assessments/{id}`).
class DiveStarAssessment {
  const DiveStarAssessment({
    required this.id,
    required this.shopId,
    required this.formVersion,
    required this.type,
    required this.reviewedAt,
    required this.gates,
    required this.scores,
    required this.comments,
    required this.totalScore,
    required this.candidateGrade,
    required this.gatesPassed,
    this.confirmed = false,
    this.confirmedAt,
  });

  factory DiveStarAssessment.fromDocument(
    String id,
    String shopId,
    Map<String, dynamic> data,
  ) {
    final gatesRaw = data['gates'];
    final scoresRaw = data['scores'];
    final commentsRaw = data['comments'];
    return DiveStarAssessment(
      id: id,
      shopId: shopId,
      formVersion: (data['form_version'] as String? ?? '').trim(),
      type: DiveStarAssessmentType.parse(data['type']),
      reviewedAt: DiveStar.parseDate(data['reviewed_at']) ?? DateTime.now().toUtc(),
      gates: _boolMap(gatesRaw),
      scores: _intMap(scoresRaw),
      comments: _stringMap(commentsRaw),
      totalScore: (data['total_score'] as num?)?.toInt() ?? 0,
      candidateGrade: DiveStar.clampGrade(
        (data['candidate_grade'] as num?)?.toInt() ?? 0,
      ),
      gatesPassed: data['gates_passed'] == true,
      confirmed: data['confirmed'] == true,
      confirmedAt: DiveStar.parseDate(data['confirmed_at']),
    );
  }

  final String id;
  final String shopId;
  final String formVersion;
  final DiveStarAssessmentType type;
  final DateTime reviewedAt;
  final Map<String, bool> gates;
  final Map<String, int> scores;
  final Map<String, String> comments;
  final int totalScore;
  final int candidateGrade;
  final bool gatesPassed;
  final bool confirmed;
  final DateTime? confirmedAt;

  Map<String, dynamic> toMap() => {
        'form_version': formVersion,
        'type': type.firestoreValue,
        'reviewed_at': reviewedAt.toUtc().toIso8601String(),
        'gates': gates,
        'scores': scores,
        'comments': comments,
        'total_score': totalScore,
        'candidate_grade': candidateGrade,
        'gates_passed': gatesPassed,
        'confirmed': confirmed,
        if (confirmedAt != null)
          'confirmed_at': confirmedAt!.toUtc().toIso8601String(),
      };

  DiveStarAssessment copyWith({
    bool? confirmed,
    DateTime? confirmedAt,
  }) {
    return DiveStarAssessment(
      id: id,
      shopId: shopId,
      formVersion: formVersion,
      type: type,
      reviewedAt: reviewedAt,
      gates: gates,
      scores: scores,
      comments: comments,
      totalScore: totalScore,
      candidateGrade: candidateGrade,
      gatesPassed: gatesPassed,
      confirmed: confirmed ?? this.confirmed,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  static Map<String, bool> _boolMap(dynamic raw) {
    if (raw is! Map) {
      return {};
    }
    return {
      for (final entry in raw.entries)
        if (entry.key is String) entry.key as String: entry.value == true,
    };
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) {
      return {};
    }
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num).toInt(),
    };
  }

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) {
      return {};
    }
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }
}
