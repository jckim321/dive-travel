import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';

/// How a region or product looks in the selected period.
enum SeatScoreBadge { selling, viewsOnly, quiet, ordinary }

/// Bookings over capacity, as a whole percent. Zero when capacity is zero.
int seatFillPercent(int booked, int capacity) {
  if (capacity <= 0) {
    return 0;
  }
  final percent = (booked * 100 / capacity).round();
  if (percent < 0) {
    return 0;
  }
  if (percent > 100) {
    return 100;
  }
  return percent;
}

/// 결제 3+ or fill 80%+ sells. Many views and few flags are views-only.
/// Five views or fewer is quiet. Anything else is ordinary.
SeatScoreBadge seatScoreBadge({
  required int views,
  required int flags,
  required int pays,
  required int fillPercent,
}) {
  if (pays >= 3 || fillPercent >= 80) {
    return SeatScoreBadge.selling;
  }
  if (views >= 30 && flags <= 3) {
    return SeatScoreBadge.viewsOnly;
  }
  if (views <= 5) {
    return SeatScoreBadge.quiet;
  }
  return SeatScoreBadge.ordinary;
}

/// One open seat's current bookings. Region comes from the catalog, not raw text.
class SeatScoreSeat {
  const SeatScoreSeat({
    required this.productId,
    required this.optionId,
    required this.productName,
    required this.place,
    required this.booked,
    required this.capacity,
  });

  final String productId;
  final String optionId;
  final String productName;
  final SameBoatPlace place;
  final int booked;
  final int capacity;
}

class SeatScoreRow {
  const SeatScoreRow({
    required this.id,
    required this.title,
    required this.regionId,
    required this.regionName,
    required this.views,
    required this.flags,
    required this.pays,
    required this.booked,
    required this.capacity,
  });

  final String id;
  final String title;
  final String regionId;
  final String regionName;
  final int views;
  final int flags;
  final int pays;
  final int booked;
  final int capacity;

  int get fillPercent => seatFillPercent(booked, capacity);

  SeatScoreBadge get badge => seatScoreBadge(
    views: views,
    flags: flags,
    pays: pays,
    fillPercent: fillPercent,
  );
}

class SeatScoreboard {
  const SeatScoreboard({required this.regions, required this.products});

  static const empty = SeatScoreboard(regions: [], products: []);

  final List<SeatScoreRow> regions;
  final List<SeatScoreRow> products;
}

/// Bucket for a view, flag, or payment whose place is not in the catalog.
const seatScoreOtherId = 'other';

/// Shown on the region list so those events still add up to the funnel.
const seatScoreOtherTitle = '기타·미분류';

String seatScoreRegionTitle(String id) {
  if (id == seatScoreOtherId) {
    return seatScoreOtherTitle;
  }
  return seatCatalogRegionName(id);
}

/// Catalog region for a stored place. The longest matching name wins.
String? seatCatalogRegionId(SameBoatPlace place) {
  DiveRegion? best;
  for (final region in RegionCatalog.known) {
    if (!placeHitsRegion(region, place)) {
      continue;
    }
    if (best == null || region.name.length > best.name.length) {
      best = region;
    }
  }
  return best?.id;
}

String seatCatalogRegionName(String id) {
  for (final region in RegionCatalog.known) {
    if (region.id == id) {
      return region.name;
    }
  }
  return '';
}

/// Korean topic marker so 「팔라우는」 and 「얍은」 both read naturally.
String seatScoreTopic(String name) {
  if (name.isEmpty) {
    return name;
  }
  final last = name.runes.last;
  if (last < 0xAC00 || last > 0xD7A3) {
    return name;
  }
  final hasBatchim = (last - 0xAC00) % 28 != 0;
  return hasBatchim ? '$name은' : '$name는';
}

/// Views, flags, and payments in [events], grouped by catalog region and product.
/// A place outside the catalog is one 「기타·미분류」 row, so the region rows
/// add up to the funnel. Fill rate uses current [seats], not the event log.
SeatScoreboard seatScoreboard({
  required Iterable<SeatLifeEvent> events,
  required Iterable<SeatScoreSeat> seats,
}) {
  final seatsByProduct = <String, List<SeatScoreSeat>>{};
  for (final seat in seats) {
    if (seat.productId.isEmpty) {
      continue;
    }
    seatsByProduct.putIfAbsent(seat.productId, () => []).add(seat);
  }

  String? regionForProduct(String productId) {
    final rows = seatsByProduct[productId];
    if (rows == null) {
      return null;
    }
    for (final seat in rows) {
      final id = seatCatalogRegionId(seat.place);
      if (id != null) {
        return id;
      }
    }
    return null;
  }

  String? regionForEvent(SeatLifeEvent event) {
    final fromEvent = seatCatalogRegionId(SameBoatPlace(country: event.region));
    if (fromEvent != null) {
      return fromEvent;
    }
    return regionForProduct(event.productId);
  }

  final regionCounts = <String, _ScoreAcc>{};
  final productCounts = <String, _ScoreAcc>{};
  for (final event in events) {
    final kind = event.kind;
    if (kind != 'view' && kind != 'flag' && kind != 'pay') {
      continue;
    }
    final regionId = regionForEvent(event) ?? seatScoreOtherId;
    final acc = regionCounts.putIfAbsent(regionId, _ScoreAcc.new);
    acc.add(kind);
    if (event.productId.isNotEmpty) {
      final acc = productCounts.putIfAbsent(event.productId, _ScoreAcc.new);
      acc.add(kind);
      acc.regionId ??= regionId;
      if (acc.title.isEmpty && event.resort.isNotEmpty) {
        acc.title = event.resort;
      }
    }
  }

  final regions = <SeatScoreRow>[];
  for (final entry in regionCounts.entries) {
    if (!entry.value.hasActivity) {
      continue;
    }
    var booked = 0;
    var capacity = 0;
    for (final rows in seatsByProduct.values) {
      for (final seat in rows) {
        final placeId = seatCatalogRegionId(seat.place);
        final matches = entry.key == seatScoreOtherId
            ? placeId == null
            : placeId == entry.key;
        if (matches) {
          booked += seat.booked;
          capacity += seat.capacity;
        }
      }
    }
    final title = seatScoreRegionTitle(entry.key);
    regions.add(
      SeatScoreRow(
        id: entry.key,
        title: title,
        regionId: entry.key,
        regionName: title,
        views: entry.value.views,
        flags: entry.value.flags,
        pays: entry.value.pays,
        booked: booked,
        capacity: capacity,
      ),
    );
  }

  final products = <SeatScoreRow>[];
  for (final entry in productCounts.entries) {
    if (!entry.value.hasActivity) {
      continue;
    }
    final rows = seatsByProduct[entry.key] ?? const <SeatScoreSeat>[];
    var booked = 0;
    var capacity = 0;
    var name = '';
    String? regionId = entry.value.regionId;
    for (final seat in rows) {
      booked += seat.booked;
      capacity += seat.capacity;
      if (name.isEmpty && seat.productName.isNotEmpty) {
        name = seat.productName;
      }
      regionId ??= seatCatalogRegionId(seat.place);
    }
    final resolved = regionId ?? '';
    products.add(
      SeatScoreRow(
        id: entry.key,
        title: name.isNotEmpty
            ? name
            : (entry.value.title.isNotEmpty ? entry.value.title : entry.key),
        regionId: resolved,
        regionName: resolved.isEmpty ? '' : seatScoreRegionTitle(resolved),
        views: entry.value.views,
        flags: entry.value.flags,
        pays: entry.value.pays,
        booked: booked,
        capacity: capacity,
      ),
    );
  }

  int byViews(SeatScoreRow a, SeatScoreRow b) {
    final byCount = b.views.compareTo(a.views);
    if (byCount != 0) {
      return byCount;
    }
    return a.title.compareTo(b.title);
  }

  regions.sort(byViews);
  products.sort(byViews);
  return SeatScoreboard(regions: regions, products: products);
}

/// The one region worth a sentence. Views-only outranks a strong seller.
/// Ordinary rows, and an empty list, are not enough evidence.
SeatScoreRow? seatScoreHeadline(List<SeatScoreRow> regions) {
  SeatScoreRow? best;
  for (final row in regions) {
    if (row.badge == SeatScoreBadge.ordinary) {
      continue;
    }
    if (best == null ||
        _headlineRank(row.badge) < _headlineRank(best.badge) ||
        (_headlineRank(row.badge) == _headlineRank(best.badge) &&
            (row.views > best.views ||
                (row.views == best.views &&
                    row.title.compareTo(best.title) < 0)))) {
      best = row;
    }
  }
  return best;
}

int _headlineRank(SeatScoreBadge badge) {
  return switch (badge) {
    SeatScoreBadge.viewsOnly => 0,
    SeatScoreBadge.selling => 1,
    SeatScoreBadge.quiet => 2,
    SeatScoreBadge.ordinary => 3,
  };
}

class _ScoreAcc {
  var views = 0;
  var flags = 0;
  var pays = 0;
  var title = '';
  String? regionId;

  bool get hasActivity => views > 0 || flags > 0 || pays > 0;

  void add(String kind) {
    switch (kind) {
      case 'view':
        views += 1;
      case 'flag':
        flags += 1;
      case 'pay':
        pays += 1;
    }
  }
}
