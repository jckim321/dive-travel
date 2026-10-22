import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star_form_import.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';

DiveStarForm _miniV2({int mysteryMin = 2}) {
  return DiveStarForm(
    version: 'v2',
    active: false,
    status: DiveStarFormStatus.draft,
    rules: const DiveStarFormRules(requiredAreaId: 'A', normalizeNa: true),
    gates: const [DiveStarFormGate(id: 'G1', title: 'gate')],
    areas: const [
      DiveStarFormArea(id: 'A', title: 'Safety', maxPoints: 50),
      DiveStarFormArea(id: 'B', title: 'Service', maxPoints: 50),
    ],
    items: const [
      DiveStarFormItem(id: 'S1', areaId: 'A', title: 's1', maxPoints: 50),
      DiveStarFormItem(id: 'D1', areaId: 'B', title: 'd1', maxPoints: 50),
    ],
    thresholds: DiveStarFormThresholds(
      star1MinTotal: 70,
      star2MinTotal: 85,
      star2SafetyMinRatio: 0.9,
      star3MinTotal: 93,
      star3AreaMinRatio: 0.8,
      star3MysteryVisitsMin: mysteryMin,
      safetyAreaId: 'A',
    ),
  );
}

void main() {
  test('form version label avoids vv1', () {
    expect(DiveStarForm.versionLabel('v1'), 'v1');
    expect(DiveStarForm.versionLabel('v2'), 'v2');
    expect(DiveStarForm.versionLabel('2'), 'v2');
  });

  test('69점은 1스타 미만, 70점은 1스타', () {
    final form = _miniV2();
    final gates = {'G1': true};
    final low = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: {'S1': 35, 'D1': 34}, // 69
    );
    expect(low.totalScore, 69);
    expect(low.candidateGrade, 0);

    final ok = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: {'S1': 35, 'D1': 35}, // 70
    );
    expect(ok.totalScore, 70);
    expect(ok.candidateGrade, 1);
  });

  test('84점은 2스타 미만, 85점+안전 90%면 2스타', () {
    final form = _miniV2();
    final gates = {'G1': true};
    // Safety 45/50 = 90%, total 84
    final low = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: {'S1': 45, 'D1': 39},
    );
    expect(low.totalScore, 84);
    expect(low.candidateGrade, 1);

    final ok = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: {'S1': 45, 'D1': 40},
    );
    expect(ok.totalScore, 85);
    expect(ok.candidateGrade, 2);
  });

  test('안전 89%면 2스타 불가, 90%면 가능', () {
    final form = _miniV2();
    final gates = {'G1': true};
    // 44/50 = 88% — use 45 for 90%. 44.5 not int: 44/50=88%, 45/50=90%
    final fail = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: {'S1': 44, 'D1': 41}, // total 85, safety 88%
    );
    expect(fail.totalScore, 85);
    expect(fail.candidateGrade, 1);
    expect(fail.reason, contains('safety_ratio'));

    final pass = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: {'S1': 45, 'D1': 40},
    );
    expect(pass.candidateGrade, 2);
  });

  test('3스타: 미스터리 1회 불가, 2회 가능', () {
    final form = _miniV2(mysteryMin: 2);
    final gates = {'G1': true};
    final items = {'S1': 50, 'D1': 50}; // 100, all areas 100%
    final one = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: items,
      mysteryVisits: 1,
    );
    expect(one.totalScore, 100);
    expect(one.candidateGrade, lessThan(3));
    expect(one.reason, contains('mystery_'));

    final two = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: items,
      mysteryVisits: 2,
    );
    expect(two.candidateGrade, 3);
  });

  test('N/A 영역은 환산 총점으로 계산', () {
    final form = _miniV2();
    final gates = {'G1': true};
    // Only A applied: 40/50 → normalized 80
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      itemScores: {'S1': 40, 'D1': 0},
      areaNotApplicable: {'B': true},
    );
    expect(result.totalScore, 80);
    expect(result.candidateGrade, 1);
  });

  test('국가 게이트 탈락이면 등급 0', () {
    final form = _miniV2();
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: {'G1': true},
      itemScores: {'S1': 50, 'D1': 50},
      countryGatesPassed: [true, false],
      mysteryVisits: 2,
    );
    expect(result.gatesPassed, isFalse);
    expect(result.candidateGrade, 0);
  });

  test('JSON import validates and saves draft only', () async {
    const json = '''
{
  "version": "v2",
  "status": "active",
  "active": true,
  "thresholds": {
    "star1_min_total": 70,
    "star2_min_total": 85,
    "star2_safety_min_pct": 90,
    "star3_min_total": 93,
    "star3_all_areas_min_pct": 80,
    "star3_mystery_visits_min": 2
  },
  "rules": {
    "na_areas_allowed_except": "A",
    "normalize_na": true,
    "country_gates_max": 5
  },
  "areas": [
    {"code": "A", "name": "Safety", "max": 50},
    {"code": "B", "name": "Service", "max": 50}
  ],
  "gates": [
    {"id": "G1", "name": "License", "criteria": "ok", "evidence": "doc", "basis": "law", "scope": "common"}
  ],
  "items": [
    {"area": "A", "id": "S1", "name": "Brief", "max": 50, "criteria": "c", "evidence": "e", "basis": "b"},
    {"area": "B", "id": "D1", "name": "Guide", "max": 50, "criteria": "c", "evidence": "e", "basis": "b"}
  ]
}
''';
    final parsed = DiveStarFormImport.parseAndValidate(json);
    expect(parsed.version, 'v2');
    expect(parsed.active, isFalse);
    expect(parsed.status, DiveStarFormStatus.draft);
    expect(parsed.thresholds.safetyAreaId, 'A');
    expect(parsed.thresholds.star3MysteryVisitsMin, 2);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final saved = await repo.importDiveStarFormDraft(parsed);
    expect(saved.active, isFalse);

    final active = await repo.ensureActiveDiveStarForm();
    expect(active.version, 'v1');

    expect(
      () => repo.importDiveStarFormDraft(parsed),
      throwsA(isA<StateError>()),
    );
  });

  test('area sum not 100 is rejected', () {
    expect(
      () => DiveStarFormImport.parseAndValidate('''
{"version":"v2","areas":[{"code":"A","name":"A","max":40}],"gates":[],"items":[]}
'''),
      throwsA(isA<DiveStarFormImportException>()),
    );
  });

  test('v1 shaped document without v2 fields parses', () {
    final form = DiveStarForm.fromDocument('v1', {
      'version': 'v1',
      'active': true,
      'gates': [
        {'id': 'business_license', 'title': '사업자 등록·영업 허가'},
        {'id': 'air_quality', 'title': '공기질'},
      ],
      'areas': [
        {'id': 'safety', 'title': '안전', 'max_points': 25},
        {'id': 'service', 'title': '서비스', 'max_points': 75},
      ],
      'thresholds': {
        'star1_min_total': 70,
        'star2_min_total': 85,
        'star2_safety_min_ratio': 0.9,
        'star3_min_total': 93,
        'star3_area_min_ratio': 0.8,
        'safety_area_id': 'safety',
      },
    });
    expect(form.version, 'v1');
    expect(form.active, isTrue);
    expect(form.status, DiveStarFormStatus.active);
    expect(form.items, isEmpty);
    expect(form.gates, hasLength(2));
    expect(form.gates.first.criteria, isEmpty);
    expect(form.gates.first.scope, 'common');
    expect(form.rules.requiredAreaId, 'safety');
    expect(form.thresholds.safetyAreaId, 'safety');
  });

  test('null string fields on gates and status do not throw', () {
    final form = DiveStarForm.fromDocument('v1', {
      'version': null,
      'status': null,
      'active': true,
      'rules': null,
      'items': null,
      'gates': [
        {
          'id': 'g1',
          'title': 'Gate',
          'criteria': null,
          'evidence': null,
          'basis': null,
          'scope': null,
          'name': null,
        },
      ],
      'areas': [
        {'id': 'safety', 'title': null, 'name': 'Safety', 'max_points': 100},
      ],
      'thresholds': {
        'safety_area_id': null,
        'star2_safety_min_pct': null,
      },
    });
    expect(form.version, 'v1');
    expect(form.gates.single.scope, 'common');
    expect(form.gates.single.criteria, isEmpty);
    expect(form.areas.single.title, 'Safety');
    expect(form.thresholds.safetyAreaId, 'safety');
  });
}
