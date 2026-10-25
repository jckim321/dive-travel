import 'package:dive_travel_app/core/models/pro_verification.dart';

/// Month summary for partner settlement (createdAt / 접수일 기준).
class PartnerSettlementMonth {
  const PartnerSettlementMonth({
    required this.year,
    required this.month,
    required this.validCount,
    required this.cancelledCount,
    required this.grossPaid,
    required this.refundTotal,
    required this.rows,
  });

  final int year;
  final int month;

  /// Still active + paid in this receive-month cohort.
  final int validCount;

  /// Cancelled / weather-cancelled among paid receive-month cohort.
  final int cancelledCount;

  /// Sum of [TourBooking.price] for all paid (or later-refunded) bookings
  /// received in this month — includes later cancellations.
  final int grossPaid;

  /// Sum of [TourBooking.refundAmount] for cancelled cohort members.
  final int refundTotal;

  final List<TourBooking> rows;

  int get netSales => grossPaid - refundTotal;
}

bool _wasPaid(TourBooking b) {
  return b.paymentStatus == PaymentStatus.captured ||
      b.paymentStatus == PaymentStatus.refunded;
}

bool _isCancelled(TourBooking b) {
  return b.status == BookingStatus.cancelled ||
      b.status == BookingStatus.weatherCancelled;
}

bool _inReceiveMonth(TourBooking b, int year, int month) {
  return b.createdAt.year == year && b.createdAt.month == month;
}

/// Settlement for [year]/[month] keyed by booking receive date ([createdAt]).
PartnerSettlementMonth computePartnerSettlementMonth({
  required List<TourBooking> bookings,
  required int year,
  required int month,
}) {
  final cohort = [
    for (final b in bookings)
      if (_inReceiveMonth(b, year, month) && _wasPaid(b)) b,
  ];
  cohort.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  var valid = 0;
  var cancelled = 0;
  var gross = 0;
  var refunds = 0;
  for (final b in cohort) {
    gross += b.price;
    if (_isCancelled(b)) {
      cancelled++;
      refunds += b.refundAmount;
    } else if (b.isActive && b.isPaid) {
      valid++;
    } else if (b.isActive) {
      // Active but payment no longer captured (edge): still in gross via _wasPaid.
      valid++;
    }
  }

  return PartnerSettlementMonth(
    year: year,
    month: month,
    validCount: valid,
    cancelledCount: cancelled,
    grossPaid: gross,
    refundTotal: refunds,
    rows: cohort,
  );
}
