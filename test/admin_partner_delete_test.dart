import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partners_roster_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

int _cardCount(WidgetTester tester, String grade) {
  final texts = tester.widgetList<Text>(
    find.descendant(
      of: find.byKey(Key('admin-partner-grade-$grade')),
      matching: find.byType(Text),
    ),
  );
  return int.parse(
    texts.map((text) => text.data).firstWhere((data) => int.tryParse(data ?? '') != null)!,
  );
}

void main() {
  test('비어 있는 리조트만 지우고 소유주·예약·후기가 있으면 거절한다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'empty-reef',
      name: '빈 리프',
      location: '세부',
      productName: '',
      consumerPrice: 0,
      professionalPrice: 0,
    );
    await repo.deleteEmptyPartnerShop('empty-reef');
    expect(await repo.fetchShopStat('empty-reef'), isNull);

    expect(
      () => repo.deleteEmptyPartnerShop('bohol-hideout'),
      throwsA(
        isA<StateError>().having((error) => '$error', 'error', contains('SHOP_HAS_REVIEWS')),
      ),
    );
    expect(await repo.fetchShopStat('bohol-hideout'), isNotNull);

    final made = await repo.provisionPartner(
      shopName: '푸른 리프',
      loginId: 'ocean01',
      password: 'password12',
      actorUid: 'test-user',
      actorName: '테스트',
    );
    expect(
      () => repo.deleteEmptyPartnerShop(made.hullId),
      throwsA(
        isA<StateError>().having((error) => '$error', 'error', contains('SHOP_HAS_OWNER')),
      ),
    );

    await repo.saveShopProfile(
      shopId: 'booked-reef',
      name: '예약 리프',
      location: '세부',
      productName: '펀',
      consumerPrice: 1,
      professionalPrice: 1,
    );
    final booking = await repo.createBooking(
      uid: 'guest-1',
      shopId: 'booked-reef',
      shopName: '예약 리프',
      productName: '펀',
      price: 1,
    );
    expect(booking, isNotNull);
    expect(
      () => repo.deleteEmptyPartnerShop('booked-reef'),
      throwsA(
        isA<StateError>().having((error) => '$error', 'error', contains('SHOP_HAS_BOOKINGS')),
      ),
    );
  });

  testWidgets('삭제가 막히면 안내하고, 지우면 목록과 카드 숫자가 바로 줄어든다', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'empty-reef',
      name: '빈 리프',
      location: '세부',
      productName: '',
      consumerPrice: 0,
      professionalPrice: 0,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await store.ensureAdminInboxLoaded();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AdminConsoleTheme.dark,
          home: const AdminPartnersRosterScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(_cardCount(tester, 'all'), 2);
    expect(_cardCount(tester, 'regular'), 1);
    expect(_cardCount(tester, 'star2'), 1);

    await tester.tap(find.byKey(const Key('admin-partner-row-bohol-hideout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<FilledButton>(find.byKey(const Key('admin-partner-delete'))).onPressed, isNull);
    expect(find.byKey(const Key('admin-partner-delete-blocked')), findsOneWidget);
    expect(find.text('상태 변경(폐업 등)을 쓰세요'), findsOneWidget);

    Navigator.of(tester.element(find.byKey(const Key('admin-partner-delete')))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.byKey(const Key('admin-partner-row-empty-reef')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-partner-row-empty-reef')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('admin-partner-delete-blocked')), findsNothing);
    expect(tester.widget<FilledButton>(find.byKey(const Key('admin-partner-delete'))).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('admin-partner-delete')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-partner-delete-cancel')));
    await tester.pump();
    expect(find.byKey(const Key('admin-partner-delete')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-partner-delete')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-partner-delete-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('admin-partner-row-empty-reef')), findsNothing);
    expect(find.byKey(const Key('admin-partner-row-bohol-hideout')), findsOneWidget);
    expect(_cardCount(tester, 'all'), 1);
    expect(_cardCount(tester, 'regular'), 0);
    expect(_cardCount(tester, 'star2'), 1);
    expect(store.shopStats.map((shop) => shop.shopId), isNot(contains('empty-reef')));
  });
}
