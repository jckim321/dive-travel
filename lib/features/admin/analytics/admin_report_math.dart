import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';

enum AdminReportPeriod { month, quarter, year, custom }

enum AdminReportCompare { previous, yearAgo, none }

class AdminReportDocument {
  const AdminReportDocument({
    required this.periodLabel,
    required this.snapshot,
    required this.dailyNet,
    required this.showSummary,
    required this.showTrend,
    required this.showPartners,
    required this.showProducts,
    required this.showOptions,
    required this.showCancels,
    required this.showBasis,
    required this.options,
    required this.topOption,
    required this.optionsApply,
    required this.basisText,
    required this.fontLicense,
  });

  final String periodLabel;
  final AdminSalesSnapshot snapshot;
  final List<int> dailyNet;
  final bool showSummary;
  final bool showTrend;
  final bool showPartners;
  final bool showProducts;
  final bool showOptions;
  final bool showCancels;
  final bool showBasis;
  final List<({String name, int count})> options;
  final String? topOption;

  /// True only when the reader picked exactly one product.
  final bool optionsApply;
  final String basisText;
  final String fontLicense;
}

AdminSalesWindow adminReportWindow({
  required AdminReportPeriod period,
  required DateTime now,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  switch (period) {
    case AdminReportPeriod.month:
      return adminSalesWindow(preset: AdminSalesPreset.thisMonth, now: now);
    case AdminReportPeriod.quarter:
      final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
      return AdminSalesWindow(
        start: DateTime(now.year, startMonth, 1),
        end: DateTime(now.year, startMonth + 3, 1),
      );
    case AdminReportPeriod.year:
      return AdminSalesWindow(
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year + 1, 1, 1),
      );
    case AdminReportPeriod.custom:
      return adminSalesWindow(
        preset: AdminSalesPreset.custom,
        now: now,
        customStart: customStart,
        customEnd: customEnd,
      );
  }
}

AdminSalesWindow adminReportCompareWindow({
  required AdminSalesWindow window,
  required AdminReportCompare compare,
}) {
  if (compare == AdminReportCompare.none) {
    return AdminSalesWindow(
      start: DateTime(1900),
      end: DateTime(1900),
    );
  }
  return adminSalesCompareWindow(
    window: window,
    compare: compare == AdminReportCompare.yearAgo
        ? AdminSalesCompare.yearAgo
        : AdminSalesCompare.previous,
  );
}

List<({String name, int count})> adminReportOptionPicks({
  required List<TourBooking> bookings,
  required AdminSalesWindow window,
}) {
  final counts = <String, int>{};
  for (final booking in bookings) {
    if (!window.contains(booking.createdAt)) {
      continue;
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
      counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  final rows = [
    for (final entry in counts.entries) (name: entry.key, count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));
  if (rows.length > 8) {
    return rows.sublist(0, 8);
  }
  return rows;
}

AdminReportDocument buildAdminReportDocument({
  required List<TourBooking> bookings,
  required AdminSalesWindow window,
  required AdminSalesWindow compareWindow,
  required List<AdminCatalogItem> catalog,
  required Set<AdminSalesBucket> buckets,
  required Set<String> shopIds,
  required Set<String> productKeys,
  required String periodLabel,
  required bool showSummary,
  required bool showTrend,
  required bool showPartners,
  required bool showProducts,
  required bool showOptions,
  required bool showCancels,
  required bool showBasis,
  required String basisText,
  required String fontLicense,
}) {
  final byProduct = adminCatalogByProduct(catalog);
  final byName = adminCatalogByName(catalog);
  final allBuckets = buckets.length >= 4;
  final filtered = [
    for (final booking in bookings)
      if (_keep(
        booking,
        buckets: buckets,
        allBuckets: allBuckets,
        shopIds: shopIds,
        productKeys: productKeys,
        byProduct: byProduct,
        byName: byName,
      ))
        booking,
  ];
  final snapshot = buildAdminSalesSnapshot(
    bookings: filtered,
    window: window,
    compareWindow: compareWindow,
    catalog: catalog,
  );
  final days = <DateTime>[];
  var cursor = adminSalesDateOnly(window.start);
  final end = adminSalesDateOnly(window.end);
  var guard = 0;
  while (cursor.isBefore(end) && guard < 400) {
    days.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
    guard++;
  }
  final optionsApply = productKeys.length == 1;
  final options = optionsApply
      ? adminReportOptionPicks(bookings: filtered, window: window)
      : const <({String name, int count})>[];
  return AdminReportDocument(
    periodLabel: periodLabel,
    snapshot: snapshot,
    dailyNet: [for (final day in days) adminSalesDayNet(filtered, day)],
    showSummary: showSummary,
    showTrend: showTrend,
    showPartners: showPartners,
    showProducts: showProducts,
    showOptions: showOptions,
    showCancels: showCancels,
    showBasis: showBasis,
    options: options,
    topOption: options.isEmpty ? null : options.first.name,
    optionsApply: optionsApply,
    basisText: basisText,
    fontLicense: fontLicense,
  );
}

bool _keep(
  TourBooking booking, {
  required Set<AdminSalesBucket> buckets,
  required bool allBuckets,
  required Set<String> shopIds,
  required Set<String> productKeys,
  required Map<String, AdminCatalogItem> byProduct,
  required Map<String, AdminCatalogItem> byName,
}) {
  if (shopIds.isNotEmpty && !shopIds.contains(booking.shopId)) {
    return false;
  }
  if (productKeys.isNotEmpty) {
    final key = '${booking.shopId}|${booking.productId}';
    if (!productKeys.contains(key)) {
      return false;
    }
  }
  final bucket = adminSalesBucket(
    booking,
    adminCatalogMatch(booking, byProduct, byName),
  );
  if (bucket == AdminSalesBucket.unknown) {
    return allBuckets;
  }
  return buckets.contains(bucket);
}
