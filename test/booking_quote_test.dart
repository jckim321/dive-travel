import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  test('empty guestRates still expose diver, nondiver, and child', () {
    const product = ShopProduct(
      id: 'p1',
      shopId: 's1',
      name: 'Trip',
      consumerPrice: 100,
      professionalPrice: 80,
    );
    final roles = [for (final rate in product.resolvedGuestRates) rate.role];
    expect(roles, containsAll([GuestRole.diver, GuestRole.nondiver, GuestRole.child]));
    expect(roles, isNot(contains(GuestRole.infant)));
    final quote = BookingQuote.compute(
      product: product,
      professional: false,
      divers: 2,
      nondivers: 1,
      children: 1,
      infants: 0,
      bookPackage: true,
      selectedOptionIds: {},
    );
    expect(quote.total, 200);
  });

  test('FOC 10+1 grants one free diver per eleven', () {
    expect(
      BookingQuote.freeCount(guests: 11, focPay: 10, focFree: 1),
      1,
    );
    expect(
      BookingQuote.freeCount(guests: 10, focPay: 10, focFree: 1),
      0,
    );
  });

  test('package plus addon uses diver counts', () {
    const product = ShopProduct(
      id: 'p1',
      shopId: 's1',
      name: 'Package',
      consumerPrice: 100,
      professionalPrice: 80,
      guestRates: [
        GuestRate(role: GuestRole.diver, consumer: 100, professional: 80),
        GuestRate(role: GuestRole.nondiver, consumer: 50, professional: 50),
      ],
      focPayCount: 10,
      focFreeCount: 1,
      options: [
        ShopProductOption(
          id: 'night',
          name: 'Night',
          consumerPrice: 10,
          professionalPrice: 10,
          kind: ProductOptionKind.addon,
        ),
      ],
    );
    final quote = BookingQuote.compute(
      product: product,
      professional: false,
      divers: 2,
      nondivers: 1,
      children: 0,
      infants: 0,
      bookPackage: true,
      selectedOptionIds: {'night'},
    );
    expect(quote.total, 2 * 100 + 50 + 2 * 10);
  });

  test('individual SKUs ignore package when package is off', () {
    const product = ShopProduct(
      id: 'p1',
      shopId: 's1',
      name: 'Package',
      consumerPrice: 100,
      professionalPrice: 80,
      options: [
        ShopProductOption(
          id: 'fun',
          name: 'Fun dive',
          consumerPrice: 40,
          professionalPrice: 40,
          kind: ProductOptionKind.individual,
        ),
      ],
    );
    final quote = BookingQuote.compute(
      product: product,
      professional: false,
      divers: 2,
      nondivers: 0,
      children: 0,
      infants: 0,
      bookPackage: false,
      selectedOptionIds: {'fun'},
    );
    expect(quote.total, 80);
  });
}
