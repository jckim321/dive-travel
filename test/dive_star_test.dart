import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';

void main() {
  test('리뷰가 없으면 Dive Star 0', () {
    expect(
      DiveStar.fromAverages(safety: 5, guide: 5, boat: 5, reviewCount: 0),
      0,
    );
  });

  test('3대 항목 평균 4.5는 Dive Star 1', () {
    expect(
      DiveStar.fromAverages(safety: 4.5, guide: 4.5, boat: 4.5, reviewCount: 2),
      1,
    );
  });

  test('평균 4.8은 Dive Star 2', () {
    expect(
      DiveStar.fromAverages(safety: 4.8, guide: 4.8, boat: 4.8, reviewCount: 3),
      2,
    );
  });

  test('최고 점수와 안전 기준을 통과하면 Dive Star 3', () {
    expect(
      DiveStar.fromAverages(safety: 4.9, guide: 5.0, boat: 4.9, reviewCount: 4),
      3,
    );
  });

  test('전체 점수가 높아도 안전 기준 미달이면 3스타가 아니다', () {
    expect(
      DiveStar.fromAverages(safety: 4.5, guide: 5.0, boat: 5.0, reviewCount: 4),
      2,
    );
  });

  test('is_verified_pro pending 문자열을 대기중으로 읽는다', () {
    expect(ProVerificationStatus.parse('pending'), ProVerificationStatus.pending);
    expect(ProVerificationStatus.parse(true), ProVerificationStatus.approved);
    expect(ProVerificationStatus.parse(false), ProVerificationStatus.none);
    expect(ProVerificationStatus.pending.firestoreValue, 'pending');
  });
}
