import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _shelfTrip(String shopId) {
  return ShopProduct(
    id: 'shelf',
    shopId: shopId,
    name: '리조트 펀다이빙',
    consumerPrice: 120000,
    professionalPrice: 90000,
    publishStatus: ProductPublishStatus.approved,
    active: true,
    listingKind: ProductListingKind.diveStar,
    submittedAt: DateTime(2026, 10, 2),
  );
}

ShopProduct _publicTrip(String shopId) {
  return ShopProduct(
    id: 'trip',
    shopId: shopId,
    name: '펀다이빙',
    consumerPrice: 100000,
    professionalPrice: 80000,
    publishStatus: ProductPublishStatus.approved,
    active: true,
    listingKind: ProductListingKind.diveStar,
    openEmptySeats: true,
    sameBoatStatus: SameBoatStatus.approved,
    capacity: 4,
    departureStart: DateTime(2026, 12, 1),
    flagClosesAt: DateTime(2026, 11, 20),
    submittedAt: DateTime(2026, 10, 1),
  );
}

void main() {
  test('missing operating status stays active', () {
    expect(ShopOperatingStatus.parse(null), ShopOperatingStatus.active);
    expect(ShopOperatingStatus.parse(''), ShopOperatingStatus.active);
    expect(ShopOperatingStatus.parse('nope'), ShopOperatingStatus.active);
    expect(ShopOperatingStatus.parse('active'), ShopOperatingStatus.active);
    expect(ShopOperatingStatus.parse('paused'), ShopOperatingStatus.paused);
    expect(
      ShopOperatingStatus.parse('contract_ended'),
      ShopOperatingStatus.contractEnded,
    );
    expect(ShopOperatingStatus.parse('closed'), ShopOperatingStatus.closed);
    expect(shopAcceptsNewBusiness(null), isTrue);
    expect(shopAcceptsNewBusiness({}), isTrue);
    expect(
      shopAcceptsNewBusiness({'operating_status': 'closed'}),
      isFalse,
    );

    final blank = ShopLiveStats.fromDocument('reef', {});
    expect(blank.operatingStatus, ShopOperatingStatus.active);
    expect(blank.operatingStatus.acceptsCustomers, isTrue);
    final paused = ShopLiveStats.fromDocument('reef', {
      'operating_status': 'paused',
    });
    expect(paused.operatingStatus.acceptsCustomers, isFalse);
  });

  test('non-active shop leaves customer lists and blocks new booking and flag', () async {
    final repo = MemoryDiverRepository.forTest();
    const shopId = 'reef-live';
    await repo.saveShopProfile(
      shopId: shopId,
      name: '리프 라이브',
      location: '세부',
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    await repo.saveShopProduct(shopId: shopId, product: _shelfTrip(shopId));
    await repo.saveShopProduct(shopId: shopId, product: _publicTrip(shopId));

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();

    expect(store.shops.map((shop) => shop.hullId), contains(shopId));
    expect(
      store.resortsFeaturedAs(ProductListingKind.diveStar).map((s) => s.hullId),
      contains(shopId),
    );
    expect(store.sameBoatOffers(SameBoatFilter.all), isNotEmpty);
    expect(store.countOnHomeShelf(ProductListingKind.diveStar), 1);

    final kept = await repo.createBooking(
      uid: 'diver-1',
      shopId: shopId,
      shopName: '리프 라이브',
      productName: '펀다이빙',
      price: 100000,
    );
    expect(kept, isNotNull);
    final planted = await repo.plantSeatFlag(
      shopId: shopId,
      productId: 'trip',
      partySize: 1,
      now: DateTime(2026, 10, 29),
      uid: 'diver-1',
    );
    expect(planted, SeatFlagPlant.planted);

    for (final status in [
      ShopOperatingStatus.paused,
      ShopOperatingStatus.contractEnded,
      ShopOperatingStatus.closed,
    ]) {
      repo.debugSetOperatingStatus(shopId, status);
      await store.refreshShopStats();

      expect(store.shops.map((shop) => shop.hullId), isNot(contains(shopId)));
      expect(
        store.resortsFeaturedAs(ProductListingKind.diveStar),
        isEmpty,
      );
      expect(store.sameBoatOffers(SameBoatFilter.all), isEmpty);
      expect(store.sameBoatResults(), isEmpty);
      expect(store.countOnHomeShelf(ProductListingKind.diveStar), 0);

      final blocked = await repo.createBooking(
        uid: 'diver-2',
        shopId: shopId,
        shopName: '리프 라이브',
        productName: '펀다이빙',
        price: 100000,
        productId: 'trip',
        partySize: 1,
      );
      expect(blocked, isNull);
      expect(
        repo.plantSeatFlag(
          shopId: shopId,
          productId: 'other',
          partySize: 1,
          now: DateTime(2026, 10, 29),
          uid: 'diver-2',
        ),
        completion(SeatFlagPlant.unavailable),
      );
    }

    final bookings = await repo.watchBookings('diver-1').first;
    expect(bookings, hasLength(1));
    expect(bookings.single.id, kept!.id);

    repo.debugSetOperatingStatus(shopId, ShopOperatingStatus.active);
    await store.refreshShopStats();
    expect(store.shops.map((shop) => shop.hullId), contains(shopId));
    final again = await repo.createBooking(
      uid: 'diver-3',
      shopId: shopId,
      shopName: '리프 라이브',
      productName: '펀다이빙',
      price: 100000,
    );
    expect(again, isNotNull);
  });
}
