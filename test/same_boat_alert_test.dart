import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/same_boat_alert.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/community/presentation/community_screen.dart';
import 'package:dive_travel_app/features/community/presentation/same_boat_empty_search.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('넓히기는 예산, 인원, 언제, 어디, 더 보기 순으로 하나씩 뺀다', () {
    final full = SameBoatSearch(
      when: SameBoatWhen.thisMonth,
      regionIds: const {'palau'},
      party: 4,
      budgetMax: SameBoatSearch.budget50,
      lastCall: true,
      departingSoon: true,
    );

    final noBudget = full.widen()!;
    expect(noBudget.budgetMax, isNull);
    expect(noBudget.party, 4);

    final noParty = noBudget.widen()!;
    expect(noParty.party, isNull);
    expect(noParty.when, SameBoatWhen.thisMonth);

    final noWhen = noParty.widen()!;
    expect(noWhen.when, SameBoatWhen.any);
    expect(noWhen.regionIds, {'palau'});

    final noWhere = noWhen.widen()!;
    expect(noWhere.regionIds, isEmpty);
    expect(noWhere.lastCall, isTrue);

    final open = noWhere.widen()!;
    expect(open.lastCall, isFalse);
    expect(open.departingSoon, isFalse);
    expect(open.widen(), isNull);

    final regionOnly = const SameBoatSearch(regionIds: {'palau'});
    expect(regionOnly.widen()!.regionIds, isEmpty);
  });

  test('같은 조건은 다시 저장하지 않고, 20개를 넘기면 가장 오래된 것을 뺀다', () {
    final search = const SameBoatSearch(party: 2);
    final first = appendSeatAlert(
      existing: const [],
      search: search,
      now: DateTime.utc(2026, 10, 1),
      id: 'a',
    );
    expect(first.result, SeatAlertWrite.saved);
    expect(first.alerts.single.toMap().keys, {
      'id',
      'when',
      'region_ids',
      'party',
      'last_call',
      'departing_soon',
      'created_at',
    });

    final again = appendSeatAlert(
      existing: first.alerts,
      search: const SameBoatSearch(party: 2, regionIds: {}),
      now: DateTime.utc(2026, 10, 2),
      id: 'b',
    );
    expect(again.result, SeatAlertWrite.alreadySaved);
    expect(again.alerts.single.id, 'a');

    final many = <SameBoatAlert>[
      for (var i = 0; i < SameBoatAlert.limit; i++)
        SameBoatAlert(
          id: 'old-$i',
          createdAt: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
          search: SameBoatSearch(party: 1, budgetMax: 1000 + i),
        ),
    ];
    final capped = appendSeatAlert(
      existing: many,
      search: const SameBoatSearch(when: SameBoatWhen.nextMonth),
      now: DateTime.utc(2026, 10, 27),
      id: 'newest',
    );
    expect(capped.alerts, hasLength(SameBoatAlert.limit));
    expect(capped.alerts.first.id, 'old-1');
    expect(capped.alerts.last.id, 'newest');
  });

  test('demand id is the member hash, day, and conditions', () {
    final at = DateTime(2026, 10, 27, 9);
    final left = SeatDemand.forSearch(
      uid: 'member-1',
      at: at,
      search: const SameBoatSearch(
        regionIds: {'cebu', 'palau'},
        party: 2,
        budgetMax: SameBoatSearch.budget50,
      ),
    );
    final right = SeatDemand.forSearch(
      uid: 'member-1',
      at: at,
      unlockBy: SeatUnlock.budget,
      search: const SameBoatSearch(
        regionIds: {'palau', 'cebu'},
        party: 2,
        budgetMax: SameBoatSearch.budget50,
      ),
    );
    expect(left.id, right.id);
    expect(left.withinShape, isTrue);
    expect(right.toMap()['unlock_by'], 'budget');
    expect(right.toMap().containsKey('email'), isFalse);
    expect(right.toMap().containsKey('phone'), isFalse);
    expect(seatUnlockOf(left.search), SeatUnlock.budget);
  });

  test('회원 문서에 조건을 저장하고 같은 조건은 이미 저장됨이다', () async {
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);

    const search = SameBoatSearch(
      when: SameBoatWhen.nextMonth,
      regionIds: {'palau'},
      party: 2,
      budgetMax: SameBoatSearch.budget100,
      lastCall: true,
    );
    expect(
      await store.saveSeatAlert(search),
      SeatAlertWrite.saved,
    );
    expect(store.seatAlerts.single.sameConditions(search), isTrue);
    expect(
      await store.saveSeatAlert(search),
      SeatAlertWrite.alreadySaved,
    );
    expect(store.seatAlerts, hasLength(1));

    final raw = store.seatAlerts.single.toMap();
    expect(raw.containsKey('email'), isFalse);
    expect(raw.containsKey('name'), isFalse);
    expect(raw.containsKey('phone'), isFalse);
  });

  testWidgets('0건 화면은 알림 저장과 조건 넓히기를 보여 준다', (tester) async {
    var widened = 0;
    var saved = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SameBoatEmptySearch(
            summary: '다음 달 · 2명',
            alreadySaved: false,
            canWiden: true,
            onSave: () => saved += 1,
            onWiden: () => widened += 1,
          ),
        ),
      ),
    );
    expect(find.text('조건에 맞는 빈자리가 아직 없어요'), findsOneWidget);
    expect(find.text('다음 달 · 2명'), findsOneWidget);
    await tester.tap(find.byKey(const Key('same-boat-widen')));
    await tester.tap(find.byKey(const Key('same-boat-alert-save')));
    expect(widened, 1);
    expect(saved, 1);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SameBoatEmptySearch(
            summary: '다음 달',
            alreadySaved: true,
            canWiden: false,
            onSave: () => saved += 1,
            onWiden: () {},
          ),
        ),
      ),
    );
    expect(find.text('이미 저장됨'), findsOneWidget);
    expect(find.byKey(const Key('same-boat-widen')), findsNothing);
    final save = tester.widget<FilledButton>(
      find.widgetWithIcon(FilledButton, Icons.check),
    );
    expect(save.onPressed, isNull);
    expect(saved, 1);
  });

  testWidgets('걸러서 0건이면 넓혀서 열린 자리로 돌아온다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: ShopProduct(
        id: 'seat-1',
        shopId: 'shop-a',
        name: '팔라우 빈자리',
        consumerPrice: 900000,
        professionalPrice: 700000,
        openEmptySeats: true,
        capacity: 4,
        departureStart: DateTime(2026, 12, 15),
        sameBoatStatus: SameBoatStatus.approved,
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
          home: const CommunityScreen(),
        ),
      ),
    );
    await tester.pump();
    await store.refreshShopStats();
    await tester.pump();

    expect(find.text('팔라우 빈자리'), findsWidgets);

    await tester.tap(find.byKey(const Key('same-boat-chip-budget')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50만 이하'));
    await tester.pump();
    await tester.tap(find.text('빈자리 0개 보기'));
    await tester.pumpAndSettle();

    expect(find.text('팔라우 빈자리'), findsNothing);
    expect(find.text('예산 50만 이하'), findsOneWidget);
    expect(find.byKey(const Key('same-boat-alert-save')), findsOneWidget);
    expect(find.byKey(const Key('same-boat-widen')), findsOneWidget);
    expect(repo.debugSeatDemands, hasLength(1));
    expect(repo.debugSeatDemands.single.containsKey('unlock_by'), isFalse);

    await tester.tap(find.byKey(const Key('same-boat-widen')));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('팔라우 빈자리'), findsWidgets);
    expect(find.byKey(const Key('same-boat-alert-save')), findsNothing);
    expect(find.text('예산 조건을 빼고 보여드려요'), findsOneWidget);
    expect(
      repo.debugSeatDemands.map((row) => row['unlock_by']).toSet(),
      {null, 'budget'},
    );
  });
}
