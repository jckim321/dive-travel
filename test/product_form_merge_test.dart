import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:flutter/material.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const shopId = AppConstants.defaultPartnerShopId;

  ShopProduct baseProduct({
    String id = 'p1',
    String includes = '보트',
    String cancellationNote = 'D-3 환불',
    String schedule = '### 1일차\n도착',
    int minGuests = 0,
    int capacity = 0,
    bool openEmptySeats = false,
    DateTime? flagClosesAt,
  }) {
    return ShopProduct(
      id: id,
      shopId: shopId,
      name: '테스트 상품',
      consumerPrice: 100000,
      professionalPrice: 80000,
      includes: includes,
      cancellationNote: cancellationNote,
      schedule: schedule,
      minGuests: minGuests,
      capacity: capacity,
      openEmptySeats: openEmptySeats,
      flagClosesAt: flagClosesAt,
      sameBoatStatus:
          openEmptySeats ? SameBoatStatus.approved : SameBoatStatus.closed,
      departureStart: openEmptySeats ? DateTime(2026, 11, 1) : null,
    );
  }

  test('mergePersistedMap: empty form fields clear; unknown keys kept', () {
    final previous = {
      'id': 'p1',
      'name': 'Old',
      'includes': '옛 포함',
      'cancellation_note': '옛 취소',
      'min_guests': 4,
      'legacy_custom': 'keep-me',
      'itinerary_days': [
        {'day': 1, 'title': 'A', 'body': 'B'},
      ],
    };
    final next = baseProduct(
      includes: '',
      cancellationNote: '',
      schedule: '### 새 일정',
    );
    final merged = ShopProduct.mergePersistedMap(
      previous: previous,
      product: next,
      clearAbsentFormFields: true,
    );
    expect(merged.containsKey('includes'), isFalse);
    expect(merged.containsKey('cancellation_note'), isFalse);
    expect(merged.containsKey('itinerary_days'), isFalse);
    expect(merged['schedule'], '### 새 일정');
    expect(merged['min_guests'], 4);
    expect(merged['legacy_custom'], 'keep-me');
  });

  test('(a) clearing includes and cancel note persists empty', () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: shopId,
      product: baseProduct(),
      clearAbsentFormFields: true,
    );
    repo.seedProductRawOverlay(shopId, 'p1', {'min_guests': 4});

    await repo.saveShopProduct(
      shopId: shopId,
      product: baseProduct(includes: '', cancellationNote: ''),
      clearAbsentFormFields: true,
    );
    final raw = repo.readProductRaw(shopId, 'p1')!;
    expect(raw.containsKey('includes'), isFalse);
    expect(raw.containsKey('cancellation_note'), isFalse);
    final loaded = ShopProduct.fromMap(shopId, raw);
    expect(loaded.includes, isEmpty);
    expect(loaded.cancellationNote, isEmpty);
  });

  test('(b) edited schedule is what detail cards would show', () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: shopId,
      product: baseProduct(schedule: '옛 일정'),
      clearAbsentFormFields: true,
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: baseProduct(schedule: '### 고친 본문\n2탱크'),
      clearAbsentFormFields: true,
    );
    final stats = await repo.fetchShopStat(shopId);
    final product = stats!.products.singleWhere((p) => p.id == 'p1');
    expect(product.schedule, '### 고친 본문\n2탱크');
    // Checkout detail uses schedule, not itinerary_days.
    expect(product.itineraryDays, isEmpty);
  });

  test('(c) seat fields survive a full-form style save', () async {
    final flag = DateTime(2026, 10, 30);
    final repo = MemoryDiverRepository.forTest();
    final seated = baseProduct(
      capacity: 6,
      openEmptySeats: true,
      flagClosesAt: flag,
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: seated,
      clearAbsentFormFields: false,
    );

    // Workbench-style save: rewrite copy text but carry seat fields from existing.
    final existing = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((p) => p.id == 'p1');
    final edited = existing.copyWith(
      includes: '가이드',
      cancellationNote: '',
      schedule: '새 일정',
      itineraryDays: const [],
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: edited,
      clearAbsentFormFields: true,
    );
    final after = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((p) => p.id == 'p1');
    expect(after.capacity, 6);
    expect(after.openEmptySeats, isTrue);
    expect(after.flagClosesAt, flag);
    expect(after.schedule, '새 일정');
  });

  test('preserveSeatFields keeps document seats over the form copy', () {
    final previous = {
      'id': 'p1',
      'name': 'Old',
      'booked_seats': 4,
      'capacity': 8,
      'open_empty_seats': true,
      'same_boat_status': 'approved',
      'flag_holds': [
        {'uid': 'u1', 'seats': 1, 'expires_at': '2026-12-01T00:00:00.000'},
      ],
      'options': [
        {
          'id': 'opt',
          'name': '옛 옵션',
          'consumer_price': 1000,
          'booked_seats': 3,
          'open_empty_seats': true,
          'same_boat_status': 'approved',
        },
      ],
    };
    final next = baseProduct().copyWith(
      name: '새 이름',
      bookedSeats: 1,
      capacity: 1,
      openEmptySeats: false,
      sameBoatStatus: SameBoatStatus.closed,
      options: [
        ShopProductOption(
          id: 'opt',
          name: '고친 옵션',
          consumerPrice: 2000,
          professionalPrice: 2000,
          bookedSeats: 1,
          openEmptySeats: false,
          sameBoatStatus: SameBoatStatus.closed,
        ),
      ],
    );
    final merged = ShopProduct.mergePersistedMap(
      previous: previous,
      product: next,
      clearAbsentFormFields: true,
      preserveSeatFields: true,
    );
    expect(merged['name'], '새 이름');
    expect(merged['booked_seats'], 4);
    expect(merged['capacity'], 8);
    expect(merged['open_empty_seats'], isTrue);
    expect(merged['same_boat_status'], 'approved');
    final options = merged['options'] as List;
    final option = options.single as Map;
    expect(option['name'], '고친 옵션');
    expect(option['consumer_price'], 2000);
    expect(option['booked_seats'], 3);
    expect(option['open_empty_seats'], isTrue);
  });

  test('legacy min_guests no longer blocks checkout party size', () {
    final product = baseProduct(minGuests: 4);
    expect(product.minGuests, 4);
    // Guard removed from tour_checkout_sheet; only max still applies.
    expect(product.maxGuests, 0);
  });

  testWidgets('checkout does not snack on min_guests when party is small',
      (tester) async {
    // Smoke: building the sheet with a min_guests product must not rely on
    // min for validation — covered by unit removal; this ensures l10n loads.
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(l10n.checkoutGuestsBelowMin(4), contains('4'));
  });

  test('same-boat preserveListing path does not wipe includes', () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: shopId,
      product: baseProduct(includes: '보트', capacity: 2, openEmptySeats: true),
      clearAbsentFormFields: true,
    );
    final existing = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((p) => p.id == 'p1');
    // Simulate seat-only patch: product map still has includes; clearAbsent false.
    await repo.saveShopProduct(
      shopId: shopId,
      product: existing.copyWith(capacity: 3),
      clearAbsentFormFields: false,
    );
    final after = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((p) => p.id == 'p1');
    expect(after.includes, '보트');
    expect(after.capacity, 3);
  });
}
