import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopLiveStats _bare(String shopId, {String name = '옛 이름'}) {
  return ShopLiveStats(
    shopId: shopId,
    reviewCount: 0,
    avgSafety: 0,
    avgGuide: 0,
    avgBoat: 0,
    avgOverall: 0,
    diveStar: 0,
    name: name,
  );
}

void main() {
  testWidgets('stale shop read keeps the saved profile, product, and status', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    const shopId = 'reef';
    await repo.saveShopProfile(
      shopId: shopId,
      name: '옛 이름',
      location: '세부',
      productName: '옛 상품',
      consumerPrice: 1,
      professionalPrice: 1,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(DiverStoreScope(store: store, child: const SizedBox()));
    await store.refreshShopStats();
    await tester.pump();
    expect(store.stats.isAdmin, isTrue);

    final stale = _bare(shopId);
    repo.debugFetchShopStatOverride = stale;

    final profile = await store.saveShopProfile(
      shopId: shopId,
      name: '새 리프',
      location: '팔라우',
      productName: '옛 상품',
      consumerPrice: 1,
      professionalPrice: 1,
      intro: '새로 적은 소개',
    );
    expect(store.liveStatsFor(shopId)?.name, '새 리프');
    await profile.readFuture;
    expect(store.liveStatsFor(shopId)?.name, '새 리프');
    expect(store.liveStatsFor(shopId)?.intro, '새로 적은 소개');
    expect(store.liveStatsFor(shopId)?.location, '팔라우');

    await store.saveShopProduct(
      shopId: shopId,
      product: ShopProduct(
        id: 'trip',
        shopId: shopId,
        name: '펀다이빙',
        consumerPrice: 120000,
        professionalPrice: 90000,
        blurb: '산호',
      ),
    );
    expect(
      store.productsForShop(shopId).map((item) => item.name),
      contains('펀다이빙'),
    );

    await store.setShopOperatingStatus(
      shopId: shopId,
      status: ShopOperatingStatus.paused,
      note: '시즌 종료',
    );
    final live = store.liveStatsFor(shopId);
    expect(live?.operatingStatus, ShopOperatingStatus.paused);
    expect(live?.operatingNote, '시즌 종료');
    expect(live?.name, '새 리프');
    expect(live?.products.map((item) => item.name), contains('펀다이빙'));

    repo.debugFetchShopStatOverride = null;
    await store.refreshShopStat(shopId);
    final caughtUp = store.liveStatsFor(shopId);
    expect(caughtUp?.name, '새 리프');
    expect(caughtUp?.operatingStatus, ShopOperatingStatus.paused);
    expect(caughtUp?.products.single.name, '펀다이빙');
  });
}
