import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';

void main() {
  late DiveStarForm form;

  setUp(() {
    form = DiveStarForm.v1();
  });

  Map<String, bool> allGatesPass() => {
        for (final gate in form.gates) gate.id: true,
      };

  test('게이트 하나라도 탈락이면 후보 등급 0', () {
    final gates = allGatesPass();
    gates[form.gates.first.id] = false;
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: gates,
      scores: {for (final area in form.areas) area.id: area.maxPoints},
    );
    expect(result.gatesPassed, isFalse);
    expect(result.candidateGrade, 0);
    expect(result.totalScore, 100);
  });

  test('게이트 통과 + 70점이면 1스타', () {
    final scores = <String, int>{
      for (final area in form.areas) area.id: 0,
    };
    // 25+20+15+10 = 70
    scores['safety'] = 25;
    scores['service'] = 20;
    scores['equipment'] = 15;
    scores['hospitality'] = 10;
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: allGatesPass(),
      scores: scores,
    );
    expect(result.totalScore, 70);
    expect(result.candidateGrade, 1);
  });

  test('85점 + 안전 90%면 2스타', () {
    final scores = <String, int>{
      'safety': 23, // >= 22.5
      'service': 17,
      'equipment': 12,
      'hospitality': 12,
      'environment': 8,
      'experience': 8,
      'reviews': 5,
    };
    expect(scores.values.fold<int>(0, (a, b) => a + b), 85);
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: allGatesPass(),
      scores: scores,
    );
    expect(result.candidateGrade, 2);
  });

  test('85점이어도 안전 90% 미달이면 2스타가 아니다', () {
    // Total 85–92 so 3-star band is out; safety below 90% of 25.
    final scores = <String, int>{
      'safety': 20, // < 22.5
      'service': 17,
      'equipment': 12,
      'hospitality': 12,
      'environment': 8,
      'experience': 8,
      'reviews': 5,
    };
    expect(scores.values.fold<int>(0, (a, b) => a + b), 82);
    // Bump to 85 without lifting safety.
    scores['service'] = 20;
    expect(scores.values.fold<int>(0, (a, b) => a + b), 85);
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: allGatesPass(),
      scores: scores,
    );
    expect(result.candidateGrade, 1);
  });

  test('93점 + 전 영역 80%면 3스타', () {
    final scores = <String, int>{
      'safety': 25,
      'service': 20,
      'equipment': 15,
      'hospitality': 15,
      'environment': 8,
      'experience': 8,
      'reviews': 4,
    };
    expect(scores.values.fold<int>(0, (a, b) => a + b), 95);
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: allGatesPass(),
      scores: scores,
    );
    expect(result.candidateGrade, 3);
  });

  test('만점 초과 점수는 잘라서 합산한다', () {
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: allGatesPass(),
      scores: {for (final area in form.areas) area.id: 999},
    );
    expect(result.totalScore, 100);
    expect(result.candidateGrade, 3);
  });

  test('메모리 저장소: 저장만으로는 샵 등급이 안 바뀌고 확정 시 바뀐다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final before = await repo.watchShopStats().first;
    expect(
      before.where((s) => s.shopId == 'shop-a').map((s) => s.diveStar),
      isEmpty,
    );

    final saved = await repo.saveDiveStarAssessment(
      shopId: 'shop-a',
      type: DiveStarAssessmentType.onsite,
      reviewedAt: DateTime.utc(2026, 3, 1),
      gates: allGatesPass(),
      scores: {
        'safety': 25,
        'service': 20,
        'equipment': 15,
        'hospitality': 15,
        'environment': 10,
        'experience': 10,
        'reviews': 5,
      },
      comments: const {},
    );
    expect(saved.candidateGrade, 3);
    expect(saved.confirmed, isFalse);

    final mid = await repo.watchShopStats().first;
    expect(mid.any((s) => s.shopId == 'shop-a' && s.diveStar > 0), isFalse);

    final confirmed = await repo.confirmDiveStarAssessment(
      shopId: 'shop-a',
      assessmentId: saved.id,
    );
    expect(confirmed.confirmed, isTrue);
    final stats = (await repo.watchShopStats().first)
        .firstWhere((s) => s.shopId == 'shop-a');
    expect(stats.diveStar, 3);
    expect(stats.diveStarReviewedAt, DateTime.utc(2026, 3, 1));
    expect(stats.diveStarExpiresAt, DateTime.utc(2027, 3, 1));
  });

  test('미확정 기록은 같은 id로 덮어쓰고 점수를 다시 계산한다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final first = await repo.saveDiveStarAssessment(
      shopId: 'shop-b',
      type: DiveStarAssessmentType.onsite,
      reviewedAt: DateTime.utc(2026, 4, 1),
      gates: allGatesPass(),
      scores: {
        'safety': 25,
        'service': 20,
        'equipment': 15,
        'hospitality': 10,
        'environment': 0,
        'experience': 0,
        'reviews': 0,
      },
      comments: const {'safety': '초안'},
    );
    expect(first.totalScore, 70);
    expect(first.candidateGrade, 1);

    final updated = await repo.saveDiveStarAssessment(
      shopId: 'shop-b',
      assessmentId: first.id,
      type: DiveStarAssessmentType.mystery,
      reviewedAt: DateTime.utc(2026, 4, 2),
      gates: allGatesPass(),
      scores: {
        'safety': 25,
        'service': 20,
        'equipment': 15,
        'hospitality': 15,
        'environment': 10,
        'experience': 10,
        'reviews': 5,
      },
      comments: const {'safety': '수정'},
    );
    expect(updated.id, first.id);
    expect(updated.type, DiveStarAssessmentType.mystery);
    expect(updated.totalScore, 100);
    expect(updated.candidateGrade, 3);
    expect(updated.comments['safety'], '수정');
    final list = await repo.listDiveStarAssessments('shop-b');
    expect(list, hasLength(1));
  });

  test('확정된 기록은 저장·삭제할 수 없다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final saved = await repo.saveDiveStarAssessment(
      shopId: 'shop-c',
      type: DiveStarAssessmentType.onsite,
      reviewedAt: DateTime.utc(2026, 5, 1),
      gates: allGatesPass(),
      scores: {
        'safety': 25,
        'service': 20,
        'equipment': 15,
        'hospitality': 15,
        'environment': 10,
        'experience': 10,
        'reviews': 5,
      },
      comments: const {},
    );
    await repo.confirmDiveStarAssessment(
      shopId: 'shop-c',
      assessmentId: saved.id,
    );

    expect(
      () => repo.saveDiveStarAssessment(
        shopId: 'shop-c',
        assessmentId: saved.id,
        type: DiveStarAssessmentType.onsite,
        reviewedAt: DateTime.utc(2026, 5, 2),
        gates: allGatesPass(),
        scores: {for (final a in form.areas) a.id: 0},
        comments: const {},
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => repo.deleteDiveStarAssessment(
        shopId: 'shop-c',
        assessmentId: saved.id,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repo.listDiveStarAssessments('shop-c'), hasLength(1));
  });

  test('미확정 기록은 삭제할 수 있다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final saved = await repo.saveDiveStarAssessment(
      shopId: 'shop-d',
      type: DiveStarAssessmentType.onsite,
      reviewedAt: DateTime.utc(2026, 6, 1),
      gates: allGatesPass(),
      scores: {for (final a in form.areas) a.id: 0},
      comments: const {},
    );
    await repo.deleteDiveStarAssessment(
      shopId: 'shop-d',
      assessmentId: saved.id,
    );
    expect(await repo.listDiveStarAssessments('shop-d'), isEmpty);
  });
}
