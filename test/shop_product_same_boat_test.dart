import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  test('listsOnSameBoat needs public listing, flag, seats, and departure', () {
    final departure = DateTime(2026, 11, 1);
    final product = ShopProduct(
      id: 'p1',
      shopId: 's1',
      name: 'Liveaboard leftover',
      consumerPrice: 100,
      professionalPrice: 80,
      openEmptySeats: true,
      capacity: 4,
      departureStart: departure,
    );
    expect(product.listsOnSameBoat, isTrue);

    expect(product.copyWith(openEmptySeats: false).listsOnSameBoat, isFalse);
    expect(product.copyWith(capacity: 0).listsOnSameBoat, isFalse);
    expect(
      product.copyWith(departureStart: null).listsOnSameBoat,
      isFalse,
    );
    expect(product.copyWith(active: false).listsOnSameBoat, isFalse);
  });

  test('fromMap round-trips leftover seat fields', () {
    final departure = DateTime.utc(2026, 12, 3);
    final flag = DateTime.utc(2026, 11, 20);
    final saved = ShopProduct(
      id: 'p2',
      shopId: 'shop-a',
      name: 'Trip',
      consumerPrice: 1,
      professionalPrice: 1,
      openEmptySeats: true,
      capacity: 6,
      departureStart: departure,
      flagClosesAt: flag,
    ).toMap();
    final loaded = ShopProduct.fromMap('shop-a', saved);
    expect(loaded.openEmptySeats, isTrue);
    expect(loaded.capacity, 6);
    expect(loaded.departureStart, departure);
    expect(loaded.flagClosesAt, flag);
    expect(loaded.listsOnSameBoat, isTrue);
  });

  test('a flag holds seats until payment, without counting twice', () {
    final now = DateTime(2026, 10, 19, 9);
    final open = ShopProduct(
      id: 'p',
      shopId: 's',
      name: 'Trip',
      consumerPrice: 1,
      professionalPrice: 1,
      openEmptySeats: true,
      capacity: 4,
      departureStart: DateTime(2026, 11, 1),
      flagClosesAt: DateTime(2026, 10, 21),
    );
    final flagged = open.plantFlag(partySize: 2, now: now);
    expect(flagged.bookedSeats, 0);
    expect(flagged.flaggedSeatsAt(now), 2);
    expect(flagged.remainingSeatsAt(now), 2);
    expect(
      flagged.flagHolds.single.expiresAt,
      ShopProduct.personalFlagUntil(now, open.flagClosesAt),
    );

    final paid = flagged.capturePayment(2, now);
    expect(paid.bookedSeats, 2);
    expect(paid.flaggedSeatsAt(now), 0);
    expect(paid.remainingSeatsAt(now), 2);

    final closed = open.copyWith(openEmptySeats: false);
    expect(closed.plantFlag(partySize: 2, now: now).flaggedSeatsAt(now), 0);
    expect(closed.capturePayment(2, now).bookedSeats, 0);
  });

  test('an expired flag releases only the provisional seats', () {
    final planted = DateTime(2026, 10, 19, 9);
    final open = ShopProduct(
      id: 'p',
      shopId: 's',
      name: 'Trip',
      consumerPrice: 1,
      professionalPrice: 1,
      openEmptySeats: true,
      capacity: 4,
      departureStart: DateTime(2026, 12, 1),
    ).plantFlag(partySize: 1, now: planted);
    final later = planted.add(const Duration(hours: 25));
    expect(open.flaggedSeatsAt(later), 0);
    expect(open.remainingSeatsAt(later), 4);
    expect(
      open.capturePayment(0, later).bookedSeats,
      0,
    );
  });

  test('personal flag deadline is the sooner of 24 hours and the boat close', () {
    final planted = DateTime(2026, 10, 19, 9);
    final soon = DateTime(2026, 10, 19, 18);
    expect(
      ShopProduct.personalFlagUntil(planted, soon),
      soon,
    );
    expect(
      ShopProduct.personalFlagUntil(planted, DateTime(2026, 11, 1)),
      planted.add(const Duration(hours: 24)),
    );
  });
}
