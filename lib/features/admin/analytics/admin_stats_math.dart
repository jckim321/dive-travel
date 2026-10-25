import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dive_star_milestone.dart';

enum AdminStatsPreset { thisWeek, thisMonth, threeMonths, thisYear }

class AdminShopGrade {
  const AdminShopGrade({required this.shopId, required this.diveStar});

  final String shopId;
  final int diveStar;
}

class AdminOptionPick {
  const AdminOptionPick({required this.name, required this.count});

  final String name;
  final int count;
}

class AdminStatsSnapshot {
  const AdminStatsSnapshot({
    required this.window,
    required this.sales,
    required this.dailyNet,
    required this.dailyYearAgoNet,
    required this.hasYearAgo,
    required this.gradeCounts,
    required this.gradeUnknown,
    required this.newBuyers,
    required this.returnBuyers,
    required this.buyerUnknown,
    required this.options,
    required this.topOption,
    required this.cancelByMonth,
    required this.monthLabels,
    required this.topCancelled,
    required this.diveStarCounts,
    required this.leadCounts,
    required this.seasonCounts,
    required this.countries,
  });

  final AdminSalesWindow window;
  final AdminSalesSnapshot sales;
  final List<int> dailyNet;
  final List<int> dailyYearAgoNet;
  final bool hasYearAgo;
  final Map<ProfileDisplayGrade, int> gradeCounts;
  final int gradeUnknown;
  final int newBuyers;
  final int returnBuyers;
  final int buyerUnknown;
  final List<AdminOptionPick> options;
  final String? topOption;
  final List<int> cancelByMonth;
  final List<String> monthLabels;
  final List<AdminProductRank> topCancelled;
  final Map<PartnerDiveStarMilestoneStep, int> diveStarCounts;
  final List<int> leadCounts;
  final List<int> seasonCounts;
  final List<AdminCountryRow> countries;
}

class AdminCountryRow {
  const AdminCountryRow({
    required this.code,
    required this.count,
    required this.net,
  });

  /// Empty when the booking has no uid, no member document, or no nationality.
  final String code;
  final int count;
  final int net;
}

AdminSalesWindow adminStatsWindow({
  required AdminStatsPreset preset,
  required DateTime now,
}) {
  switch (preset) {
    case AdminStatsPreset.thisWeek:
      return adminSalesWindow(preset: AdminSalesPreset.thisWeek, now: now);
    case AdminStatsPreset.thisMonth:
      return adminSalesWindow(preset: AdminSalesPreset.thisMonth, now: now);
    case AdminStatsPreset.threeMonths:
      return adminSalesWindow(preset: AdminSalesPreset.threeMonths, now: now);
    case AdminStatsPreset.thisYear:
      final today = adminSalesDateOnly(now);
      return AdminSalesWindow(
        start: DateTime(now.year, 1, 1),
        end: today.add(const Duration(days: 1)),
      );
  }
}

/// Twelve calendar months ending at [now], plus the same span last year.
AdminSalesWindow adminStatsLoadWindow(DateTime now) {
  final end = DateTime(now.year, now.month + 1, 1);
  final start = DateTime(now.year, now.month - 11, 1);
  final yearStart = adminSalesMinusYear(start);
  final yearEnd = adminSalesMinusYear(end);
  final loadStart = yearStart.isBefore(start) ? yearStart : start;
  final loadEnd = yearEnd.isAfter(end) ? yearEnd : end;
  return AdminSalesWindow(start: loadStart, end: loadEnd);
}

List<DateTime> _days(AdminSalesWindow window) {
  final days = <DateTime>[];
  var cursor = adminSalesDateOnly(window.start);
  final end = adminSalesDateOnly(window.end);
  while (cursor.isBefore(end)) {
    days.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
  }
  return days;
}

int _leadBucket(TourBooking booking) {
  final tour = booking.tourDate;
  if (tour == null) {
    return 0;
  }
  final days = adminSalesDateOnly(tour)
      .difference(adminSalesDateOnly(booking.createdAt))
      .inDays;
  if (days <= 0) {
    return 0;
  }
  if (days <= 3) {
    return 1;
  }
  if (days <= 7) {
    return 2;
  }
  if (days <= 14) {
    return 3;
  }
  if (days <= 30) {
    return 4;
  }
  return 5;
}

AdminStatsSnapshot buildAdminStatsSnapshot({
  required List<TourBooking> bookings,
  required AdminSalesWindow window,
  required DateTime now,
  required List<AdminCatalogItem> catalog,
  required List<MemberAccount> members,
  required List<AdminShopGrade> shops,
  required List<DiveStarApplication> applications,
}) {
  final compare = adminSalesCompareWindow(
    window: window,
    compare: AdminSalesCompare.yearAgo,
  );
  final sales = buildAdminSalesSnapshot(
    bookings: bookings,
    window: window,
    compareWindow: compare,
    catalog: catalog,
  );
  final days = _days(window);
  final daily = [for (final day in days) adminSalesDayNet(bookings, day)];
  final priorDays = [for (final day in days) adminSalesMinusYear(day)];
  final dailyPrior = [
    for (final day in priorDays) adminSalesDayNet(bookings, day),
  ];
  final hasYearAgo = bookings.any(
    (booking) => compare.contains(booking.createdAt),
  );

  final membersByUid = {for (final member in members) member.uid: member};
  final grades = {for (final grade in ProfileDisplayGrade.values) grade: 0};
  var gradeUnknown = 0;
  var fresh = 0;
  var returning = 0;
  var buyerUnknown = 0;
  final optionCounts = <String, int>{};
  final lead = List<int>.filled(6, 0);
  final countryAcc = <String, _CountryAcc>{};
  for (final booking in bookings) {
    if (!window.contains(booking.createdAt)) {
      continue;
    }
    final country = countryAcc.putIfAbsent(
      _countryCode(booking, membersByUid),
      _CountryAcc.new,
    );
    country.count++;
    country.net += _countryNet(booking);
    lead[_leadBucket(booking)]++;
    final member = membersByUid[booking.uid];
    if (member == null) {
      gradeUnknown++;
    } else {
      final shown = ProfileDisplayGrade.fromMember(
        grade: member.grade,
        isInstructor: member.isInstructor,
      );
      grades[shown] = (grades[shown] ?? 0) + 1;
    }
    if (adminSalesWasPaid(booking)) {
      if (member == null) {
        buyerUnknown++;
      } else if (member.paidPurchaseCount >= 2) {
        returning++;
      } else {
        fresh++;
      }
    }
    final raw = booking.optionName.trim();
    if (raw.isEmpty) {
      continue;
    }
    for (final part in raw.split('·')) {
      final name = part.trim();
      if (name.isEmpty) {
        continue;
      }
      optionCounts[name] = (optionCounts[name] ?? 0) + 1;
    }
  }
  final options = [
    for (final entry in optionCounts.entries)
      AdminOptionPick(name: entry.key, count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));
  final topOptions = options.length > 6 ? options.sublist(0, 6) : options;

  final months = <DateTime>[
    for (var i = 11; i >= 0; i--) DateTime(now.year, now.month - i, 1),
  ];
  final cancelByMonth = <int>[];
  final season = <int>[];
  for (final month in months) {
    final monthWindow = AdminSalesWindow(
      start: month,
      end: DateTime(month.year, month.month + 1, 1),
    );
    var cancels = 0;
    var received = 0;
    for (final booking in bookings) {
      if (!monthWindow.contains(booking.createdAt)) {
        continue;
      }
      received++;
      if (adminSalesIsCancelled(booking)) {
        cancels++;
      }
    }
    cancelByMonth.add(cancels);
    season.add(received);
  }

  final cancelProducts = <String, _CancelAcc>{};
  for (final booking in bookings) {
    if (!window.contains(booking.createdAt) || !adminSalesIsCancelled(booking)) {
      continue;
    }
    final key = booking.productId.isNotEmpty
        ? '${booking.shopId}|${booking.productId}'
        : '${booking.shopId}|${booking.productName}';
    final acc = cancelProducts.putIfAbsent(key, _CancelAcc.new);
    acc.count++;
    if (acc.label.isEmpty) {
      acc.label = booking.productName.trim().isEmpty
          ? booking.shopId
          : booking.productName.trim();
    }
    acc.shopName = booking.shopName.trim();
  }
  final cancelledRanks = cancelProducts.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  final topCancelled = <AdminProductRank>[
    for (final item in cancelledRanks.take(3))
      AdminProductRank(
        label: item.label,
        shopName: item.shopName,
        net: 0,
        count: item.count,
      ),
  ];

  final dive = {for (final step in PartnerDiveStarMilestoneStep.values) step: 0};
  for (final shop in shops) {
    final step = PartnerDiveStarMilestone.resolve(
      diveStarGrade: shop.diveStar,
      latestApplication: PartnerDiveStarMilestone.latestForShop(
        applications,
        shop.shopId,
      ),
    );
    dive[step] = (dive[step] ?? 0) + 1;
  }

  return AdminStatsSnapshot(
    window: window,
    sales: sales,
    dailyNet: daily,
    dailyYearAgoNet: dailyPrior,
    hasYearAgo: hasYearAgo,
    gradeCounts: grades,
    gradeUnknown: gradeUnknown,
    newBuyers: fresh,
    returnBuyers: returning,
    buyerUnknown: buyerUnknown,
    options: topOptions,
    topOption: topOptions.isEmpty ? null : topOptions.first.name,
    cancelByMonth: cancelByMonth,
    monthLabels: [for (final month in months) '${month.month}'],
    topCancelled: topCancelled,
    diveStarCounts: dive,
    leadCounts: lead,
    seasonCounts: season,
    countries: _countryRows(countryAcc),
  );
}

String _countryCode(
  TourBooking booking,
  Map<String, MemberAccount> membersByUid,
) {
  final uid = booking.uid.trim();
  if (uid.isEmpty) {
    return '';
  }
  final member = membersByUid[uid];
  if (member == null) {
    return '';
  }
  return normalizeNationalityCode(member.nationality) ?? '';
}

/// Same paid-minus-refund amount the sales snapshot uses for one booking.
int _countryNet(TourBooking booking) {
  if (!adminSalesWasPaid(booking)) {
    return 0;
  }
  var net = booking.price;
  if (adminSalesIsCancelled(booking)) {
    net -= booking.refundAmount;
  }
  return net;
}

List<AdminCountryRow> _countryRows(Map<String, _CountryAcc> acc) {
  final rows = [
    for (final entry in acc.entries)
      AdminCountryRow(
        code: entry.key,
        count: entry.value.count,
        net: entry.value.net,
      ),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) {
        return byCount;
      }
      return b.net.compareTo(a.net);
    });
  return rows;
}

class _CancelAcc {
  int count = 0;
  String label = '';
  String shopName = '';
}

class _CountryAcc {
  int count = 0;
  int net = 0;
}
