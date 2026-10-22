import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  group('ShopProduct.withGuestStarReview', () {
    test('folds stars into average and count', () {
      const product = ShopProduct(
        id: 'p1',
        shopId: 'shop-a',
        name: 'Trip',
        consumerPrice: 100,
        professionalPrice: 80,
      );

      final first = product.withGuestStarReview(5);
      expect(first.guestReviewCount, 1);
      expect(first.guestRating, 5);

      final second = first.withGuestStarReview(3);
      expect(second.guestReviewCount, 2);
      expect(second.guestRating, 4);
    });

    test('replace and remove guest stars', () {
      final product = const ShopProduct(
        id: 'p1',
        shopId: 'shop-a',
        name: 'Trip',
        consumerPrice: 100,
        professionalPrice: 80,
      ).withGuestStarReview(5).withGuestStarReview(3);
      final replaced = product.replaceGuestStarReview(5, 1);
      expect(replaced.guestReviewCount, 2);
      expect(replaced.guestRating, closeTo(2, 0.01));
      final removed = replaced.removeGuestStarReview(1);
      expect(removed.guestReviewCount, 1);
      expect(removed.guestRating, closeTo(3, 0.01));
    });

    test('also updates matching option guest averages', () {
      const product = ShopProduct(
        id: 'p1',
        shopId: 'shop-a',
        name: 'Trip',
        consumerPrice: 100,
        professionalPrice: 80,
        options: [
          ShopProductOption(
            id: 'base',
            name: 'Base',
            kind: ProductOptionKind.basePackage,
          ),
        ],
      );
      final updated = product.withGuestStarReview(5, optionId: 'base');
      expect(updated.guestReviewCount, 1);
      expect(updated.options.first.guestReviewCount, 1);
      expect(updated.options.first.guestRating, 5);
    });

    test('round-trips guest fields in toMap/fromMap', () {
      final product = const ShopProduct(
        id: 'p1',
        shopId: 'shop-a',
        name: 'Trip',
        consumerPrice: 100,
        professionalPrice: 80,
      ).withGuestStarReview(4);

      final mapped = ShopProduct.fromMap('shop-a', product.toMap());
      expect(mapped.guestReviewCount, 1);
      expect(mapped.guestRating, 4);
    });
  });

  group('MemoryDiverRepository.submitOperationReview', () {
    test('updates product guest_rating when productId is set', () async {
      final repo = MemoryDiverRepository.forTest();
      const shopId = 'shop-a';
      const product = ShopProduct(
        id: 'prod-1',
        shopId: shopId,
        name: 'Blue Trip',
        consumerPrice: 200,
        professionalPrice: 160,
      );
      await repo.saveShopProduct(shopId: shopId, product: product);
      repo.seedBooking(
        TourBooking(
          id: 'booking-1',
          uid: 'test-user',
          shopId: shopId,
          shopName: 'Shop A',
          productName: 'Blue Trip',
          productId: 'prod-1',
          price: 200,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          tourDate: DateTime.now().subtract(const Duration(days: 1)),
          status: BookingStatus.confirmed,
        ),
      );

      final outcome = await repo.submitOperationReview(
        uid: 'test-user',
        shopId: shopId,
        safety: 4,
        guide: 4,
        boat: 4,
        bookingId: 'booking-1',
        productId: 'prod-1',
        comment: 'Nice trip',
      );

      expect(outcome.productLink, ReviewProductLinkStatus.linked);
      final stats = await repo.watchShopStats().first;
      final live = stats.firstWhere((item) => item.shopId == shopId);
      expect(live.reviewCount, 1);
      expect(live.avgOverall, closeTo(4, 0.01));
      final updated = live.products.firstWhere((item) => item.id == 'prod-1');
      expect(updated.guestReviewCount, 1);
      expect(updated.guestRating, 4);
    });

    test('saves shop averages but reports missing product id', () async {
      final repo = MemoryDiverRepository.forTest();
      const shopId = 'shop-a';
      await repo.saveShopProduct(
        shopId: shopId,
        product: const ShopProduct(
          id: 'prod-1',
          shopId: shopId,
          name: 'Blue Trip',
          consumerPrice: 200,
          professionalPrice: 160,
        ),
      );
      repo.seedBooking(
        TourBooking(
          id: 'booking-2',
          uid: 'test-user',
          shopId: shopId,
          shopName: 'Shop A',
          productName: 'Blue Trip',
          productId: '',
          price: 200,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          tourDate: DateTime.now().subtract(const Duration(days: 1)),
          status: BookingStatus.confirmed,
        ),
      );

      final outcome = await repo.submitOperationReview(
        uid: 'test-user',
        shopId: shopId,
        safety: 5,
        guide: 5,
        boat: 5,
        bookingId: 'booking-2',
      );

      expect(outcome.productLink, ReviewProductLinkStatus.missingProductId);
      final stats = await repo.watchShopStats().first;
      final live = stats.firstWhere((item) => item.shopId == shopId);
      expect(live.reviewCount, 1);
      expect(live.products.first.guestReviewCount, 0);
    });

    test('reports productNotFound when id is unknown', () async {
      final repo = MemoryDiverRepository.forTest();
      const shopId = 'shop-a';
      await repo.saveShopProduct(
        shopId: shopId,
        product: const ShopProduct(
          id: 'prod-1',
          shopId: shopId,
          name: 'Blue Trip',
          consumerPrice: 200,
          professionalPrice: 160,
        ),
      );
      repo.seedBooking(
        TourBooking(
          id: 'booking-3',
          uid: 'test-user',
          shopId: shopId,
          shopName: 'Shop A',
          productName: 'Ghost',
          productId: 'missing-sku',
          price: 200,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          tourDate: DateTime.now().subtract(const Duration(days: 1)),
          status: BookingStatus.confirmed,
        ),
      );

      final outcome = await repo.submitOperationReview(
        uid: 'test-user',
        shopId: shopId,
        safety: 5,
        guide: 5,
        boat: 5,
        bookingId: 'booking-3',
        productId: 'missing-sku',
      );

      expect(outcome.productLink, ReviewProductLinkStatus.productNotFound);
      final page = await repo.fetchShopReviewsPage(shopId: shopId);
      expect(page.reviews.first.productId, 'missing-sku');
    });
  });

  group('update/delete operation review aggregates', () {
    Future<void> _seedReviewedBooking(
      MemoryDiverRepository repo, {
      required String bookingId,
      required String productId,
    }) async {
      await repo.saveShopProduct(
        shopId: 'shop-a',
        product: const ShopProduct(
          id: 'prod-1',
          shopId: 'shop-a',
          name: 'Blue Trip',
          consumerPrice: 200,
          professionalPrice: 160,
        ),
      );
      repo.seedBooking(
        TourBooking(
          id: bookingId,
          uid: 'test-user',
          shopId: 'shop-a',
          shopName: 'Shop A',
          productName: 'Blue Trip',
          productId: productId,
          price: 200,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          tourDate: DateTime.now().subtract(const Duration(days: 1)),
          status: BookingStatus.confirmed,
        ),
      );
    }

    test('별 5 → 3 수정 후 shop avg와 product guest_*가 맞는다', () async {
      final repo = MemoryDiverRepository.forTest();
      await _seedReviewedBooking(repo, bookingId: 'b-edit', productId: 'prod-1');
      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        safety: 5,
        guide: 5,
        boat: 5,
        bookingId: 'b-edit',
        productId: 'prod-1',
      );
      final mine = await repo.listMyReviews('test-user');
      final reviewId = mine.single.id;

      await repo.updateOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        reviewId: reviewId,
        safety: 3,
        guide: 3,
        boat: 3,
        comment: 'ok',
      );

      final stats = (await repo.watchShopStats().first)
          .firstWhere((item) => item.shopId == 'shop-a');
      expect(stats.reviewCount, 1);
      expect(stats.avgSafety, closeTo(3, 0.01));
      expect(stats.avgOverall, closeTo(3, 0.01));
      final product = stats.products.firstWhere((item) => item.id == 'prod-1');
      expect(product.guestReviewCount, 1);
      expect(product.guestRating, closeTo(3, 0.01));
      final updated = (await repo.listMyReviews('test-user')).single;
      expect(updated.wasEdited, isTrue);
      expect(updated.stars, 3);
    });

    test('후기 3건 중 1건 삭제하면 count와 평균이 맞는다', () async {
      final repo = MemoryDiverRepository.forTest();
      await repo.saveShopProduct(
        shopId: 'shop-a',
        product: const ShopProduct(
          id: 'prod-1',
          shopId: 'shop-a',
          name: 'Blue Trip',
          consumerPrice: 200,
          professionalPrice: 160,
        ),
      );
      for (var i = 1; i <= 3; i++) {
        repo.seedBooking(
          TourBooking(
            id: 'b-$i',
            uid: 'test-user',
            shopId: 'shop-a',
            shopName: 'Shop A',
            productName: 'Blue Trip',
            productId: 'prod-1',
            price: 200,
            createdAt: DateTime.now().subtract(Duration(days: 5 + i)),
            tourDate: DateTime.now().subtract(Duration(days: i)),
            status: BookingStatus.confirmed,
          ),
        );
        await repo.submitOperationReview(
          uid: 'test-user',
          shopId: 'shop-a',
          safety: i == 1 ? 5 : 3,
          guide: i == 1 ? 5 : 3,
          boat: i == 1 ? 5 : 3,
          bookingId: 'b-$i',
          productId: 'prod-1',
        );
      }
      final mine = await repo.listMyReviews('test-user');
      expect(mine, hasLength(3));
      final toDelete = mine.firstWhere((item) => item.bookingId == 'b-1');

      await repo.deleteOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        reviewId: toDelete.id,
      );

      final stats = (await repo.watchShopStats().first)
          .firstWhere((item) => item.shopId == 'shop-a');
      expect(stats.reviewCount, 2);
      expect(stats.avgSafety, closeTo(3, 0.01));
      final product = stats.products.firstWhere((item) => item.id == 'prod-1');
      expect(product.guestReviewCount, 2);
      expect(product.guestRating, closeTo(3, 0.01));
      final bookings = await repo.watchBookings('test-user').first;
      expect(
        bookings.firstWhere((item) => item.id == 'b-1').reviewed,
        isFalse,
      );
    });

    test('마지막 1건 삭제하면 count 0·avg 0', () async {
      final repo = MemoryDiverRepository.forTest();
      await _seedReviewedBooking(repo, bookingId: 'b-last', productId: 'prod-1');
      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        safety: 4,
        guide: 4,
        boat: 4,
        bookingId: 'b-last',
        productId: 'prod-1',
      );
      final id = (await repo.listMyReviews('test-user')).single.id;
      await repo.deleteOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        reviewId: id,
      );
      final stats = (await repo.watchShopStats().first)
          .firstWhere((item) => item.shopId == 'shop-a');
      expect(stats.reviewCount, 0);
      expect(stats.avgSafety, 0);
      expect(stats.avgOverall, 0);
      final product = stats.products.firstWhere((item) => item.id == 'prod-1');
      expect(product.guestReviewCount, 0);
      expect(product.guestRating, 0);
    });

    test('product_id 없는 후기 수정·삭제는 상품 집계를 건드리지 않는다', () async {
      final repo = MemoryDiverRepository.forTest();
      await repo.saveShopProduct(
        shopId: 'shop-a',
        product: const ShopProduct(
          id: 'prod-1',
          shopId: 'shop-a',
          name: 'Blue Trip',
          consumerPrice: 200,
          professionalPrice: 160,
        ),
      );
      repo.seedBooking(
        TourBooking(
          id: 'b-noprod',
          uid: 'test-user',
          shopId: 'shop-a',
          shopName: 'Shop A',
          productName: 'Blue Trip',
          productId: '',
          price: 200,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          tourDate: DateTime.now().subtract(const Duration(days: 1)),
          status: BookingStatus.confirmed,
        ),
      );
      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        safety: 5,
        guide: 5,
        boat: 5,
        bookingId: 'b-noprod',
      );
      final before = (await repo.watchShopStats().first)
          .firstWhere((item) => item.shopId == 'shop-a')
          .products
          .first
          .guestReviewCount;
      expect(before, 0);
      final id = (await repo.listMyReviews('test-user')).single.id;
      await repo.updateOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        reviewId: id,
        safety: 2,
        guide: 2,
        boat: 2,
      );
      var stats = (await repo.watchShopStats().first)
          .firstWhere((item) => item.shopId == 'shop-a');
      expect(stats.avgSafety, closeTo(2, 0.01));
      expect(stats.products.first.guestReviewCount, 0);
      await repo.deleteOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        reviewId: id,
      );
      stats = (await repo.watchShopStats().first)
          .firstWhere((item) => item.shopId == 'shop-a');
      expect(stats.reviewCount, 0);
      expect(stats.products.first.guestReviewCount, 0);
    });

    test('수정 후 평균 소수점 처리', () async {
      final repo = MemoryDiverRepository.forTest();
      await repo.saveShopProduct(
        shopId: 'shop-a',
        product: const ShopProduct(
          id: 'prod-1',
          shopId: 'shop-a',
          name: 'Blue Trip',
          consumerPrice: 200,
          professionalPrice: 160,
        ),
      );
      for (final id in ['b-a', 'b-b']) {
        repo.seedBooking(
          TourBooking(
            id: id,
            uid: 'test-user',
            shopId: 'shop-a',
            shopName: 'Shop A',
            productName: 'Blue Trip',
            productId: 'prod-1',
            price: 200,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            tourDate: DateTime.now().subtract(const Duration(days: 1)),
            status: BookingStatus.confirmed,
          ),
        );
      }
      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        safety: 5,
        guide: 5,
        boat: 5,
        bookingId: 'b-a',
        productId: 'prod-1',
      );
      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        safety: 4,
        guide: 4,
        boat: 4,
        bookingId: 'b-b',
        productId: 'prod-1',
      );
      final firstId =
          (await repo.listMyReviews('test-user')).firstWhere((r) => r.bookingId == 'b-a').id;
      await repo.updateOperationReview(
        uid: 'test-user',
        shopId: 'shop-a',
        reviewId: firstId,
        safety: 3,
        guide: 3,
        boat: 3,
      );
      // (3+4)/2 = 3.5
      final stats = (await repo.watchShopStats().first)
          .firstWhere((item) => item.shopId == 'shop-a');
      expect(stats.avgSafety, closeTo(3.5, 0.01));
      expect(stats.avgOverall, closeTo(3.5, 0.01));
      final product = stats.products.firstWhere((item) => item.id == 'prod-1');
      expect(product.guestRating, closeTo(3.5, 0.01));
    });
  });
}
