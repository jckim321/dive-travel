import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
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
