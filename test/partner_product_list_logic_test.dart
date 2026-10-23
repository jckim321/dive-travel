import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';

ShopProduct _product({
  required String id,
  ProductPublishStatus publish = ProductPublishStatus.approved,
  bool active = true,
  int consumerPrice = 100000,
  SameBoatStatus sameBoat = SameBoatStatus.closed,
  bool openEmptySeats = false,
  int capacity = 0,
  DateTime? departure,
}) {
  return ShopProduct(
    id: id,
    shopId: 'shop-a',
    name: id,
    consumerPrice: consumerPrice,
    professionalPrice: consumerPrice,
    active: active,
    publishStatus: publish,
    sameBoatStatus: sameBoat,
    openEmptySeats: openEmptySeats,
    capacity: capacity,
    departureStart: departure,
  );
}

void main() {
  group('partnerPublishBadgeKind', () {
    test('pending / rejected / listed / closed', () {
      expect(
        partnerPublishBadgeKind(
          _product(id: 'p', publish: ProductPublishStatus.pending, active: false),
        ),
        PartnerPublishBadgeKind.pending,
      );
      expect(
        partnerPublishBadgeKind(
          _product(id: 'r', publish: ProductPublishStatus.rejected, active: false),
        ),
        PartnerPublishBadgeKind.rejected,
      );
      expect(
        partnerPublishBadgeKind(_product(id: 'live')),
        PartnerPublishBadgeKind.listed,
      );
      expect(
        partnerPublishBadgeKind(
          _product(id: 'down', active: false),
        ),
        PartnerPublishBadgeKind.closed,
      );
      expect(
        partnerPublishBadgeKind(
          _product(id: 'draft', publish: ProductPublishStatus.draft, active: false),
        ),
        PartnerPublishBadgeKind.closed,
      );
    });
  });

  group('partnerSameBoatLineKind', () {
    test('precedence pending → live → rejected → not opened', () {
      expect(
        partnerSameBoatLineKind(
          _product(id: 'a', sameBoat: SameBoatStatus.pending, openEmptySeats: true),
        ),
        PartnerSameBoatLineKind.pendingReview,
      );
      expect(
        partnerSameBoatLineKind(
          _product(
            id: 'b',
            sameBoat: SameBoatStatus.approved,
            openEmptySeats: true,
            capacity: 10,
            departure: DateTime(2026, 11, 1),
          ),
        ),
        PartnerSameBoatLineKind.liveOpen,
      );
      expect(
        partnerSameBoatLineKind(
          _product(id: 'c', sameBoat: SameBoatStatus.rejected),
        ),
        PartnerSameBoatLineKind.rejected,
      );
      expect(
        partnerSameBoatLineKind(_product(id: 'd')),
        PartnerSameBoatLineKind.notOpened,
      );
    });
  });

  group('seats + price', () {
    test('seats enabled only when listed publicly', () {
      expect(partnerSeatsActionEnabled(_product(id: 'ok')), isTrue);
      expect(
        partnerSeatsActionEnabled(
          _product(id: 'pend', publish: ProductPublishStatus.pending, active: false),
        ),
        isFalse,
      );
      expect(
        partnerSeatsActionEnabled(_product(id: 'down', active: false)),
        isFalse,
      );
    });

    test('manage when any same-boat open activity', () {
      expect(partnerSeatsIsManage(_product(id: 'closed')), isFalse);
      expect(
        partnerSeatsIsManage(
          _product(id: 'open', openEmptySeats: true, sameBoat: SameBoatStatus.pending),
        ),
        isTrue,
      );
    });

    test('price missing when consumerPrice <= 0', () {
      expect(partnerPriceMissing(_product(id: 'ok')), isFalse);
      expect(
        partnerPriceMissing(_product(id: 'zero', consumerPrice: 0)),
        isTrue,
      );
    });
  });

  group('filter counts + list', () {
    final products = [
      _product(id: 'pending', publish: ProductPublishStatus.pending, active: false),
      _product(id: 'listed'),
      _product(id: 'closed', active: false),
      _product(id: 'rejected', publish: ProductPublishStatus.rejected, active: false),
      _product(id: 'draft', publish: ProductPublishStatus.draft, active: false),
    ];

    test('counts: all includes closed/draft; listed is isListedPublicly only', () {
      final counts = partnerProductFilterCounts(products);
      expect(counts.all, 5);
      expect(counts.pending, 1);
      expect(counts.listed, 1);
      expect(counts.rejected, 1);
    });

    test('filter listed excludes approved+inactive', () {
      final listed = filterPartnerProducts(
        products: products,
        filter: PartnerProductStatusFilter.listed,
      );
      expect(listed.map((p) => p.id), ['listed']);
    });

    test('filter pending / rejected / all', () {
      expect(
        filterPartnerProducts(
          products: products,
          filter: PartnerProductStatusFilter.pending,
        ).single.id,
        'pending',
      );
      expect(
        filterPartnerProducts(
          products: products,
          filter: PartnerProductStatusFilter.rejected,
        ).single.id,
        'rejected',
      );
      expect(
        filterPartnerProducts(
          products: products,
          filter: PartnerProductStatusFilter.all,
        ).length,
        5,
      );
    });
  });
}
