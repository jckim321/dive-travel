import 'package:dive_travel_app/core/models/pro_verification.dart';

/// One day of shop counters. No member id. No payment count.
class ShopDayStats {
  const ShopDayStats({
    required this.dayId,
    required this.visits,
    required this.productViews,
    required this.dwellSeconds,
  });

  final String dayId;
  final int visits;
  final int productViews;
  final int dwellSeconds;

  Map<String, int> toMap() => {
        'visits': visits,
        'product_views': productViews,
        'dwell_seconds': dwellSeconds,
      };
}

const int dailyStatsDwellCap = 1800;

String shopDayId(DateTime now) {
  final local = now.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? shopDayDate(String dayId) {
  final parts = dayId.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  return DateTime(year, month, day);
}

bool dailyStatsDayIdOk(String dayId) => shopDayDate(dayId) != null;

int cappedDwellDelta(int seconds) {
  if (seconds <= 0) {
    return 0;
  }
  if (seconds > dailyStatsDwellCap) {
    return dailyStatsDwellCap;
  }
  return seconds;
}

/// Same shape as the daily_stats create rule. Dwell starts at zero.
bool dailyStatsCreateAllowed({
  required String dayId,
  required int visits,
  required int productViews,
  required int dwellSeconds,
}) {
  return dailyStatsDayIdOk(dayId) &&
      visits >= 0 &&
      visits <= 1 &&
      productViews >= 0 &&
      productViews <= 1 &&
      dwellSeconds == 0;
}

/// Same shape as the daily_stats update rule.
/// A missing document rejects the write, including a dwell-only update.
bool dailyStatsUpdateAllowed({
  required bool exists,
  required int visits,
  required int productViews,
  required int dwellSeconds,
  required int nextVisits,
  required int nextProductViews,
  required int nextDwellSeconds,
}) {
  if (!exists) {
    return false;
  }
  return nextVisits >= visits &&
      nextVisits <= visits + 1 &&
      nextProductViews >= productViews &&
      nextProductViews <= productViews + 1 &&
      nextDwellSeconds >= dwellSeconds &&
      nextDwellSeconds <= dwellSeconds + dailyStatsDwellCap;
}

class ShopCounterWindow {
  const ShopCounterWindow({
    required this.visits,
    required this.productViews,
    required this.dwellSeconds,
    required this.paidBookings,
  });

  final int visits;
  final int productViews;
  final int dwellSeconds;
  final int paidBookings;

  /// Paid receive-date bookings divided by product views.
  /// Null when there are no views, so the rate is not invented.
  double? get strikeRate {
    if (productViews <= 0) {
      return null;
    }
    return paidBookings / productViews;
  }

  int? get averageDwellSeconds {
    if (visits <= 0) {
      return null;
    }
    return (dwellSeconds / visits).round();
  }
}

bool shopCounterWasPaid(TourBooking booking) {
  return booking.paymentStatus == PaymentStatus.captured ||
      booking.paymentStatus == PaymentStatus.refunded;
}

/// [end] is exclusive, matching the sales window.
ShopCounterWindow sumShopCounters({
  required Iterable<ShopDayStats> days,
  required DateTime start,
  required DateTime end,
  required Iterable<TourBooking> bookings,
}) {
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  var visits = 0;
  var views = 0;
  var dwell = 0;
  for (final day in days) {
    final date = shopDayDate(day.dayId);
    if (date == null || date.isBefore(startDay) || !date.isBefore(endDay)) {
      continue;
    }
    visits += day.visits;
    views += day.productViews;
    dwell += day.dwellSeconds;
  }
  var paid = 0;
  for (final booking in bookings) {
    if (!shopCounterWasPaid(booking)) {
      continue;
    }
    if (booking.createdAt.isBefore(start) || !booking.createdAt.isBefore(end)) {
      continue;
    }
    paid += 1;
  }
  return ShopCounterWindow(
    visits: visits,
    productViews: views,
    dwellSeconds: dwell,
    paidBookings: paid,
  );
}
