import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_settlement_logic.dart';

/// Today cancels must be at least this many, and at least twice the
/// prior-28-day daily average. The average is trusted only when that
/// window has at least [adminCancelBaselineMinBookings] bookings.
const int adminCancelSpikeMultiple = 2;
const int adminCancelSpikeMinCount = 3;
const int adminCancelBaselineDays = 28;
const int adminCancelBaselineMinBookings = 10;

/// This week's paid gross is a drop when it is at most 70% of last week
/// and last week was at least this many won.
const int adminWeekDropMinLastGross = 100000;

/// Date ranges the overview is allowed to read. Nothing older, except the
/// previous calendar month and the same span one year earlier.
class AdminOverviewWindows {
  const AdminOverviewWindows({
    required this.recentStart,
    required this.recentEnd,
    required this.previousMonthStart,
    required this.previousMonthEnd,
    required this.yearAgoMonthStart,
    required this.yearAgoMonthEnd,
    required this.yearAgoChartStart,
    required this.yearAgoChartEnd,
    required this.cancelStart,
    required this.cancelEnd,
  });

  final DateTime recentStart;
  final DateTime recentEnd;
  final DateTime previousMonthStart;
  final DateTime previousMonthEnd;
  final DateTime yearAgoMonthStart;
  final DateTime yearAgoMonthEnd;
  final DateTime yearAgoChartStart;
  final DateTime yearAgoChartEnd;
  final DateTime cancelStart;
  final DateTime cancelEnd;

  factory AdminOverviewWindows.of(DateTime now) {
    final today = dateOnly(now);
    final recentStart = today.subtract(const Duration(days: 29));
    final recentEnd = today.add(const Duration(days: 1));
    final thisMonth = DateTime(now.year, now.month, 1);
    final prevStart = DateTime(now.year, now.month - 1, 1);
    return AdminOverviewWindows(
      recentStart: recentStart,
      recentEnd: recentEnd,
      previousMonthStart: prevStart,
      previousMonthEnd: thisMonth,
      yearAgoMonthStart: DateTime(now.year - 1, now.month, 1),
      yearAgoMonthEnd: DateTime(now.year - 1, now.month + 1, 1),
      yearAgoChartStart: minusYear(recentStart),
      yearAgoChartEnd: minusYear(recentEnd),
      cancelStart: today.subtract(const Duration(days: adminCancelBaselineDays)),
      cancelEnd: recentEnd,
    );
  }
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Monday 00:00 of the local week that contains [value].
DateTime startOfWeek(DateTime value) {
  final day = dateOnly(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime minusYear(DateTime value) {
  final year = value.year - 1;
  final lastDay = DateTime(year, value.month + 1, 0).day;
  final day = value.day > lastDay ? lastDay : value.day;
  return DateTime(year, value.month, day, value.hour, value.minute, value.second);
}

List<TourBooking> mergeOverviewBookings(Iterable<List<TourBooking>> batches) {
  final byId = <String, TourBooking>{};
  for (final batch in batches) {
    for (final booking in batch) {
      final prev = byId[booking.id];
      if (prev == null ||
          (prev.cancelledAt == null && booking.cancelledAt != null)) {
        byId[booking.id] = booking;
      }
    }
  }
  return byId.values.toList();
}

class AdminOverviewFigures {
  const AdminOverviewFigures({
    required this.todayCount,
    required this.yesterdayCount,
    required this.todayGross,
    required this.yesterdayGross,
    required this.todayCancelCount,
    required this.todayRefund,
    required this.monthNet,
    required this.previousMonthNet,
    required this.yearAgoMonthNet,
    required this.hasYearAgoMonth,
    required this.last14Net,
    required this.last30Net,
    required this.last30YearAgoNet,
    required this.hasYearAgoChart,
  });

  final int todayCount;
  final int yesterdayCount;
  final int todayGross;
  final int yesterdayGross;
  final int todayCancelCount;
  final int todayRefund;
  final int monthNet;
  final int previousMonthNet;
  final int yearAgoMonthNet;
  final bool hasYearAgoMonth;
  final List<int> last14Net;
  final List<int> last30Net;
  final List<int> last30YearAgoNet;
  final bool hasYearAgoChart;

  static const empty = AdminOverviewFigures(
    todayCount: 0,
    yesterdayCount: 0,
    todayGross: 0,
    yesterdayGross: 0,
    todayCancelCount: 0,
    todayRefund: 0,
    monthNet: 0,
    previousMonthNet: 0,
    yearAgoMonthNet: 0,
    hasYearAgoMonth: false,
    last14Net: [],
    last30Net: [],
    last30YearAgoNet: [],
    hasYearAgoChart: false,
  );
}

bool overviewWasPaid(TourBooking booking) {
  return booking.paymentStatus == PaymentStatus.captured ||
      booking.paymentStatus == PaymentStatus.refunded;
}

bool overviewIsCancelled(TourBooking booking) {
  return booking.status == BookingStatus.cancelled ||
      booking.status == BookingStatus.weatherCancelled;
}

int _grossPaidBetween(
  List<TourBooking> bookings,
  DateTime start,
  DateTime end,
) {
  var sum = 0;
  for (final booking in bookings) {
    if (!overviewWasPaid(booking)) {
      continue;
    }
    if (booking.createdAt.isBefore(start) || !booking.createdAt.isBefore(end)) {
      continue;
    }
    sum += booking.price;
  }
  return sum;
}

int _countCreatedBetween(
  List<TourBooking> bookings,
  DateTime start,
  DateTime end,
) {
  var count = 0;
  for (final booking in bookings) {
    if (!booking.createdAt.isBefore(start) && booking.createdAt.isBefore(end)) {
      count++;
    }
  }
  return count;
}

int _netOnDay(List<TourBooking> bookings, DateTime day) {
  final end = day.add(const Duration(days: 1));
  final slice = [
    for (final booking in bookings)
      if (!booking.createdAt.isBefore(day) && booking.createdAt.isBefore(end))
        booking,
  ];
  if (slice.isEmpty) {
    return 0;
  }
  return computePartnerSettlementMonth(
    bookings: slice,
    year: day.year,
    month: day.month,
  ).netSales;
}

AdminOverviewFigures buildAdminOverviewFigures({
  required List<TourBooking> bookings,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));
  final yesterday = today.subtract(const Duration(days: 1));
  final days30 = [
    for (var i = 29; i >= 0; i--) today.subtract(Duration(days: i)),
  ];
  final days14 = days30.sublist(days30.length - 14);
  final yearAgoDays = [for (final day in days30) minusYear(day)];
  final hasYearAgoChart = bookings.any((booking) {
    final created = booking.createdAt;
    return !created.isBefore(yearAgoDays.first) &&
        created.isBefore(yearAgoDays.last.add(const Duration(days: 1)));
  });
  final yearAgoMonth = computePartnerSettlementMonth(
    bookings: bookings,
    year: now.year - 1,
    month: now.month,
  );
  final hasYearAgoMonth = bookings.any(
    (booking) =>
        booking.createdAt.year == now.year - 1 &&
        booking.createdAt.month == now.month,
  );
  var todayCancels = 0;
  var todayRefund = 0;
  for (final booking in bookings) {
    final at = booking.cancelledAt;
    if (at == null || !overviewIsCancelled(booking)) {
      continue;
    }
    if (at.isBefore(today) || !at.isBefore(tomorrow)) {
      continue;
    }
    todayCancels++;
    todayRefund += booking.refundAmount;
  }
  final prev = DateTime(now.year, now.month - 1, 1);
  return AdminOverviewFigures(
    todayCount: _countCreatedBetween(bookings, today, tomorrow),
    yesterdayCount: _countCreatedBetween(bookings, yesterday, today),
    todayGross: _grossPaidBetween(bookings, today, tomorrow),
    yesterdayGross: _grossPaidBetween(bookings, yesterday, today),
    todayCancelCount: todayCancels,
    todayRefund: todayRefund,
    monthNet: computePartnerSettlementMonth(
      bookings: bookings,
      year: now.year,
      month: now.month,
    ).netSales,
    previousMonthNet: computePartnerSettlementMonth(
      bookings: bookings,
      year: prev.year,
      month: prev.month,
    ).netSales,
    yearAgoMonthNet: yearAgoMonth.netSales,
    hasYearAgoMonth: hasYearAgoMonth,
    last14Net: [for (final day in days14) _netOnDay(bookings, day)],
    last30Net: [for (final day in days30) _netOnDay(bookings, day)],
    last30YearAgoNet: [
      for (final day in yearAgoDays) _netOnDay(bookings, day),
    ],
    hasYearAgoChart: hasYearAgoChart,
  );
}

class AdminOverviewAlert {
  const AdminOverviewAlert({
    required this.cancelSpike,
    required this.todayCancels,
    required this.droppingShops,
  });

  final bool cancelSpike;
  final int todayCancels;
  final List<String> droppingShops;

  bool get visible => cancelSpike || droppingShops.isNotEmpty;
}

AdminOverviewAlert? evaluateAdminOverviewAlert({
  required List<TourBooking> bookings,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));
  final baselineStart = today.subtract(
    const Duration(days: adminCancelBaselineDays),
  );
  var todayCancels = 0;
  var baselineCancels = 0;
  for (final booking in bookings) {
    final at = booking.cancelledAt;
    if (at == null || !overviewIsCancelled(booking)) {
      continue;
    }
    if (!at.isBefore(today) && at.isBefore(tomorrow)) {
      todayCancels++;
    } else if (!at.isBefore(baselineStart) && at.isBefore(today)) {
      baselineCancels++;
    }
  }
  final baselineBookings = _countCreatedBetween(bookings, baselineStart, today);
  final average = baselineCancels / adminCancelBaselineDays;
  final cancelSpike = baselineBookings >= adminCancelBaselineMinBookings &&
      todayCancels >= adminCancelSpikeMinCount &&
      todayCancels >= average * adminCancelSpikeMultiple;

  final thisWeek = startOfWeek(now);
  final nextWeek = thisWeek.add(const Duration(days: 7));
  final lastWeek = thisWeek.subtract(const Duration(days: 7));
  final byShop = <String, ({int current, int previous, String name})>{};
  for (final booking in bookings) {
    if (!overviewWasPaid(booking)) {
      continue;
    }
    final created = booking.createdAt;
    final inCurrent = !created.isBefore(thisWeek) && created.isBefore(nextWeek);
    final inPrevious = !created.isBefore(lastWeek) && created.isBefore(thisWeek);
    if (!inCurrent && !inPrevious) {
      continue;
    }
    final current = byShop[booking.shopId];
    final name = booking.shopName.trim().isEmpty
        ? (current?.name ?? booking.shopId)
        : booking.shopName.trim();
    byShop[booking.shopId] = (
      current: (current?.current ?? 0) + (inCurrent ? booking.price : 0),
      previous: (current?.previous ?? 0) + (inPrevious ? booking.price : 0),
      name: name,
    );
  }
  final dropping = <String>[];
  for (final shop in byShop.values) {
    if (shop.previous < adminWeekDropMinLastGross) {
      continue;
    }
    if (shop.current * 100 <= shop.previous * 70) {
      dropping.add(shop.name);
    }
  }
  dropping.sort();
  final alert = AdminOverviewAlert(
    cancelSpike: cancelSpike,
    todayCancels: todayCancels,
    droppingShops: dropping,
  );
  if (!alert.visible) {
    return null;
  }
  return alert;
}

enum AdminActivityKind { signup, refund, signature, diveStar }

class AdminActivityItem {
  const AdminActivityItem({
    required this.at,
    required this.kind,
    required this.label,
  });

  final DateTime at;
  final AdminActivityKind kind;
  final String label;
}

List<AdminActivityItem> buildAdminActivity({
  required DateTime now,
  required List<MemberAccount> members,
  required List<TourBooking> bookings,
  required List<PartnerContract> contracts,
  required List<DiveStarApplication> applications,
  int limit = 8,
}) {
  final start = dateOnly(now).subtract(const Duration(days: 14));
  final end = dateOnly(now).add(const Duration(days: 1));
  final items = <AdminActivityItem>[];
  for (final member in members) {
    final at = member.createdAt;
    if (at == null || at.isBefore(start) || !at.isBefore(end)) {
      continue;
    }
    final name = member.displayName.trim().isEmpty
        ? ''
        : member.displayName.trim();
    items.add(
      AdminActivityItem(
        at: at,
        kind: AdminActivityKind.signup,
        label: name,
      ),
    );
  }
  for (final booking in bookings) {
    final at = booking.cancelledAt;
    if (at == null ||
        !overviewIsCancelled(booking) ||
        at.isBefore(start) ||
        !at.isBefore(end)) {
      continue;
    }
    items.add(
      AdminActivityItem(
        at: at,
        kind: AdminActivityKind.refund,
        label: booking.shopName.trim(),
      ),
    );
  }
  for (final contract in contracts) {
    final at = contract.executedAt ?? contract.signature?.signedAt;
    if (contract.status != PartnerContractStatus.executed ||
        at == null ||
        at.isBefore(start) ||
        !at.isBefore(end)) {
      continue;
    }
    items.add(
      AdminActivityItem(
        at: at,
        kind: AdminActivityKind.signature,
        label: contract.title.trim(),
      ),
    );
  }
  for (final application in applications) {
    final at = application.submittedAt;
    if (at.isBefore(start) || !at.isBefore(end)) {
      continue;
    }
    items.add(
      AdminActivityItem(
        at: at,
        kind: AdminActivityKind.diveStar,
        label: application.shopName.trim(),
      ),
    );
  }
  items.sort((a, b) => b.at.compareTo(a.at));
  if (items.length <= limit) {
    return items;
  }
  return items.sublist(0, limit);
}

/// Text + color badge for a live booking row.
enum AdminLiveBadge { paid, cancelled, partialRefund, other }

AdminLiveBadge liveBadgeFor(TourBooking booking) {
  if (overviewIsCancelled(booking) &&
      booking.refundAmount > 0 &&
      booking.refundAmount < booking.price) {
    return AdminLiveBadge.partialRefund;
  }
  if (overviewIsCancelled(booking)) {
    return AdminLiveBadge.cancelled;
  }
  if (booking.paymentStatus == PaymentStatus.captured) {
    return AdminLiveBadge.paid;
  }
  return AdminLiveBadge.other;
}

List<TourBooking> latestLiveBookings(
  Map<String, List<TourBooking>> byShop, {
  int limit = 5,
}) {
  final byId = <String, TourBooking>{};
  for (final list in byShop.values) {
    for (final booking in list) {
      byId[booking.id] = booking;
    }
  }
  final all = byId.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (all.length <= limit) {
    return all;
  }
  return all.sublist(0, limit);
}
