import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_day_stats.dart';

void main() {
  test('a dwell write is rejected when the day document does not exist', () async {
    final repo = MemoryDiverRepository();
    final now = DateTime(2026, 10, 26, 9);
    final wrote = await repo.recordShopDwell(
      shopId: 'shop-a',
      now: now,
      seconds: 90,
    );
    expect(wrote, isFalse);
    expect(await repo.listShopDailyStats('shop-a'), isEmpty);
    expect(
      dailyStatsUpdateAllowed(
        exists: false,
        visits: 0,
        productViews: 0,
        dwellSeconds: 0,
        nextVisits: 0,
        nextProductViews: 0,
        nextDwellSeconds: 90,
      ),
      isFalse,
    );
  });

  test('the day document is created before dwell, and one bump stops at 1800', () async {
    final repo = MemoryDiverRepository();
    final now = DateTime(2026, 10, 26, 9);
    expect(
      await repo.recordShopDay(shopId: 'shop-a', now: now, visit: true),
      isTrue,
    );
    expect(
      await repo.recordShopDwell(shopId: 'shop-a', now: now, seconds: 2000),
      isTrue,
    );
    final day = (await repo.listShopDailyStats('shop-a')).single;
    expect(day.visits, 1);
    expect(day.dwellSeconds, 1800);
    expect(day.toMap().keys, ['visits', 'product_views', 'dwell_seconds']);
    expect(
      dailyStatsUpdateAllowed(
        exists: true,
        visits: 1,
        productViews: 0,
        dwellSeconds: 0,
        nextVisits: 1,
        nextProductViews: 0,
        nextDwellSeconds: 1801,
      ),
      isFalse,
    );
  });

  test('strike uses paid receive-date bookings over product views', () {
    final start = DateTime(2026, 10, 1);
    final end = DateTime(2026, 11, 1);
    final days = [
      const ShopDayStats(
        dayId: '2026-10-10',
        visits: 4,
        productViews: 2,
        dwellSeconds: 120,
      ),
      const ShopDayStats(
        dayId: '2026-09-30',
        visits: 9,
        productViews: 9,
        dwellSeconds: 9,
      ),
    ];
    final bookings = [
      TourBooking(
        id: 'paid',
        uid: 'm1',
        shopId: 'shop-a',
        shopName: 'Shop',
        productName: 'Tour',
        price: 10000,
        createdAt: DateTime(2026, 10, 10, 12),
        tourDate: DateTime(2026, 10, 20),
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.captured,
      ),
      TourBooking(
        id: 'unpaid',
        uid: 'm2',
        shopId: 'shop-a',
        shopName: 'Shop',
        productName: 'Tour',
        price: 10000,
        createdAt: DateTime(2026, 10, 11),
        tourDate: DateTime(2026, 10, 20),
        status: BookingStatus.requested,
        paymentStatus: PaymentStatus.unpaid,
      ),
    ];
    final window = sumShopCounters(
      days: days,
      start: start,
      end: end,
      bookings: bookings,
    );
    expect(window.productViews, 2);
    expect(window.paidBookings, 1);
    expect(window.strikeRate, 0.5);
    expect(window.toString(), isNot(contains('m1')));

    final noViews = sumShopCounters(
      days: const [
        ShopDayStats(
          dayId: '2026-10-10',
          visits: 1,
          productViews: 0,
          dwellSeconds: 0,
        ),
      ],
      start: start,
      end: end,
      bookings: bookings,
    );
    expect(noViews.strikeRate, isNull);
  });
}
