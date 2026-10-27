import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/seat_score.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_same_boat_brief_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('기간은 오늘을 포함한 길이고 직전 구간은 같은 길이이다', () {
    final now = DateTime(2026, 10, 27, 15);
    final week = seatBriefWindow(
      preset: SeatBriefPreset.sevenDays,
      now: now,
    );
    expect(week.start, DateTime(2026, 10, 21));
    expect(week.end, DateTime(2026, 10, 28));
    expect(seatBriefRangeLabel(week), '2026.10.21 ~ 10.27');
    final previous = seatBriefPreviousWindow(week);
    expect(previous.start, DateTime(2026, 10, 14));
    expect(previous.end, DateTime(2026, 10, 21));
    expect(seatBriefBeforeRecording(week), isTrue);
    expect(
      seatBriefBeforeRecording(
        seatBriefWindow(preset: SeatBriefPreset.today, now: now),
      ),
      isFalse,
    );

    final year = seatBriefWindow(preset: SeatBriefPreset.thisYear, now: now);
    expect(year.start, DateTime(2026, 1, 1));
    final month = seatBriefWindow(
      preset: SeatBriefPreset.thirtyDays,
      now: now,
    );
    expect(month.end.difference(month.start).inDays, 30);

    final custom = seatBriefWindow(
      preset: SeatBriefPreset.custom,
      now: now,
      customStart: DateTime(2026, 10, 27),
      customEnd: DateTime(2026, 10, 21),
    );
    expect(custom.start, DateTime(2026, 10, 21));
    expect(custom.end, DateTime(2026, 10, 28));
  });

  test('깔때기 비율은 열림 조회 깃발 결제만 센다', () {
    final funnel = seatBriefFunnel([
      _event('a', 'open', DateTime(2026, 10, 27, 9)),
      _event('b', 'view', DateTime(2026, 10, 27, 10)),
      _event('c', 'view', DateTime(2026, 10, 27, 11)),
      _event('d', 'flag', DateTime(2026, 10, 27, 12)),
      _event('e', 'pay', DateTime(2026, 10, 27, 13)),
      _event('f', 'expire', DateTime(2026, 10, 27, 14)),
    ]);
    expect(funnel.opens, 1);
    expect(funnel.views, 2);
    expect(funnel.flags, 1);
    expect(funnel.pays, 1);
    expect(funnel.viewsPerOpen, 2);
    expect(funnel.flagPercent, 50);
    expect(funnel.payPercent, 100);
    expect(seatBriefDeltaLabel(2, 1), '+1');
    expect(seatBriefDeltaLabel(1, 3), '-2');
    final thin = seatBriefFunnel([
      _event('o1', 'open', DateTime(2026, 10, 27, 8)),
      _event('o2', 'open', DateTime(2026, 10, 27, 8, 1)),
      _event('o3', 'open', DateTime(2026, 10, 27, 8, 2)),
      _event('v1', 'view', DateTime(2026, 10, 27, 8, 3)),
    ]);
    expect(thin.viewsPerOpen.toStringAsFixed(1), '0.3');
  });

  testWidgets('브리프는 고른 기간의 사건만 읽고 직전 기간과 비교한다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await _plant(repo, 'in-open', 'open', DateTime(2026, 10, 27, 10));
    await _plant(repo, 'in-view-1', 'view', DateTime(2026, 10, 27, 11));
    await _plant(repo, 'in-view-2', 'view', DateTime(2026, 10, 27, 12));
    await _plant(repo, 'in-flag', 'flag', DateTime(2026, 10, 27, 13));
    await _plant(repo, 'in-pay', 'pay', DateTime(2026, 10, 27, 14));
    await _plant(repo, 'week-open', 'open', DateTime(2026, 10, 21, 8));
    await _plant(repo, 'prev-open', 'open', DateTime(2026, 10, 20, 12));
    await _plant(repo, 'prev-view', 'view', DateTime(2026, 10, 20, 13));
    await _plant(repo, 'outside', 'open', DateTime(2026, 10, 13, 12));
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminSameBoatBriefScreen(now: DateTime(2026, 10, 27, 15)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('2026.10.21 ~ 10.27'), findsOneWidget);
    expect(_count(tester, 'seat-brief-opens'), '2');
    expect(_count(tester, 'seat-brief-views'), '2');
    expect(_count(tester, 'seat-brief-flags'), '1');
    expect(_count(tester, 'seat-brief-pays'), '1');
    expect(find.text('열림 → 조회 자리당 1.0회'), findsOneWidget);
    expect(find.text('조회 → 깃발 50%'), findsOneWidget);
    expect(find.text('깃발 → 결제 100%'), findsOneWidget);
    expect(find.text('기록 시작일 이전은 예약 기준'), findsOneWidget);
    expect(repo.debugSeatEventQueries, [
      (DateTime(2026, 10, 21), DateTime(2026, 10, 28)),
    ]);

    await tester.tap(find.byKey(const Key('seat-brief-preset-today')));
    await tester.pump();
    await tester.pump();

    expect(_count(tester, 'seat-brief-opens'), '1');
    expect(find.text('기록 시작일 이전은 예약 기준'), findsNothing);
    expect(find.byKey(const Key('seat-brief-opens-delta')), findsNothing);

    await tester.tap(find.byKey(const Key('seat-brief-compare')));
    await tester.pump();
    await tester.pump();

    expect(_count(tester, 'seat-brief-opens'), '1');
    expect(_count(tester, 'seat-brief-opens-delta'), '+1');
    expect(find.text('기록 시작일 이전은 예약 기준'), findsOneWidget);
    expect(repo.debugSeatEventQueries, [
      (DateTime(2026, 10, 21), DateTime(2026, 10, 28)),
      (DateTime(2026, 10, 27), DateTime(2026, 10, 28)),
      (DateTime(2026, 10, 27), DateTime(2026, 10, 28)),
      (DateTime(2026, 10, 26), DateTime(2026, 10, 27)),
    ]);
  });

  testWidgets('놓친 수요는 기간 안 같은 조건 상위 3개와 막힌 이유만 보여 준다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    const palau = SameBoatSearch(
      when: SameBoatWhen.nextMonth,
      regionIds: {'palau'},
      party: 2,
      budgetMax: SameBoatSearch.budget100,
    );
    const cebu = SameBoatSearch(
      when: SameBoatWhen.thisMonth,
      regionIds: {'cebu'},
      party: 4,
    );
    const yap = SameBoatSearch(
      when: SameBoatWhen.nextMonth,
      regionIds: {'yap'},
      party: 1,
    );
    expect(
      await _demand(repo, 'a', palau, DateTime(2026, 10, 22, 12), SeatUnlock.budget),
      isTrue,
    );
    expect(
      await _demand(repo, 'b', palau, DateTime(2026, 10, 23, 12), SeatUnlock.party),
      isTrue,
    );
    expect(
      await _demand(repo, 'c', palau, DateTime(2026, 10, 24, 12), SeatUnlock.budget),
      isTrue,
    );
    expect(
      await _demand(repo, 'd', cebu, DateTime(2026, 10, 25, 12), SeatUnlock.where),
      isTrue,
    );
    expect(await _demand(repo, 'e', cebu, DateTime(2026, 10, 26, 12), null), isTrue);
    expect(await _demand(repo, 'f', yap, DateTime(2026, 10, 22, 12), null), isTrue);
    expect(
      await _demand(repo, 'g', palau, DateTime(2026, 10, 13, 12), SeatUnlock.more),
      isTrue,
    );
    expect(await _demand(repo, 'h', palau, DateTime(2026, 10, 20, 12), null), isTrue);

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminSameBoatBriefScreen(now: DateTime(2026, 10, 27, 15)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(repo.debugSeatDemandQueries, [
      (DateTime(2026, 10, 21), DateTime(2026, 10, 28)),
    ]);
    expect(
      tester.widget<Text>(find.byKey(const Key('seat-demand-rank-0'))).data,
      '팔라우 · 11월 · 2명 · 100만 이하',
    );
    expect(find.text('3회'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('seat-demand-rank-1'))).data,
      '필리핀 세부 · 10월 · 4명',
    );
    expect(find.text('2회'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('seat-demand-rank-2'))).data,
      '얍 · 11월 · 1명',
    );
    expect(find.text('1회'), findsWidgets);
    expect(_count(tester, 'seat-demand-wall-budget'), '2');
    expect(_count(tester, 'seat-demand-wall-party'), '1');
    expect(_count(tester, 'seat-demand-wall-where'), '1');
    expect(find.byKey(const Key('seat-demand-wall-when')), findsNothing);
    expect(find.byKey(const Key('seat-demand-wall-more')), findsNothing);
    expect(find.text('알림 대기'), findsNothing);
    expect(find.byKey(const Key('seat-demand-empty')), findsNothing);

    await tester.tap(find.byKey(const Key('seat-brief-compare')));
    await tester.pump();
    await tester.pump();
    expect(_count(tester, 'seat-demand-rank-0-delta'), '+2');
    expect(_count(tester, 'seat-demand-wall-budget-delta'), '+2');

    await tester.tap(find.byKey(const Key('seat-brief-compare')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('seat-brief-preset-today')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('seat-demand-empty')), findsOneWidget);
    expect(find.byKey(const Key('seat-demand-rank-0')), findsNothing);
    expect(repo.debugSeatDemandQueries.last, (
      DateTime(2026, 10, 27),
      DateTime(2026, 10, 28),
    ));
  });

  test('성적표는 목록 id로 묶고 배지 규칙으로 한 지역만 고른다', () {
    expect(
      seatScoreBadge(views: 9, flags: 0, pays: 0, fillPercent: 0),
      SeatScoreBadge.ordinary,
    );
    expect(
      seatScoreBadge(views: 5, flags: 0, pays: 0, fillPercent: 0),
      SeatScoreBadge.quiet,
    );
    expect(
      seatScoreBadge(views: 2, flags: 0, pays: 3, fillPercent: 0),
      SeatScoreBadge.selling,
    );
    expect(
      seatScoreBadge(views: 1, flags: 0, pays: 0, fillPercent: 80),
      SeatScoreBadge.selling,
    );
    expect(
      seatScoreBadge(views: 30, flags: 3, pays: 0, fillPercent: 15),
      SeatScoreBadge.viewsOnly,
    );
    expect(
      seatScoreBadge(views: 30, flags: 4, pays: 0, fillPercent: 10),
      SeatScoreBadge.ordinary,
    );
    expect(seatScoreTopic('팔라우'), '팔라우는');
    expect(seatScoreTopic('얍'), '얍은');

    final at = DateTime(2026, 10, 22, 12);
    final events = <SeatLifeEvent>[
      for (var i = 0; i < 30; i++)
        _event('cebu-view-$i', 'view', at, region: '필리핀 세부', productId: 'cebu-live'),
      _event('cebu-flag', 'flag', at, region: 'cebu', productId: 'cebu-live'),
      _event('palau-ko', 'view', at, region: '팔라우', productId: 'palau-live'),
      _event('palau-id', 'view', at, region: 'palau', productId: 'palau-live'),
      _event('palau-pay', 'pay', at, region: 'palau', productId: 'palau-live'),
      _event('open-ignored', 'open', at, region: '팔라우', productId: 'palau-live'),
    ];
    final board = seatScoreboard(
      events: events,
      seats: const [
        SeatScoreSeat(
          productId: 'palau-live',
          optionId: 'a',
          productName: '팔라우 씨월드',
          place: SameBoatPlace(continent: 'palau'),
          booked: 4,
          capacity: 5,
        ),
        SeatScoreSeat(
          productId: 'palau-live',
          optionId: 'b',
          productName: '팔라우 씨월드',
          place: SameBoatPlace(continent: '팔라우'),
          booked: 4,
          capacity: 5,
        ),
        SeatScoreSeat(
          productId: 'cebu-live',
          optionId: '',
          productName: '세부 리브',
          place: SameBoatPlace(country: '필리핀 세부'),
          booked: 3,
          capacity: 20,
        ),
      ],
    );
    expect(board.regions.map((row) => row.id).toList(), ['cebu', 'palau']);
    expect(board.regions.first.views, 30);
    expect(board.regions.first.flags, 1);
    expect(board.regions.first.fillPercent, 15);
    expect(board.regions.first.badge, SeatScoreBadge.viewsOnly);
    expect(board.regions[1].views, 2);
    expect(board.regions[1].pays, 1);
    expect(board.regions[1].fillPercent, 80);
    expect(board.regions[1].title, '팔라우');
    expect(board.products.first.id, 'cebu-live');
    expect(board.products.first.regionName, '필리핀 세부');
    expect(board.products[1].title, '팔라우 씨월드');
    expect(board.products[1].regionId, 'palau');
    expect(board.products[1].booked, 8);
    final headline = seatScoreHeadline(board.regions);
    expect(headline?.id, 'cebu');
    expect(
      seatScoreHeadline([
        SeatScoreRow(
          id: 'yap',
          title: '얍',
          regionId: 'yap',
          regionName: '얍',
          views: 9,
          flags: 1,
          pays: 1,
          booked: 1,
          capacity: 10,
        ),
      ]),
      isNull,
    );
  });

  testWidgets('자리 성적표는 고른 기간의 지역과 상품만 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: const ShopProduct(
        id: 'palau-live',
        shopId: 'shop-a',
        name: '팔라우 씨월드',
        continent: 'palau',
        consumerPrice: 150000,
        professionalPrice: 100000,
        capacity: 10,
        bookedSeats: 8,
      ),
    );
    await repo.saveShopProduct(
      shopId: 'shop-b',
      product: const ShopProduct(
        id: 'cebu-live',
        shopId: 'shop-b',
        name: '세부 리브',
        continent: '필리핀 세부',
        consumerPrice: 220000,
        professionalPrice: 150000,
        capacity: 20,
        bookedSeats: 3,
      ),
    );
    for (var i = 0; i < 30; i++) {
      await _plant(
        repo,
        'cebu-view-$i',
        'view',
        DateTime(2026, 10, 22, 10),
        region: '필리핀 세부',
        productId: 'cebu-live',
      );
    }
    await _plant(
      repo,
      'cebu-flag-1',
      'flag',
      DateTime(2026, 10, 22, 11),
      region: 'cebu',
      productId: 'cebu-live',
    );
    await _plant(
      repo,
      'cebu-flag-2',
      'flag',
      DateTime(2026, 10, 23, 11),
      region: '필리핀 세부',
      productId: 'cebu-live',
    );
    await _plant(
      repo,
      'palau-ko',
      'view',
      DateTime(2026, 10, 24, 12),
      region: '팔라우',
      productId: 'palau-live',
    );
    await _plant(
      repo,
      'palau-id',
      'view',
      DateTime(2026, 10, 24, 13),
      region: 'palau',
      productId: 'palau-live',
    );
    await _plant(
      repo,
      'palau-old',
      'view',
      DateTime(2026, 10, 13, 12),
      region: '팔라우',
      productId: 'palau-live',
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
          home: AdminSameBoatBriefScreen(now: DateTime(2026, 10, 27, 15)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(repo.debugSeatEventQueries, [
      (DateTime(2026, 10, 21), DateTime(2026, 10, 28)),
    ]);
    expect(find.text('결과 카드'), findsNothing);
    expect(
      _count(tester, 'seat-brief-conclusion'),
      '필리핀 세부는 조회 30 · 깃발 2 · 결제 0. 가격이 막고 있는 것으로 보여요',
    );
    expect(_count(tester, 'seat-score-region-cebu'), '필리핀 세부');
    expect(_count(tester, 'seat-score-badge-cebu'), '조회만 많음');
    expect(_count(tester, 'seat-score-counts-cebu'), '조회 30  깃발 2  결제 0');
    expect(_count(tester, 'seat-score-fill-cebu'), '채움 15%');
    expect(_count(tester, 'seat-score-region-palau'), '팔라우');
    expect(_count(tester, 'seat-score-badge-palau'), '잘 팔림');
    expect(_count(tester, 'seat-score-counts-palau'), '조회 2  깃발 0  결제 0');
    expect(_count(tester, 'seat-score-fill-palau'), '채움 80%');

    await tester.tap(find.byKey(const Key('seat-score-tab-product')));
    await tester.pump();
    expect(_count(tester, 'seat-score-product-cebu-live'), '세부 리브');
    expect(_count(tester, 'seat-score-product-cebu-live-region'), '필리핀 세부');
    expect(_count(tester, 'seat-score-product-palau-live'), '팔라우 씨월드');
    expect(_count(tester, 'seat-score-product-palau-live-region'), '팔라우');
    expect(find.byKey(const Key('seat-score-region-cebu')), findsNothing);

    await tester.tap(find.byKey(const Key('seat-brief-preset-today')));
    await tester.pump();
    await tester.pump();
    expect(_count(tester, 'seat-brief-conclusion'), '기록이 더 쌓이면 알려 드릴게요');
    expect(find.byKey(const Key('seat-score-empty')), findsOneWidget);
    expect(repo.debugSeatEventQueries.last, (
      DateTime(2026, 10, 27),
      DateTime(2026, 10, 28),
    ));
  });

  testWidgets('상품관리에서 같은배 모니터 옆 탭으로 브리프가 열린다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DiverStore(MemoryDiverRepository.forTest(isAdmin: true));
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AdminConsoleTheme.dark,
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-menu-shops')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('admin-sub-same-boat-brief')));
    await tester.tap(find.byKey(const Key('admin-sub-same-boat-brief')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('admin-same-boat-brief')), findsOneWidget);
    expect(find.byKey(const Key('seat-brief-preset-7')), findsOneWidget);
  });
}

String _count(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

SeatLifeEvent _event(
  String id,
  String kind,
  DateTime at, {
  String region = '',
  String productId = 'seat-1',
}) {
  return SeatLifeEvent(
    id: id,
    kind: kind,
    seatId: 'seat-1',
    shopId: 'shop-a',
    productId: productId,
    userKey: 'a' * 64,
    region: region,
    at: at,
  );
}

Future<void> _plant(
  MemoryDiverRepository repo,
  String id,
  String kind,
  DateTime at, {
  String region = '',
  String productId = 'seat-1',
}) {
  return repo.createSeatEvent(
    _event(id, kind, at, region: region, productId: productId),
  );
}

Future<bool> _demand(
  MemoryDiverRepository repo,
  String uid,
  SameBoatSearch search,
  DateTime at,
  SeatUnlock? unlock,
) {
  return repo.createSeatDemand(
    SeatDemand.forSearch(uid: uid, search: search, at: at, unlockBy: unlock),
  );
}
