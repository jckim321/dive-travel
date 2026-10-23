import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_hub_screen.dart';

ShopProduct _product({
  required String id,
  String name = 'Trip',
  String shopId = 'shop-a',
  ProductListingKind listingKind = ProductListingKind.exploreOnly,
  SameBoatStatus sameBoatStatus = SameBoatStatus.closed,
  bool openEmptySeats = false,
  DateTime? departure,
  ProductPublishStatus publishStatus = ProductPublishStatus.approved,
  bool active = true,
}) {
  return ShopProduct(
    id: id,
    shopId: shopId,
    name: name,
    consumerPrice: 100000,
    professionalPrice: 80000,
    listingKind: listingKind,
    publishStatus: publishStatus,
    active: active,
    openEmptySeats: openEmptySeats,
    sameBoatStatus: sameBoatStatus,
    capacity: openEmptySeats ? 4 : 0,
    departureStart: departure,
  );
}

void main() {
  final now = DateTime.utc(2026, 10, 21);

  test('hub filter keeps only public products for a shop', () {
    final listed = filterSameBoatHubProducts(
      products: [
        _product(id: 'a', shopId: 'shop-a'),
        _product(id: 'b', shopId: 'shop-b'),
        _product(
          id: 'draft',
          shopId: 'shop-a',
          publishStatus: ProductPublishStatus.pending,
          active: false,
        ),
      ],
      shopId: 'shop-a',
    );
    expect(listed.map((p) => p.id), ['a']);
  });

  test('awaiting-publish list shows partner pending not open for seats', () {
    final pending = _product(
      id: 'pending',
      shopId: 'shop-a',
      publishStatus: ProductPublishStatus.pending,
      active: false,
    );
    final live = _product(id: 'live', shopId: 'shop-a');
    final awaiting = filterAwaitingPublishProducts(
      products: [pending, live],
      shopId: 'shop-a',
    );
    expect(awaiting.map((p) => p.id), ['pending']);
  });

  test('hub filter splits by same-boat status and source', () {
    final pending = _product(
      id: 'pending',
      name: 'Pending trip',
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.pending,
      departure: now,
      listingKind: ProductListingKind.diverPlanned,
    );
    final live = _product(
      id: 'live',
      name: 'Live trip',
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      departure: now,
      listingKind: ProductListingKind.exploreOnly,
    );
    final curated = _product(
      id: 'curated',
      shopId: 'curated-special',
      name: 'Special',
      listingKind: ProductListingKind.curated,
    );

    final pendingOnly = filterSameBoatHubProducts(
      products: [pending, live, curated],
      status: SameBoatHubStatusFilter.pending,
    );
    expect(pendingOnly.map((p) => p.id), ['pending']);

    final liveOnly = filterSameBoatHubProducts(
      products: [pending, live, curated],
      status: SameBoatHubStatusFilter.live,
    );
    expect(liveOnly.map((p) => p.id), ['live']);

    final diy = filterSameBoatHubProducts(
      products: [pending, live, curated],
      source: SameBoatHubSourceFilter.diy,
    );
    expect(diy.map((p) => p.id), ['pending']);

    final search = filterSameBoatHubProducts(
      products: [pending, live, curated],
      query: 'live',
    );
    expect(search.map((p) => p.id), ['live']);
  });
}
