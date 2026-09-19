import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/region_catalog.dart';

void main() {
  test('카탈로그 지명은 실제 위경도로 해석한다', () {
    final palau = RegionCatalog.resolve('팔라우', 3);
    expect(palau.longitude, closeTo(134.48, 0.2));
    expect(palau.latitude, closeTo(7.33, 0.2));

    final cozumel = RegionCatalog.resolve('코멜', 2);
    expect(cozumel.longitude, closeTo(-86.92, 0.3));
    expect(cozumel.latitude, closeTo(20.42, 0.3));

    final bohol = RegionCatalog.resolve('필리핀 보홀', 1);
    expect(bohol.longitude, closeTo(124.14, 0.2));
    expect(bohol.latitude, closeTo(9.83, 0.2));
  });

  test('나라 이름만 있어도 그 해역 근처로 떨어진다', () {
    final philippines = RegionCatalog.resolve('필리핀', 1);
    expect(philippines.longitude, closeTo(123.5, 1.5));
    expect(philippines.latitude, inInclusiveRange(5, 20));
  });

  test('포인트 로그는 나라 스탬프로 묶인다', () {
    final bohol = RegionCatalog.resolve('보홀', 2);
    expect(RegionCatalog.countryOf(bohol), '필리핀');
    expect(
      RegionCatalog.passportCountries.any((item) => item.name == '필리핀'),
      isTrue,
    );
  });
}
