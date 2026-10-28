import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/product_change.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  test('a normal booking stores the price that was passed in', () async {
    final repo = MemoryDiverRepository();
    final saved = await repo.createBooking(
      uid: 'guest-1',
      shopId: 'shop-a',
      shopName: 'Shop',
      productName: 'Tour',
      price: 45000,
    );
    expect(saved, isTrue);
    final rows = await repo.watchBookings('guest-1').first;
    expect(rows.single.price, 45000);
  });

  test('a flag stores the planted price and an old hold stays at zero', () {
    final now = DateTime(2026, 10, 26, 9);
    final product = ShopProduct(
      id: 'p1',
      shopId: 'shop-a',
      name: 'Boat',
      consumerPrice: 50000,
      professionalPrice: 40000,
      capacity: 4,
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      departureStart: DateTime(2026, 11, 1),
    ).plantFlag(partySize: 2, now: now, uid: 'guest-1', lockedPrice: 100000);

    final hold = product.liveFlagFor('guest-1', now)!;
    expect(hold.lockedPrice, 100000);
    expect(hold.toMap()['locked_price'], 100000);
    final quoted = ShopProduct(
      id: 'p1',
      shopId: 'shop-a',
      name: 'Boat',
      consumerPrice: 40000,
      professionalPrice: 30000,
    );
    final locked = CheckoutCharge.resolve(
      fromFlag: true,
      lockedPartySize: 2,
      lockedPrice: 100000,
      divers: 9,
      product: quoted,
    );
    expect(locked.partySize, 2);
    expect(locked.total, 100000);
    final normal = CheckoutCharge.resolve(
      fromFlag: false,
      lockedPartySize: 9,
      lockedPrice: 100000,
      divers: 2,
      product: quoted,
    );
    expect(normal.partySize, 2);
    expect(normal.total, 80000);
    final three = CheckoutCharge.resolve(
      fromFlag: true,
      lockedPartySize: 3,
      product: quoted.copyWith(consumerPrice: 100000),
    );
    expect(three.partySize, 3);
    expect(three.total, 300000);

    final old = SeatHold.fromMap({
      'seats': 1,
      'expires_at': now.add(const Duration(hours: 2)).toIso8601String(),
      'uid': 'guest-2',
    })!;
    expect(old.lockedPrice, 0);
    expect(old.toMap().containsKey('locked_price'), isFalse);
    final missingLock = CheckoutCharge.resolve(
      fromFlag: true,
      lockedPartySize: 2,
      lockedPrice: 0,
      product: quoted,
    );
    expect(missingLock.partySize, 2);
    expect(missingLock.total, 80000);
  });

  test('price and capacity changes are recorded and booked seats are not', () {
    final previous = ShopProduct(
      id: 'p1',
      shopId: 'shop-a',
      name: 'Boat',
      consumerPrice: 10000,
      professionalPrice: 8000,
      capacity: 8,
      bookedSeats: 1,
      options: const [
        ShopProductOption(id: 'opt', name: 'Gear', consumerPrice: 3000),
      ],
    );
    final next = previous.copyWith(
      consumerPrice: 12000,
      capacity: 10,
      bookedSeats: 4,
      options: const [
        ShopProductOption(id: 'opt', name: 'Gear', consumerPrice: 3000, capacity: 6),
      ],
    );
    final lines = productPriceCapacityChanges(previous: previous, next: next);
    expect(
      lines.map((line) => '${line.optionId}:${line.field}:${line.before}:${line.after}'),
      [
        ':consumer_price:10000:12000',
        ':capacity:8:10',
        'opt:capacity:0:6',
      ],
    );
  });

  test('saving a product writes the product and its history together', () async {
    final repo = MemoryDiverRepository();
    const shopId = AppConstants.defaultPartnerShopId;
    final first = ShopProduct(
      id: 'p1',
      shopId: shopId,
      name: 'Boat',
      consumerPrice: 10000,
      professionalPrice: 8000,
    );
    await repo.saveShopProduct(shopId: shopId, product: first);
    await repo.saveShopProduct(
      shopId: shopId,
      product: first.copyWith(consumerPrice: 12000),
    );
    final shops = await repo.fetchShopStats();
    final saved = shops
        .firstWhere((shop) => shop.shopId == shopId)
        .products
        .single;
    expect(saved.consumerPrice, 12000);
    final history = await repo.listProductChanges(shopId);
    expect(
      history.where((line) => line.field == ProductChangeRecord.consumerPrice && line.after == 12000),
      isNotEmpty,
    );
    expect(history.every((line) => line.field != 'booked_seats'), isTrue);
  });
}
