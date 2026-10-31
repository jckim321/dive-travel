import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const shopId = 'shop-a';

  ShopProduct product({int consumerPrice = 100000}) {
    return ShopProduct(
      id: 'fun-dive',
      shopId: shopId,
      name: '펀다이빙',
      consumerPrice: consumerPrice,
      professionalPrice: 80000,
    );
  }

  test('writes the product document and then the shop array', () async {
    final repo = MemoryDiverRepository();
    await repo.saveShopProduct(shopId: shopId, product: product());

    expect(repo.readProductDoc(shopId, 'fun-dive')?['consumer_price'], 100000);
    final shop = await repo.fetchShopStat(shopId);
    expect(shop?.products.single.consumerPrice, 100000);
  });

  test('leaves the shop array unchanged when the product document write fails',
      () async {
    final repo = MemoryDiverRepository();
    await repo.saveShopProduct(shopId: shopId, product: product());
    repo.debugFailProductDocWrite = true;

    await expectLater(
      repo.saveShopProduct(
        shopId: shopId,
        product: product(consumerPrice: 200000),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'PRODUCT_DOC_WRITE_FAILED',
        ),
      ),
    );

    expect(repo.readProductDoc(shopId, 'fun-dive')?['consumer_price'], 100000);
    final shop = await repo.fetchShopStat(shopId);
    expect(shop?.products.single.consumerPrice, 100000);
  });

  test('deletes the product document before the shop array', () async {
    final repo = MemoryDiverRepository();
    await repo.saveShopProduct(shopId: shopId, product: product());
    await repo.deleteShopProduct(shopId: shopId, productId: 'fun-dive');

    expect(repo.readProductDoc(shopId, 'fun-dive'), isNull);
    final shop = await repo.fetchShopStat(shopId);
    expect(shop?.products, isEmpty);
  });

  test('leaves the shop array when the product document delete fails', () async {
    final repo = MemoryDiverRepository();
    await repo.saveShopProduct(shopId: shopId, product: product());
    repo.debugFailProductDocWrite = true;

    await expectLater(
      repo.deleteShopProduct(shopId: shopId, productId: 'fun-dive'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'PRODUCT_DOC_WRITE_FAILED',
        ),
      ),
    );

    expect(repo.readProductDoc(shopId, 'fun-dive')?['consumer_price'], 100000);
    final shop = await repo.fetchShopStat(shopId);
    expect(shop?.products, hasLength(1));
  });

  test('updates the product document before the shop array publish status',
      () async {
    final repo = MemoryDiverRepository();
    await repo.saveShopProduct(shopId: shopId, product: product());
    await repo.setShopProductPublishStatus(
      shopId: shopId,
      productId: 'fun-dive',
      status: ProductPublishStatus.draft,
    );

    expect(repo.readProductDoc(shopId, 'fun-dive')?['publish_status'], 'draft');
    final shop = await repo.fetchShopStat(shopId);
    expect(shop?.products.single.publishStatus, ProductPublishStatus.draft);
  });

  test('leaves publish status on the array when the product document write fails',
      () async {
    final repo = MemoryDiverRepository();
    await repo.saveShopProduct(shopId: shopId, product: product());
    repo.debugFailProductDocWrite = true;

    await expectLater(
      repo.setShopProductPublishStatus(
        shopId: shopId,
        productId: 'fun-dive',
        status: ProductPublishStatus.draft,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'PRODUCT_DOC_WRITE_FAILED',
        ),
      ),
    );

    expect(
      repo.readProductDoc(shopId, 'fun-dive')?['publish_status'],
      'approved',
    );
    final shop = await repo.fetchShopStat(shopId);
    expect(shop?.products.single.publishStatus, ProductPublishStatus.approved);
  });
}
