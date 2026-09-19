import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';

void main() {
  final bohol = DiveShopCatalog.shops.firstWhere((shop) => shop.id == 'bohol-hideout');

  test('일반 다이버는 샵이 등록한 소비자가를 그대로 본다', () {
    final quote = TourPricePolicy.quote(bohol, isInstructor: false);
    expect(quote.isProfessional, isFalse);
    expect(quote.amount, 180000);
    expect(quote.hasDiscount, isFalse);
  });

  test('강사 세션은 관리자 할인율로 우대가를 계산한다', () {
    final quote = TourPricePolicy.quote(bohol, isInstructor: true);
    expect(quote.isProfessional, isTrue);
    expect(quote.amount, 126000);
    expect(quote.compareAtAmount, 180000);
    expect(quote.hasDiscount, isTrue);
  });

  test('관리자 정액 할인은 소비자가에서 금액을 뺀다', () {
    const discount = InstructorDiscount(
      kind: InstructorDiscountKind.amount,
      value: 20000,
    );
    final quote = TourPricePolicy.quote(
      bohol,
      isInstructor: true,
      discount: discount,
    );
    expect(quote.amount, 160000);
  });

  test('포인트 검색과 대륙 필터가 샵 목록을 줄인다', () {
    final palau = DiveShopCatalog.search(query: '팔라우', continent: ContinentFilter.all);
    expect(palau, hasLength(1));
    expect(palau.single.id, 'palau-rock-islands');

    final africa = DiveShopCatalog.search(query: '', continent: 'africa');
    expect(africa.map((shop) => shop.id), ['dahab-bluehole']);
  });

  test('리조트 안에서는 기본 상품과 메뉴 상품이 같이 나온다', () {
    final listings = DiveShopCatalog.listingsOnHull(
      DiveShopCatalog.shops,
      'bohol-hideout',
    );
    expect(
      listings.map((shop) => shop.productName),
      containsAll(['2탱크 펀다이빙', '나이트 1탱크']),
    );
  });
}
