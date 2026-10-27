import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/product_change.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  ShopProduct trip({
    required String shopId,
    required String id,
    required int price,
  }) {
    return ShopProduct(
      id: id,
      shopId: shopId,
      name: '블루홀',
      consumerPrice: price,
      professionalPrice: price,
    );
  }

  test('다이버 제안 저장은 가격이 바뀌어도 product_changes를 쓰지 않는다', () async {
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(store.uid, 'test-user');
    expect(store.stats.isAdmin, isFalse);
    expect(store.stats.isBusiness, isFalse);

    const shopId = 'curated-test-user';
    await store.saveShopProduct(
      shopId: shopId,
      product: trip(shopId: shopId, id: 'trip-1', price: 150000),
      creatorSubmission: true,
      submitterUid: store.uid,
      intent: ProductSaveIntent.submitForReview,
    );
    await store.saveShopProduct(
      shopId: shopId,
      product: trip(shopId: shopId, id: 'trip-1', price: 180000),
      creatorSubmission: true,
      submitterUid: store.uid,
      intent: ProductSaveIntent.submitForReview,
    );

    expect(await repo.listProductChanges(shopId), isEmpty);
    final shops = await repo.fetchShopStats();
    final saved = shops.singleWhere((shop) => shop.shopId == shopId);
    expect(saved.products.single.consumerPrice, 180000);
    expect(saved.products.single.publishStatus, ProductPublishStatus.pending);
  });

  test('관리자 상품 저장은 product_changes를 그대로 남긴다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);

    const shopId = AppConstants.defaultPartnerShopId;
    await store.saveShopProduct(
      shopId: shopId,
      product: trip(shopId: shopId, id: 'admin-1', price: 10000),
    );
    final history = await repo.listProductChanges(shopId);
    expect(
      history.where(
        (line) =>
            line.field == ProductChangeRecord.consumerPrice &&
            line.after == 10000,
      ),
      isNotEmpty,
    );
  });
}
