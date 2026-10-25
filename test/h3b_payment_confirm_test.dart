import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  const shopId = AppConstants.defaultPartnerShopId;

  Future<MemoryDiverRepository> seededSeats({
    required String productId,
    int capacity = 4,
  }) async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: shopId,
      product: ShopProduct(
        id: productId,
        shopId: shopId,
        name: 'Open',
        consumerPrice: 100000,
        professionalPrice: 70000,
        openEmptySeats: true,
        capacity: capacity,
        sameBoatStatus: SameBoatStatus.approved,
        listingKind: ProductListingKind.diverPlanned,
        publishStatus: ProductPublishStatus.approved,
      ),
    );
    return repo;
  }

  Future<int> purchaseCount(MemoryDiverRepository repo) async {
    final snap = await repo.watchDiver('test-user').first;
    return snap.stats.paidPurchaseCount;
  }

  group('resolveGuestDisplayName', () {
    test('uses real profile/auth name only; never email local-part', () {
      expect(
        resolveGuestDisplayName(
          authDisplayName: 'Jongcheol',
          email: 'jong@dive.local',
        ),
        'Jongcheol',
      );
      expect(
        resolveGuestDisplayName(
          profileDisplayName: '파트너님',
          email: 'a@b.c',
        ),
        '파트너님',
      );
      expect(
        resolveGuestDisplayName(
          authDisplayName: 'jong',
          email: 'jong@dive.local',
        ),
        '',
      );
      expect(
        resolveGuestDisplayName(
          profileDisplayName: '다이버',
          email: 'x@y.z',
        ),
        '',
      );
      expect(
        resolveGuestDisplayName(authDisplayName: '', email: 'x@y.z'),
        '',
      );
    });
  });

  test('createBooking defaults stay requested/unpaid; checkout can pass confirmed',
      () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Default',
      price: 1,
    );
    final unpaid = (await repo.watchBookings('test-user').first).first;
    expect(unpaid.status, BookingStatus.requested);
    expect(unpaid.paymentStatus, PaymentStatus.unpaid);
    expect(unpaid.awaitsShopConfirm, isTrue);

    await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Paid',
      price: 1,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
      guestDisplayName: '손님',
    );
    final paid = (await repo.watchBookings('test-user').first)
        .firstWhere((b) => b.productName == 'Paid');
    expect(paid.status, BookingStatus.confirmed);
    expect(paid.paymentStatus, PaymentStatus.captured);
    expect(paid.awaitsShopConfirm, isFalse);
    expect(paid.guestDisplayName, '손님');
  });

  test(
      'cancelBookingAsGuest after auto-confirm restores seats and refunds',
      () async {
    final repo = await seededSeats(productId: 'p-h3b-cancel');
    final tour = DateTime.now().add(const Duration(days: 14));
    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Paid seats',
      price: 200000,
      tourDate: tour,
      productId: 'p-h3b-cancel',
      partySize: 2,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    expect(saved, isTrue);
    var stats = await repo.fetchShopStat(shopId);
    expect(
      stats!.products.singleWhere((p) => p.id == 'p-h3b-cancel').bookedSeats,
      2,
    );
    final booking = (await repo.watchBookings('test-user').first).first;
    expect(booking.seatsHeld, 2);
    expect(booking.isPaid, isTrue);

    await repo.cancelBookingAsGuest(uid: 'test-user', bookingId: booking.id);
    final after = (await repo.watchBookings('test-user').first).first;
    expect(after.status, BookingStatus.cancelled);
    expect(after.paymentStatus, PaymentStatus.refunded);
    expect(after.refundPercent, 100);
    expect(after.seatsHeld, 0);
    stats = await repo.fetchShopStat(shopId);
    expect(
      stats!.products.singleWhere((p) => p.id == 'p-h3b-cancel').bookedSeats,
      0,
    );
  });

  test('purchase bump once after dual write; mid-fail and retry stay correct',
      () async {
    final repo = MemoryDiverRepository.forTest();
    expect(await purchaseCount(repo), 0);

    // Mid-fail: user copy rolled back, no shop copy, no bump.
    repo.debugFailBeforeShopBookingWrite = true;
    final failed = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Fail',
      price: 1,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    expect(failed, isFalse);
    expect(await repo.watchBookings('test-user').first, isEmpty);
    expect(await purchaseCount(repo), 0);

    // Retry succeeds → bump exactly once.
    final ok = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Ok',
      price: 1,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    expect(ok, isTrue);
    expect(await purchaseCount(repo), 1);

    // Second paid create → +1 again (new booking).
    await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Ok2',
      price: 1,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    expect(await purchaseCount(repo), 2);

    // Unpaid default create does not bump; confirm bumps once.
    await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Legacy',
      price: 1,
    );
    expect(await purchaseCount(repo), 2);
    final legacy = (await repo.watchBookings('test-user').first)
        .firstWhere((b) => b.productName == 'Legacy');
    final confirmed = await repo.confirmShopBooking(
      shopId: shopId,
      bookingId: legacy.id,
    );
    expect(confirmed, isTrue);
    expect(await purchaseCount(repo), 3);

    // Confirm again / already-captured booking does not double-bump.
    final again = await repo.confirmShopBooking(
      shopId: shopId,
      bookingId: legacy.id,
    );
    expect(again, isFalse);
    expect(await purchaseCount(repo), 3);

    final paidId = (await repo.watchBookings('test-user').first)
        .firstWhere((b) => b.productName == 'Ok')
        .id;
    final noop = await repo.confirmShopBooking(
      shopId: shopId,
      bookingId: paidId,
    );
    expect(noop, isFalse);
    expect(await purchaseCount(repo), 3);
  });
}
