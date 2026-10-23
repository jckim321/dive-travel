import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_snapshot.dart';

void main() {
  test('Firestore 유저 문서의 로그 횟수와 방문 지역으로 지도·산소통 값을 만든다', () {
    final snapshot = DiverSnapshot.fromUserDocument(
      data: {
        'display_name': '종철',
        'total_log_count': 12,
        'unique_regions_count': 2,
        'visited_regions': ['팔라우', '코멜'],
        'region_log_counts': {'팔라우': 7, '코멜': 5},
        'favorite_shop_ids': ['bohol-hideout', 'palau-rock'],
        'is_instructor': false,
        'is_verified_pro': false,
      },
      logs: const [],
    );

    expect(snapshot.stats.totalLogCount, 12);
    expect(snapshot.stats.uniqueRegionsCount, 2);
    expect(snapshot.regions.map((region) => region.name), ['팔라우', '코멜']);
    expect(snapshot.regions.first.logCount, 7);
    expect(snapshot.favoriteShopIds, {'bohol-hideout', 'palau-rock'});
    expect(snapshot.stats.isAdmin, isFalse);
  });

  test('is_admin 플래그만 관리자 스냅샷이 된다', () {
    final byFlag = DiverSnapshot.fromUserDocument(
      data: {
        'display_name': '관리자',
        'email': 'staff@dive.local',
        'is_admin': true,
        'is_instructor': false,
        'is_verified_pro': false,
      },
      logs: const [],
    );
    expect(byFlag.stats.isAdmin, isTrue);

    final byOwnerEmailOnly = DiverSnapshot.fromUserDocument(
      data: {
        'display_name': 'Jongcheol',
        'email': 'jckim321@gmail.com',
        'is_instructor': false,
        'is_verified_pro': false,
      },
      logs: const [],
    );
    expect(byOwnerEmailOnly.stats.isAdmin, isFalse);
  });
}
