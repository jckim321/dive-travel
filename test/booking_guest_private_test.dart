import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';

void main() {
  test('예약자 연락처·생년월일은 본인 예약에만 있고 샵 복사본에는 이름만 있다', () async {
    final repo = MemoryDiverRepository.forTest();
    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: 'hull',
      shopName: '샵',
      productName: '상품',
      price: 50000,
      guestDisplayName: '김다이버',
      guestBirthDate: '1990-05-06',
      guestContact: '010-1234-5678',
    );
    expect(saved, isTrue);

    final user = await repo.watchBookings('test-user').first;
    final shop = await repo.fetchShopBookings('hull');
    expect(user.single.price, 50000);
    expect(shop.single.price, 50000);
    expect(user.single.guestDisplayName, '김다이버');
    expect(user.single.guestBirthDate, '1990-05-06');
    expect(user.single.guestContact, '010-1234-5678');
    expect(shop.single.guestDisplayName, '김다이버');
    expect(shop.single.guestBirthDate, isEmpty);
    expect(shop.single.guestContact, isEmpty);

    await repo.cancelBookingAsGuest(
      uid: 'test-user',
      bookingId: user.single.id,
    );
    final userAfter = await repo.watchBookings('test-user').first;
    final shopAfter = await repo.fetchShopBookings('hull');
    expect(userAfter.single.guestBirthDate, '1990-05-06');
    expect(userAfter.single.guestContact, '010-1234-5678');
    expect(shopAfter.single.guestDisplayName, '김다이버');
    expect(shopAfter.single.guestBirthDate, isEmpty);
    expect(shopAfter.single.guestContact, isEmpty);
  });
}
