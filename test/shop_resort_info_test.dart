import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/shop_resort_info.dart';

void main() {
  group('validateShopMapUrl', () {
    test('빈 값은 허용', () {
      expect(validateShopMapUrl(''), isNull);
      expect(validateShopMapUrl('  '), isNull);
    });

    test('https 구글·네이버·카카오 허용', () {
      expect(
        validateShopMapUrl('https://www.google.com/maps/place/Test'),
        isNull,
      );
      expect(
        validateShopMapUrl('https://maps.google.com/?q=Seoul'),
        isNull,
      );
      expect(
        validateShopMapUrl('https://maps.app.goo.gl/abc'),
        isNull,
      );
      expect(validateShopMapUrl('https://goo.gl/maps/abc'), isNull);
      expect(
        validateShopMapUrl('https://map.naver.com/v5/entry/place/1'),
        isNull,
      );
      expect(validateShopMapUrl('https://naver.me/x'), isNull);
      expect(validateShopMapUrl('https://map.kakao.com/?q=1'), isNull);
      expect(validateShopMapUrl('https://kko.to/abc'), isNull);
    });

    test('http·다른 도메인·비지도 google 거부', () {
      expect(validateShopMapUrl('http://maps.google.com/'), 'map_url_https_only');
      expect(validateShopMapUrl('https://evil.com/maps'), 'map_url_domain');
      expect(
        validateShopMapUrl('https://www.google.com/search?q=1'),
        'map_url_domain',
      );
      expect(validateShopMapUrl('javascript:alert(1)'), 'map_url_invalid');
      expect(validateShopMapUrl('not a url'), 'map_url_invalid');
    });
  });

  group('AccessRoute / NearbySpot', () {
    test('라운드트립', () {
      final route = AccessRoute(
        from: '공항에서',
        transport: const ['pickup', 'taxi'],
        duration: '40분',
        cost: '15달러',
        tips: '미팅 포인트 확인',
      );
      final again = AccessRoute.fromMap(route.toMap());
      expect(again.from, '공항에서');
      expect(again.transport, ['pickup', 'taxi']);

      final spot = NearbySpot(
        name: '블루홀',
        distance: '20분',
        blurb: '스노클',
      );
      expect(NearbySpot.fromMap(spot.toMap()).name, '블루홀');
    });

    test('목록 상한', () {
      final routes = AccessRoute.listFrom([
        for (var i = 0; i < 8; i++) {'from': 'r$i'},
      ]);
      expect(routes.length, kMaxAccessRoutes);

      final spots = NearbySpot.listFrom([
        for (var i = 0; i < 15; i++) {'name': 's$i'},
      ]);
      expect(spots.length, kMaxNearbySpots);
    });
  });
}
