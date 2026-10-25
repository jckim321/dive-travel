import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_settlement_logic.dart';

/// Longest custom receive window. Longer picks are cut to this.
const int adminSalesMaxMonths = 12;

enum AdminSalesPreset { today, thisWeek, thisMonth, threeMonths, custom }

enum AdminSalesCompare { previous, yearAgo }

enum AdminSalesBucket { tour, course, experience, sameBoat, unknown }

class AdminSalesWindow {
  const AdminSalesWindow({
    required this.start,
    required this.end,
    this.clamped = false,
  });

  /// Inclusive.
  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final bool clamped;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
}

class AdminCatalogItem {
  const AdminCatalogItem({
    required this.shopId,
    required this.productId,
    required this.name,
    required this.category,
  });

  final String shopId;
  final String productId;
  final String name;
  final ProductCategory category;
}

class AdminSalesTotals {
  const AdminSalesTotals({
    required this.received,
    required this.paidCount,
    required this.cancelCount,
    required this.gross,
    required this.refund,
    required this.activePartners,
  });

  final int received;
  final int paidCount;
  final int cancelCount;
  final int gross;
  final int refund;
  final int activePartners;

  int get net => gross - refund;

  int? get average => paidCount == 0 ? null : gross ~/ paidCount;

  /// Cancelled receive-cohort ÷ all received bookings. Unpaid counts.
  double? get cancelRate => received == 0 ? null : cancelCount / received;

  static const empty = AdminSalesTotals(
    received: 0,
    paidCount: 0,
    cancelCount: 0,
    gross: 0,
    refund: 0,
    activePartners: 0,
  );
}

class AdminPartnerPerformance {
  const AdminPartnerPerformance({
    required this.shopId,
    required this.shopName,
    required this.received,
    required this.gross,
    required this.refund,
    required this.net,
    required this.compareNet,
    required this.cancelCount,
    required this.share,
    required this.mine,
  });

  final String shopId;
  final String shopName;
  final int received;
  final int gross;
  final int refund;
  final int net;
  final int compareNet;
  final int cancelCount;
  final double? share;
  final bool mine;

  double? get cancelRate => received == 0 ? null : cancelCount / received;
}

class AdminCategoryShare {
  const AdminCategoryShare({
    required this.bucket,
    required this.net,
    required this.share,
  });

  final AdminSalesBucket bucket;
  final int net;
  final double? share;
}

class AdminProductRank {
  const AdminProductRank({
    required this.label,
    required this.shopName,
    required this.net,
    required this.count,
  });

  final String label;
  final String shopName;
  final int net;
  final int count;
}

class AdminSalesSnapshot {
  const AdminSalesSnapshot({
    required this.window,
    required this.compareWindow,
    required this.totals,
    required this.compareTotals,
    required this.partners,
    required this.categories,
    required this.topProducts,
  });

  final AdminSalesWindow window;
  final AdminSalesWindow compareWindow;
  final AdminSalesTotals totals;
  final AdminSalesTotals compareTotals;
  final List<AdminPartnerPerformance> partners;
  final List<AdminCategoryShare> categories;
  final List<AdminProductRank> topProducts;
}

bool adminSalesWasPaid(TourBooking booking) {
  return booking.paymentStatus == PaymentStatus.captured ||
      booking.paymentStatus == PaymentStatus.refunded;
}

bool adminSalesIsCancelled(TourBooking booking) {
  return booking.status == BookingStatus.cancelled ||
      booking.status == BookingStatus.weatherCancelled;
}

DateTime adminSalesDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime adminSalesStartOfWeek(DateTime value) {
  final day = adminSalesDateOnly(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime adminSalesMinusYear(DateTime value) {
  final year = value.year - 1;
  final lastDay = DateTime(year, value.month + 1, 0).day;
  final day = value.day > lastDay ? lastDay : value.day;
  return DateTime(
    year,
    value.month,
    day,
    value.hour,
    value.minute,
    value.second,
  );
}

AdminSalesWindow adminSalesWindow({
  required AdminSalesPreset preset,
  required DateTime now,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final today = adminSalesDateOnly(now);
  switch (preset) {
    case AdminSalesPreset.today:
      return AdminSalesWindow(
        start: today,
        end: today.add(const Duration(days: 1)),
      );
    case AdminSalesPreset.thisWeek:
      final start = adminSalesStartOfWeek(now);
      return AdminSalesWindow(
        start: start,
        end: start.add(const Duration(days: 7)),
      );
    case AdminSalesPreset.thisMonth:
      return AdminSalesWindow(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1),
      );
    case AdminSalesPreset.threeMonths:
      return AdminSalesWindow(
        start: DateTime(now.year, now.month - 2, 1),
        end: DateTime(now.year, now.month + 1, 1),
      );
    case AdminSalesPreset.custom:
      var start = adminSalesDateOnly(customStart ?? today);
      var end = adminSalesDateOnly(customEnd ?? today).add(
        const Duration(days: 1),
      );
      if (!end.isAfter(start)) {
        end = start.add(const Duration(days: 1));
      }
      final cap = DateTime(start.year, start.month + adminSalesMaxMonths, start.day);
      var clamped = false;
      if (end.isAfter(cap)) {
        end = cap;
        clamped = true;
      }
      return AdminSalesWindow(start: start, end: end, clamped: clamped);
  }
}

AdminSalesWindow adminSalesCompareWindow({
  required AdminSalesWindow window,
  required AdminSalesCompare compare,
}) {
  if (compare == AdminSalesCompare.yearAgo) {
    return AdminSalesWindow(
      start: adminSalesMinusYear(window.start),
      end: adminSalesMinusYear(window.end),
    );
  }
  if (window.start.day == 1 && window.end.day == 1) {
    final months = (window.end.year - window.start.year) * 12 +
        window.end.month -
        window.start.month;
    return AdminSalesWindow(
      start: DateTime(window.start.year, window.start.month - months, 1),
      end: window.start,
    );
  }
  final length = window.end.difference(window.start);
  return AdminSalesWindow(
    start: window.start.subtract(length),
    end: window.start,
  );
}

AdminCatalogItem? adminCatalogMatch(
  TourBooking booking,
  Map<String, AdminCatalogItem> byShopProduct,
  Map<String, AdminCatalogItem> byShopName,
) {
  if (booking.productId.isNotEmpty) {
    final hit = byShopProduct['${booking.shopId}|${booking.productId}'];
    if (hit != null) {
      return hit;
    }
  }
  final name = booking.productName.trim();
  if (name.isEmpty) {
    return null;
  }
  return byShopName['${booking.shopId}|$name'];
}

Map<String, AdminCatalogItem> adminCatalogByProduct(List<AdminCatalogItem> items) {
  return {for (final item in items) '${item.shopId}|${item.productId}': item};
}

Map<String, AdminCatalogItem> adminCatalogByName(List<AdminCatalogItem> items) {
  return {for (final item in items) '${item.shopId}|${item.name}': item};
}

AdminSalesBucket adminSalesBucket(TourBooking booking, AdminCatalogItem? item) {
  if (booking.fromFlag) {
    return AdminSalesBucket.sameBoat;
  }
  if (item == null) {
    return AdminSalesBucket.unknown;
  }
  switch (item.category) {
    case ProductCategory.course:
      return AdminSalesBucket.course;
    case ProductCategory.funDive:
      return AdminSalesBucket.experience;
    case ProductCategory.resortPackage:
    case ProductCategory.dayTrip:
    case ProductCategory.liveaboard:
      return AdminSalesBucket.tour;
  }
}

class _ShopAcc {
  int received = 0;
  int gross = 0;
  int refund = 0;
  int cancelCount = 0;
  String name = '';
}

class _ProductAcc {
  int net = 0;
  int count = 0;
  String label = '';
  String shopName = '';
}

AdminSalesSnapshot buildAdminSalesSnapshot({
  required List<TourBooking> bookings,
  required AdminSalesWindow window,
  required AdminSalesWindow compareWindow,
  required List<AdminCatalogItem> catalog,
  String? ownedShopId,
}) {
  final byProduct = adminCatalogByProduct(catalog);
  final byName = adminCatalogByName(catalog);
  final current = _accumulate(bookings, window, byProduct, byName);
  final prior = _accumulate(bookings, compareWindow, byProduct, byName);
  final totalNet = current.totals.net;
  final partners = <AdminPartnerPerformance>[];
  final shopIds = {...current.shops.keys, ...prior.shops.keys};
  for (final id in shopIds) {
    final row = current.shops[id];
    if (row == null || row.received == 0) {
      continue;
    }
    final net = row.gross - row.refund;
    partners.add(
      AdminPartnerPerformance(
        shopId: id,
        shopName: row.name.isEmpty ? id : row.name,
        received: row.received,
        gross: row.gross,
        refund: row.refund,
        net: net,
        compareNet: () {
          final old = prior.shops[id];
          if (old == null) {
            return 0;
          }
          return old.gross - old.refund;
        }(),
        cancelCount: row.cancelCount,
        share: totalNet == 0 ? null : net / totalNet,
        mine: ownedShopId != null &&
            ownedShopId.isNotEmpty &&
            ownedShopId == id,
      ),
    );
  }
  partners.sort((a, b) {
    final byNet = b.net.compareTo(a.net);
    if (byNet != 0) {
      return byNet;
    }
    return a.shopName.compareTo(b.shopName);
  });

  final categories = <AdminCategoryShare>[];
  for (final bucket in AdminSalesBucket.values) {
    final net = current.bucketNet[bucket] ?? 0;
    if (bucket == AdminSalesBucket.unknown && net == 0) {
      continue;
    }
    categories.add(
      AdminCategoryShare(
        bucket: bucket,
        net: net,
        share: totalNet == 0 ? null : net / totalNet,
      ),
    );
  }

  final products = current.products.values.toList()
    ..sort((a, b) {
      final byNet = b.net.compareTo(a.net);
      if (byNet != 0) {
        return byNet;
      }
      return b.count.compareTo(a.count);
    });
  final top = <AdminProductRank>[];
  for (final product in products) {
    if (top.length == 5) {
      break;
    }
    if (product.count == 0) {
      continue;
    }
    top.add(
      AdminProductRank(
        label: product.label,
        shopName: product.shopName,
        net: product.net,
        count: product.count,
      ),
    );
  }

  return AdminSalesSnapshot(
    window: window,
    compareWindow: compareWindow,
    totals: current.totals,
    compareTotals: prior.totals,
    partners: partners,
    categories: categories,
    topProducts: top,
  );
}

class _Accum {
  AdminSalesTotals totals = AdminSalesTotals.empty;
  final shops = <String, _ShopAcc>{};
  final bucketNet = <AdminSalesBucket, int>{};
  final products = <String, _ProductAcc>{};
}

_Accum _accumulate(
  List<TourBooking> bookings,
  AdminSalesWindow window,
  Map<String, AdminCatalogItem> byProduct,
  Map<String, AdminCatalogItem> byName,
) {
  final acc = _Accum();
  var received = 0;
  var paidCount = 0;
  var cancelCount = 0;
  var gross = 0;
  var refund = 0;
  final active = <String>{};
  for (final booking in bookings) {
    if (!window.contains(booking.createdAt)) {
      continue;
    }
    received++;
    active.add(booking.shopId);
    final shop = acc.shops.putIfAbsent(booking.shopId, _ShopAcc.new);
    shop.received++;
    if (shop.name.isEmpty && booking.shopName.trim().isNotEmpty) {
      shop.name = booking.shopName.trim();
    }
    final cancelled = adminSalesIsCancelled(booking);
    if (cancelled) {
      cancelCount++;
      shop.cancelCount++;
    }
    final item = adminCatalogMatch(booking, byProduct, byName);
    final bucket = adminSalesBucket(booking, item);
    var contribution = 0;
    if (adminSalesWasPaid(booking)) {
      paidCount++;
      gross += booking.price;
      shop.gross += booking.price;
      contribution += booking.price;
      if (cancelled) {
        refund += booking.refundAmount;
        shop.refund += booking.refundAmount;
        contribution -= booking.refundAmount;
      }
    }
    acc.bucketNet[bucket] = (acc.bucketNet[bucket] ?? 0) + contribution;
    final productKey = booking.productId.isNotEmpty
        ? '${booking.shopId}|${booking.productId}'
        : '${booking.shopId}|name:${booking.productName.trim()}';
    final product = acc.products.putIfAbsent(productKey, _ProductAcc.new);
    product.count++;
    product.net += contribution;
    if (product.label.isEmpty) {
      product.label = item?.name.trim().isNotEmpty == true
          ? item!.name.trim()
          : (booking.productName.trim().isEmpty
                ? booking.shopId
                : booking.productName.trim());
    }
    if (product.shopName.isEmpty) {
      product.shopName = booking.shopName.trim();
    }
  }
  acc.totals = AdminSalesTotals(
    received: received,
    paidCount: paidCount,
    cancelCount: cancelCount,
    gross: gross,
    refund: refund,
    activePartners: active.length,
  );
  return acc;
}

/// Net sales for bookings received on [day] (local date).
int adminSalesDayNet(List<TourBooking> bookings, DateTime day) {
  final start = adminSalesDateOnly(day);
  final end = start.add(const Duration(days: 1));
  var net = 0;
  for (final booking in bookings) {
    if (booking.createdAt.isBefore(start) || !booking.createdAt.isBefore(end)) {
      continue;
    }
    if (!adminSalesWasPaid(booking)) {
      continue;
    }
    net += booking.price;
    if (adminSalesIsCancelled(booking)) {
      net -= booking.refundAmount;
    }
  }
  return net;
}

/// A full calendar month's net must match partner settlement.
int adminSalesNetForCalendarMonth({
  required List<TourBooking> bookings,
  required int year,
  required int month,
}) {
  final window = AdminSalesWindow(
    start: DateTime(year, month, 1),
    end: DateTime(year, month + 1, 1),
  );
  final snapshot = buildAdminSalesSnapshot(
    bookings: bookings,
    window: window,
    compareWindow: adminSalesCompareWindow(
      window: window,
      compare: AdminSalesCompare.previous,
    ),
    catalog: const [],
  );
  return snapshot.totals.net;
}

int partnerSettlementNet({
  required List<TourBooking> bookings,
  required int year,
  required int month,
}) {
  return computePartnerSettlementMonth(
    bookings: bookings,
    year: year,
    month: month,
  ).netSales;
}
