import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  final shopId = AppConstants.defaultPartnerShopId;

  Future<DiverStore> partnerStore() async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: shopId,
    );
    final store = DiverStore(repo);
    await repo.signIn(email: 'partner@dive.local', password: 'test');
    await pumpEventQueue();
    return store;
  }

  test('close after concurrent booking keeps booked_seats from latest', () async {
    final store = await partnerStore();
    final product = ShopProduct(
      id: 'seat-safe-1',
      shopId: shopId,
      name: '패키지',
      consumerPrice: 100000,
      professionalPrice: 100000,
      active: true,
      publishStatus: ProductPublishStatus.approved,
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      capacity: 10,
      bookedSeats: 0,
      departureStart: DateTime(2026, 12, 1),
    );
    await store.saveShopProduct(
      shopId: shopId,
      product: product,
      intent: ProductSaveIntent.preserveListing,
    );

    // Simulate another client booking while list UI still holds bookedSeats:0.
    final mid = store.productsForShop(shopId).single;
    await store.saveShopProduct(
      shopId: shopId,
      product: mid.copyWith(bookedSeats: 3),
      intent: ProductSaveIntent.preserveListing,
    );

    // Stale UI would have bookedSeats:0 — patch API must refresh first.
    await store.setPartnerProductActive(
      shopId: shopId,
      productId: product.id,
      active: false,
    );

    final after = store.productsForShop(shopId).single;
    expect(after.active, isFalse);
    expect(after.bookedSeats, 3);
    expect(after.sameBoatStatus, SameBoatStatus.approved);
    expect(after.capacity, 10);
  });

  test('discard option after hold keeps flag_holds; closes when committed', () async {
    final store = await partnerStore();
    final hold = SeatHold(
      seats: 2,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final product = ShopProduct(
      id: 'seat-safe-2',
      shopId: shopId,
      name: '패키지',
      consumerPrice: 100000,
      professionalPrice: 100000,
      active: true,
      publishStatus: ProductPublishStatus.approved,
      options: [
        ShopProductOption(
          id: 'opt-a',
          name: '픽업',
          kind: ProductOptionKind.addon,
          consumerPrice: 20000,
          professionalPrice: 20000,
          bookedSeats: 1,
          flagHolds: [hold],
        ),
        ShopProductOption(
          id: 'opt-b',
          name: '렌탈',
          kind: ProductOptionKind.addon,
          consumerPrice: 10000,
          professionalPrice: 10000,
        ),
      ],
    );
    await store.saveShopProduct(
      shopId: shopId,
      product: product,
      intent: ProductSaveIntent.preserveListing,
    );

    final closed = await store.discardPartnerOption(
      shopId: shopId,
      productId: product.id,
      optionId: 'opt-a',
    );
    expect(closed, PartnerOptionDiscardResult.closed);

    final afterClose = store.productsForShop(shopId).single;
    final optA = afterClose.options.firstWhere((o) => o.id == 'opt-a');
    expect(optA.bookable, isFalse);
    expect(optA.bookedSeats, 1);
    expect(optA.flagHolds, isNotEmpty);

    final deleted = await store.discardPartnerOption(
      shopId: shopId,
      productId: product.id,
      optionId: 'opt-b',
    );
    expect(deleted, PartnerOptionDiscardResult.deleted);
    expect(
      store.productsForShop(shopId).single.options.any((o) => o.id == 'opt-b'),
      isFalse,
    );
  });

  test('admin→partner overlay can close and reopen', () async {
    final store = await partnerStore();
    await store.saveShopProduct(
      shopId: shopId,
      product: ShopProduct(
        id: 'active-1',
        shopId: shopId,
        name: '라이브',
        consumerPrice: 90000,
        professionalPrice: 90000,
        active: true,
        publishStatus: ProductPublishStatus.approved,
      ),
      intent: ProductSaveIntent.submitForReview,
    );
    await store.setPartnerProductActive(
      shopId: shopId,
      productId: 'active-1',
      active: false,
    );
    expect(store.productsForShop(shopId).single.active, isFalse);
    await store.setPartnerProductActive(
      shopId: shopId,
      productId: 'active-1',
      active: true,
    );
    expect(store.productsForShop(shopId).single.isListedPublicly, isTrue);
  });
}
