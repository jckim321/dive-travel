import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_product_reader.dart';

void main() {
  final hold = SeatHold(
    seats: 1,
    expiresAt: DateTime.utc(2026, 12, 1),
    uid: 'guest',
  );

  ShopProduct arrayProduct() {
    return ShopProduct(
      id: 'seat-1',
      shopId: 'shop-1',
      name: '배열 이름',
      consumerPrice: 10000,
      professionalPrice: 8000,
      openEmptySeats: true,
      capacity: 4,
      bookedSeats: 2,
      flagHolds: [hold],
      departureStart: DateTime.utc(2027, 6, 1),
      sameBoatStatus: SameBoatStatus.approved,
      options: [
        ShopProductOption(
          id: 'opt-1',
          name: '배열 옵션',
          bookedSeats: 1,
          flagHolds: [hold],
        ),
      ],
    );
  }

  ShopProduct documentProduct() {
    return ShopProduct(
      id: 'seat-1',
      shopId: 'shop-1',
      name: '문서 이름',
      consumerPrice: 90000,
      professionalPrice: 70000,
      openEmptySeats: true,
      capacity: 6,
      bookedSeats: 9,
      departureStart: DateTime.utc(2027, 6, 1),
      sameBoatStatus: SameBoatStatus.approved,
      options: [
        ShopProductOption(
          id: 'opt-1',
          name: '문서 옵션',
          consumerPrice: 5000,
          professionalPrice: 4000,
          bookedSeats: 8,
        ),
      ],
    );
  }

  test('readers use product documents and array seat counts', () {
    final read = productsForReaders(
      arrayProducts: [arrayProduct()],
      documentProducts: [documentProduct()],
    ).single;
    expect(read.name, '문서 이름');
    expect(read.consumerPrice, 90000);
    expect(read.capacity, 6);
    expect(read.bookedSeats, 2);
    expect(read.flagHolds.single.uid, 'guest');
    expect(read.options.single.name, '문서 옵션');
    expect(read.options.single.bookedSeats, 1);
    expect(read.options.single.flagHolds.single.uid, 'guest');
    expect(read.listsOnSameBoat, isTrue);
  });

  test('a shop with no product documents keeps the array', () {
    final array = arrayProduct();
    final read = productsForReaders(
      arrayProducts: [array],
      documentProducts: const [],
    );
    expect(read.single.name, '배열 이름');
    expect(read.single.bookedSeats, 2);
  });

  test('empty-seat documents stay off the resort shelf and on same boat', () {
    final read = productsForReaders(
      arrayProducts: [
        arrayProduct(),
        const ShopProduct(
          id: 'fun-1',
          shopId: 'shop-1',
          name: '일반 상품',
          consumerPrice: 150000,
          professionalPrice: 120000,
        ),
      ],
      documentProducts: [
        documentProduct(),
        const ShopProduct(
          id: 'fun-1',
          shopId: 'shop-1',
          name: '일반 문서',
          consumerPrice: 150000,
          professionalPrice: 120000,
        ),
      ],
    );
    expect(
      read.where(isCustomerShelfProduct).map((product) => product.name),
      ['일반 문서'],
    );
    expect(
      SameBoatBoard.offers(read).map((offer) => offer.product.name),
      ['문서 이름'],
    );
  });

  test('memory fetch reads documents and leaves array seats in place', () async {
    const shopId = 'reader-shop';
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProfile(
      shopId: shopId,
      name: '리조트',
      location: '팡라오',
      productName: '리조트',
      consumerPrice: 1,
      professionalPrice: 1,
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: ShopProduct(
        id: 'seat-1',
        shopId: shopId,
        name: '배열 이름',
        consumerPrice: 10000,
        professionalPrice: 8000,
        openEmptySeats: true,
        capacity: 4,
        bookedSeats: 2,
        flagHolds: [hold],
        departureStart: DateTime.utc(2027, 6, 1),
        sameBoatStatus: SameBoatStatus.approved,
      ),
    );
    repo.debugSetProductDoc(shopId, 'seat-1', {
      'name': '문서 이름',
      'consumer_price': 90000,
      'professional_price': 70000,
      'open_empty_seats': true,
      'capacity': 6,
      'booked_seats': 9,
      'departure_start': DateTime.utc(2027, 6, 1).toIso8601String(),
      'same_boat_status': SameBoatStatus.approved.firestoreValue,
      'publish_status': ProductPublishStatus.approved.firestoreValue,
      'active': true,
    });

    final stats = await repo.fetchShopStat(shopId);
    expect(stats!.products.single.name, '배열 이름');
    expect(stats.products.single.bookedSeats, 2);
    expect(stats.readerProducts.single.name, '문서 이름');
    expect(stats.readerProducts.single.consumerPrice, 90000);
    expect(stats.readerProducts.single.bookedSeats, 2);
    expect(stats.readerProducts.single.flagHolds.single.uid, 'guest');
    expect(stats.readerProducts.single.listsOnSameBoat, isTrue);
  });
}
