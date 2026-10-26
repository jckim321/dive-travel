import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/same_boat_alert.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/community/presentation/community_screen.dart';
import 'package:dive_travel_app/features/community/presentation/same_boat_search_bar.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved alert line names the calendar month and the other filters', () {
    final l10n = lookupAppLocalizations(const Locale('ko'));
    final line = sameBoatAlertSummary(
      search: const SameBoatSearch(
        when: SameBoatWhen.nextMonth,
        regionIds: {'palau'},
        party: 2,
        budgetMax: SameBoatSearch.budget100,
      ),
      l10n: l10n,
      now: DateTime(2026, 10, 27),
    );
    expect(line, '언제 11월 · 어디 팔라우 · 몇 명 2명 · 예산 100만 이하');
  });

  testWidgets('마이 배지는 맞는 열린 자리가 있을 때만 보이고, 줄은 그 조건으로 같은배를 연다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => CommunityScreen.savedSearch.value = null);

    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 15);
    final monthLabel = '${DateTime(now.year, now.month + 1).month}월';
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: ShopProduct(
        id: 'palau-seat',
        shopId: 'shop-a',
        name: '팔라우 빈자리',
        continent: '팔라우',
        consumerPrice: 900000,
        professionalPrice: 700000,
        openEmptySeats: true,
        capacity: 4,
        departureStart: nextMonth,
        sameBoatStatus: SameBoatStatus.approved,
      ),
    );
    await repo.saveShopProduct(
      shopId: 'shop-b',
      product: ShopProduct(
        id: 'cebu-seat',
        shopId: 'shop-b',
        name: '세부 빈자리',
        continent: '필리핀 세부',
        consumerPrice: 800000,
        professionalPrice: 600000,
        openEmptySeats: true,
        capacity: 4,
        departureStart: nextMonth,
        sameBoatStatus: SameBoatStatus.approved,
      ),
    );
    await repo.saveSeatAlerts(
      uid: 'test-user',
      alerts: [
        SameBoatAlert(
          id: 'match',
          createdAt: DateTime.utc(2026, 10, 2),
          search: const SameBoatSearch(
            when: SameBoatWhen.nextMonth,
            regionIds: {'palau'},
            party: 2,
            budgetMax: SameBoatSearch.budget100,
          ),
        ),
        SameBoatAlert(
          id: 'miss',
          createdAt: DateTime.utc(2026, 10, 1),
          search: const SameBoatSearch(
            when: SameBoatWhen.nextMonth,
            regionIds: {'yap'},
            party: 2,
          ),
        ),
      ],
    );
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: SessionScope(
          session: session,
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MainShell(),
          ),
        ),
      ),
    );
    await tester.pump();
    await store.refreshShopStats();
    await tester.pump();

    expect(find.byKey(const Key('my-tab-alert-badge')), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('seat-alert-match')));
    await tester.pump();

    expect(
      find.text('언제 $monthLabel · 어디 팔라우 · 몇 명 2명 · 예산 100만 이하'),
      findsOneWidget,
    );
    expect(find.text('맞는 빈자리 1개'), findsOneWidget);
    expect(find.text('맞는 빈자리 없음 · 자리가 나면 표시돼요'), findsOneWidget);
    expect(
      find.text('저장한 조건에 맞는 빈자리가 생기면 여기와 마이 탭에 표시돼요'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('seat-alert-match')));
    await tester.pump();
    await tester.pump();

    expect(find.text('팔라우 빈자리'), findsWidgets);
    expect(find.text('세부 빈자리'), findsNothing);

    await tester.tap(find.text('마이'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('seat-alert-delete-match')));
    await tester.tap(find.byKey(const Key('seat-alert-delete-match')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('seat-alert-match')), findsNothing);
    expect(find.byKey(const Key('my-tab-alert-badge')), findsNothing);
    expect(store.seatAlerts.single.id, 'miss');
  });
}
