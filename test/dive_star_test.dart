import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

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

  test('Firestore loose nested maps still parse products and covers', () {
    final stats = ShopLiveStats.fromDocument('cairns-gbr', {
      'name': '케언즈 그레이트리프',
      'cover_url': 'https://cdn.example/shops/cairns-gbr/cover.jpg',
      'products': [
        <Object?, Object?>{
          'id': 'p-1',
          'name': '외곽 리프 2탱크',
          'consumer_price': 260000,
          'professional_price': 182000,
          'cover_url': 'https://cdn.example/shops/cairns-gbr/products/p-1.jpg',
          'listing_kind': 'dive_star',
          'publish_status': 'approved',
          'active': true,
          'submitted_at': '2026-10-13T12:00:00.000Z',
        },
      ],
    });
    expect(stats.products, hasLength(1));
    expect(stats.products.first.coverUrl, contains('products/p-1'));
    expect(stats.products.first.isListedPublicly, isTrue);
  });
}
