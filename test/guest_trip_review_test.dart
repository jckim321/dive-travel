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
}
