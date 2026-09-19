import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';

enum TravelStyleKind {
  firstOcean,
  homeContinent,
  collector,
  deepLocal,
  pro,
}

class TravelStyleInsight {
  const TravelStyleInsight({
    required this.kind,
    required this.nextContinent,
    required this.stampedContinents,
    required this.stampedCountries,
    this.suggestedShop,
  });

  final TravelStyleKind kind;
  final String nextContinent;
  final Set<String> stampedContinents;
  final Set<String> stampedCountries;
  final DiveShop? suggestedShop;

  int get stampCount => stampedCountries.length;
}

abstract final class TravelStyleAnalyzer {
  static const _openOrder = <String>[
    ContinentId.oceania,
    ContinentId.africa,
    ContinentId.americas,
    ContinentId.europe,
    ContinentId.polar,
    ContinentId.asia,
  ];

  static TravelStyleInsight analyze({
    required List<DiveRegion> regions,
    required DiverStats stats,
    required List<DiveShop> shops,
  }) {
    final stamped = {for (final region in regions) region.continent};
    final countries = {for (final region in regions) RegionCatalog.countryOf(region)};
    final next = nextContinent(regions);
    return TravelStyleInsight(
      kind: _kind(regions, stats, stamped),
      nextContinent: next,
      stampedContinents: stamped,
      stampedCountries: countries,
      suggestedShop: shopForContinent(next, shops),
    );
  }

  static TravelStyleKind _kind(
    List<DiveRegion> regions,
    DiverStats stats,
    Set<String> stamped,
  ) {
    if (stats.totalLogCount == 0 || regions.isEmpty) {
      return TravelStyleKind.firstOcean;
    }
    if (stats.isInstructor) {
      return TravelStyleKind.pro;
    }
    if (regions.any((region) => region.isGolden)) {
      return TravelStyleKind.deepLocal;
    }
    if (stamped.length >= 3) {
      return TravelStyleKind.collector;
    }
    return TravelStyleKind.homeContinent;
  }

  static String nextContinent(List<DiveRegion> regions) {
    final stamped = {for (final region in regions) region.continent};
    if (stamped.isEmpty) {
      return ContinentId.asia;
    }
    for (final id in _openOrder) {
      if (!stamped.contains(id)) {
        return id;
      }
    }
    var weakest = ContinentId.all.first;
    var minLogs = 1 << 30;
    for (final id in ContinentId.all) {
      final logs = regions
          .where((region) => region.continent == id)
          .fold<int>(0, (sum, region) => sum + region.logCount);
      if (logs < minLogs) {
        minLogs = logs;
        weakest = id;
      }
    }
    return weakest;
  }

  static DiveShop? shopForContinent(String continent, List<DiveShop> shops) {
    final hits = [
      for (final shop in shops)
        if (shop.continent == continent) shop,
    ];
    hits.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return hits.isEmpty ? null : hits.first;
  }

  static TourBooking? nextTrip(
    List<TourBooking> bookings, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final upcoming = [
      for (final booking in bookings)
        if (booking.isActive && !booking.scheduledFor.isBefore(today)) booking,
    ]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  static int daysUntil(DateTime date, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final start = DateTime(clock.year, clock.month, clock.day);
    final end = DateTime(date.year, date.month, date.day);
    return end.difference(start).inDays;
  }
}
