import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_same_boat_monitor_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

ShopProduct _live({
  required String id,
  required int booked,
  DateTime? openedAt,
  SameBoatStatus status = SameBoatStatus.approved,
}) {
  return ShopProduct(
    id: id,
    shopId: 'shop-a',
    name: id,
    consumerPrice: 100000,
    professionalPrice: 80000,
    active: true,
    publishStatus: ProductPublishStatus.approved,
    openEmptySeats: true,
    capacity: 8,
    bookedSeats: booked,
    departureStart: DateTime(2026, 12, 15),
    sameBoatStatus: status,
    sameBoatOpenedAt: openedAt,
  );
}

void main() {
  test('날짜 차이는 달력 일수이고 시각이 없으면 null', () {
    final today = DateTime(2026, 10, 27, 18);
    expect(sameBoatZeroBookingOpenDays(null, today), isNull);
    expect(
      sameBoatZeroBookingOpenDays(DateTime(2026, 10, 27, 1), today),
      0,
    );
    expect(
      sameBoatZeroBookingOpenDays(DateTime(2026, 10, 24, 23), today),
      3,
    );
  });

  testWidgets('예약 0인 열린 타일만 배지 문구를 보여 준다', (tester) async {
    final today = DateTime.now();
    final opened = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 3));
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: _live(id: 'aged', booked: 0, openedAt: opened),
    );
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: _live(id: 'legacy', booked: 0),
    );
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: _live(id: 'booked', booked: 2, openedAt: opened),
    );
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: _live(
        id: 'hidden',
        booked: 0,
        openedAt: opened,
        status: SameBoatStatus.hidden,
      ),
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AdminConsoleTheme.dark,
          home: const AdminSameBoatMonitorScreen(embedded: true),
        ),
      ),
    );
    await tester.pump();
    await store.refreshShopStats();
    await tester.pump();

    expect(find.text('열린 지 3일째 예약 0'), findsOneWidget);
    expect(find.text('예약 0'), findsOneWidget);
    expect(
      find.byKey(const Key('admin-same-boat-zero-badge-booked')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('admin-same-boat-zero-badge-hidden')),
      findsNothing,
    );
    expect(find.byKey(const Key('admin-same-boat-hide-aged')), findsOneWidget);
    expect(
      find.byKey(const Key('admin-same-boat-reopen-hidden')),
      findsOneWidget,
    );
  });
}
