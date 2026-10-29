import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partners_roster_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('status save records one event and keeps the note on the shop', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'reef',
      name: '리프',
      location: '세부',
      productName: '펀',
      consumerPrice: 1,
      professionalPrice: 1,
    );
    final longNote = '가' * 600;
    await repo.setShopOperatingStatus(
      shopId: 'reef',
      status: ShopOperatingStatus.closed,
      note: longNote,
      byUid: 'admin-1',
      byName: '',
    );
    final stats = await repo.fetchShopStat('reef');
    expect(stats?.operatingStatus, ShopOperatingStatus.closed);
    expect(stats?.operatingNote.length, 500);
    final events = await repo.fetchShopOperatingEvents('reef');
    expect(events, hasLength(1));
    expect(events.single.kind, 'status');
    expect(events.single.fromStatus, ShopOperatingStatus.active);
    expect(events.single.toStatus, ShopOperatingStatus.closed);
    expect(events.single.note.length, 500);
    expect(events.single.byUid, 'admin-1');
    expect(events.single.byName, 'admin-1');

    final parsed = ShopLiveStats.fromDocument('reef', {
      'operating_status': 'paused',
      'operating_note': '메모',
    });
    expect(parsed.operatingStatus, ShopOperatingStatus.paused);
    expect(parsed.operatingNote, '메모');
  });

  testWidgets('paused and closed shops stay on the partner list and status save writes history', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final made = await repo.provisionPartner(
      shopName: '푸른 리프',
      loginId: 'ocean01',
      password: 'password12',
      actorUid: 'test-user',
      actorName: '테스트 다이버',
    );
    final shopId = made.hullId;
    await repo.saveShopProfile(
      shopId: shopId,
      name: '푸른 리프',
      location: '세부',
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: ShopProduct(
        id: 'trip',
        shopId: shopId,
        name: '펀다이빙',
        consumerPrice: 100000,
        professionalPrice: 80000,
      ),
    );
    repo.debugSetOperatingStatus(shopId, ShopOperatingStatus.paused);
    await repo.saveShopProfile(
      shopId: 'closed-reef',
      name: '닫힌 리프',
      location: '팔라우',
      productName: '',
      consumerPrice: 0,
      professionalPrice: 0,
    );
    repo.debugSetOperatingStatus('closed-reef', ShopOperatingStatus.closed);

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await store.ensureAdminInboxLoaded();
    expect(store.uid, 'test-user');
    expect(store.shops.map((shop) => shop.hullId), isNot(contains(shopId)));
    expect(store.shops.map((shop) => shop.hullId), isNot(contains('closed-reef')));

    var opened = '';
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminPartnersRosterScreen(
            onOpenProducts: (id) => opened = id,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(Key('admin-partner-row-$shopId')), findsOneWidget);
    expect(find.text('푸른 리프'), findsOneWidget);
    expect(find.text('대표 푸른 리프 · 아이디 ocean01 · 활동중지'), findsOneWidget);
    expect(find.byKey(const Key('admin-partner-row-closed-reef')), findsOneWidget);
    expect(find.text('대표 — · 아이디 — · 폐업'), findsOneWidget);

    await tester.tap(find.byKey(Key('admin-partner-row-$shopId')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('펀다이빙'), findsOneWidget);
    expect(find.text('변경 이력이 없습니다.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-partner-status-closed')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('admin-partner-note')), '시즌 종료');
    await tester.tap(find.byKey(const Key('admin-partner-operating-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('활동중지 → 폐업'), findsOneWidget);
    expect(find.textContaining('시즌 종료'), findsWidgets);
    final live = store.liveStatsFor(shopId);
    expect(live?.operatingStatus, ShopOperatingStatus.closed);
    expect(live?.operatingNote, '시즌 종료');
    final events = await repo.fetchShopOperatingEvents(shopId);
    expect(events, hasLength(1));
    expect(events.single.kind, 'status');
    expect(events.single.byUid, 'test-user');

    await tester.tap(find.byKey(const Key('admin-partner-edit-resort')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ResortDeskScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(ResortDeskScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.byKey(const Key('admin-partner-open-products')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-partner-open-products')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(opened, shopId);
    expect(find.byKey(const Key('admin-partner-operating-save')), findsNothing);
  });
}
