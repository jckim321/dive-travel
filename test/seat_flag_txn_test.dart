import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/active_seat_flag.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  const shopId = AppConstants.defaultPartnerShopId;

  ShopProduct openProduct({
    required String id,
    required int capacity,
    DateTime? flagClosesAt,
    int bookedSeats = 0,
  }) {
    final now = DateTime(2026, 10, 23, 12);
    return ShopProduct(
      id: id,
      shopId: shopId,
      name: 'Open seats $id',
      consumerPrice: 100000,
      professionalPrice: 80000,
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      capacity: capacity,
      bookedSeats: bookedSeats,
      departureStart: now.add(const Duration(days: 10)),
      flagClosesAt: flagClosesAt ?? now.add(const Duration(days: 5)),
      listingKind: ProductListingKind.diverPlanned,
      publishStatus: ProductPublishStatus.approved,
    );
  }

  Future<MemoryDiverRepository> seeded(ShopProduct product) async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(shopId: shopId, product: product);
    return repo;
  }

  test('(a) expired flags do not count toward the 3-flag limit', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = await seeded(openProduct(id: 'p-new', capacity: 4));
    repo.seedActiveSeatFlags('test-user', [
      for (var i = 0; i < 3; i++)
        ActiveSeatFlag(
          shopId: shopId,
          productId: 'expired-$i',
          expiresAt: now.subtract(const Duration(hours: 1)),
        ),
    ]);

    final result = await repo.plantSeatFlag(
      shopId: shopId,
      productId: 'p-new',
      partySize: 1,
      now: now,
      uid: 'test-user',
    );
    expect(result, SeatFlagPlant.planted);
    final live = ActiveSeatFlag.liveOnly(
      repo.readActiveSeatFlags('test-user'),
      now,
    );
    expect(live, hasLength(1));
    expect(live.single.productId, 'p-new');
  });

  test('(b) plant is blocked within 2 hours of flag close', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = await seeded(
      openProduct(
        id: 'p-late',
        capacity: 4,
        flagClosesAt: now.add(const Duration(hours: 1)),
      ),
    );
    final result = await repo.plantSeatFlag(
      shopId: shopId,
      productId: 'p-late',
      partySize: 1,
      now: now,
      uid: 'test-user',
    );
    expect(result, SeatFlagPlant.tooLate);
  });

  test('(c) last seat: only one of two concurrent createBooking succeeds',
      () async {
    final repo = await seeded(openProduct(id: 'p-race', capacity: 1));
    final results = await Future.wait([
      repo.createBooking(
        uid: 'user-a',
        shopId: shopId,
        shopName: 'Shop',
        productName: 'Race',
        price: 1,
        productId: 'p-race',
        partySize: 1,
      ),
      repo.createBooking(
        uid: 'user-b',
        shopId: shopId,
        shopName: 'Shop',
        productName: 'Race',
        price: 1,
        productId: 'p-race',
        partySize: 1,
      ),
    ]);
    expect(results.where((ok) => ok).length, 1);
    final stats = await repo.fetchShopStat(shopId);
    final product = stats!.products.singleWhere((p) => p.id == 'p-race');
    expect(product.bookedSeats, 1);
  });

  test('last seat plant race: first planter wins', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = await seeded(openProduct(id: 'p-plant-race', capacity: 1));
    final results = await Future.wait([
      repo.plantSeatFlag(
        shopId: shopId,
        productId: 'p-plant-race',
        partySize: 1,
        now: now,
        uid: 'user-a',
      ),
      repo.plantSeatFlag(
        shopId: shopId,
        productId: 'p-plant-race',
        partySize: 1,
        now: now,
        uid: 'user-b',
      ),
    ]);
    expect(results.where((r) => r == SeatFlagPlant.planted).length, 1);
    expect(results.where((r) => r == SeatFlagPlant.taken).length, 1);
  });

  test('same product second flag is alreadyHeld', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = await seeded(openProduct(id: 'p-dup', capacity: 4));
    expect(
      await repo.plantSeatFlag(
        shopId: shopId,
        productId: 'p-dup',
        partySize: 1,
        now: now,
        uid: 'test-user',
      ),
      SeatFlagPlant.planted,
    );
    expect(
      await repo.plantSeatFlag(
        shopId: shopId,
        productId: 'p-dup',
        partySize: 1,
        now: now,
        uid: 'test-user',
      ),
      SeatFlagPlant.alreadyHeld,
    );
  });

  test('fourth live flag hits limitReached', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = MemoryDiverRepository.forTest();
    for (var i = 0; i < 4; i++) {
      await repo.saveShopProduct(
        shopId: shopId,
        product: openProduct(id: 'p-lim-$i', capacity: 2),
      );
    }
    for (var i = 0; i < 3; i++) {
      expect(
        await repo.plantSeatFlag(
          shopId: shopId,
          productId: 'p-lim-$i',
          partySize: 1,
          now: now,
          uid: 'test-user',
        ),
        SeatFlagPlant.planted,
      );
    }
    expect(
      await repo.plantSeatFlag(
        shopId: shopId,
        productId: 'p-lim-3',
        partySize: 1,
        now: now,
        uid: 'test-user',
      ),
      SeatFlagPlant.limitReached,
    );
  });

  test('cancelSeatFlag frees seats immediately', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = await seeded(openProduct(id: 'p-cancel', capacity: 2));
    await repo.plantSeatFlag(
      shopId: shopId,
      productId: 'p-cancel',
      partySize: 1,
      now: now,
      uid: 'test-user',
    );
    var stats = await repo.fetchShopStat(shopId);
    expect(
      stats!.products.singleWhere((p) => p.id == 'p-cancel').remainingSeatsAt(now),
      1,
    );
    final ok = await repo.cancelSeatFlag(
      uid: 'test-user',
      shopId: shopId,
      productId: 'p-cancel',
      now: now,
    );
    expect(ok, isTrue);
    stats = await repo.fetchShopStat(shopId);
    expect(
      stats!.products.singleWhere((p) => p.id == 'p-cancel').remainingSeatsAt(now),
      2,
    );
    expect(repo.readActiveSeatFlags('test-user'), isEmpty);
  });

  test('plant → createBooking records seats_held and consumes hold', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = await seeded(openProduct(id: 'p-flow', capacity: 3));
    await repo.plantSeatFlag(
      shopId: shopId,
      productId: 'p-flow',
      partySize: 2,
      now: now,
      uid: 'test-user',
    );
    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Flow',
      price: 1,
      productId: 'p-flow',
      partySize: 2,
      fromFlag: true,
    );
    expect(saved, isTrue);
    final booking = (await repo.watchBookings('test-user').first).first;
    expect(booking.seatsHeld, 2);
    final stats = await repo.fetchShopStat(shopId);
    final product = stats!.products.singleWhere((p) => p.id == 'p-flow');
    expect(product.bookedSeats, 2);
    expect(product.flaggedSeatsAt(now), 0);
  });

  test('expired flag createBooking fails when no seats left', () async {
    final plantedAt = DateTime(2026, 10, 20, 12);
    final now = DateTime(2026, 10, 23, 12);
    final product = openProduct(id: 'p-exp', capacity: 1).plantFlag(
      partySize: 1,
      now: plantedAt,
      uid: 'test-user',
    );
    // Force expiry by rewriting hold.
    final expired = product.copyWith(
      flagHolds: [
        SeatHold(
          seats: 1,
          expiresAt: now.subtract(const Duration(minutes: 1)),
          uid: 'test-user',
        ),
      ],
      bookedSeats: 1,
    );
    final repo = await seeded(expired);
    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Exp',
      price: 1,
      productId: 'p-exp',
      partySize: 1,
    );
    expect(saved, isFalse);
  });

  test('cancel restores seats_held once; legacy bookings skip restore',
      () async {
    final repo = await seeded(openProduct(id: 'p-rest', capacity: 4));
    await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Rest',
      price: 1,
      productId: 'p-rest',
      partySize: 2,
    );
    var stats = await repo.fetchShopStat(shopId);
    expect(stats!.products.singleWhere((p) => p.id == 'p-rest').bookedSeats, 2);

    final booking = (await repo.watchBookings('test-user').first).first;
    expect(booking.seatsHeld, 2);
    await repo.cancelBookingAsGuest(uid: 'test-user', bookingId: booking.id);
    stats = await repo.fetchShopStat(shopId);
    expect(stats!.products.singleWhere((p) => p.id == 'p-rest').bookedSeats, 0);

    await repo.cancelBookingAsGuest(uid: 'test-user', bookingId: booking.id);
    stats = await repo.fetchShopStat(shopId);
    expect(stats!.products.singleWhere((p) => p.id == 'p-rest').bookedSeats, 0);

    // Legacy booking without seats_held: cancel does not change booked.
    await repo.saveShopProduct(
      shopId: shopId,
      product: openProduct(id: 'p-legacy', capacity: 3, bookedSeats: 2),
    );
    repo.seedBooking(
      TourBooking(
        id: 'legacy-1',
        uid: 'test-user',
        shopId: shopId,
        shopName: 'Shop',
        productName: 'Legacy',
        productId: 'p-legacy',
        price: 1,
        createdAt: DateTime(2026, 10, 1),
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.captured,
        partySize: 2,
        seatsHeld: 0,
      ),
    );
    await repo.cancelBookingAsGuest(uid: 'test-user', bookingId: 'legacy-1');
    stats = await repo.fetchShopStat(shopId);
    expect(
      stats!.products.singleWhere((p) => p.id == 'p-legacy').bookedSeats,
      2,
    );
  });

  test('open_empty_seats off skips seat hold; confirm does not change booked',
      () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: shopId,
      product: const ShopProduct(
        id: 'p-closed',
        shopId: shopId,
        name: 'Closed',
        consumerPrice: 1,
        professionalPrice: 1,
        openEmptySeats: false,
        capacity: 2,
      ),
    );
    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Closed',
      price: 1,
      productId: 'p-closed',
      partySize: 2,
    );
    expect(saved, isTrue);
    final booking = (await repo.watchBookings('test-user').first).first;
    expect(booking.seatsHeld, 0);
    var stats = await repo.fetchShopStat(shopId);
    expect(stats!.products.singleWhere((p) => p.id == 'p-closed').bookedSeats, 0);

    await repo.confirmShopBooking(shopId: shopId, bookingId: booking.id);
    stats = await repo.fetchShopStat(shopId);
    expect(stats!.products.singleWhere((p) => p.id == 'p-closed').bookedSeats, 0);
  });

  test('a second plant keeps the old party; replace moves it to 3', () async {
    final now = DateTime(2026, 10, 23, 12);
    final repo = await seeded(openProduct(id: 'p-size', capacity: 4));
    await repo.plantSeatFlag(
      shopId: shopId,
      productId: 'p-size',
      partySize: 1,
      now: now,
      uid: 'test-user',
      lockedPrice: 100000,
    );
    final again = await repo.plantSeatFlag(
      shopId: shopId,
      productId: 'p-size',
      partySize: 3,
      now: now,
      uid: 'test-user',
      lockedPrice: 300000,
    );
    expect(again, SeatFlagPlant.alreadyHeld);
    var product = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((item) => item.id == 'p-size');
    final hold = product.liveFlagFor('test-user', now)!;
    expect(hold.seats, 1);
    expect(hold.lockedPrice, 100000);

    final replaced = await repo.replaceSeatFlag(
      shopId: shopId,
      productId: 'p-size',
      partySize: 3,
      now: now,
      uid: 'test-user',
      lockedPrice: 300000,
    );
    expect(replaced, SeatFlagPlant.planted);
    product = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((item) => item.id == 'p-size');
    final next = product.liveFlagFor('test-user', now)!;
    expect(next.seats, 3);
    expect(next.lockedPrice, 300000);
    expect(next.expiresAt, hold.expiresAt);
    expect(product.flaggedSeatsAt(now), 3);
    expect(repo.readActiveSeatFlags('test-user'), hasLength(1));

    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Open seats p-size',
      price: 300000,
      productId: 'p-size',
      partySize: 3,
      fromFlag: true,
      divers: 3,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    expect(saved, isTrue);
    final booking = (await repo.watchBookings('test-user').first).single;
    expect(booking.partySize, 3);
    expect(booking.divers, 3);
    expect(booking.price, 300000);
    product = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((item) => item.id == 'p-size');
    expect(product.bookedSeats, 3);
  });
}
