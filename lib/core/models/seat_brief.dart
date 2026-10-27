import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';

/// First local day `seat_events` exist. Earlier days are not in that log.
final seatEventRecordingStart = DateTime(2026, 10, 27);

enum SeatBriefPreset { today, sevenDays, thirtyDays, thisYear, custom }

/// Inclusive [start], exclusive [end]. Both are local midnights.
class SeatBriefWindow {
  const SeatBriefWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
}

DateTime seatBriefDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

SeatBriefWindow seatBriefWindow({
  required SeatBriefPreset preset,
  required DateTime now,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final today = seatBriefDateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));
  switch (preset) {
    case SeatBriefPreset.today:
      return SeatBriefWindow(start: today, end: tomorrow);
    case SeatBriefPreset.sevenDays:
      return SeatBriefWindow(
        start: today.subtract(const Duration(days: 6)),
        end: tomorrow,
      );
    case SeatBriefPreset.thirtyDays:
      return SeatBriefWindow(
        start: today.subtract(const Duration(days: 29)),
        end: tomorrow,
      );
    case SeatBriefPreset.thisYear:
      return SeatBriefWindow(start: DateTime(today.year, 1, 1), end: tomorrow);
    case SeatBriefPreset.custom:
      var start = seatBriefDateOnly(customStart ?? today);
      var endDay = seatBriefDateOnly(customEnd ?? today);
      if (endDay.isBefore(start)) {
        final swap = start;
        start = endDay;
        endDay = swap;
      }
      return SeatBriefWindow(
        start: start,
        end: endDay.add(const Duration(days: 1)),
      );
  }
}

/// The window of the same length immediately before [window].
SeatBriefWindow seatBriefPreviousWindow(SeatBriefWindow window) {
  final length = window.end.difference(window.start);
  return SeatBriefWindow(
    start: window.start.subtract(length),
    end: window.start,
  );
}

bool seatBriefBeforeRecording(SeatBriefWindow window) =>
    window.start.isBefore(seatEventRecordingStart);

String seatBriefRangeLabel(SeatBriefWindow window) {
  final last = window.end.subtract(const Duration(days: 1));
  String two(int value) => value.toString().padLeft(2, '0');
  final start =
      '${window.start.year}.${two(window.start.month)}.${two(window.start.day)}';
  final end = window.start.year == last.year
      ? '${two(last.month)}.${two(last.day)}'
      : '${last.year}.${two(last.month)}.${two(last.day)}';
  return '$start ~ $end';
}

class SeatBriefFunnel {
  const SeatBriefFunnel({
    required this.opens,
    required this.views,
    required this.flags,
    required this.pays,
  });

  static const empty = SeatBriefFunnel(opens: 0, views: 0, flags: 0, pays: 0);

  final int opens;
  final int views;
  final int flags;
  final int pays;

  int get viewsPerOpen => opens == 0 ? 0 : views ~/ opens;

  int get flagPercent => views == 0 ? 0 : flags * 100 ~/ views;

  int get payPercent => flags == 0 ? 0 : pays * 100 ~/ flags;
}

SeatBriefFunnel seatBriefFunnel(Iterable<SeatLifeEvent> events) {
  var opens = 0;
  var views = 0;
  var flags = 0;
  var pays = 0;
  for (final event in events) {
    switch (event.kind) {
      case 'open':
        opens += 1;
      case 'view':
        views += 1;
      case 'flag':
        flags += 1;
      case 'pay':
        pays += 1;
    }
  }
  return SeatBriefFunnel(opens: opens, views: views, flags: flags, pays: pays);
}

String seatBriefDeltaLabel(int current, int previous) {
  final delta = current - previous;
  if (delta > 0) {
    return '+$delta';
  }
  return '$delta';
}

class SeatDemandGroup {
  const SeatDemandGroup({
    required this.search,
    required this.count,
    required this.latestAt,
  });

  final SameBoatSearch search;
  final int count;
  final DateTime latestAt;
}

class SeatDemandWall {
  const SeatDemandWall({required this.unlock, required this.count});

  final SeatUnlock unlock;
  final int count;
}

class SeatDemandDigest {
  const SeatDemandDigest({
    required this.top,
    required this.all,
    required this.walls,
  });

  static const empty = SeatDemandDigest(top: [], all: [], walls: []);

  final List<SeatDemandGroup> top;
  final List<SeatDemandGroup> all;
  final List<SeatDemandWall> walls;

  bool get isEmpty => all.isEmpty;

  int countFor(SameBoatSearch search) {
    for (final group in all) {
      if (group.search.sameConditions(search)) {
        return group.count;
      }
    }
    return 0;
  }

  int wallCount(SeatUnlock unlock) {
    for (final wall in walls) {
      if (wall.unlock == unlock) {
        return wall.count;
      }
    }
    return 0;
  }
}

/// Top three identical searches, then unlock counts. Ignores member identity.
SeatDemandDigest seatDemandDigest(Iterable<SeatDemand> rows) {
  final groups = <String, _DemandAcc>{};
  final walls = {for (final unlock in SeatUnlock.values) unlock: 0};
  for (final row in rows) {
    final key = _demandKey(row.search);
    final acc = groups.putIfAbsent(key, () => _DemandAcc(row.search, row.at));
    acc.count += 1;
    if (row.at.isAfter(acc.latestAt)) {
      acc.latestAt = row.at;
    }
    final unlock = row.unlockBy;
    if (unlock != null) {
      walls[unlock] = walls[unlock]! + 1;
    }
  }
  final ranked = groups.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) {
        return byCount;
      }
      return _demandKey(a.search).compareTo(_demandKey(b.search));
    });
  const order = [
    SeatUnlock.budget,
    SeatUnlock.party,
    SeatUnlock.when,
    SeatUnlock.where,
    SeatUnlock.more,
  ];
  return SeatDemandDigest(
    top: [
      for (final acc in ranked.take(3))
        SeatDemandGroup(
          search: acc.search,
          count: acc.count,
          latestAt: acc.latestAt,
        ),
    ],
    all: [
      for (final acc in ranked)
        SeatDemandGroup(
          search: acc.search,
          count: acc.count,
          latestAt: acc.latestAt,
        ),
    ],
    walls: [
      for (final unlock in order)
        if (walls[unlock]! > 0)
          SeatDemandWall(unlock: unlock, count: walls[unlock]!),
    ],
  );
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

class _DemandAcc {
  _DemandAcc(this.search, this.latestAt);

  final SameBoatSearch search;
  int count = 0;
  DateTime latestAt;
}
