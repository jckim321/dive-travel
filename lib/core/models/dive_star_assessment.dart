import 'package:dive_travel_app/core/data/dive_star.dart';

/// One pass/fail gate on a Dive Star audit form.
class DiveStarFormGate {
  const DiveStarFormGate({
    required this.id,
    required this.title,
    this.criteria = '',
    this.evidence = '',
    this.basis = '',
    this.scope = 'common',
  });

  factory DiveStarFormGate.fromMap(Map<String, dynamic> data) {
    final title = (data['title'] as String? ?? data['name'] as String? ?? '')
        .trim();
    return DiveStarFormGate(
      id: (data['id'] as String? ?? '').trim(),
      title: title,
      criteria: (data['criteria'] as String? ?? '').trim(),
      evidence: (data['evidence'] as String? ?? '').trim(),
      basis: (data['basis'] as String? ?? '').trim(),
      scope: (data['scope'] as String? ?? 'common').trim().isEmpty
          ? 'common'
          : (data['scope'] as String).trim(),
    );
  }

  final String id;
  final String title;
  final String criteria;
  final String evidence;
  final String basis;
  final String scope;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        if (title.isNotEmpty) 'name': title,
        if (criteria.isNotEmpty) 'criteria': criteria,
        if (evidence.isNotEmpty) 'evidence': evidence,
        if (basis.isNotEmpty) 'basis': basis,
        if (scope.isNotEmpty) 'scope': scope,
      };
}

/// One scored area (max points) on a Dive Star audit form.
class DiveStarFormArea {
  const DiveStarFormArea({
    required this.id,
    required this.title,
    required this.maxPoints,
  });

  factory DiveStarFormArea.fromMap(Map<String, dynamic> data) {
    final id = (data['id'] as String? ?? data['code'] as String? ?? '').trim();
    final title =
        (data['title'] as String? ?? data['name'] as String? ?? '').trim();
    final max = (data['max_points'] as num?)?.toInt() ??
        (data['max'] as num?)?.toInt() ??
        0;
    return DiveStarFormArea(id: id, title: title, maxPoints: max);
  }

  final String id;
  final String title;
  final int maxPoints;

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': id,
        'title': title,
        'name': title,
        'max_points': maxPoints,
        'max': maxPoints,
      };
}

/// Line-item score row (v2).
class DiveStarFormItem {
  const DiveStarFormItem({
    required this.id,
    required this.areaId,
    required this.title,
    required this.maxPoints,
    this.criteria = '',
    this.evidence = '',
    this.basis = '',
  });

  factory DiveStarFormItem.fromMap(Map<String, dynamic> data) {
    return DiveStarFormItem(
      id: (data['id'] as String? ?? '').trim(),
      areaId: (data['area'] as String? ?? data['area_id'] as String? ?? '')
          .trim(),
      title: (data['name'] as String? ?? data['title'] as String? ?? '').trim(),
      maxPoints: (data['max'] as num?)?.toInt() ??
          (data['max_points'] as num?)?.toInt() ??
          0,
      criteria: (data['criteria'] as String? ?? '').trim(),
      evidence: (data['evidence'] as String? ?? '').trim(),
      basis: (data['basis'] as String? ?? '').trim(),
    );
  }

  final String id;
  final String areaId;
  final String title;
  final int maxPoints;
  final String criteria;
  final String evidence;
  final String basis;

  Map<String, dynamic> toMap() => {
        'id': id,
        'area': areaId,
        'name': title,
        'max': maxPoints,
        if (criteria.isNotEmpty) 'criteria': criteria,
        if (evidence.isNotEmpty) 'evidence': evidence,
        if (basis.isNotEmpty) 'basis': basis,
      };
}

/// Form-level scoring rules (v2).
class DiveStarFormRules {
  const DiveStarFormRules({
    this.requiredAreaId = 'A',
    this.normalizeNa = true,
    this.countryGatesMax = 5,
  });

  factory DiveStarFormRules.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const DiveStarFormRules();
    }
    final except =
        (data['na_areas_allowed_except'] as String? ?? 'A').trim();
    return DiveStarFormRules(
      requiredAreaId: except.isEmpty ? 'A' : except,
      normalizeNa: data['normalize_na'] != false,
      countryGatesMax: (data['country_gates_max'] as num?)?.toInt() ?? 5,
    );
  }

  final String requiredAreaId;
  final bool normalizeNa;
  final int countryGatesMax;

  Map<String, dynamic> toMap() => {
        'na_areas_allowed_except': requiredAreaId,
        'normalize_na': normalizeNa,
        'country_gates_max': countryGatesMax,
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
    this.star3MysteryVisitsMin = 0,
    this.safetyAreaId = 'safety',
  });

  factory DiveStarFormThresholds.fromMap(
    Map<String, dynamic>? data, {
    String? fallbackSafetyAreaId,
  }) {
    if (data == null) {
      return DiveStarFormThresholds(
        safetyAreaId: fallbackSafetyAreaId ?? 'safety',
      );
    }
    final pctSafety = (data['star2_safety_min_pct'] as num?)?.toDouble();
    final pctArea = (data['star3_all_areas_min_pct'] as num?)?.toDouble();
    final safetyId = (data['safety_area_id'] as String?)?.trim();
    return DiveStarFormThresholds(
      star1MinTotal: (data['star1_min_total'] as num?)?.toInt() ?? 70,
      star2MinTotal: (data['star2_min_total'] as num?)?.toInt() ?? 85,
      star2SafetyMinRatio: pctSafety != null
          ? pctSafety / 100.0
          : (data['star2_safety_min_ratio'] as num?)?.toDouble() ?? 0.9,
      star3MinTotal: (data['star3_min_total'] as num?)?.toInt() ?? 93,
      star3AreaMinRatio: pctArea != null
          ? pctArea / 100.0
          : (data['star3_area_min_ratio'] as num?)?.toDouble() ?? 0.8,
      star3MysteryVisitsMin:
          (data['star3_mystery_visits_min'] as num?)?.toInt() ?? 0,
      safetyAreaId: (safetyId != null && safetyId.isNotEmpty)
          ? safetyId
          : (fallbackSafetyAreaId ?? 'safety'),
    );
  }

  final int star1MinTotal;
  final int star2MinTotal;
  final double star2SafetyMinRatio;
  final int star3MinTotal;
  final double star3AreaMinRatio;
  final int star3MysteryVisitsMin;
  final String safetyAreaId;

  Map<String, dynamic> toMap() => {
        'star1_min_total': star1MinTotal,
        'star2_min_total': star2MinTotal,
        'star2_safety_min_ratio': star2SafetyMinRatio,
        'star2_safety_min_pct': (star2SafetyMinRatio * 100).round(),
        'star3_min_total': star3MinTotal,
        'star3_area_min_ratio': star3AreaMinRatio,
        'star3_all_areas_min_pct': (star3AreaMinRatio * 100).round(),
        'star3_mystery_visits_min': star3MysteryVisitsMin,
        'safety_area_id': safetyAreaId,
      };
}

enum DiveStarFormStatus {
  draft,
  active;

  static DiveStarFormStatus parse(dynamic raw, {required bool activeFlag}) {
    final value = (raw as String?)?.trim().toLowerCase() ?? '';
    if (value == 'draft') {
      return DiveStarFormStatus.draft;
    }
    if (value == 'active') {
      return DiveStarFormStatus.active;
    }
    return activeFlag ? DiveStarFormStatus.active : DiveStarFormStatus.draft;
  }

  String get firestoreValue => name;
}

/// Versioned audit form document (`dive_star_forms/{version}`).
class DiveStarForm {
  const DiveStarForm({
    required this.version,
    required this.gates,
    required this.areas,
    required this.thresholds,
    this.active = true,
    this.status = DiveStarFormStatus.active,
    this.rules = const DiveStarFormRules(requiredAreaId: 'safety'),
    this.items = const [],
  });

  factory DiveStarForm.fromDocument(String id, Map<String, dynamic> data) {
    final gatesRaw = data['gates'] as List<dynamic>? ?? const [];
    final areasRaw = data['areas'] as List<dynamic>? ?? const [];
    final itemsRaw = data['items'] as List<dynamic>? ?? const [];
    final rulesMap = data['rules'] is Map
        ? Map<String, dynamic>.from(data['rules'] as Map)
        : null;
    final rules = rulesMap == null
        ? const DiveStarFormRules(requiredAreaId: 'safety')
        : DiveStarFormRules.fromMap(rulesMap);
    final active = data['active'] != false;
    return DiveStarForm(
      version: (data['version'] as String?)?.trim().isNotEmpty == true
          ? (data['version'] as String).trim()
          : id,
      active: active,
      status: DiveStarFormStatus.parse(data['status'], activeFlag: active),
      rules: rules,
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
      items: [
        for (final item in itemsRaw)
          if (item is Map)
            DiveStarFormItem.fromMap(Map<String, dynamic>.from(item)),
      ],
      thresholds: DiveStarFormThresholds.fromMap(
        data['thresholds'] is Map
            ? Map<String, dynamic>.from(data['thresholds'] as Map)
            : null,
        fallbackSafetyAreaId: rules.requiredAreaId,
      ),
    );
  }

  /// Built-in v1 seed when Firestore has no form yet.
  factory DiveStarForm.v1() {
    return const DiveStarForm(
      version: 'v1',
      active: true,
      status: DiveStarFormStatus.active,
      rules: DiveStarFormRules(requiredAreaId: 'safety'),
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
      thresholds: DiveStarFormThresholds(safetyAreaId: 'safety'),
    );
  }

  final String version;
  final bool active;
  final DiveStarFormStatus status;
  final DiveStarFormRules rules;
  final List<DiveStarFormGate> gates;
  final List<DiveStarFormArea> areas;
  final List<DiveStarFormItem> items;
  final DiveStarFormThresholds thresholds;

  bool get isDraft => status == DiveStarFormStatus.draft || !active;

  Map<String, dynamic> toMap() => {
        'version': version,
        'active': active,
        'status': status.firestoreValue,
        'rules': rules.toMap(),
        'gates': [for (final g in gates) g.toMap()],
        'areas': [for (final a in areas) a.toMap()],
        'items': [for (final i in items) i.toMap()],
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

  List<DiveStarFormItem> itemsForArea(String areaId) => [
        for (final item in items)
          if (item.areaId == areaId) item,
      ];

  /// Display label like `v1` / `v2` (avoids `vv1`).
  static String versionLabel(String formVersion) {
    final v = formVersion.trim();
    if (v.isEmpty) {
      return 'v?';
    }
    if (v.toLowerCase().startsWith('v')) {
      return v;
    }
    return 'v$v';
  }
}

enum DiveStarAssessmentType {
  onsite,
  mystery,
  document;

  static DiveStarAssessmentType parse(dynamic raw) {
    final value = (raw as String?)?.trim().toLowerCase() ?? '';
    if (value == 'mystery') {
      return DiveStarAssessmentType.mystery;
    }
    if (value == 'document' || value == 'docs' || value == 'paper') {
      return DiveStarAssessmentType.document;
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
    this.reason = '',
    this.areaScores = const {},
    this.areaMax = const {},
  });

  final int totalScore;
  final int candidateGrade;
  final bool gatesPassed;
  final String reason;
  final Map<String, int> areaScores;
  final Map<String, int> areaMax;
}

/// Pure scoring from a form version + answers.
abstract final class DiveStarScoring {
  /// v1 path: [scores] are per-area. v2 path: pass [itemScores] (+ optional N/A).
  static DiveStarScoreResult evaluate({
    required DiveStarForm form,
    required Map<String, bool> gates,
    Map<String, int> scores = const {},
    Map<String, int> itemScores = const {},
    Map<String, bool> areaNotApplicable = const {},
    List<bool> countryGatesPassed = const [],
    int mysteryVisits = 0,
  }) {
    final commonPassed = form.gates.every((gate) => gates[gate.id] == true);
    final countryPassed =
        countryGatesPassed.isEmpty || countryGatesPassed.every((p) => p);
    final gatesPassed = commonPassed && countryPassed;

    final areaScores = <String, int>{};
    final areaMax = <String, int>{};
    final appliedAreas = <DiveStarFormArea>[];

    final useItems = form.items.isNotEmpty && itemScores.isNotEmpty;
    if (useItems) {
      for (final area in form.areas) {
        final na = areaNotApplicable[area.id] == true;
        final required = area.id == form.rules.requiredAreaId ||
            area.id == form.thresholds.safetyAreaId;
        if (na && !required) {
          continue;
        }
        appliedAreas.add(area);
        var earned = 0;
        var max = 0;
        for (final item in form.itemsForArea(area.id)) {
          max += item.maxPoints;
          earned += (itemScores[item.id] ?? 0).clamp(0, item.maxPoints);
        }
        if (max <= 0) {
          max = area.maxPoints;
          earned = (scores[area.id] ?? 0).clamp(0, area.maxPoints);
        }
        areaScores[area.id] = earned.clamp(0, max);
        areaMax[area.id] = max;
      }
    } else {
      for (final area in form.areas) {
        final na = areaNotApplicable[area.id] == true;
        final required = area.id == form.rules.requiredAreaId ||
            area.id == form.thresholds.safetyAreaId;
        if (na && !required) {
          continue;
        }
        appliedAreas.add(area);
        final earned = (scores[area.id] ?? 0).clamp(0, area.maxPoints);
        areaScores[area.id] = earned;
        areaMax[area.id] = area.maxPoints;
      }
    }

    var earnedSum = 0;
    var maxSum = 0;
    for (final area in appliedAreas) {
      earnedSum += areaScores[area.id] ?? 0;
      maxSum += areaMax[area.id] ?? area.maxPoints;
    }

    final int totalScore;
    if (form.rules.normalizeNa && maxSum > 0 && appliedAreas.length < form.areas.length) {
      totalScore = ((earnedSum / maxSum) * 100).round().clamp(0, 100);
    } else if (form.rules.normalizeNa && maxSum > 0 && maxSum != 100) {
      // Item totals may not equal 100 if misconfigured; still normalize.
      totalScore = maxSum == 100
          ? earnedSum.clamp(0, 100)
          : ((earnedSum / maxSum) * 100).round().clamp(0, 100);
    } else {
      totalScore = earnedSum.clamp(0, 100);
    }

    // v1: all areas applied, maxSum 100 → raw sum.
    final int displayTotal;
    if (!useItems && areaNotApplicable.isEmpty) {
      displayTotal = earnedSum.clamp(0, 100);
    } else {
      displayTotal = totalScore;
    }

    if (!gatesPassed) {
      return DiveStarScoreResult(
        totalScore: displayTotal,
        candidateGrade: 0,
        gatesPassed: false,
        reason: 'gate_failed',
        areaScores: areaScores,
        areaMax: areaMax,
      );
    }

    final t = form.thresholds;
    final safetyId = form.areaById(t.safetyAreaId)?.id ??
        form.areaById(form.rules.requiredAreaId)?.id ??
        t.safetyAreaId;
    final safetyMax =
        areaMax[safetyId] ?? form.areaById(safetyId)?.maxPoints ?? 0;
    final safetyScore = (areaScores[safetyId] ?? 0).clamp(0, safetyMax);
    final safetyRatio = safetyMax <= 0 ? 1.0 : safetyScore / safetyMax;
    final safetyOk = safetyMax <= 0 || safetyRatio >= t.star2SafetyMinRatio;

    final allAreasOk = appliedAreas.every((area) {
      final max = areaMax[area.id] ?? area.maxPoints;
      if (max <= 0) {
        return true;
      }
      final score = areaScores[area.id] ?? 0;
      return score >= max * t.star3AreaMinRatio;
    });

    final mysteryOk = t.star3MysteryVisitsMin <= 0 ||
        mysteryVisits >= t.star3MysteryVisitsMin;

    var grade = 0;
    var reason = 'below_star1';
    if (displayTotal >= t.star1MinTotal) {
      grade = 1;
      reason = 'star1';
    }
    if (displayTotal >= t.star2MinTotal) {
      if (safetyOk) {
        grade = 2;
        reason = 'star2';
      } else {
        reason =
            'safety_ratio_${(safetyRatio * 100).round()}_need_${(t.star2SafetyMinRatio * 100).round()}';
        if (displayTotal >= t.star1MinTotal) {
          grade = 1;
        }
      }
    }
    if (displayTotal >= t.star3MinTotal) {
      if (allAreasOk && mysteryOk) {
        grade = 3;
        reason = 'star3';
      } else if (!allAreasOk) {
        reason = 'area_ratio_below_star3';
      } else if (!mysteryOk) {
        reason = 'mystery_${mysteryVisits}_need_${t.star3MysteryVisitsMin}';
      }
    }

    return DiveStarScoreResult(
      totalScore: displayTotal,
      candidateGrade: DiveStar.clampGrade(grade),
      gatesPassed: true,
      reason: reason,
      areaScores: areaScores,
      areaMax: areaMax,
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
    return DiveStarAssessment(
      id: id,
      shopId: shopId,
      formVersion: (data['form_version'] as String? ?? '').trim(),
      type: DiveStarAssessmentType.parse(data['type']),
      reviewedAt:
          DiveStar.parseDate(data['reviewed_at']) ?? DateTime.now().toUtc(),
      gates: _boolMap(data['gates']),
      scores: _intMap(data['scores']),
      comments: _stringMap(data['comments']),
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
