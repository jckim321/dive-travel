import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
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
    expect(find.text('열림 → 조회 자리당 1회'), findsOneWidget);
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

SeatLifeEvent _event(String id, String kind, DateTime at) {
  return SeatLifeEvent(
    id: id,
    kind: kind,
    seatId: 'seat-1',
    shopId: 'shop-a',
    productId: 'seat-1',
    userKey: 'a' * 64,
    at: at,
  );
}

Future<void> _plant(
  MemoryDiverRepository repo,
  String id,
  String kind,
  DateTime at,
) {
  return repo.createSeatEvent(_event(id, kind, at));
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
