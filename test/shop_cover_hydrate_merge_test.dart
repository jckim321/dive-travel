import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  group('mergeHydratedShopCovers', () {
    test('(a) customer covers: shop + product cover URLs are applied', () {
      final current = ShopLiveStats(
        shopId: 'shop-a',
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
        coverUrl: 'https://cdn.example/old-shop.jpg',
        galleryUrls: const ['https://cdn.example/old-g.jpg'],
        products: [
          ShopProduct(
            id: 'p1',
            shopId: 'shop-a',
            name: '패키지',
            consumerPrice: 100000,
            professionalPrice: 100000,
            coverUrl: 'https://cdn.example/old-p.jpg',
          ),
        ],
      );
      final hydrated = ShopLiveStats(
        shopId: 'shop-a',
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
        coverUrl: 'https://cdn.example/readable-shop.jpg',
        galleryUrls: const ['https://cdn.example/readable-g.jpg'],
        products: [
          ShopProduct(
            id: 'p1',
            shopId: 'shop-a',
            name: '패키지',
            consumerPrice: 100000,
            professionalPrice: 100000,
            coverUrl: 'https://cdn.example/readable-p.jpg',
          ),
        ],
      );

      final merged = mergeHydratedShopCovers(
        current: [current],
        hydratedCovers: [hydrated],
      ).single;

      expect(merged.coverUrl, 'https://cdn.example/readable-shop.jpg');
      expect(merged.galleryUrls, ['https://cdn.example/readable-g.jpg']);
      expect(
        merged.products.single.coverUrl,
        'https://cdn.example/readable-p.jpg',
      );
    });

    test('(b) late hydrate keeps seats / same-boat / closed (active)', () {
      final current = ShopLiveStats(
        shopId: 'shop-a',
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
        coverUrl: 'https://cdn.example/shop.jpg',
        products: [
          ShopProduct(
            id: 'p1',
            shopId: 'shop-a',
            name: '패키지',
            consumerPrice: 100000,
            professionalPrice: 100000,
            active: false,
            publishStatus: ProductPublishStatus.approved,
            openEmptySeats: true,
            sameBoatStatus: SameBoatStatus.approved,
            capacity: 10,
            bookedSeats: 3,
            departureStart: DateTime(2026, 12, 1),
            flagHolds: [
              SeatHold(
                seats: 1,
                expiresAt: DateTime(2026, 12, 2),
              ),
            ],
            coverUrl: 'https://cdn.example/p.jpg',
          ),
        ],
      );
      // Stale snapshot from before open/close: no seats, still active.
      final hydrated = ShopLiveStats(
        shopId: 'shop-a',
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
        coverUrl: 'https://cdn.example/readable-shop.jpg',
        products: [
          ShopProduct(
            id: 'p1',
            shopId: 'shop-a',
            name: '패키지',
            consumerPrice: 100000,
            professionalPrice: 100000,
            active: true,
            publishStatus: ProductPublishStatus.approved,
            openEmptySeats: false,
            sameBoatStatus: SameBoatStatus.closed,
            capacity: 0,
            bookedSeats: 0,
            coverUrl: 'https://cdn.example/readable-p.jpg',
          ),
        ],
      );

      final product = mergeHydratedShopCovers(
        current: [current],
        hydratedCovers: [hydrated],
      ).single.products.single;

      expect(product.coverUrl, 'https://cdn.example/readable-p.jpg');
      expect(product.active, isFalse);
      expect(product.openEmptySeats, isTrue);
      expect(product.sameBoatStatus, SameBoatStatus.approved);
      expect(product.capacity, 10);
      expect(product.bookedSeats, 3);
      expect(product.flagHolds, isNotEmpty);
      expect(product.departureStart, DateTime(2026, 12, 1));
    });

    test('does not re-add shops missing from current', () {
      final current = ShopLiveStats(
        shopId: 'keep',
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
      );
      final hydrated = [
        current.copyWith(coverUrl: 'https://cdn.example/a.jpg'),
        ShopLiveStats(
          shopId: 'ghost',
          reviewCount: 0,
          avgSafety: 0,
          avgGuide: 0,
          avgBoat: 0,
          avgOverall: 0,
          diveStar: 0,
          coverUrl: 'https://cdn.example/ghost.jpg',
        ),
      ];
      final merged = mergeHydratedShopCovers(
        current: [current],
        hydratedCovers: hydrated,
      );
      expect(merged.map((s) => s.shopId), ['keep']);
      expect(merged.single.coverUrl, 'https://cdn.example/a.jpg');
    });
  });
}
