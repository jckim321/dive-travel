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
    test('drafting / listed / closed (H1a)', () {
      expect(
        partnerPublishBadgeKind(
          _product(id: 'p', publish: ProductPublishStatus.pending, active: false),
        ),
        PartnerPublishBadgeKind.drafting,
      );
      expect(
        partnerPublishBadgeKind(
          _product(id: 'r', publish: ProductPublishStatus.rejected, active: false),
        ),
        PartnerPublishBadgeKind.drafting,
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
        PartnerPublishBadgeKind.drafting,
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

    test('rejected actions never shown (H1a)', () {
      expect(partnerShowRejectedActions(_product(id: 'live')), isFalse);
      expect(
        partnerShowRejectedActions(
          _product(
            id: 'rej',
            publish: ProductPublishStatus.rejected,
            active: false,
          ),
        ),
        isFalse,
      );
    });

    test('live summary uses remaining seats and departure', () {
      final live = _product(
        id: 'live',
        sameBoat: SameBoatStatus.approved,
        openEmptySeats: true,
        capacity: 10,
        departure: DateTime(2026, 11, 15),
      );
      final summary = partnerSameBoatLiveSummary(live);
      expect(summary.seats, 10);
      expect(summary.departure, DateTime(2026, 11, 15));
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

    test('counts: drafting folds pending/rejected/draft; listed is public only', () {
      final counts = partnerProductFilterCounts(products);
      expect(counts.all, 5);
      expect(counts.drafting, 3);
      expect(counts.listed, 1);
      expect(counts.closed, 1);
    });

    test('filter listed excludes approved+inactive', () {
      final listed = filterPartnerProducts(
        products: products,
        filter: PartnerProductStatusFilter.listed,
      );
      expect(listed.map((p) => p.id), ['listed']);
    });

    test('filter drafting / closed / all', () {
      expect(
        filterPartnerProducts(
          products: products,
          filter: PartnerProductStatusFilter.drafting,
        ).map((p) => p.id).toSet(),
        {'pending', 'rejected', 'draft'},
      );
      expect(
        filterPartnerProducts(
          products: products,
          filter: PartnerProductStatusFilter.closed,
        ).single.id,
        'closed',
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

  group('close warning + lines', () {
    test('needs close warning for live same-boat or holds', () {
      final now = DateTime(2026, 10, 1);
      expect(
        partnerNeedsCloseSeatWarning(_product(id: 'plain'), now: now),
        isFalse,
      );
      expect(
        partnerNeedsCloseSeatWarning(
          _product(
            id: 'live',
            sameBoat: SameBoatStatus.approved,
            openEmptySeats: true,
            capacity: 5,
            departure: DateTime(2026, 11, 1),
          ),
          now: now,
        ),
        isTrue,
      );
      expect(
        partnerNeedsCloseSeatWarning(
          ShopProduct(
            id: 'hold',
            shopId: 'shop-a',
            name: 'hold',
            consumerPrice: 1,
            professionalPrice: 1,
            active: true,
            publishStatus: ProductPublishStatus.approved,
            flagHolds: [
              SeatHold(
                seats: 2,
                expiresAt: now.add(const Duration(hours: 1)),
              ),
            ],
          ),
          now: now,
        ),
        isTrue,
      );
    });

    test('close warning seat count sums live + holds', () {
      final now = DateTime(2026, 10, 1);
      final product = ShopProduct(
        id: 'sum',
        shopId: 'shop-a',
        name: 'sum',
        consumerPrice: 1,
        professionalPrice: 1,
        active: true,
        publishStatus: ProductPublishStatus.approved,
        openEmptySeats: true,
        sameBoatStatus: SameBoatStatus.approved,
        capacity: 10,
        bookedSeats: 2,
        departureStart: DateTime(2026, 11, 1),
        flagHolds: [
          SeatHold(seats: 1, expiresAt: now.add(const Duration(hours: 1))),
        ],
      );
      expect(partnerCloseWarningSeatCount(product, now: now), 9);
    });

    test('common addons exclude nested; individuals by kind', () {
      final product = ShopProduct(
        id: 'p',
        shopId: 'shop-a',
        name: 'p',
        consumerPrice: 1,
        professionalPrice: 1,
        options: [
          ShopProductOption(
            id: 'ind',
            name: '원데이',
            kind: ProductOptionKind.individual,
            consumerPrice: 1,
            professionalPrice: 1,
          ),
          ShopProductOption(
            id: 'add',
            name: '픽업',
            kind: ProductOptionKind.addon,
            consumerPrice: 1,
            professionalPrice: 1,
          ),
          ShopProductOption(
            id: 'nested',
            name: '중첩',
            kind: ProductOptionKind.addon,
            parentOptionId: 'ind',
            consumerPrice: 1,
            professionalPrice: 1,
          ),
        ],
      );
      expect(partnerIndividualOptions(product).single.id, 'ind');
      expect(partnerCommonAddons(product).single.id, 'add');
    });
  });
}
