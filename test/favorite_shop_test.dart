import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_snapshot.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';

void main() {
  test('찜한 리조트는 사용자 스냅샷에 저장되고 해제된다', () async {
    final repository = MemoryDiverRepository.forTest();
    final snapshots = <DiverSnapshot>[];
    final subscription = repository
        .watchDiver('test-user')
        .listen(snapshots.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    await repository.setFavoriteShop(
      uid: 'test-user',
      shopId: 'bohol-hideout',
      favorite: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(snapshots.last.favoriteShopIds, contains('bohol-hideout'));

    await repository.setFavoriteShop(
      uid: 'test-user',
      shopId: 'bohol-hideout',
      favorite: false,
    );
    await Future<void>.delayed(Duration.zero);
    expect(snapshots.last.favoriteShopIds, isEmpty);
  });
}
