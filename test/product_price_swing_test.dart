import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/product_price_swing.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _base({
  int consumer = 100000,
  int professional = 80000,
  List<GuestRate> guestRates = const [],
  List<ShopProductOption> options = const [],
}) {
  return ShopProduct(
    id: 'p1',
    shopId: 'shop-a',
    name: 'Trip',
    consumerPrice: consumer,
    professionalPrice: professional,
    guestRates: guestRates,
    options: options,
    active: true,
    publishStatus: ProductPublishStatus.approved,
  );
}

void main() {
  group('ProductPriceSwingGate', () {
    test('no confirm under 30%', () {
      final prev = _base(consumer: 100000);
      final next = _base(consumer: 129000);
      expect(
        ProductPriceSwingGate.needsConfirm(previous: prev, next: next),
        isFalse,
      );
    });

    test('confirm at ±30% base consumer', () {
      final prev = _base(consumer: 100000);
      final next = _base(consumer: 130000);
      final swings = ProductPriceSwingGate.findSwings(previous: prev, next: next);
      expect(swings, isNotEmpty);
      expect(swings.first.labelKey, 'base_consumer');
    });

    test('covers professional, guest_rates, and options', () {
      final prev = _base(
        consumer: 100000,
        professional: 80000,
        guestRates: const [
          GuestRate(
            role: GuestRole.nondiver,
            enabled: true,
            consumer: 50000,
            professional: 40000,
          ),
          GuestRate(
            role: GuestRole.child,
            enabled: true,
            consumer: 30000,
            professional: 20000,
          ),
        ],
        options: const [
          ShopProductOption(
            id: 'opt-a',
            name: 'Nitrox',
            consumerPrice: 20000,
            professionalPrice: 15000,
          ),
        ],
      );
      final next = _base(
        consumer: 100000,
        professional: 120000,
        guestRates: const [
          GuestRate(
            role: GuestRole.nondiver,
            enabled: true,
            consumer: 80000,
            professional: 40000,
          ),
          GuestRate(
            role: GuestRole.child,
            enabled: true,
            consumer: 30000,
            professional: 40000,
          ),
        ],
        options: const [
          ShopProductOption(
            id: 'opt-a',
            name: 'Nitrox',
            consumerPrice: 40000,
            professionalPrice: 15000,
          ),
        ],
      );
      final keys = ProductPriceSwingGate.findSwings(previous: prev, next: next)
          .map((s) => s.labelKey)
          .toSet();
      expect(keys.contains('base_professional'), isTrue);
      expect(keys.contains('guest_nondiver_consumer'), isTrue);
      expect(keys.contains('guest_child_professional'), isTrue);
      expect(keys.contains('option_opt-a_consumer'), isTrue);
    });
  });
}
