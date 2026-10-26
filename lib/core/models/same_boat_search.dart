import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';

/// When a departure must fall. [any] does not filter.
enum SameBoatWhen { any, thisMonth, nextMonth, withinThreeMonths }

extension SameBoatWhenStorage on SameBoatWhen {
  String get firestoreValue {
    return switch (this) {
      SameBoatWhen.any => 'any',
      SameBoatWhen.thisMonth => 'this_month',
      SameBoatWhen.nextMonth => 'next_month',
      SameBoatWhen.withinThreeMonths => 'within_three_months',
    };
  }

  static SameBoatWhen parse(dynamic value) {
    return switch (value) {
      'this_month' => SameBoatWhen.thisMonth,
      'next_month' => SameBoatWhen.nextMonth,
      'within_three_months' => SameBoatWhen.withinThreeMonths,
      _ => SameBoatWhen.any,
    };
  }
}

/// Place strings already stored on the product and shop. Not free text.
class SameBoatPlace {
  const SameBoatPlace({
    this.continent = '',
    this.location = '',
    this.country = '',
    this.sites = const [],
  });

  final String continent;
  final String location;
  final String country;
  final List<String> sites;
}

/// Buyer filters for the live same-boat list. Sort stays newest-first.
class SameBoatSearch {
  const SameBoatSearch({
    this.when = SameBoatWhen.any,
    this.regionIds = const {},
    this.party,
    this.budgetMax,
    this.lastCall = false,
    this.departingSoon = false,
  });

  static const partyFivePlus = 5;
  static const budget50 = 500000;
  static const budget100 = 1000000;
  static const budget200 = 2000000;

  final SameBoatWhen when;
  final Set<String> regionIds;

  /// Minimum remaining seats. Null means any size. [partyFivePlus] is 5 or more.
  final int? party;

  /// Maximum price per person, inclusive. Null means no cap.
  final int? budgetMax;
  final bool lastCall;
  final bool departingSoon;

  bool get hasActiveFilter =>
      when != SameBoatWhen.any ||
      regionIds.isNotEmpty ||
      party != null ||
      budgetMax != null ||
      lastCall ||
      departingSoon;

  /// Drops one active condition: budget, party, when, where, then more.
  /// Null when every condition is already open.
  SameBoatSearch? widen() {
    if (budgetMax != null) {
      return copyWith(clearBudget: true);
    }
    if (party != null) {
      return copyWith(clearParty: true);
    }
    if (when != SameBoatWhen.any) {
      return copyWith(when: SameBoatWhen.any);
    }
    if (regionIds.isNotEmpty) {
      return copyWith(regionIds: const {});
    }
    if (lastCall || departingSoon) {
      return copyWith(lastCall: false, departingSoon: false);
    }
    return null;
  }

  bool sameConditions(SameBoatSearch other) {
    return when == other.when &&
        party == other.party &&
        budgetMax == other.budgetMax &&
        lastCall == other.lastCall &&
        departingSoon == other.departingSoon &&
        regionIds.length == other.regionIds.length &&
        regionIds.containsAll(other.regionIds);
  }

  SameBoatSearch copyWith({
    SameBoatWhen? when,
    Set<String>? regionIds,
    int? party,
    bool clearParty = false,
    int? budgetMax,
    bool clearBudget = false,
    bool? lastCall,
    bool? departingSoon,
  }) {
    return SameBoatSearch(
      when: when ?? this.when,
      regionIds: regionIds ?? this.regionIds,
      party: clearParty ? null : (party ?? this.party),
      budgetMax: clearBudget ? null : (budgetMax ?? this.budgetMax),
      lastCall: lastCall ?? this.lastCall,
      departingSoon: departingSoon ?? this.departingSoon,
    );
  }

  /// Keeps the incoming order, which is newest-open first.
  List<SameBoatOffer> apply(
    List<SameBoatOffer> offers, {
    required DateTime now,
    required int Function(SameBoatOffer offer) priceOf,
    required SameBoatPlace Function(SameBoatOffer offer) placeOf,
  }) {
    if (!hasActiveFilter) {
      return offers;
    }
    return [
      for (final offer in offers)
        if (matches(
          offer,
          now: now,
          pricePerPerson: priceOf(offer),
          place: placeOf(offer),
        ))
          offer,
    ];
  }

  bool matches(
    SameBoatOffer offer, {
    required DateTime now,
    required int pricePerPerson,
    required SameBoatPlace place,
  }) {
    if (party != null && offer.remainingSeatsAt(now) < party!) {
      return false;
    }
    if (budgetMax != null && pricePerPerson > budgetMax!) {
      return false;
    }
    if (!_whenMatches(offer.departureStart, now)) {
      return false;
    }
    if (regionIds.isNotEmpty && !_regionMatches(place)) {
      return false;
    }
    if (lastCall &&
        !_soon(offer.flagClosesAt ?? offer.departureStart, now)) {
      return false;
    }
    if (departingSoon && !_soon(offer.departureStart, now)) {
      return false;
    }
    return true;
  }

  bool _whenMatches(DateTime? departure, DateTime now) {
    if (when == SameBoatWhen.any) {
      return true;
    }
    if (departure == null) {
      return false;
    }
    final day = DateTime(departure.year, departure.month, departure.day);
    final today = DateTime(now.year, now.month, now.day);
    switch (when) {
      case SameBoatWhen.any:
        return true;
      case SameBoatWhen.thisMonth:
        return day.year == today.year && day.month == today.month;
      case SameBoatWhen.nextMonth:
        final next = DateTime(today.year, today.month + 1);
        return day.year == next.year && day.month == next.month;
      case SameBoatWhen.withinThreeMonths:
        final limit = DateTime(today.year, today.month + 3, today.day);
        return !day.isBefore(today) && !day.isAfter(limit);
    }
  }

  bool _regionMatches(SameBoatPlace place) {
    for (final id in regionIds) {
      final region = _regionById(id);
      if (region != null && placeHitsRegion(region, place)) {
        return true;
      }
    }
    return false;
  }

  static bool _soon(DateTime? at, DateTime now) {
    if (at == null) {
      return false;
    }
    return !at.isAfter(now.add(SameBoatBoard.window));
  }
}

DiveRegion? _regionById(String id) {
  for (final region in RegionCatalog.known) {
    if (region.id == id) {
      return region;
    }
  }
  return null;
}

/// Exact id or display name. A stored label may also contain the full name.
bool placeHitsRegion(DiveRegion region, SameBoatPlace place) {
  bool hit(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return false;
    }
    if (text == region.id || text.toLowerCase() == region.id.toLowerCase()) {
      return true;
    }
    if (text == region.name) {
      return true;
    }
    return region.name.length >= 2 && text.contains(region.name);
  }

  if (hit(place.continent) || hit(place.location) || hit(place.country)) {
    return true;
  }
  for (final site in place.sites) {
    if (hit(site)) {
      return true;
    }
  }
  return false;
}
