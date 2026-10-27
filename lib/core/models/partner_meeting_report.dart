import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/seat_score.dart';

/// Seat events store the hull, the text before `--`.
/// `owned_shop_id` is the shop id saved at promotion, which can be a listing
/// id such as `hull--product`. Compare only through this function.
String partnerShopHull(String shopId) {
  final trimmed = shopId.trim();
  final cut = trimmed.indexOf('--');
  if (cut < 0) {
    return trimmed;
  }
  return trimmed.substring(0, cut);
}

const meetingReportForbiddenKeys = {
  'uid',
  'user_key',
  'name',
  'email',
  'phone',
  'nationality',
  'member_grade',
};

const meetingReportWait = '기록이 더 쌓이면 알려 드릴게요';

class MeetingReportSections {
  const MeetingReportSections({
    this.conclusion = true,
    this.funnel = true,
    this.scorecard = true,
    this.demand = true,
    this.proposals = true,
  });

  final bool conclusion;
  final bool funnel;
  final bool scorecard;
  final bool demand;
  final bool proposals;

  Map<String, Object> toMap() {
    return {
      'conclusion': conclusion,
      'funnel': funnel,
      'scorecard': scorecard,
      'demand': demand,
      'proposals': proposals,
    };
  }

  static MeetingReportSections fromMap(Map<String, dynamic> data) {
    return MeetingReportSections(
      conclusion: data['conclusion'] == true,
      funnel: data['funnel'] == true,
      scorecard: data['scorecard'] == true,
      demand: data['demand'] == true,
      proposals: data['proposals'] == true,
    );
  }
}

/// Conditions to build again. Dates are inclusive local days.
class MeetingReportRecipe {
  const MeetingReportRecipe({
    required this.shopId,
    required this.periodStart,
    required this.periodEnd,
    this.productIds = const [],
    this.regionId = '',
    this.compare = false,
    this.sections = const MeetingReportSections(),
  });

  final String shopId;
  final List<String> productIds;
  final String regionId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool compare;
  final MeetingReportSections sections;

  String get hullId => partnerShopHull(shopId);

  /// Same length, pushed one calendar month. Does not copy numbers.
  MeetingReportRecipe nextMonth() {
    final start = _dateOnly(periodStart);
    final end = _dateOnly(periodEnd);
    final length = end.difference(start);
    final shifted = DateTime(start.year, start.month + 1, start.day);
    final nextStart =
        shifted.month == (start.month % 12) + 1 ||
            (start.month == 12 && shifted.month == 1)
        ? shifted
        : DateTime(start.year, start.month + 2, 0);
    return MeetingReportRecipe(
      shopId: hullId,
      productIds: productIds,
      regionId: regionId,
      periodStart: nextStart,
      periodEnd: nextStart.add(length),
      compare: compare,
      sections: sections,
    );
  }

  Map<String, Object> toMap() {
    return {
      'shop_id': hullId,
      'product_ids': productIds,
      'region_id': regionId,
      'period_start': _dayId(periodStart),
      'period_end': _dayId(periodEnd),
      'compare': compare,
      'sections': sections.toMap(),
    };
  }

  static MeetingReportRecipe? fromMap(Map<String, dynamic> data) {
    final shopId = data['shop_id'];
    final start = _parseDay(data['period_start']);
    final end = _parseDay(data['period_end']);
    final sections = data['sections'];
    if (shopId is! String || start == null || end == null) {
      return null;
    }
    if (sections is! Map) {
      return null;
    }
    return MeetingReportRecipe(
      shopId: partnerShopHull(shopId),
      productIds: [
        for (final id in data['product_ids'] as List? ?? const [])
          if (id is String) id,
      ],
      regionId: data['region_id'] as String? ?? '',
      periodStart: start,
      periodEnd: end,
      compare: data['compare'] == true,
      sections: MeetingReportSections.fromMap(Map<String, dynamic>.from(sections)),
    );
  }
}

class MeetingDemandLine {
  const MeetingDemandLine({required this.label, required this.count});

  final String label;
  final int count;

  Map<String, Object> toMap() => {'label': label, 'count': count};
}

class MeetingScoreLine {
  const MeetingScoreLine({
    required this.productId,
    required this.title,
    required this.views,
    required this.flags,
    required this.pays,
    required this.fillPercent,
    required this.badge,
  });

  final String productId;
  final String title;
  final int views;
  final int flags;
  final int pays;
  final int fillPercent;
  final SeatScoreBadge badge;

  Map<String, Object> toMap() {
    return {
      'product_id': productId,
      'title': title,
      'views': views,
      'flags': flags,
      'pays': pays,
      'fill_percent': fillPercent,
      'badge': badge.name,
    };
  }
}

class MeetingReportSnapshot {
  const MeetingReportSnapshot({
    this.conclusion = '',
    this.funnel = SeatBriefFunnel.empty,
    this.funnelPrevious,
    this.fillPercent = 0,
    this.scoreRows = const [],
    this.demands = const [],
    this.proposals = const [],
  });

  final String conclusion;
  final SeatBriefFunnel funnel;
  final SeatBriefFunnel? funnelPrevious;
  final int fillPercent;
  final List<MeetingScoreLine> scoreRows;
  final List<MeetingDemandLine> demands;
  final List<String> proposals;
}

/// One current seat used only for fill rate. No member fields.
class MeetingReportSeat {
  const MeetingReportSeat({
    required this.shopId,
    required this.productId,
    required this.productName,
    required this.regionId,
    required this.booked,
    required this.capacity,
  });

  final String shopId;
  final String productId;
  final String productName;
  final String regionId;
  final int booked;
  final int capacity;
}

class PartnerMeetingReport {
  const PartnerMeetingReport({
    required this.id,
    required this.recipe,
    required this.snapshot,
    required this.createdAt,
    this.shared = false,
    this.sharedAt,
  });

  final String id;
  final MeetingReportRecipe recipe;
  final MeetingReportSnapshot snapshot;
  final DateTime createdAt;
  final bool shared;
  final DateTime? sharedAt;

  PartnerMeetingReport share(DateTime at) {
    return PartnerMeetingReport(
      id: id,
      recipe: recipe,
      snapshot: snapshot,
      createdAt: createdAt,
      shared: true,
      sharedAt: at,
    );
  }

  /// Takes a sent report back. The partner can no longer read it.
  PartnerMeetingReport unshare() {
    return PartnerMeetingReport(
      id: id,
      recipe: recipe,
      snapshot: snapshot,
      createdAt: createdAt,
      shared: false,
    );
  }

  Map<String, Object> toMap() {
    final sections = recipe.sections;
    final snapshot = <String, Object>{};
    if (sections.conclusion) {
      snapshot['conclusion'] = this.snapshot.conclusion;
    }
    if (sections.funnel) {
      snapshot['funnel'] = _funnelMap(this.snapshot.funnel);
      final previous = this.snapshot.funnelPrevious;
      if (recipe.compare && previous != null) {
        snapshot['funnel_previous'] = _funnelMap(previous);
      }
    }
    if (sections.scorecard) {
      snapshot['fill_percent'] = this.snapshot.fillPercent;
      snapshot['score_rows'] = [
        for (final row in this.snapshot.scoreRows) row.toMap(),
      ];
    }
    if (sections.demand && this.snapshot.demands.isNotEmpty) {
      snapshot['demands'] = [
        for (final line in this.snapshot.demands) line.toMap(),
      ];
    }
    if (sections.proposals && this.snapshot.proposals.isNotEmpty) {
      snapshot['proposals'] = this.snapshot.proposals;
    }
    return {
      'shop_id': recipe.hullId,
      'recipe': recipe.toMap(),
      'snapshot': snapshot,
      'shared': shared,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (shared && sharedAt != null)
        'shared_at': sharedAt!.toUtc().toIso8601String(),
    };
  }

  bool get withinShape {
    final data = toMap();
    if (meetingMapHasForbidden(data)) {
      return false;
    }
    final shopId = data['shop_id'];
    if (shopId is! String || shopId.isEmpty || shopId != partnerShopHull(shopId)) {
      return false;
    }
    if (data['shared'] is! bool || data['created_at'] is! String) {
      return false;
    }
    if (shared && data['shared_at'] is! String) {
      return false;
    }
    if (!shared && data.containsKey('shared_at')) {
      return false;
    }
    final snapshot = data['snapshot'];
    if (snapshot is! Map) {
      return false;
    }
    final conclusion = snapshot['conclusion'];
    if (conclusion is String && conclusion.length > 400) {
      return false;
    }
    final proposals = snapshot['proposals'];
    if (proposals is List) {
      if (proposals.length > 2) {
        return false;
      }
      for (final line in proposals) {
        if (line is! String || line.length > 200) {
          return false;
        }
      }
    }
    final rows = snapshot['score_rows'];
    if (rows is List && rows.length > 20) {
      return false;
    }
    return true;
  }

  static PartnerMeetingReport? fromMap(String id, Map<String, dynamic> data) {
    if (meetingMapHasForbidden(data)) {
      return null;
    }
    final recipeRaw = data['recipe'];
    if (recipeRaw is! Map) {
      return null;
    }
    final recipe = MeetingReportRecipe.fromMap(Map<String, dynamic>.from(recipeRaw));
    if (recipe == null) {
      return null;
    }
    final createdAt = DateTime.tryParse(data['created_at'] as String? ?? '');
    if (createdAt == null || data['shared'] is! bool) {
      return null;
    }
    final report = PartnerMeetingReport(
      id: id,
      recipe: recipe,
      snapshot: _snapshotFromMap(data['snapshot']),
      createdAt: createdAt,
      shared: data['shared'] as bool,
      sharedAt: DateTime.tryParse(data['shared_at'] as String? ?? ''),
    );
    if (!report.withinShape) {
      return null;
    }
    return report;
  }
}

/// Counts and sentences for one partner. Other shops and member keys are dropped.
PartnerMeetingReport buildPartnerMeetingReport({
  required String id,
  required MeetingReportRecipe recipe,
  required Iterable<SeatLifeEvent> events,
  required Iterable<SeatDemand> demands,
  required Iterable<MeetingReportSeat> seats,
  required DateTime createdAt,
  Iterable<SeatLifeEvent> previousEvents = const [],
}) {
  final hull = recipe.hullId;
  final stored = MeetingReportRecipe(
    shopId: hull,
    productIds: recipe.productIds,
    regionId: recipe.regionId,
    periodStart: recipe.periodStart,
    periodEnd: recipe.periodEnd,
    compare: recipe.compare,
    sections: recipe.sections,
  );
  final mine = [
    for (final event in events)
      if (_eventInReport(event, stored)) event,
  ];
  final earlier = [
    for (final event in previousEvents)
      if (_eventForShop(event, stored)) event,
  ];
  final shopSeats = [
    for (final seat in seats)
      if (_seatInReport(seat, stored)) seat,
  ];
  final funnel = seatBriefFunnel(mine);
  final funnelPrevious = stored.compare ? seatBriefFunnel(earlier) : null;
  final booked = shopSeats.fold<int>(0, (sum, seat) => sum + seat.booked);
  final capacity = shopSeats.fold<int>(0, (sum, seat) => sum + seat.capacity);
  final fill = seatFillPercent(booked, capacity);
  final scoreRows = _scoreRows(mine, shopSeats);
  final demandLines = _demandLines(demands, stored, shopSeats);
  final regionName = _regionName(stored, shopSeats);
  final top = demandLines.isEmpty ? null : demandLines.first;
  return PartnerMeetingReport(
    id: id,
    recipe: stored,
    createdAt: createdAt,
    snapshot: MeetingReportSnapshot(
      conclusion: meetingConclusion(
        regionName: regionName,
        funnel: funnel,
        fillPercent: fill,
        topDemand: top,
      ),
      funnel: funnel,
      funnelPrevious: funnelPrevious,
      fillPercent: fill,
      scoreRows: scoreRows,
      demands: [
        for (final line in demandLines)
          MeetingDemandLine(label: line.label, count: line.count),
      ],
      proposals: meetingProposals(demandLines),
    ),
  );
}

String meetingConclusion({
  required String regionName,
  required SeatBriefFunnel funnel,
  required int fillPercent,
  required _DemandDraft? topDemand,
}) {
  final activity =
      funnel.opens + funnel.views + funnel.flags + funnel.pays > 0;
  if (!activity) {
    return meetingReportWait;
  }
  final badge = seatScoreBadge(
    views: funnel.views,
    flags: funnel.flags,
    pays: funnel.pays,
    fillPercent: fillPercent,
  );
  if (badge == SeatScoreBadge.selling) {
    final place = _placeClause(regionName, topDemand);
    final head =
        '$place 조회 ${funnel.views} · 결제 ${funnel.pays}${_way(funnel.pays)} 반응이 좋';
    if (topDemand == null || topDemand.condition.isEmpty) {
      return '$head아요.';
    }
    return '$head지만, ${topDemand.condition} 조건 수요 ${topDemand.count}건이 자리를 못 찾았어요.';
  }
  if (badge == SeatScoreBadge.viewsOnly) {
    final who = regionName.isEmpty ? '' : seatScoreTopic(regionName);
    final lead = who.isEmpty ? '' : '$who ';
    return '$lead조회 ${funnel.views} · 깃발 ${funnel.flags} · 결제 ${funnel.pays}. 가격이 원인일 수 있어요';
  }
  return meetingReportWait;
}

List<String> meetingProposals(List<_DemandDraft> lines) {
  if (lines.isEmpty) {
    return const [meetingReportWait];
  }
  final picked = <_DemandDraft>[lines.first];
  for (final line in lines.skip(1)) {
    if (line.when != lines.first.when || line.party != lines.first.party) {
      picked.add(line);
      break;
    }
  }
  return [for (final line in picked.take(2)) line.proposal];
}

class _DemandDraft {
  const _DemandDraft({
    required this.label,
    required this.condition,
    required this.count,
    required this.when,
    required this.party,
    required this.month,
    required this.proposal,
  });

  final String label;
  final String condition;
  final int count;
  final SameBoatWhen when;
  final int? party;
  final String? month;
  final String proposal;
}

bool _eventForShop(SeatLifeEvent event, MeetingReportRecipe recipe) {
  if (partnerShopHull(event.shopId) != recipe.hullId || recipe.hullId.isEmpty) {
    return false;
  }
  if (recipe.productIds.isEmpty) {
    return true;
  }
  return recipe.productIds.contains(event.productId);
}

bool _eventInReport(SeatLifeEvent event, MeetingReportRecipe recipe) {
  return _eventForShop(event, recipe) &&
      _inPeriod(event.at, recipe.periodStart, recipe.periodEnd);
}

bool _seatInReport(MeetingReportSeat seat, MeetingReportRecipe recipe) {
  if (partnerShopHull(seat.shopId) != recipe.hullId || recipe.hullId.isEmpty) {
    return false;
  }
  if (recipe.productIds.isNotEmpty && !recipe.productIds.contains(seat.productId)) {
    return false;
  }
  if (recipe.regionId.isNotEmpty && seat.regionId != recipe.regionId) {
    return false;
  }
  return true;
}

bool _inPeriod(DateTime at, DateTime start, DateTime endInclusive) {
  final from = _dateOnly(start);
  final to = _dateOnly(endInclusive).add(const Duration(days: 1));
  return !at.isBefore(from) && at.isBefore(to);
}

List<MeetingScoreLine> _scoreRows(
  List<SeatLifeEvent> events,
  List<MeetingReportSeat> seats,
) {
  final byProduct = <String, List<SeatLifeEvent>>{};
  for (final event in events) {
    if (event.productId.isEmpty) {
      continue;
    }
    if (event.kind != 'view' && event.kind != 'flag' && event.kind != 'pay') {
      continue;
    }
    byProduct.putIfAbsent(event.productId, () => []).add(event);
  }
  final names = <String, String>{};
  final booked = <String, int>{};
  final capacity = <String, int>{};
  for (final seat in seats) {
    if (seat.productName.isNotEmpty) {
      names[seat.productId] = seat.productName;
    }
    booked[seat.productId] = (booked[seat.productId] ?? 0) + seat.booked;
    capacity[seat.productId] = (capacity[seat.productId] ?? 0) + seat.capacity;
  }
  final rows = <MeetingScoreLine>[];
  for (final entry in byProduct.entries) {
    final funnel = seatBriefFunnel(entry.value);
    final fill = seatFillPercent(
      booked[entry.key] ?? 0,
      capacity[entry.key] ?? 0,
    );
    rows.add(
      MeetingScoreLine(
        productId: entry.key,
        title: names[entry.key] ?? entry.key,
        views: funnel.views,
        flags: funnel.flags,
        pays: funnel.pays,
        fillPercent: fill,
        badge: seatScoreBadge(
          views: funnel.views,
          flags: funnel.flags,
          pays: funnel.pays,
          fillPercent: fill,
        ),
      ),
    );
  }
  rows.sort((a, b) {
    final byViews = b.views.compareTo(a.views);
    if (byViews != 0) {
      return byViews;
    }
    return a.productId.compareTo(b.productId);
  });
  if (rows.length > 20) {
    return rows.sublist(0, 20);
  }
  return rows;
}

List<_DemandDraft> _demandLines(
  Iterable<SeatDemand> demands,
  MeetingReportRecipe recipe,
  List<MeetingReportSeat> seats,
) {
  final regions = <String>{
    if (recipe.regionId.isNotEmpty) recipe.regionId,
    if (recipe.regionId.isEmpty)
      for (final seat in seats)
        if (seat.regionId.isNotEmpty) seat.regionId,
  };
  final buckets = <String, _DemandAcc>{};
  for (final demand in demands) {
    if (!_demandMatches(demand, regions)) {
      continue;
    }
    final key = _demandKey(demand.search);
    final acc = buckets.putIfAbsent(key, () => _DemandAcc(demand.search, demand.at));
    acc.count += 1;
    if (demand.at.isAfter(acc.latestAt)) {
      acc.latestAt = demand.at;
    }
    final unlock = demand.unlockBy;
    if (unlock != null) {
      acc.unlocks[unlock] = (acc.unlocks[unlock] ?? 0) + 1;
    }
  }
  final ranked = buckets.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) {
        return byCount;
      }
      return _demandKey(a.search).compareTo(_demandKey(b.search));
    });
  return [
    for (final acc in ranked.take(3))
      _DemandDraft(
        label: _demandLabel(acc, includeMonth: true),
        condition: _demandLabel(acc, includeMonth: false),
        count: acc.count,
        when: acc.search.when,
        party: acc.search.party,
        month: _whenMonth(acc.search.when, acc.latestAt),
        proposal: _proposal(acc),
      ),
  ];
}

bool _demandMatches(SeatDemand demand, Set<String> regions) {
  if (regions.isEmpty) {
    return false;
  }
  for (final id in demand.search.regionIds) {
    if (regions.contains(id)) {
      return true;
    }
  }
  return false;
}

String _demandKey(SameBoatSearch search) {
  final regions = search.regionIds.toList()..sort();
  return [
    search.when.name,
    regions.join(','),
    '${search.party ?? 0}',
    '${search.budgetMax ?? 0}',
    search.lastCall,
    search.departingSoon,
  ].join('|');
}

String _proposal(_DemandAcc acc) {
  final label = _demandLabel(acc, includeMonth: true);
  final demand = '$label 수요 ${acc.count}건.';
  if (_priceMayBeCause(acc)) {
    return '$demand 가격이 원인일 수 있어요';
  }
  return demand;
}

bool _priceMayBeCause(_DemandAcc acc) {
  if (acc.search.budgetMax != null) {
    return true;
  }
  if (acc.unlocks.isEmpty) {
    return false;
  }
  var top = 0;
  SeatUnlock? winner;
  for (final entry in acc.unlocks.entries) {
    if (entry.value > top) {
      top = entry.value;
      winner = entry.key;
    }
  }
  return winner == SeatUnlock.budget;
}

String _demandLabel(_DemandAcc acc, {required bool includeMonth}) {
  final parts = <String>[];
  if (includeMonth) {
    final month = _whenMonth(acc.search.when, acc.latestAt);
    if (month != null) {
      parts.add(month);
    }
  }
  final party = acc.search.party;
  if (party != null) {
    parts.add(
      party >= SameBoatSearch.partyFivePlus ? '5명+' : '$party명',
    );
  }
  final budget = acc.search.budgetMax;
  if (budget != null) {
    parts.add('1인 ${_budgetLabel(budget)}');
  }
  return parts.join(' · ');
}

String _budgetLabel(int budget) {
  if (budget == SameBoatSearch.budget50) {
    return '50만 이하';
  }
  if (budget == SameBoatSearch.budget100) {
    return '100만 이하';
  }
  if (budget == SameBoatSearch.budget200) {
    return '200만 이하';
  }
  return '$budget원 이하';
}

String? _whenMonth(SameBoatWhen when, DateTime at) {
  final local = at.toLocal();
  switch (when) {
    case SameBoatWhen.any:
      return null;
    case SameBoatWhen.thisMonth:
      return '${local.month}월';
    case SameBoatWhen.nextMonth:
      return '${DateTime(local.year, local.month + 1).month}월';
    case SameBoatWhen.withinThreeMonths:
      return '3개월 이내';
  }
}

String _regionName(MeetingReportRecipe recipe, List<MeetingReportSeat> seats) {
  if (recipe.regionId.isNotEmpty) {
    final name = seatCatalogRegionName(recipe.regionId);
    if (name.isNotEmpty) {
      return name;
    }
  }
  for (final seat in seats) {
    final name = seatCatalogRegionName(seat.regionId);
    if (name.isNotEmpty) {
      return name;
    }
  }
  return '';
}

String _way(int value) {
  const batchim = {0, 1, 3, 6, 7, 8};
  return batchim.contains(value.abs() % 10) ? '으로' : '로';
}

String _placeClause(String regionName, _DemandDraft? top) {
  final month = top?.month;
  if (regionName.isEmpty) {
    return month == null ? '이 자리는' : '$month 자리는';
  }
  if (month == null) {
    return '$regionName 자리는';
  }
  return '$month $regionName 자리는';
}

class _DemandAcc {
  _DemandAcc(this.search, this.latestAt);

  final SameBoatSearch search;
  int count = 0;
  DateTime latestAt;
  final unlocks = <SeatUnlock, int>{};
}

Map<String, Object> _funnelMap(SeatBriefFunnel funnel) {
  return {
    'opens': funnel.opens,
    'views': funnel.views,
    'flags': funnel.flags,
    'pays': funnel.pays,
  };
}

MeetingReportSnapshot _snapshotFromMap(Object? raw) {
  if (raw is! Map) {
    return const MeetingReportSnapshot();
  }
  final data = Map<String, dynamic>.from(raw);
  return MeetingReportSnapshot(
    conclusion: data['conclusion'] as String? ?? '',
    funnel: _funnelFromMap(data['funnel']),
    funnelPrevious: data['funnel_previous'] == null
        ? null
        : _funnelFromMap(data['funnel_previous']),
    fillPercent: (data['fill_percent'] as num?)?.toInt() ?? 0,
    scoreRows: [
      for (final row in data['score_rows'] as List? ?? const [])
        if (row is Map) _scoreFromMap(Map<String, dynamic>.from(row)),
    ].whereType<MeetingScoreLine>().toList(),
    demands: [
      for (final row in data['demands'] as List? ?? const [])
        if (row is Map)
          MeetingDemandLine(
            label: (row['label'] as String?) ?? '',
            count: (row['count'] as num?)?.toInt() ?? 0,
          ),
    ],
    proposals: [
      for (final line in data['proposals'] as List? ?? const [])
        if (line is String) line,
    ],
  );
}

MeetingScoreLine? _scoreFromMap(Map<String, dynamic> data) {
  final productId = data['product_id'];
  if (productId is! String) {
    return null;
  }
  return MeetingScoreLine(
    productId: productId,
    title: data['title'] as String? ?? productId,
    views: (data['views'] as num?)?.toInt() ?? 0,
    flags: (data['flags'] as num?)?.toInt() ?? 0,
    pays: (data['pays'] as num?)?.toInt() ?? 0,
    fillPercent: (data['fill_percent'] as num?)?.toInt() ?? 0,
    badge: _badgeOf(data['badge'] as String?),
  );
}

SeatScoreBadge _badgeOf(String? name) {
  for (final badge in SeatScoreBadge.values) {
    if (badge.name == name) {
      return badge;
    }
  }
  return SeatScoreBadge.ordinary;
}

SeatBriefFunnel _funnelFromMap(Object? raw) {
  if (raw is! Map) {
    return SeatBriefFunnel.empty;
  }
  final data = Map<String, dynamic>.from(raw);
  return SeatBriefFunnel(
    opens: (data['opens'] as num?)?.toInt() ?? 0,
    views: (data['views'] as num?)?.toInt() ?? 0,
    flags: (data['flags'] as num?)?.toInt() ?? 0,
    pays: (data['pays'] as num?)?.toInt() ?? 0,
  );
}

bool meetingMapHasForbidden(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String && meetingReportForbiddenKeys.contains(key)) {
        return true;
      }
      if (meetingMapHasForbidden(entry.value)) {
        return true;
      }
    }
  } else if (value is List) {
    for (final item in value) {
      if (meetingMapHasForbidden(item)) {
        return true;
      }
    }
  }
  return false;
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String _dayId(DateTime value) {
  final day = _dateOnly(value);
  String two(int number) => number.toString().padLeft(2, '0');
  return '${day.year}-${two(day.month)}-${two(day.day)}';
}

DateTime? _parseDay(Object? value) {
  if (value is! String) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return null;
  }
  return _dateOnly(parsed);
}
