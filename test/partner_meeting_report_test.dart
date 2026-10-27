import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';

void main() {
  const secret = 'SECRET-USER-KEY';
  final period = MeetingReportRecipe(
    shopId: 'palau-dive--listing',
    regionId: 'palau',
    periodStart: DateTime(2026, 10, 1),
    periodEnd: DateTime(2026, 10, 27),
    compare: true,
  );

  test('샵 비교는 -- 앞부분으로 맞추고 다른 샵과 기간 밖은 빠진다', () {
    expect(partnerShopHull(' palau-dive--listing '), 'palau-dive');
    expect(partnerShopHull('palau-dive'), 'palau-dive');

    final report = buildPartnerMeetingReport(
      id: 'rep-1',
      recipe: period,
      createdAt: DateTime.utc(2026, 10, 27),
      events: [
        _event('mine', 'view', DateTime(2026, 10, 22), shopId: 'palau-dive'),
        _event('other', 'view', DateTime(2026, 10, 22), shopId: 'cebu-dive'),
        _event('old', 'view', DateTime(2026, 9, 30), shopId: 'palau-dive'),
        _event('pay', 'pay', DateTime(2026, 10, 23), shopId: 'palau-dive'),
        _event('pay2', 'pay', DateTime(2026, 10, 24), shopId: 'palau-dive'),
        _event('pay3', 'pay', DateTime(2026, 10, 25), shopId: 'palau-dive'),
      ],
      previousEvents: [
        _event('prev-mine', 'view', DateTime(2026, 9, 10), shopId: 'palau-dive'),
        _event('prev-other', 'view', DateTime(2026, 9, 10), shopId: 'cebu-dive'),
      ],
      demands: const [],
      seats: const [
        MeetingReportSeat(
          shopId: 'palau-dive',
          productId: 'live',
          productName: '팔라우 씨월드',
          regionId: 'palau',
          booked: 8,
          capacity: 10,
        ),
        MeetingReportSeat(
          shopId: 'cebu-dive',
          productId: 'other',
          productName: '세부',
          regionId: 'cebu',
          booked: 20,
          capacity: 20,
        ),
      ],
    );

    expect(report.recipe.hullId, 'palau-dive');
    expect(report.snapshot.funnel.views, 1);
    expect(report.snapshot.funnel.pays, 3);
    expect(report.snapshot.funnelPrevious?.views, 1);
    expect(report.snapshot.fillPercent, 80);
    expect(report.snapshot.scoreRows, hasLength(1));
    expect(report.snapshot.scoreRows.first.productId, 'live');
    expect(report.withinShape, isTrue);
  });

  test('수요는 그 지역 조건만 묶고 회원 키는 남지 않는다', () {
    final report = buildPartnerMeetingReport(
      id: 'rep-2',
      recipe: period,
      createdAt: DateTime.utc(2026, 10, 27),
      events: [
        for (var i = 0; i < 30; i++)
          _event('view-$i', 'view', DateTime(2026, 10, 22), shopId: 'palau-dive'),
        _event('flag-1', 'flag', DateTime(2026, 10, 22), shopId: 'palau-dive'),
        _event('flag-2', 'flag', DateTime(2026, 10, 22), shopId: 'palau-dive'),
      ],
      demands: [
        _demand('a', secret, const {'palau'}, party: 2, budget: SameBoatSearch.budget100),
        _demand('b', 'other-secret', const {'palau'}, party: 2, budget: SameBoatSearch.budget100),
        _demand('c', secret, const {'cebu'}, party: 4),
        _demand(
          'd',
          secret,
          const {'palau'},
          party: 4,
          when: SameBoatWhen.nextMonth,
          unlock: null,
        ),
      ],
      seats: const [
        MeetingReportSeat(
          shopId: 'palau-dive',
          productId: 'live',
          productName: '팔라우 씨월드',
          regionId: 'palau',
          booked: 3,
          capacity: 20,
        ),
      ],
    );

    expect(report.snapshot.demands.map((line) => line.count).toList(), [2, 1]);
    expect(report.snapshot.demands.first.label, '10월 · 2명 · 1인 100만 이하');
    final stored = report.toMap().toString();
    expect(stored.contains(secret), isFalse);
    expect(stored.contains('user_key'), isFalse);
    expect(stored.contains('cebu'), isFalse);
    expect(
      report.snapshot.conclusion,
      '팔라우는 조회 30 · 깃발 2 · 결제 0. 가격이 원인일 수 있어요',
    );
    expect(report.snapshot.proposals, [
      '10월 · 2명 · 1인 100만 이하 수요 2건. 가격이 원인일 수 있어요',
      '11월 · 4명 수요 1건.',
    ]);
    expect(report.snapshot.proposals.join().contains('막고'), isFalse);
    expect(report.snapshot.proposals.join().contains('벽'), isFalse);
    expect(report.snapshot.proposals.join().contains('석'), isFalse);
    expect(report.snapshot.proposals.join().contains('만원대'), isFalse);
  });

  test('잘 팔리고 수요가 있으면 그 조건을 결론에 붙인다', () {
    final report = buildPartnerMeetingReport(
      id: 'rep-3',
      recipe: period,
      createdAt: DateTime.utc(2026, 10, 27),
      events: [
        _event('view', 'view', DateTime(2026, 10, 22), shopId: 'palau-dive'),
        for (var i = 0; i < 3; i++)
          _event('pay-$i', 'pay', DateTime(2026, 10, 23, i), shopId: 'palau-dive'),
      ],
      demands: [
        for (var i = 0; i < 14; i++)
          _demand(
            'd-$i',
            secret,
            const {'palau'},
            party: 2,
            budget: SameBoatSearch.budget100,
            when: SameBoatWhen.nextMonth,
          ),
      ],
      seats: const [
        MeetingReportSeat(
          shopId: 'palau-dive',
          productId: 'live',
          productName: '팔라우 씨월드',
          regionId: 'palau',
          booked: 8,
          capacity: 10,
        ),
      ],
    );

    expect(
      report.snapshot.conclusion,
      '11월 팔라우 자리는 조회 1 · 결제 3으로 반응이 좋지만, 2명 · 1인 100만 이하 조건 수요 14건이 자리를 못 찾았어요.',
    );
    expect(report.snapshot.conclusion.contains('막고'), isFalse);
  });

  test('기록이 없으면 결론과 제안은 더 쌓이면 알려 준다', () {
    final report = buildPartnerMeetingReport(
      id: 'rep-4',
      recipe: period,
      createdAt: DateTime.utc(2026, 10, 27),
      events: const [],
      demands: const [],
      seats: const [],
    );
    expect(report.snapshot.conclusion, meetingReportWait);
    expect(report.snapshot.proposals, [meetingReportWait]);
  });

  test('레시피는 다음 달로 밀리고 보내기 취소는 shared를 끈다', () {
    final report = buildPartnerMeetingReport(
      id: 'rep-5',
      recipe: period,
      createdAt: DateTime.utc(2026, 10, 27, 1),
      events: [
        _event('view', 'view', DateTime(2026, 10, 22), shopId: 'palau-dive'),
      ],
      demands: const [],
      seats: const [],
    );
    final next = report.recipe.nextMonth();
    expect(next.periodStart, DateTime(2026, 11, 1));
    expect(next.periodEnd, DateTime(2026, 11, 27));
    expect(next.hullId, 'palau-dive');

    final sent = report.share(DateTime.utc(2026, 10, 27, 2));
    expect(sent.shared, isTrue);
    expect(sent.toMap().containsKey('shared_at'), isTrue);
    final cancelled = sent.unshare();
    expect(cancelled.shared, isFalse);
    expect(cancelled.sharedAt, isNull);
    expect(cancelled.toMap().containsKey('shared_at'), isFalse);
    expect(cancelled.snapshot.conclusion, report.snapshot.conclusion);

    final rebuilt = buildPartnerMeetingReport(
      id: 'rep-6',
      recipe: next,
      createdAt: DateTime.utc(2026, 11, 27),
      events: report.recipe.periodStart == next.periodStart
          ? [_event('view', 'view', DateTime(2026, 10, 22), shopId: 'palau-dive')]
          : const [],
      demands: const [],
      seats: const [],
    );
    expect(rebuilt.snapshot.funnel.views, 0);
    expect(rebuilt.snapshot.conclusion, meetingReportWait);

    final leaked = Map<String, dynamic>.from(report.toMap());
    (leaked['snapshot'] as Map)['user_key'] = secret;
    expect(PartnerMeetingReport.fromMap('rep-5', leaked), isNull);
    expect(
      PartnerMeetingReport.fromMap('rep-5', Map<String, dynamic>.from(report.toMap())),
      isNotNull,
    );
  });

  test('끄지 않은 섹션만 스냅샷에 남는다', () {
    final report = buildPartnerMeetingReport(
      id: 'rep-7',
      recipe: MeetingReportRecipe(
        shopId: 'palau-dive',
        regionId: 'palau',
        periodStart: DateTime(2026, 10, 1),
        periodEnd: DateTime(2026, 10, 27),
        sections: const MeetingReportSections(proposals: false, demand: false),
      ),
      createdAt: DateTime.utc(2026, 10, 27),
      events: [
        _event('view', 'view', DateTime(2026, 10, 22), shopId: 'palau-dive'),
      ],
      demands: [
        _demand('a', secret, const {'palau'}, party: 2),
      ],
      seats: const [],
    );
    final snapshot = report.toMap()['snapshot'] as Map;
    expect(snapshot.containsKey('proposals'), isFalse);
    expect(snapshot.containsKey('demands'), isFalse);
    expect(snapshot.containsKey('funnel'), isTrue);
    expect(snapshot.toString().contains(secret), isFalse);
  });

  test('받은 목록은 shared와 샵 앞부분을 함께 건다', () async {
    final query = MeetingReportListQuery.sharedForOwnedShop(
      'palau-dive--fundive',
    );
    expect(query, isNotNull);
    expect(query!.shared, isTrue);
    expect(query.shopId, 'palau-dive');
    expect(MeetingReportListQuery.sharedForOwnedShop('--listing'), isNull);
    expect(MeetingReportListQuery.sharedForOwnedShop('   '), isNull);

    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'palau-dive--fundive',
    );
    final mine = _stored('mr_palau', 'palau-dive');
    final draft = _stored('mr_draft', 'palau-dive');
    final other = _stored('mr_cebu', 'cebu-dive');
    await repo.saveMeetingReport(mine);
    await repo.saveMeetingReport(draft);
    await repo.saveMeetingReport(other);
    await repo.setMeetingReportShared(id: mine.id, shared: true);
    await repo.setMeetingReportShared(id: other.id, shared: true);

    final rows = await repo.listSharedMeetingReports(
      shopId: 'palau-dive--fundive',
    );
    expect(repo.debugMeetingReportQueries, hasLength(1));
    expect(repo.debugMeetingReportQueries.single.shared, isTrue);
    expect(repo.debugMeetingReportQueries.single.shopId, 'palau-dive');
    expect(rows.map((row) => row.id), ['mr_palau']);

    expect(await repo.listSharedMeetingReports(shopId: '--x'), isEmpty);
    expect(repo.debugMeetingReportQueries, hasLength(1));

    expect((await repo.getMeetingReport('mr_palau'))?.id, 'mr_palau');
    expect(repo.getMeetingReport('mr_draft'), throwsStateError);
    expect(repo.getMeetingReport('mr_cebu'), throwsStateError);
  });

  test('링크는 #report=id만 담고 숫자는 넣지 않는다', () {
    final page = Uri.parse(
      'https://jckim321.github.io/dive-travel/?views=30&pays=3#/',
    );
    final url = meetingReportShareUrl(page, 'mr_palau');
    expect(url, 'https://jckim321.github.io/dive-travel/#report=mr_palau');
    expect(url.contains('30'), isFalse);
    expect(url.contains('pays'), isFalse);
    expect(meetingReportIdFromFragment(Uri.parse(url).fragment), 'mr_palau');
    expect(meetingReportIdFromFragment('#report=mr_palau'), 'mr_palau');
    expect(meetingReportIdFromFragment('report=mr_palau&views=30'), isNull);
    expect(meetingReportIdFromFragment(''), isNull);
    expect(
      meetingReportCreatedLabel(DateTime(2026, 10, 27, 15)),
      '2026.10.27',
    );
  });
}

PartnerMeetingReport _stored(String id, String shopId) {
  return buildPartnerMeetingReport(
    id: id,
    recipe: MeetingReportRecipe(
      shopId: shopId,
      periodStart: DateTime(2026, 10, 21),
      periodEnd: DateTime(2026, 10, 27),
    ),
    events: const [],
    demands: const [],
    seats: const [],
    createdAt: DateTime(2026, 10, 27, 15),
  );
}

SeatLifeEvent _event(
  String id,
  String kind,
  DateTime at, {
  required String shopId,
}) {
  return SeatLifeEvent(
    id: id,
    kind: kind,
    seatId: 'seat-1',
    shopId: shopId,
    productId: 'live',
    userKey: 'a' * 64,
    at: at,
  );
}

SeatDemand _demand(
  String id,
  String userKey,
  Set<String> regions, {
  int? party,
  int? budget,
  SameBoatWhen when = SameBoatWhen.thisMonth,
  DateTime? at,
  SeatUnlock? unlock = SeatUnlock.budget,
}) {
  return SeatDemand(
    id: id,
    userKey: userKey,
    day: '2026-10-22',
    search: SameBoatSearch(
      when: when,
      regionIds: regions,
      party: party,
      budgetMax: budget,
    ),
    at: at ?? DateTime(2026, 10, 22, 12),
    unlockBy: unlock,
  );
}
