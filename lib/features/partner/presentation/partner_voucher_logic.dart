import 'package:dive_travel_app/core/models/pro_verification.dart';

/// Partner voucher list tabs (시안 24).
enum PartnerVoucherTab { arrived, past, cancelled }

DateTime partnerVoucherDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool partnerVoucherIsPastTour(TourBooking booking, {DateTime? now}) {
  final today = partnerVoucherDateOnly(now ?? DateTime.now());
  return partnerVoucherDateOnly(booking.scheduledFor).isBefore(today);
}

bool partnerVoucherMatchesTab(
  TourBooking booking,
  PartnerVoucherTab tab, {
  DateTime? now,
}) {
  return switch (tab) {
    PartnerVoucherTab.arrived =>
      booking.isActive && !partnerVoucherIsPastTour(booking, now: now),
    PartnerVoucherTab.past =>
      booking.isActive && partnerVoucherIsPastTour(booking, now: now),
    PartnerVoucherTab.cancelled =>
      booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.weatherCancelled,
  };
}

List<TourBooking> filterPartnerVouchers({
  required Iterable<TourBooking> bookings,
  required PartnerVoucherTab tab,
  DateTime? now,
}) {
  final list = [
    for (final booking in bookings)
      if (partnerVoucherMatchesTab(booking, tab, now: now)) booking,
  ];
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

class PartnerVoucherTabCounts {
  const PartnerVoucherTabCounts({
    required this.arrived,
    required this.past,
    required this.cancelled,
  });

  final int arrived;
  final int past;
  final int cancelled;
}

PartnerVoucherTabCounts partnerVoucherTabCounts(
  Iterable<TourBooking> bookings, {
  DateTime? now,
}) {
  var arrived = 0;
  var past = 0;
  var cancelled = 0;
  for (final booking in bookings) {
    if (partnerVoucherMatchesTab(booking, PartnerVoucherTab.arrived, now: now)) {
      arrived += 1;
    } else if (partnerVoucherMatchesTab(
      booking,
      PartnerVoucherTab.past,
      now: now,
    )) {
      past += 1;
    } else if (partnerVoucherMatchesTab(
      booking,
      PartnerVoucherTab.cancelled,
      now: now,
    )) {
      cancelled += 1;
    }
  }
  return PartnerVoucherTabCounts(
    arrived: arrived,
    past: past,
    cancelled: cancelled,
  );
}

/// Unread arrived vouchers (for home badge).
int partnerVoucherUnreadArrivedCount(
  Iterable<TourBooking> bookings, {
  DateTime? now,
}) {
  var count = 0;
  for (final booking in bookings) {
    if (!partnerVoucherMatchesTab(
      booking,
      PartnerVoucherTab.arrived,
      now: now,
    )) {
      continue;
    }
    if (!booking.partnerAcked) {
      count += 1;
    }
  }
  return count;
}

/// Honest status chip for partner vouchers (no fake payment-complete).
enum PartnerVoucherStatusKind { awaitingConfirm, confirmed, cancelled }

PartnerVoucherStatusKind partnerVoucherStatusKind(TourBooking booking) {
  return switch (booking.status) {
    BookingStatus.requested => PartnerVoucherStatusKind.awaitingConfirm,
    BookingStatus.confirmed => PartnerVoucherStatusKind.confirmed,
    BookingStatus.cancelled ||
    BookingStatus.weatherCancelled =>
      PartnerVoucherStatusKind.cancelled,
  };
}

/// FOC line from quote labels, if any.
String? partnerVoucherFocLabel(TourBooking booking) {
  for (final line in booking.quoteLines) {
    final label = line.label.trim();
    if (label.isEmpty) {
      continue;
    }
    final lower = label.toLowerCase();
    if (label.contains('FOC') ||
        label.contains('foc') ||
        (lower.contains('강사') && lower.contains('무료'))) {
      return label;
    }
  }
  return null;
}
