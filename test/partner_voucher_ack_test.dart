import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
void main() {
  final shopId = AppConstants.defaultPartnerShopId;

  test('repo ackPartnerBooking sets partner_acked_at', () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.createBooking(
      uid: 'guest-1',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Pkg',
      price: 100000,
      divers: 2,
    );
    final before = (await repo.fetchShopBookings(shopId)).single;
    expect(before.partnerAcked, isFalse);

    await repo.ackPartnerBooking(shopId: shopId, bookingId: before.id);
    final after = (await repo.fetchShopBookings(shopId)).single;
    expect(after.partnerAcked, isTrue);
    expect(after.partnerAckedAt, isNotNull);
  });

  test('store ackPartnerBooking updates shopBookings stream', () async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: shopId,
    );
    final store = DiverStore(repo);
    await repo.signIn(email: 'partner@dive.local', password: 'test');
    await pumpEventQueue();

    await repo.createBooking(
      uid: 'guest-1',
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Pkg',
      price: 90000,
      divers: 1,
    );
    await pumpEventQueue();

    expect(store.shopBookings, isNotEmpty);
    final id = store.shopBookings.first.id;
    expect(store.shopBookings.first.partnerAcked, isFalse);

    await store.ackPartnerBooking(shopId: shopId, bookingId: id);
    await pumpEventQueue();

    expect(
      store.shopBookings.firstWhere((b) => b.id == id).partnerAcked,
      isTrue,
    );
  });
}
