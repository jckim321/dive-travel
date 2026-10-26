import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_same_boat_monitor_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

final _now = DateTime(2026, 10, 27);
final _departure = DateTime(2026, 12, 15);

ShopProduct _hiddenSeat() {
  return ShopProduct(
    id: 'seat-1',
    shopId: 'shop-a',
    name: '팔라우 빈자리',
    consumerPrice: 400000,
    professionalPrice: 320000,
    openEmptySeats: true,
    capacity: 8,
    bookedSeats: 1,
    departureStart: _departure,
    sameBoatStatus: SameBoatStatus.hidden,
    sameBoatOpenedAt: DateTime(2026, 10, 20),
    options: [
      ShopProductOption(
        id: 'cabin',
        name: '캐빈',
        openEmptySeats: true,
        capacity: 2,
        departureStart: _departure,
        sameBoatStatus: SameBoatStatus.hidden,
        sameBoatOpenedAt: DateTime(2026, 10, 20),
      ),
    ],
  );
}

Future<DiverStore> _loadedStore(MemoryDiverRepository repo) async {
  final store = DiverStore(repo);
  await Future<void>.delayed(Duration.zero);
  await store.refreshShopStats();
  if (!store.stats.isAdmin) {
    throw StateError('test admin snapshot did not arrive');
  }
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('다시 열기는 저장 전에 열린 줄과 고객 목록으로 옮긴다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProduct(shopId: 'shop-a', product: _hiddenSeat());
    final stale = await repo.fetchShopStat('shop-a');
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
    expect(store.stats.isAdmin, isTrue);

    expect(
      find.byKey(const Key('admin-same-boat-reopen-seat-1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('admin-same-boat-hide-seat-1')), findsNothing);
    expect(store.sameBoatOffers(SameBoatFilter.all, now: _now), isEmpty);

    final gate = Completer<void>();
    repo.debugDelayShopProductSave = () => gate.future;
    repo.debugFetchShopStatOverride = stale;

    await tester.tap(find.byKey(const Key('admin-same-boat-reopen-seat-1')));
    await tester.pump();

    expect(
      find.byKey(const Key('admin-same-boat-hide-seat-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('admin-same-boat-reopen-seat-1')),
      findsNothing,
    );
    expect(find.text('숨긴 빈자리가 없습니다.'), findsOneWidget);
    expect(
      store
          .sameBoatOffers(SameBoatFilter.all, now: _now)
          .map((offer) => offer.optionId)
          .toSet(),
      {'', 'cabin'},
    );

    gate.complete();
    repo.debugDelayShopProductSave = null;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const Key('admin-same-boat-hide-seat-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('admin-same-boat-reopen-seat-1')),
      findsNothing,
    );
    expect(
      store
          .sameBoatOffers(SameBoatFilter.all, now: _now)
          .map((offer) => offer.optionId)
          .toSet(),
      {'', 'cabin'},
    );
    repo.debugFetchShopStatOverride = null;
    final stored = await repo.fetchShopStat('shop-a');
    final product = stored!.products.single;
    expect(product.sameBoatStatus, SameBoatStatus.approved);
    expect(product.options.single.sameBoatStatus, SameBoatStatus.approved);
    expect(product.bookedSeats, 1);
    expect(product.openEmptySeats, isTrue);
  });

  test('저장이 실패하면 숨긴 자리와 고객 목록을 되돌린다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProduct(shopId: 'shop-a', product: _hiddenSeat());
    final store = await _loadedStore(repo);
    addTearDown(store.dispose);

    final gate = Completer<void>();
    repo.debugDelayShopProductSave = () async {
      await gate.future;
      throw StateError('write failed');
    };

    final pending = store.setSameBoatStatus(
      shopId: 'shop-a',
      productId: 'seat-1',
      status: SameBoatStatus.approved,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      store.allShopProducts
          .singleWhere((product) => product.id == 'seat-1')
          .sameBoatStatus,
      SameBoatStatus.approved,
    );
    expect(
      store
          .sameBoatOffers(SameBoatFilter.all, now: _now)
          .map((offer) => offer.optionId)
          .toSet(),
      {'', 'cabin'},
    );

    gate.complete();
    await expectLater(pending, throwsA(isA<StateError>()));
    expect(
      store.allShopProducts
          .singleWhere((product) => product.id == 'seat-1')
          .sameBoatStatus,
      SameBoatStatus.hidden,
    );
    expect(store.sameBoatOffers(SameBoatFilter.all, now: _now), isEmpty);
  });
}
