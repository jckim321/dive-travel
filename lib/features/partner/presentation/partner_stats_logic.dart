import 'package:dive_travel_app/core/models/pro_verification.dart';

enum PartnerStatsPeriod { thisWeek, thisMonth, threeMonths }

DateTime partnerStatsPeriodStart(PartnerStatsPeriod period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case PartnerStatsPeriod.thisWeek:
      return today.subtract(const Duration(days: 6));
    case PartnerStatsPeriod.thisMonth:
      return DateTime(now.year, now.month, 1);
    case PartnerStatsPeriod.threeMonths:
      return today.subtract(const Duration(days: 89));
  }
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _inRange(TourBooking b, DateTime start, DateTime endInclusive) {
  final day = _dayOnly(b.createdAt);
  return !day.isBefore(start) && !day.isAfter(endInclusive);
}

bool _countsForProductStats(TourBooking b) {
  return b.isActive && b.isPaid;
}

int _partyHeadcount(TourBooking b) {
  if (b.hasPartyDetail) {
    return b.divers + b.nondivers + b.children + b.infants;
  }
  return b.partySize > 0 ? b.partySize : 1;
}

class PartnerProductBookingRow {
  const PartnerProductBookingRow({
    required this.productKey,
    required this.productLabel,
    required this.bookingCount,
    required this.guestCount,
    this.prevBookingCount = 0,
  });

  final String productKey;
  final String productLabel;
  final int bookingCount;
  final int guestCount;
  final int prevBookingCount;

  /// Null when previous period had zero bookings.
  double? get changeRatio {
    if (prevBookingCount <= 0) {
      return bookingCount > 0 ? 1.0 : null;
    }
    return (bookingCount - prevBookingCount) / prevBookingCount;
  }
}

List<PartnerProductBookingRow> computeProductBookingRows({
  required List<TourBooking> bookings,
  required PartnerStatsPeriod period,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final end = _dayOnly(clock);
  final start = partnerStatsPeriodStart(period, clock);
  final spanDays = end.difference(start).inDays + 1;
  final prevEnd = start.subtract(const Duration(days: 1));
  final prevStart = prevEnd.subtract(Duration(days: spanDays - 1));

  final current = <String, PartnerProductBookingRow>{};
  final prevCounts = <String, int>{};

  void addCurrent(TourBooking b) {
    final key =
        b.productId.isNotEmpty ? b.productId : b.productLabel;
    final existing = current[key];
    current[key] = PartnerProductBookingRow(
      productKey: key,
      productLabel: b.productLabel,
      bookingCount: (existing?.bookingCount ?? 0) + 1,
      guestCount: (existing?.guestCount ?? 0) + _partyHeadcount(b),
      prevBookingCount: existing?.prevBookingCount ?? 0,
    );
  }

  for (final b in bookings) {
    if (!_countsForProductStats(b)) {
      continue;
    }
    if (_inRange(b, start, end)) {
      addCurrent(b);
    } else if (_inRange(b, prevStart, prevEnd)) {
      final key =
          b.productId.isNotEmpty ? b.productId : b.productLabel;
      prevCounts[key] = (prevCounts[key] ?? 0) + 1;
    }
  }

  final rows = [
    for (final entry in current.entries)
      PartnerProductBookingRow(
        productKey: entry.value.productKey,
        productLabel: entry.value.productLabel,
        bookingCount: entry.value.bookingCount,
        guestCount: entry.value.guestCount,
        prevBookingCount: prevCounts[entry.key] ?? 0,
      ),
  ];
  rows.sort((a, b) => b.bookingCount.compareTo(a.bookingCount));
  return rows;
}
